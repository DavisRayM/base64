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

    fn _char_index(self: Base64, char: u8) u8 {
        if (char == '=') {
            return 64;
        }

        var index: u8 = 0;

        for (0..63) |i| {
            if (self._char_at(i) == char) {
                break;
            }

            index += 1;
        }

        return index;
    }

    fn encode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const len = try _calc_encode_length(input);
        const out = try allocator.alloc(u8, len);
        var buf = [_]u8{ 0, 0, 0 };
        var count: u64 = 0;
        var iout: u64 = 0;

        for (input, 0..) |_, i| {
            buf[count] = input[i];
            count += 1;

            if (count == 3) {
                out[iout] = self._char_at(buf[0] >> 2);
                out[iout + 1] = self._char_at(((buf[0] & 0b0000_0011) << 4) + (buf[1] >> 4));
                out[iout + 2] = self._char_at(((buf[1] & 0b0000_1111) << 2) + (buf[2] >> 6));
                out[iout + 3] = self._char_at(buf[2] & 0b0011_1111);
                iout += 4;
                count = 0;
            }
        }

        if (count == 1) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at((buf[0] & 0b0000_0011) << 4);
            out[iout + 2] = '=';
            out[iout + 3] = '=';
            iout += 4;
        }

        if (count == 2) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at(((buf[0] & 0b0000_0011) << 4) + (buf[1] >> 4));
            out[iout + 2] = self._char_at((buf[1] & 0b0000_1111) << 2);
            out[iout + 3] = '=';
            iout += 4;
        }

        return out;
    }

    fn decode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const len = try _calc_decode_length(input);
        const out = try allocator.alloc(u8, len);
        var buf = [_]u8{ 0, 0, 0, 0 };
        var iout: u64 = 0;
        var count: u64 = 0;

        for (0..input.len) |i| {
            buf[count] = self._char_index(input[i]);
            count += 1;

            if (count == 4) {
                out[iout] = (buf[0] << 2) + (buf[1] >> 4);
                if (buf[2] != 64) {
                    out[iout + 1] = (buf[1] << 4) + (buf[2] >> 2);
                }
                if (buf[3] != 64) {
                    out[iout + 2] = (buf[2] << 6) + buf[3];
                }

                iout += 3;
                count = 0;
            }
        }

        return out;
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const out = try base64.encode(allocator, "Hi");
    defer allocator.free(out);

    std.debug.print("{s}\n", .{out});
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

test "expexted encoded string returned" {
    const allocator = testing.allocator;
    const in = "Hi";

    const base64 = Base64.init();
    const out = try base64.encode(allocator, in);
    defer allocator.free(out);

    try testing.expectEqualStrings("SGk=", out);
}

test "decodes string correctly" {
    const allocator = testing.allocator;
    const expected = "Hello there";

    const base64 = Base64.init();
    const encoded = try base64.encode(allocator, expected);
    defer allocator.free(encoded);

    const out = try base64.decode(allocator, encoded);
    defer allocator.free(out);

    try testing.expectEqualStrings(expected, out);
}
