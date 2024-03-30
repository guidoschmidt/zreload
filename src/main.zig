const std = @import("std");
const zreload = @import("zreload");

fn onReload(buffer: []const u8) !void {
    std.debug.print("\n{s}", .{buffer});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    //// Watch multiple files
    var file_watcher = zreload.FileWatcher{ .allocator = allocator };
    file_watcher.init();

    try file_watcher.addFile("src/glsl/test.glsl", &onReload);
    try file_watcher.addFile("src/data/input.txt", &onReload);
    try file_watcher.asyncWatch();

    while (true) {
        std.debug.print("\nGame Loop", .{});
        std.time.sleep(std.time.ns_per_s * 3);
    }
}
