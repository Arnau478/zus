const std = @import("std");

pub const Args = struct {
    pub const meta = .{};
};

pub fn main(_: Args) void {
    std.process.exit(1);
}
