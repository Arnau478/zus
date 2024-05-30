const std = @import("std");
const zig_args = @import("zig-args");

pub const Applet = enum {
    true,
    false,

    pub fn import(self: Applet) type {
        return switch (self) {
            .true => @import("applets/true/main.zig"),
            .false => @import("applets/false/main.zig"),
        };
    }
};

pub const Args = struct {
    pub const Generic = struct {
        help: bool = false,

        pub const meta = .{
            .name = "zus",
            .usage_summary = "[applet] [flags]",
            .full_text = 
            \\Supported applets:
            \\
                ++
                list: {
                var tuple: std.meta.Tuple(&[_]type{[]const u8} ** std.enums.values(Applet).len) = undefined;
                for (std.enums.values(Applet), 0..) |applet, i| {
                    tuple[i] = @tagName(applet);
                }
                break :list std.fmt.comptimePrint("  - {s}\n" ** std.enums.values(Applet).len, tuple);
            } ++
                \\
                \\To get more help on a specific applet, run `--help` on it
            ,
            .option_docs = .{
                .help = "show the help message",
            },
        };
    };

    pub const Verb = @Type(.{
        .Union = .{
            .layout = .auto,
            .tag_type = Applet,
            .fields = fields: {
                var fields: [std.enums.values(Applet).len]std.builtin.Type.UnionField = undefined;
                for (&fields, std.enums.values(Applet)) |*field, applet| {
                    field.* = .{
                        .name = @tagName(applet),
                        .type = applet.import().Args,
                        .alignment = @alignOf(type),
                    };
                }
                break :fields &fields;
            },
            .decls = &.{},
        },
    });
};

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.args();

    std.debug.assert(args.skip());

    const parse_res = zig_args.parseWithVerb(Args.Generic, Args.Verb, &args, allocator, .{ .forward = argError }) catch return;
    defer parse_res.deinit();

    if (parse_res.verb) |applet| {
        switch (applet) {
            inline else => |applet_args, tag| {
                if (parse_res.options.help) {
                    zig_args.printHelp(tag.import().Args, "zus " ++ @tagName(tag), std.io.getStdOut().writer()) catch {};
                    std.process.exit(0);
                }
                tag.import().main(applet_args);
            },
        }
    } else {
        if (parse_res.options.help) {
            zig_args.printHelp(Args.Generic, "zus", std.io.getStdOut().writer()) catch {};
            std.process.exit(0);
        }

        printError(
            \\Expected an applet name
            \\Use --help to get more info
        , .{});
    }
}

fn printError(comptime fmt: []const u8, args: anytype) noreturn {
    const stdout = std.io.getStdOut();
    stdout.writer().print(fmt ++ "\n", args) catch {};
    std.process.exit(1);
}

fn argError(err: zig_args.Error) !void {
    printError("{}", .{err});
}
