pub const String = extern struct {
    data: [*:0]u8 align(1) = undefined,
};

pub const Byten = extern struct {
    data: [*:0]u8 align(1) = undefined,
};

pub const AuthenticationOk = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        byte1: u8 align(1) = 'R',
        length: i32 align(1) = 8,
        tag: i32 align(1) = 0,
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationKerberosV5 = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        byte1: u8 align(1) = 'R',
        length: i32 align(1) = 8,
        tag: i32 align(1) = 2,
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationMD5Password = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        byte1: u8 align(1) = 'R',
        length: i32 align(1) = 12,
        tag: i32 align(1) = 5,
        salt: [4]u8 align(1) = undefined,
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationSCMCredential = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        byte1: u8 align(1) = 'R',
        length: i32 align(1) = 8,
        tag: i32 align(1) = 6,
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationCleartextPassword = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        byte1: u8 align(1) = 'R',
        length: i32 align(1) = 8,
        tag: i32 align(1) = 3,
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationGSS = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as an authentication request.
        byte1: u8 align(1) = 'R',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = 8,
        /// Specifies that GSSAPI authentication is required.
        tag: i32 align(1) = 7,
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationGSSContinue = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as an authentication request.
        byte1: u8 align(1) = 'R',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = 8,
        /// Specifies that this message contains GSSAPI or SSPI data.
        tag: i32 align(1) = 8,
        /// GSSAPI or SSPI authentication data.
        data: []u8 align(1),
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationSSPI = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as an authentication request.
        byte1: u8 align(1) = 'R',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = 8,
        /// Specifies that SSPI authentication is required.
        tag: i32 align(1) = 9,
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationSASL = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as an authentication request.
        byte1: u8 align(1) = 'R',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = 8,
        /// Specifies that SASL authentication is required.
        tag: i32 align(1) = 10,
        /// The message body is a list of SASL authentication mechanisms, in the server's order of preference. A zero byte is required as terminator after the last authentication mechanism name. For each mechanism, there is the following:
        mechanisms: [:0]const u8 align(1) = "",
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationSASLContinue = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as an authentication request.
        byte1: u8 align(1) = 'R',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// Specifies that this message contains a SASL challenge.
        tag: i32 align(1) = 11,
        /// SASL data, specific to the SASL mechanism being used.
        data: []const u8 align(1) = "",
    };
    pub const bytes = Bytes{};
};

pub const AuthenticationSASLFinal = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as an authentication request.
        byte1: u8 align(1) = 'R',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// Specifies that SASL authentication has completed.
        tag: i32 align(1) = 12,
        /// SASL outcome "additional data", specific to the SASL mechanism being used.
        data: []const u8 align(1) = "",
    };
    pub const bytes = Bytes{};
};

pub const CancelRequest = extern struct {
    pub const direction = .frontend;
    pub const Bytes = extern struct {
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = 16,
        /// The cancel request code. The value is chosen to contain 1234 in the most significant 16 bits, and 5678 in the least significant 16 bits. (To avoid confusion, this code must not be the same as any protocol version number.)
        code: i32 align(1) = 80877102,
        /// The process ID of the target backend.
        process_id: i32 align(1),
        /// The secret key for the target backend.
        secret_key: i32 align(1),
    };
    pub const bytes = Bytes{};
};

pub const Close = extern struct {
    pub const direction = .frontend;
    pub const Bytes = extern struct {
        /// Identifies the message as a Close command.
        byte1: u8 align(1) = 'C',
        /// Length of message contents in bytes, including self.
        length: i32 align(1),
        /// 'S' to close a prepared statement; or 'P' to close a portal.
        type: u8 align(1),
        /// The name of the prepared statement or portal to close (an empty string selects the unnamed prepared statement or portal).
        name: []u8 align(1),
    };
    pub const bytes = Bytes{};
};

pub const CloseComplete = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as a Close-complete indicator.
        byte1: u8 align(1) = '3',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = 4,
    };
    pub const bytes = Bytes{};
};

pub const CommandComplete = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as a command-completed response.
        byte1: u8 align(1) = 'C',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// The command tag. This is usually a single word that identifies which SQL command was completed.
        /// For an INSERT command, the tag is INSERT oid rows, where rows is the number of rows inserted. oid used to be the object ID of the inserted row if rows was 1 and the target table had OIDs, but OIDs system columns are not supported anymore; therefore oid is always 0.
        /// For a DELETE command, the tag is DELETE rows where rows is the number of rows deleted.
        /// For an UPDATE command, the tag is UPDATE rows where rows is the number of rows updated.
        /// For a SELECT or CREATE TABLE AS command, the tag is SELECT rows where rows is the number of rows retrieved.
        /// For a MOVE command, the tag is MOVE rows where rows is the number of rows the cursor's position has been changed by.
        /// For a FETCH command, the tag is FETCH rows where rows is the number of rows that have been retrieved from the cursor.
        /// For a COPY command, the tag is COPY rows where rows is the number of rows copied. (Note: the row count appears only in PostgreSQL 8.2 and later.)
        tag: [8]u8 align(1) = .{ 0, 0, 0, 0, 0, 0, 0, 0 },
    };
    pub const bytes = Bytes{};
};

pub const CopyData = extern struct {
    pub const direction = .both;
    pub const Bytes = extern struct {
        /// Identifies the message as copy data.
        byte1: u8 align(1) = 'd',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// Data that forms part of a copy-in or copy-out operation.
        data: []const u8 align(1),
    };
    pub const bytes = Bytes{};
};

pub const CopyDone = extern struct {
    pub const direction = .frontend;
    pub const Bytes = extern struct {
        /// Identifies the message as copy-done.
        byte1: u8 align(1) = 'c',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = 4,
    };
    pub const bytes = Bytes{};
};

