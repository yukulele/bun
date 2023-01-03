var symbolFor = Symbol.for;

const lazy = globalThis[symbolFor("Bun.lazy")];
if (!lazy || typeof lazy !== "function") {
  throw new Error(
    "Something went wrong while loading Bun. Expected 'Bun.lazy' to be defined.",
  );
}

var defineProperties = Object.defineProperties;
const { createFIFO } = import.meta.primordials;

var nativeConnect = lazy("bun:sql");

export class SQL extends Promise {
  #connection;

  active = false;
  #executed = false;
  #resolve;
  #reject;
  #query;

  get executed() {
    return this.#executed;
  }

  constructor(connection, query) {
    let resolve, reject;
    super((resolve1, reject1) => {
      resolve = resolve1;
      reject = reject1;
    });
    this.#resolve = resolve;
    this.#reject = reject;
    this.#connection = connection;
    this.#query = query;
  }

  static get [Symbol.species]() {
    return Promise;
  }

  async #handle() {
    if (this.#executed) {
      return;
    }

    this.#executed = true;
    var resolve = this.#resolve,
      reject = this.#reject,
      query = this.#query,
      connection = this.#connection;
    this.#reject = this.#resolve = this.#query = this.#connection = undefined;
    connection.query(query, resolve, reject);
  }

  then() {
    this.#handle();
    return super.then.apply(this, arguments);
  }

  catch() {
    this.#handle();
    return super.catch.apply(this, arguments);
  }

  finally() {
    this.#handle();
    return super.finally.apply(this, arguments);
  }
}

const readyStateConnecting = 0,
  readyStateConnected = 1,
  readyStateClosed = 2;

const IS_DEBUG = Bun.version.includes("_debug");
const connectionInternalTag = Symbol("connectionInternalTag");

export class Connection {
  #handle = undefined;
  #hostIndex = 0;
  host;
  port;

  #queue = createFIFO();
  query;
  #options;
  #closeRequested = false;
  #needsDrain = false;
  #readyState;

  constructor(options, internalTag) {
    if (!IS_DEBUG && internalTag !== connectionInternalTag)
      throw new Error("Cannot instantiate Connection directly");

    this.#options = options;
    this.host = options.host;
    this.port = options.port;
    this.#hostIndex = 0;
    this.query = this.#queryEnqueue;
    this.#closeRequested = false;

    this.#connect(options);
  }

  get options() {
    return this.#options;
  }

  #onClose(code) {
    this.#updateReadyState(readyStateClosed);

    var { onClose } = this.#options;
    if (onClose) onClose(code);
  }
  #onNotice(notice) {}

  // can be called before onOpen returns
  #onOpen(handle) {
    if (this.#handle !== handle) {
      if (this.#handle) {
        throw new Error("Internal error: handle mismatch");
      }

      this.#handle = handle;
    }
    this.#updateReadyState(readyStateConnected);

    var { onOpen } = this.#options;
    if (onOpen) onOpen(this);
  }

  #onTimeout() {
    this.#updateReadyState(readyStateClosed);

    var { onTimeout, onClose } = this.#options;
    if (onTimeout) onTimeout();
    else if (onClose) onClose("ERR_TIMEOUT");
  }

  #updateReadyState(readyState) {
    this.#readyState = readyState;
    switch (readyState) {
      case readyStateClosed: {
        this.#handle = undefined;
        this.query = this.#queryEnqueueAndConnect;
        break;
      }
      case readyStateConnected: {
        this.query = this.#query;
        break;
      }
      case readyStateConnecting: {
        this.query = this.#queryEnqueue;
        break;
      }
    }
  }

  #connect(options) {
    this.#hostIndex = 0;

    const handlers = {
      onClose: (code) => this.#onClose(code),
      onNotice: (notice) => this.#onNotice(notice),
      onOpen: (handle) => this.#onOpen(handle),
      onTimeout: () => this.#onTimeout(),
      onDrain: () => this.#onDrain(),
    };

    const host = this.host,
      hostCount = host.length,
      port = this.port;
    do {
      try {
        const hostIndex = this.#hostIndex;
        this.#hostIndex = (this.#hostIndex + 1) % hostCount;

        if (options.path) {
          this.#handle = nativeConnect({
            host: host[hostIndex],
            port: port[hostIndex],
            database: options.database,
            user: options.user,
            pass: options.pass,
            path: options.path,
            ...handlers,
          });
        } else {
          this.#handle = nativeConnect({
            host: host[hostIndex],
            port: port[hostIndex],
            database: options.database,
            user: options.user,
            pass: options.pass,
            ...handlers,
          });
        }
      } catch (e) {
        if (e?.code !== "ERR_UNAVAILABLE") throw e;
      }
    } while (this.#hostIndex !== 0);
  }

  #queryEnqueueAndConnect(query, resolve, reject) {
    this.#queue.push({ 0: query, 1: resolve, 2: reject });
    this.#connect(this.#options);
  }

  // must be called from connecting state
  #queryEnqueue(sql, resolve, reject) {
    this.#queue.push({ 0: sql, 1: resolve, 2: reject });
  }

  #query(sql, resolve, reject) {
    var queue = this.#queue;
    if (!queue.isEmpty() || this.#needsDrain) {
      queue.push({ 0: sql, 1: resolve, 2: reject });
      return;
    }

    this.#needsDrain = this.#handle.query(sql, resolve, reject, false);
  }

  #onDrain() {
    var queue = this.#queue,
      remaining = queue.size(),
      hasMore = remaining > 0,
      canSendMore = false,
      handle = this.#handle;

    if (hasMore && handle) {
      let sql, resolve, reject;
      while (
        (({ 0: sql, 1: resolve, 2: reject } = queue.shift()),
        (hasMore = canSendMore =
          handle.query(sql, resolve, reject, (hasMore = remaining-- > 1))),
        hasMore)
      ) {}
      this.#needsDrain = !canSendMore;
    } else {
      this.#needsDrain = false;
    }
  }

  ref() {
    this.#handle?.ref?.();
  }

  unref() {
    this.#handle?.unref?.();
  }

  close(force = false) {
    var handle = this.#handle;
    if (
      !handle ||
      this.#readyState === readyStateClosed ||
      this.#closeRequested
    )
      return;
    this.#closeRequested = true;

    if (force || this.#queue.isEmpty()) {
      handle.unref();
      handle.close();
    }
  }
}

