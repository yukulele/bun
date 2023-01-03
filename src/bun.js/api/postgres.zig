const Bun = @This();
const default_allocator = @import("bun").default_allocator;
const bun = @import("bun");
const Environment = bun.Environment;
const NetworkThread = @import("bun").HTTP.NetworkThread;
const Global = bun.Global;
const strings = bun.strings;
const string = bun.string;
const Output = @import("bun").Output;
const MutableString = @import("bun").MutableString;
const std = @import("std");
const Allocator = std.mem.Allocator;
const JSC = @import("bun").JSC;
const JSValue = JSC.JSValue;
const JSGlobalObject = JSC.JSGlobalObject;

const uws = bun.uws;
const Socket = uws.NewSocketHandler(false);
const SocketContext = uws.SocketContext;
const Messages = @import("./postgres_messages.zig");

const ErrorCode = enum(i32) {
    cancel,
    invalid_response,
    timeout,
    closed,
    failed_to_write,
    failed_to_connect,
    failed_to_allocate_memory,
    invalid_utf8,
    ended,
    unknown,

    pub const status = bun.enumMap(ErrorCode, .{
        .{ .cancel, "cancel" },
        .{ .invalid_response, "invalidResponse" },
        .{ .timeout, "timeout" },
        .{ .closed, "closed" },
        .{ .failed_to_write, "failedToWrite" },
        .{ .failed_to_connect, "failedToConnect" },
        .{ .failed_to_allocate_memory, "failedToAllocateMemory" },
        .{ .invalid_utf8, "invalidUtf8" },
        .{ .ended, "ended" },
        .{ .unknown, "unknown" },
    });

    pub const code = bun.enumMap(ErrorCode, .{
        .{ .cancel, "POSTGRES_ERROR_CANCEL" },
        .{ .invalid_response, "POSTGRES_ERROR_INVALID_RESPONSE" },
        .{ .timeout, "POSTGRES_ERROR_TIMEOUT" },
        .{ .closed, "POSTGRES_ERROR_CLOSED" },
        .{ .failed_to_write, "POSTGRES_ERROR_FAILED_TO_WRITE" },
        .{ .failed_to_connect, "POSTGRES_ERROR_FAILED_TO_CONNECT" },
        .{ .failed_to_allocate_memory, "POSTGRES_ERROR_FAILED_TO_ALLOCATE_MEMORY" },
        .{ .invalid_utf8, "POSTGRES_ERROR_INVALID_UTF8" },
        .{ .ended, "POSTGRES_ERROR_ENDED" },
        .{ .unknown, "POSTGRES_ERROR_UNKNOWN" },
    });

    pub const label = bun.enumMap(ErrorCode, .{
        .{ .cancel, "The connection was cancelled" },
        .{ .invalid_response, "The connection has an invalid response" },
        .{ .timeout, "The connection timed out" },
        .{ .closed, "The connection was closed" },
        .{ .failed_to_write, "The connection failed to write" },
        .{ .failed_to_connect, "The connection failed to connect" },
        .{ .failed_to_allocate_memory, "Failed to allocate memory" },
        .{ .invalid_utf8, "Received invalid UTF-8" },
        .{ .ended, "The connection was ended" },
        .{ .unknown, "An unknown error occurred" },
    });

    pub fn toErrorInstance(
        this: ErrorCode,
        globalObject: *JSC.JSGlobalObject,
    ) JSC.JSValue {
        var instance = globalObject.createErrorInstance(
            "{s}",
            .{this.label()},
        );
        instance.put("code", JSC.ZigString.init(this.code()).toValueGC(globalObject));
        instance.put("name", JSC.ZigString.static("PostgresError").toValueGC(globalObject));
        return instance;
    }
};

const ConnectionOptions = union(enum) {
    pub const TCP = struct {
        hostname: []const u8 = "localhost",
        port: u16 = 5432,
        database: []const u8 = "postgres",
        user: []const u8 = "",
        password: []const u8 = "",
    };
    tcp: TCP,
    tls: struct {
        tcp: TCP,
    },
};

pub const PostgresData = struct {
    tcp_ctx: ?*uws.SocketContext = null,
};

pub const Protocol = struct {};