pub const CopyFail = extern struct {
    pub const direction = .frontend;
    pub const Bytes = extern struct {
        /// Identifies the message as copy-fail.
        byte1: u8 align(1) = 'f',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// The failure message.
        message: [:0]const u8 align(1) = "",
    };
    pub const bytes = Bytes{};
};

pub const CopyInResponse = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as a CopyInResponse.
        byte1: u8 align(1) = 'G',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,

        /// 0 indicates the overall COPY format is textual (rows separated by newlines, columns separated by separator characters, etc.). 1 indicates the overall copy format is binary (similar to DataRow format). See COPY for more information.
        copy_format: i8 align(1) = undefined,

        /// The format code being used for the data transfer.
        columns_count: i16 align(1) = 0,

        /// The format codes to be used for each column. Each must presently be zero (text) or one (binary). All must be zero if the overall copy format is textual.
        columns: []i16 align(1) = &[_]i16{},
    };
    pub const bytes = Bytes{};
};

pub const CopyOutResponse = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as a CopyOutResponse.
        byte1: u8 align(1) = 'H',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,

        /// 0 indicates the overall COPY format is textual (rows separated by newlines, columns separated by separator characters, etc.). 1 indicates the overall copy format is binary (similar to DataRow format). See COPY for more information.
        copy_format: i8 align(1) = undefined,

        /// The format code being used for the data transfer.
        columns_count: i16 align(1) = 0,

        /// The format codes to be used for each column. Each must presently be zero (text) or one (binary). All must be zero if the overall copy format is textual.
        columns: []i16 align(1) = &[_]i16{},
    };
    pub const bytes = Bytes{};
};

pub const CopyBothResponse = extern struct {
    pub const direction = .backend;
    pub const Bytes = struct {
        /// Identifies the message as a CopyBothResponse.
        byte1: u8 align(1) = 'W',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,

        /// 0 indicates the overall COPY format is textual (rows separated by newlines, columns separated by separator characters, etc.). 1 indicates the overall copy format is binary (similar to DataRow format). See COPY for more information.
        copy_format: i8 align(1) = undefined,

        /// The format code being used for the data transfer.
        columns_count: i16 align(1) = 0,

        /// The format codes to be used for each column. Each must presently be zero (text) or one (binary). All must be zero if the overall copy format is textual.
        columns: [*]i16 align(1) = &[_]i16{},
    };
    pub const bytes = Bytes{};
};

pub const DataRow = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as a DataRow.
        byte1: u8 align(1) = 'D',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// The number of column values that follow (possibly zero).
        columns_count: i16 align(1) = 0,
    };
    pub const bytes = Bytes{};
};

pub const Describe = extern struct {
    pub const direction = .frontend;
    pub const Bytes = extern struct {
        /// Identifies the message as a Describe command.
        byte1: u8 align(1) = 'D',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// The object to describe. 'S' to describe a prepared statement; or 'P' to describe a portal.
        object_type: u8 align(1) = 'S',
        /// The name of the prepared statement or portal to describe (an empty string selects the unnamed prepared statement or portal).
        object_name: [*:0]const u8 align(1) = "",
    };
    pub const bytes = Bytes{};
};

pub const EmptyQueryResponse = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as an EmptyQueryResponse.
        byte1: u8 align(1) = 'I',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = 4,
    };
    pub const bytes = Bytes{};
};

pub const ErrorResponse = extern struct {
    pub const direction = .backend;
    pub const Bytes = extern struct {
        /// Identifies the message as an ErrorResponse.
        byte1: u8 align(1) = 'E',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// The fields of the error response.
        fields: [*:0]const Field align(1) = &[_]Field{},
    };
    pub const bytes = Bytes{};

    pub const Field = extern struct {
        /// The error code.
        code: u8 align(1) = undefined,
        /// The error message.
        message: [:0]const u8 align(1) = "",
    };
};

pub const Execute = extern struct {
    pub const direction = .frontend;
    pub const Bytes = extern struct {
        /// Identifies the message as an Execute command.
        byte1: u8 align(1) = 'E',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// The name of the portal to execute (an empty string selects the unnamed portal).
        portal_name: [*:0]const u8 align(1) = "",
        /// The maximum number of rows to return, if portal contains a query that returns rows (ignored otherwise). Zero denotes "no limit".
        max_rows: i32 align(1) = 0,
    };
    pub const bytes = Bytes{};
};

pub const Flush = extern struct {
    pub const direction = .frontend;
    pub const Bytes = extern struct {
        /// Identifies the message as a Flush.
        byte1: u8 align(1) = 'H',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = 4,
    };
    pub const bytes = Bytes{};
};

pub const FunctionCall = extern struct {
    pub const direction = .frontend;
    pub const Bytes = extern struct {
        /// Identifies the message as a FunctionCall.
        byte1: u8 align(1) = 'F',
        /// Length of message contents in bytes, including self.
        length: i32 align(1) = undefined,
        /// The object ID of the function to be called.
        function_id: i32 align(1) = undefined,

        /// The number of argument format codes that follow (denoted C below). This can be zero to indicate that there are no arguments or that the arguments all use the default format (text); or one, in which case the specified format code is applied to all arguments; or it can equal the actual number of arguments.
        format_codes_len: i16 align(1) = 0,

        format_codes: [:0]i16 align(1) = &[_]i16{},
    };
    pub const bytes = Bytes{};

    pub const Argument = extern struct {
        /// The argument value, in the format indicated by the associated format code. n is the above length.
        value: [:0]const u8 align(1) = "",
    };
};