function database(a, b) {
  const options = parseOptions(a, b);

  const connection = new Connection(options);

  function sql(strings, ...args) {
    const query = strings[0];
    if (!query || !query.length) {
      throw new Error("SQL query must not be empty");
    }

    return new SQL(connection, query);
  }

  sql.connection = connection;
  sql.ref = function ref() {
    this.connection.ref();
  };
  sql.unref = function unref() {
    this.connection.unref();
  };

  return sql;
}

// This code is thanks to postgres.js
function parseOptions(a, b) {
  if (a && a.shared) return a;

  const env = process.env,
    o = (typeof a === "string" ? b : a) || {},
    { url, multihost } = parseUrl(a),
    query = [...url.searchParams].reduce((a, [b, c]) => ((a[b] = c), a), {}),
    host =
      o.hostname ||
      o.host ||
      multihost ||
      url.hostname ||
      env.PGHOST ||
      "localhost",
    port = o.port || url.port || env.PGPORT || 5432,
    user =
      o.user ||
      o.username ||
      url.username ||
      env.PGUSERNAME ||
      env.PGUSER ||
      osUsername();

  const { protocol } = url;
  if (
    protocol &&
    protocol.length &&
    protocol !== "file:" &&
    protocol !== "http:" &&
    protocol !== "https:" &&
    protocol !== "pg:" &&
    protocol !== "pgx:" &&
    protocol !== "postgres:" &&
    protocol !== "postgresql:" &&
    protocol !== "unix:"
  ) {
    throw new Error("Only PostgresSQL is supported by bun:sql");
  }

  o.no_prepare && (o.prepare = false);
  query.sslmode && ((query.ssl = query.sslmode), delete query.sslmode);

  const defaults = {
    max: 10,
    ssl: false,
    idle_timeout: null,
    connect_timeout: 30,
    // max_lifetime: max_lifetime,
    max_pipeline: 100,
    // backoff: backoff,
    keep_alive: 60,
    prepare: true,
    debug: false,
    fetch_types: true,
    publications: "alltables",
    target_session_attrs: null,
  };

  return {
    host: Array.isArray(host)
      ? host
      : host.split(",").map((x) => x.split(":")[0]),
    port: Array.isArray(port)
      ? port
      : host.split(",").map((x) => parseInt(x.split(":")[1] || port)),
    path: o.path || (host.indexOf("/") > -1 && host + "/.s.PGSQL." + port),
    database:
      o.database ||
      o.db ||
      (url.pathname || "").slice(1) ||
      env.PGDATABASE ||
      user,
    user: user,
    pass: o.pass || o.password || url.password || env.PGPASSWORD || "",
    ...Object.entries(defaults).reduce(
      (acc, [k, d]) => (
        (acc[k] =
          k in o
            ? o[k]
            : k in query
            ? query[k] === "disable" || query[k] === "false"
              ? false
              : query[k]
            : env["PG" + k.toUpperCase()] || d),
        acc
      ),
      {},
    ),
    connection: {
      application_name: "bun:sql",
      ...o.connection,
      ...Object.entries(query).reduce(
        (acc, [k, v]) => (k in defaults || (acc[k] = v), acc),
        {},
      ),
    },
    onclose: o.onclose,
    // types: o.types || {},
    // TODO:
    // target_session_attrs: tsa(o, url, env),
    // onnotice: o.onnotice,
    // onnotify: o.onnotify,
    // onparameter: o.onparameter,

    // socket: o.socket,
    // transform: parseTransform(o.transform || { undefined: undefined }),
    parameters: {},
    shared: { retries: 0, typeArrayMap: {} },
  };
}

function parseUrl(url) {
  if (typeof url !== "string") return { url: { searchParams: new Map() } };

  let host = url;
  host = host.slice(host.indexOf("://") + 3).split(/[?/]/)[0];
  host = decodeURIComponent(host.slice(host.indexOf("@") + 1));

  return {
    url: new URL(url.replace(host, host.split(",")[0])),
    multihost: host.indexOf(",") > -1 && host,
  };
}

function osUsername() {
  try {
    return import.meta.require("node:os").userInfo().username; // eslint-disable-line
  } catch (_) {
    return process.env.USERNAME || process.env.USER || process.env.LOGNAME; // eslint-disable-line
  }
}

export default database;
database[Symbol.for("CommonJS")] = 0;
database.Connection = Connection;
database.SQL = SQL;
database.database = database;
export { database };