pub const PostgresConnection = struct {
    const log = Output.scoped(.PostgresConnection, false);

    tcp: Socket,
    poll_ref: JSC.PollRef = .{},

    pub fn connect(globalThis: *JSC.JSGlobalObject, db: *PostgresSQLDatabase, options: ConnectionOptions) !void {
        autoRegister(globalThis);
        log("connect {s}:{d}", .{ options.tcp.hostname, options.tcp.port });
        const socket = Socket.connectAnon(
            options.tcp.hostname,
            options.tcp.port,
            globalThis.bunVM().rareData().postgres_data.tcp_ctx.?,
            &db.connection,
        ) orelse {
            return error.FailedToConnect;
        };
        db.connection.tcp = socket;
    }

    pub fn closeGracefully(this: *PostgresConnection) void {
        this.tcp.close(0, null); // todo
    }

    pub fn autoRegister(global: *JSC.JSGlobalObject) void {
        var vm = global.bunVM();

        if (vm.rareData().postgres_data.tcp_ctx == null) {
            var opts: uws.us_socket_context_options_t = undefined;
            @memset(@ptrCast([*]u8, &opts), 0, @sizeOf(uws.us_socket_context_options_t));
            var ctx = uws.us_create_socket_context(0, vm.uws_event_loop.?, @sizeOf(usize), opts).?;
            vm.rareData().postgres_data.tcp_ctx = ctx;
            Socket.configure(
                ctx,
                false,
                PostgresConnection,
                struct {
                    pub const onClose = PostgresConnection.onClose;
                    pub const onData = PostgresConnection.onData;
                    pub const onWritable = PostgresConnection.onWritable;
                    pub const onTimeout = PostgresConnection.onTimeout;
                    pub const onConnectError = PostgresConnection.onConnectError;
                    pub const onEnd = PostgresConnection.onEnd;
                },
            );
        }
    }

    pub inline fn database(this: *PostgresConnection) *PostgresSQLDatabase {
        return @fieldParentPtr(PostgresSQLDatabase, "connection", this);
    }

    pub fn onWritable(
        this: *PostgresConnection,
        socket: Socket,
    ) void {
        std.debug.assert(socket.socket == this.tcp.socket);
        // if (this.to_send.len == 0)
        //     return;

        // const wrote = socket.write(this.to_send, true);
        // if (wrote < 0) {
        //     this.terminate(ErrorCode.failed_to_write);
        //     return;
        // }
        // this.to_send = this.to_send[@min(@intCast(usize, wrote), this.to_send.len)..];
    }
    pub fn onTimeout(
        this: *PostgresConnection,
        _: Socket,
    ) void {
        this.terminate(ErrorCode.timeout);
    }
    pub fn onConnectError(this: *PostgresConnection, _: Socket, _: c_int) void {
        this.terminate(ErrorCode.failed_to_connect);
    }

    pub fn onEnd(this: *PostgresConnection, socket: Socket) void {
        log("onEnd", .{});
        std.debug.assert(socket.socket == this.tcp.socket);
        this.terminate(ErrorCode.ended);
    }

    pub fn onData(_: *PostgresConnection, _: Socket, data: []const u8) void {
        log("onData: {d}", .{data.len});
    }

    pub fn onClose(this: *PostgresConnection, _: Socket, _: c_int, _: ?*anyopaque) void {
        log("onClose", .{});
        this.terminate(ErrorCode.closed);
    }

    pub fn onOpen(this: *PostgresConnection, socket: Socket) void {
        log("onOpen", .{});
        std.debug.assert(socket.socket == this.tcp.socket);
    }

    pub fn terminate(this: *PostgresConnection, code: ErrorCode) void {
        log("terminate - {s}", .{code.code()});
        this.poll_ref.disable();

        if (this.tcp.isEstablished() and !this.tcp.isClosed()) {
            this.tcp.ext(?*anyopaque).?.* = null;
            this.tcp.close(0, null);
        }

        this.database().terminate(code);
    }
};

const PendingQuery = struct {
    resolve: JSC.JSValue,
    reject: JSC.JSValue,
    query: JSC.ZigString.Slice,
};

