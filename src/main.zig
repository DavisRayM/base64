const std = @import("std");
const base64 = @import("base64");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}
