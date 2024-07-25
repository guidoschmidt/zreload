const std = @import("std");
const SourceFile = @import("SourceFile.zig");

const FileWatcher = @This();

watch_thread: std.Thread = undefined,
allocator: std.mem.Allocator,
file_sources: std.ArrayList(SourceFile) = undefined,
callbacks: std.StringHashMap(*fn ([]const u8) anyerror!void) = undefined,

pub fn init(self: *FileWatcher) void {
    self.file_sources = std.ArrayList(SourceFile).init(self.allocator);
    self.callbacks = std.StringHashMap(*fn ([]const u8) anyerror!void).init(self.allocator);
}

pub fn watch(self: *FileWatcher) !void {
    for (self.file_sources.items) |*source| {
        if (try source.reloadOnModified(self.allocator)) {
            const cb = self.callbacks.get(source.file_path).?;
            try cb(source.buffer);
        }
    }
}

fn loop(self: *FileWatcher) !void {
    while (true) {
        try self.watch();
    }
}

pub fn asyncWatch(self: *FileWatcher) !void {
    self.watch_thread = try std.Thread.spawn(.{}, loop, .{ self });
}

pub fn addFile(self: *FileWatcher, file_path: []const u8, cb: *const fn ([]const u8) anyerror!void) !void {
    var source = SourceFile{};
    try source.load(file_path, self.allocator);
    try self.file_sources.append(source);
    try self.callbacks.put(source.file_path, @constCast(cb));
}

pub fn deinit(self: *FileWatcher) void {
    self.watch_thread.join();
    self.file_sources.deinit();
    self.callbacks.deinit();
}