pub const PostgresSQLDatabase = struct {
    const log = Output.scoped(.PostgresSQLDatabase, false);
    pub usingnamespace JSC.Codegen.JSPostgresSQLDatabase;
    arena: std.heap.ArenaAllocator,
    connection: PostgresConnection,
    options: ConnectionOptions,
    this_jsvalue: JSC.JSValue = .zero,
    globalObject: *JSC.JSGlobalObject,
    status: Status = .connecting,
    has_pending_activity: std.atomic.Atomic(bool) = std.atomic.Atomic(bool).init(false),

    close_status: ErrorCode = .unknown,

    pending_queries: std.ArrayListUnmanaged(PendingQuery) = .{},

    pub const Status = enum {
        connecting,
        connected,
        closing,
        closed,

        pub const label = bun.enumMap(Status, .{
            .{ .connecting, "connecting" },
            .{ .connected, "connected" },
            .{ .closing, "closing" },
            .{ .closed, "closed" },
        });
    };

    pub fn hasPendingActivity(this: *PostgresSQLDatabase) callconv(.C) bool {
        @fence(.Acquire);
        return this.has_pending_activity.load(.Acquire);
    }

    pub fn getStatus(this: *PostgresSQLDatabase, globalThis: *JSC.JSGlobalObject) callconv(.C) JSC.JSValue {
        return JSC.ZigString.init(this.status.label()).toValueGC(globalThis);
    }

    fn setStatus(
        this: *PostgresSQLDatabase,
        status: Status,
        _: JSC.JSValue,
    ) void {
        this.status = status;
        this.updateHasPendingData();
        if (status == .connected) {}
    }

    pub fn updateHasPendingData(this: *PostgresSQLDatabase) void {
        @fence(.Release);
        this.has_pending_activity.store(this.status != .closed, .Release);
    }

    pub fn terminate(this: *PostgresSQLDatabase, code: ErrorCode) void {
        const js_value = this.this_jsvalue;
        if (this.status == .connecting) {
            this.setStatus(.closed, js_value);
            return;
        }
        this.close_status = code;

        if (this.status == .closed)
            return;

        this.setStatus(.closed, js_value);
    }

    pub fn connect(globalObject: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) callconv(.C) JSC.JSValue {
        const arguments_ = callframe.arguments(8);
        const arguments: []const JSC.JSValue = arguments_.ptr[0..arguments_.len];

        if (arguments.len < 1) {
            globalObject.throwNotEnoughArguments("connect", 1, 0);
            return .zero;
        }

        if (arguments[0].isEmptyOrUndefinedOrNull()) {
            globalObject.throwInvalidArgumentType("connect", "options", "url string or object");
            return .zero;
        }

        var arena = std.heap.ArenaAllocator.init(globalObject.allocator());

        var options = ConnectionOptions{ .tcp = .{} };

        if (arguments[0].get(globalObject, "host")) |value| {
            if (!value.isEmptyOrUndefinedOrNull()) {
                const str = value.toSlice(globalObject, arena.allocator()).clone(arena.allocator()) catch @panic("Out of memory");
                if (str.len > 0)
                    options.tcp.hostname = str.slice();
            }
        }
        if (arguments[0].get(globalObject, "port")) |value| {
            if (!value.isEmptyOrUndefinedOrNull()) {
                const str = value.toSlice(globalObject, arena.allocator()).clone(arena.allocator()) catch @panic("Out of memory");
                if (str.len > 0)
                    options.tcp.port = std.fmt.parseInt(u16, str.slice(), 10) catch @panic("Error parsing port number");
            }
        }
        if (arguments[0].get(globalObject, "database")) |value| {
            if (!value.isEmptyOrUndefinedOrNull()) {
                const str = value.toSlice(globalObject, arena.allocator()).clone(arena.allocator()) catch @panic("Out of memory");
                if (str.len > 0)
                    options.tcp.database = str.slice();
            }
        }
        if (arguments[0].get(globalObject, "user")) |value| {
            if (!value.isEmptyOrUndefinedOrNull()) {
                const str = value.toSlice(globalObject, arena.allocator()).clone(arena.allocator()) catch @panic("Out of memory");
                if (str.len > 0)
                    options.tcp.user = str.slice();
            }
        }
        if (arguments[0].get(globalObject, "pass")) |value| {
            if (!value.isEmptyOrUndefinedOrNull()) {
                const str = value.toSlice(globalObject, arena.allocator()).clone(arena.allocator()) catch @panic("Out of memory");
                if (str.len > 0)
                    options.tcp.password = str.slice();
            }
        }
        // if (arguments[0].get(globalObject, "path")) |value| {
        //     if (!value.isEmptyOrUndefinedOrNull()) {
        //         const str = value.toSlice(globalObject).clone(arena.allocator());
        //         if (str.len > 0)
        //             options.tcp.p = str.slice();
        //     }
        // }
        var db = globalObject.allocator().create(PostgresSQLDatabase) catch |err| {
            arena.deinit();
            globalObject.throwError(err, "failed to allocate db");
            return .zero;
        };

        const this = db.toJS(globalObject);
        db.* = .{
            .this_jsvalue = this,
            .options = options,
            .status = .connecting,
            .arena = arena,
            .globalObject = globalObject,
            .connection = undefined,
        };
        PostgresSQLDatabase.onCloseSetCached(this, globalObject, arguments[0].get(globalObject, "onClose") orelse @panic("Expected onClose. Don't call this function outside of bun:sql."));
        PostgresSQLDatabase.onNoticeSetCached(this, globalObject, arguments[0].get(globalObject, "onNotice") orelse @panic("Expected onNotice. Don't call this function outside of bun:sql."));
        PostgresSQLDatabase.onOpenSetCached(this, globalObject, arguments[0].get(globalObject, "onOpen") orelse @panic("Expected onOpen. Don't call this function outside of bun:sql."));
        PostgresSQLDatabase.onTimeoutSetCached(this, globalObject, arguments[0].get(globalObject, "onTimeout") orelse @panic("Expected onTimeout. Don't call this function outside of bun:sql."));
        PostgresSQLDatabase.onDrainSetCached(this, globalObject, arguments[0].get(globalObject, "onDrain") orelse @panic("Expected onDrain. Don't call this function outside of bun:sql."));
        db.updateHasPendingData();
        PostgresConnection.connect(globalObject, db, options) catch |err| {
            arena.deinit();
            globalObject.throwError(err, "failed to connect");
            return .zero;
        };

        return this;
    }

    pub fn query(_: *PostgresSQLDatabase, _: *JSC.JSGlobalObject, _: *JSC.CallFrame) callconv(.C) JSC.JSValue {
        return JSC.JSValue.jsUndefined();
    }

    pub fn ref(_: *PostgresSQLDatabase, _: *JSC.JSGlobalObject, _: *JSC.CallFrame) callconv(.C) JSC.JSValue {
        return JSC.JSValue.jsUndefined();
    }

    pub fn unref(_: *PostgresSQLDatabase, _: *JSC.JSGlobalObject, _: *JSC.CallFrame) callconv(.C) JSC.JSValue {
        return JSC.JSValue.jsUndefined();
    }

    pub fn close(this: *PostgresSQLDatabase, globalObject: *JSC.JSGlobalObject, _: *JSC.CallFrame) callconv(.C) JSC.JSValue {
        if (this.status == .closed) {
            return JSC.ZigString.init(this.close_status.label()).toValueGC(globalObject);
        }

        if (this.status == .closing) {
            return JSC.JSValue.jsUndefined();
        }

        std.debug.assert(!this.connection.tcp.isClosed());
        std.debug.assert(this.connection.tcp.isEstablished());
        std.debug.assert(!this.connection.tcp.isShutdown());

        this.setStatus(.closing, this.this_jsvalue);
        this.connection.closeGracefully();
        return JSC.JSValue.jsUndefined();
    }

    pub fn finalize(this: *PostgresSQLDatabase) callconv(.C) void {
        this.deinit();
    }

    pub fn deinit(this: *PostgresSQLDatabase) void {
        std.debug.assert(this.status == .closed);
        this.arena.deinit();
        bun.default_allocator.destroy(this);
    }
};

comptime {
    @export(PostgresSQLDatabase.connect, .{
        .name = "Bun__PostgreSQL__connect",
    });
}
