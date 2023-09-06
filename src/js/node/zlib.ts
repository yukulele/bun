const { Transform } = require("node:stream");
const { throwNotImplemented } = require("$shared");

const { zlib: constants } = $processBindingConstants;

const codes = {
  __proto__: null,
  "0": "Z_OK",
  "1": "Z_STREAM_END",
  "2": "Z_NEED_DICT",
  Z_OK: 0,
  Z_STREAM_END: 1,
  Z_NEED_DICT: 2,
  Z_ERRNO: -1,
  Z_STREAM_ERROR: -2,
  Z_DATA_ERROR: -3,
  Z_MEM_ERROR: -4,
  Z_BUF_ERROR: -5,
  Z_VERSION_ERROR: -6,
  "-1": "Z_ERRNO",
  "-2": "Z_STREAM_ERROR",
  "-3": "Z_DATA_ERROR",
  "-4": "Z_MEM_ERROR",
  "-5": "Z_BUF_ERROR",
  "-6": "Z_VERSION_ERROR",
};

function callbackified(callback, fn, ...args) {
  try {
    callback(null, fn(...args));
  } catch (err) {
    callback(err);
  }
}

let slow_zlib;
function slowFallback(name: string, args: any[]) {
  return (slow_zlib ??= require("./zlib.browserify.js"))[name](...args);
}

function ZlibBase(this, opts, processor) {
  Reflect.apply(Transform, this, [{ autoDestroy: true, ...opts }]);
  this._cb = processor;
  this._buffer = [];
}
ZlibBase.prototype = Object.create(Transform.prototype);
ZlibBase.prototype._transform = function (chunk, encoding, callback) {
  console.log("ZlibBase.prototype._transform", chunk, encoding, callback);
  this._buffer.push(chunk);
  callback();
};
ZlibBase.prototype._flush = function (callback) {
  const buffer = Buffer.concat(this._buffer);
  this._buffer = [];
  console.log("ZlibBase.prototype._flush", buffer, this._cb);
  callbackified(callback, this._cb, buffer);
};

function Deflate(this, options) {
  ZlibBase.call(this, options, Bun.deflateSync);
}
Deflate.prototype = Object.create(ZlibBase.prototype);

function Inflate(this, options) {
  ZlibBase.call(this, options, Bun.inflateSync);
}
Inflate.prototype = Object.create(ZlibBase.prototype);

function Gzip(this, options) {
  ZlibBase.call(this, options, Bun.gzipSync);
}
Gzip.prototype = Object.create(ZlibBase.prototype);

function Gunzip(this, options) {
  ZlibBase.call(this, options, Bun.gunzipSync);
}
Gunzip.prototype = Object.create(ZlibBase.prototype);

// function DeflateRaw(options) {
//   return new ZlibBase(options, DeflateRaw);
// }
// DeflateRaw.prototype = Object.create(ZlibBase.prototype);

// function InflateRaw(options) {
//   return new ZlibBase(options, InflateRaw);
// }
// InflateRaw.prototype = Object.create(ZlibBase.prototype);

// function Unzip(this, options) {
//   ZlibBase.call(this, options, Unzip);
// }
// Unzip.prototype = Object.create(ZlibBase.prototype);

function BrotliCompress() {
  throw throwNotImplemented("Brotli compression", 267);
}
BrotliCompress.prototype = Object.create(ZlibBase.prototype);

function BrotliDecompress() {
  throw throwNotImplemented("Brotli compression", 267);
}
BrotliDecompress.prototype = Object.create(ZlibBase.prototype);

function deflate(buffer, options, callback) {
  if (typeof options === "function") {
    callback = options;
    options = undefined;
  }
  if (typeof callback !== "function") {
    throw new TypeError("Callback must be a function");
  }
  // TODO: async
  process.nextTick(callbackified, callback, deflateSync, buffer, options);
}

function deflateSync(buffer, options) {
  // TODO: options
  return Buffer.from(Bun.deflateSync(buffer));
}

function gzip(buffer, options, callback) {
  if (typeof options === "function") {
    callback = options;
    options = undefined;
  }
  if (typeof callback !== "function") {
    throw new TypeError("Callback must be a function");
  }
  // TODO: async
  process.nextTick(callbackified, callback, gzipSync, buffer, options);
}

function gzipSync(buffer, options) {
  // TODO: options
  return Buffer.from(Bun.gzipSync(buffer));
}

function deflateRaw(...args) {
  return slowFallback("deflateRaw", args);
}

function deflateRawSync(...args) {
  return slowFallback("deflateRawSync", args);
}

/// "Decompress either a Gzip- or Deflate-compressed stream by auto-detecting the header."
function unzip(...args) {
  return slowFallback("unzip", args);
}

function unzipSync(...args) {
  return slowFallback("unzipSync", args);
}

function inflate(buffer, options, callback) {
  if (typeof options === "function") {
    callback = options;
    options = undefined;
  }
  if (typeof callback !== "function") {
    throw new TypeError("Callback must be a function");
  }
  // TODO: async
  process.nextTick(callbackified, callback, gzipSync, buffer, options);
}

function inflateSync(buffer, options) {
  // TODO: options
  return Buffer.from(Bun.inflateSync(buffer));
}

function gunzip(callback, buffer, options) {
  if (typeof options === "function") {
    callback = options;
    options = undefined;
  }
  if (typeof callback !== "function") {
    throw new TypeError("Callback must be a function");
  }
  // TODO: async
  process.nextTick(callbackified, callback, gzipSync, buffer, options);
}

function gunzipSync(buffer, options) {
  // TODO: options
  return Buffer.from(Bun.gunzipSync(buffer));
}

function inflateRaw(...args) {
  return slowFallback("inflateRaw", args);
}

function inflateRawSync(...args) {
  return slowFallback("inflateRawSync", args);
}

function brotliCompress() {
  throw throwNotImplemented("Brotli compression", 267);
}

function brotliCompressSync() {
  throw throwNotImplemented("Brotli compression", 267);
}

function brotliDecompress() {
  throw throwNotImplemented("Brotli compression", 267);
}

function brotliDecompressSync() {
  throw throwNotImplemented("Brotli compression", 267);
}

const createDeflate = opts => new Deflate(opts);

const createInflate = opts => new Inflate(opts);

// const createDeflateRaw = opts => new DeflateRaw(opts);

// const createInflateRaw = opts => new InflateRaw(opts);

const createGzip = opts => new Gzip(opts);

const createGunzip = opts => new Gunzip(opts);

// const createUnzip = opts => new Unzip(opts);

function createBrotliCompress() {
  throw throwNotImplemented("Brotli compression", 267);
}

function createBrotliDecompress() {
  throw throwNotImplemented("Brotli compression", 267);
}

export default {
  Deflate,
  Inflate,
  Gzip,
  Gunzip,
  // DeflateRaw,
  // InflateRaw,
  // Unzip,
  BrotliCompress,
  BrotliDecompress,
  deflate,
  deflateSync,
  gzip,
  gzipSync,
  deflateRaw,
  deflateRawSync,
  unzip,
  unzipSync,
  inflate,
  inflateSync,
  gunzip,
  gunzipSync,
  inflateRaw,
  inflateRawSync,
  brotliCompress,
  brotliCompressSync,
  brotliDecompress,
  brotliDecompressSync,
  createDeflate,
  createInflate,
  // createDeflateRaw,
  // createInflateRaw,
  createGzip,
  createGunzip,
  // createUnzip,
  createBrotliCompress,
  createBrotliDecompress,
  constants,
  codes,
};
