const std = @import("std");

file: std.fs.File = undefined,
file_path: []const u8 = undefined,
stat: std.fs.File.Stat = undefined,
mtime: i128 = 0,
counter: usize = 0,
buffer: []u8 = undefined,

const SourceFile = @This();

pub fn load(self: *SourceFile, file_path: []const u8, allocator: std.mem.Allocator) !void {
    self.file_path = file_path;
    self.file = try std.fs.cwd().openFile(self.file_path, .{ .mode = .read_only });
    const stat = try self.file.stat();
    self.mtime = stat.mtime;
    self.buffer = try allocator.alloc(u8, stat.size);
    _ = try self.file.read(self.buffer);
    try self.file.sync();
}

pub fn reload(self: *SourceFile, allocator: std.mem.Allocator) !void {
    try self.file.sync();
    std.debug.print("\nRELOAD {d} -- {s}", .{ self.counter, self.file_path });
    allocator.free(self.buffer);

    self.file.close();
    self.file = try std.fs.cwd().openFile(self.file_path, .{ .mode = .read_only });
    const stat = try self.file.stat();
    self.buffer = try allocator.alloc(u8, stat.size);
    _ = try self.file.readAll(self.buffer);

    //// @TODO Optimizations
    // self.buffer = try std.mem.replaceOwned(u8, allocator, self.buffer, " = ", "=");
    // self.buffer = try std.mem.replaceOwned(u8, allocator, self.buffer, "\n", "");

    try self.file.sync();
    self.counter += 1;

    self.mtime = stat.mtime;
}

pub fn reloadOnModified(self: *SourceFile, allocator: std.mem.Allocator) !bool {
    const stat = try self.file.stat();
    if (stat.size > 0 and self.mtime < stat.mtime) {
        try self.reload(allocator);
        return true;
    }
    return false;
}

pub fn watch(self: *SourceFile, allocator: std.mem.Allocator) !void {
    while (true) {
        try self.reloadOnModified(allocator);
    }
}

pub fn asyncWatch(self: *SourceFile, allocator: std.mem.Allocator) !void {
    _ = try std.Thread.spawn(.{}, watch, .{ self, allocator });
}
