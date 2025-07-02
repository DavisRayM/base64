const std = @import("std");
const testing = std.testing;

const Base64 = struct {
    _table: *const [64]u8,

    fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symb = "0123456789+/";

        return .{
            ._table = upper ++ lower ++ numbers_symb,
        };
    }

    fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }
};

/// Calculates number of bytes required to encode an input to Base64.
///
/// See: https://www.rfc-editor.org/rfc/rfc4648#section-4
fn _calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }

    const num_groups = try std.math.divCeil(usize, input.len, 3);
    return num_groups * 4;
}

/// Calculates number of bytes required to decode a Base64 input.
///
/// See: https://www.rfc-editor.org/rfc/rfc4648#section-4
fn _calc_decode_length(input: []const u8) !usize {
    // In most cases this will never be the case; unless padding is not included.
    if (input.len < 4) {
        return 3;
    }

    const num_groups = try std.math.divFloor(usize, input.len, 4);
    var estimate = num_groups * 3;
    var i = input.len - 1;

    while (i > 0) : (i -= 1) {
        if (input[i] == '=') {
            estimate -= 1;
        } else {
            break;
        }
    }

    return estimate;
}

pub fn main() !void {
    const base64 = Base64.init();

    std.debug.print("Char at index 28: {c}\n", .{base64._char_at(28)});
}

test "encode length for input with length less than 3" {
    const in = "Hi";
    const out = try _calc_encode_length(in);
    try testing.expectEqual(out, 4);
}

test "encode length rounded up for extra padding" {
    const in = "Hello";
    const out = try _calc_encode_length(in);
    try testing.expectEqual(out, 8);
}

test "decode length for input with length less than 4" {
    const in = "aA";
    const out = try _calc_decode_length(in);
    try testing.expectEqual(out, 3);
}

test "decode length handles padding accordingly" {
    const in = "SGVsbG8=";
    const out = try _calc_decode_length(in);
    try testing.expectEqual(out, 5);
}
