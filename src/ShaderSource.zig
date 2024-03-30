const std = @import("std");
const fs = std.fs;

pub fn loadShaderSource(allocator: std.mem.Allocator, file_path: []const u8 ) ![]const u8 {
    const file = try (fs.cwd().openFile(file_path, .{ .mode = .read_only }));
    const stats = try file.stat();
    const original_source = try file.readToEndAllocOptions(allocator, stats.size, null, @alignOf(u8), 0);
    return try replaceIncludes(allocator, original_source);
}

pub fn replaceIncludes(alloc: std.mem.Allocator, source: []const u8) ![]const u8 {
    var final_source: []const u8 = "";
    var splitIt = std.mem.tokenize(u8, source, "\n");
    while (splitIt.next()) |entry| {
        var partial_split_it = std.mem.splitSequence(u8, entry, "#include");
        _ = partial_split_it.next();
        if (partial_split_it.next()) |replace| {
            var partial_file_it = std.mem.splitSequence(u8, replace, "\"");
            _ = partial_file_it.next();
            if (partial_file_it.next()) |include_file| {
                const partial_path = try std.fmt.allocPrint(alloc, "src/wgsl/{s}", .{ include_file });
                var partial_file = try fs.cwd().openFile(partial_path, .{ .mode = .read_only });
                const stats = try partial_file.stat();
                var partial_contents: []const u8 = try partial_file.readToEndAllocOptions(alloc, stats.size, null, @alignOf(u8), 0);
                if (std.mem.containsAtLeast(u8, partial_contents, 1, "#include")) {
                    partial_contents = try replaceIncludes(alloc, partial_contents);
                }
                final_source = try std.fmt.allocPrint(alloc, "{s}{s}", .{ final_source, partial_contents });
            }
            continue;
        }
        final_source = try std.fmt.allocPrint(alloc, "{s}\n{s}", .{ final_source, entry });
    }
    return final_source;
}

pub fn loadShaderSourceComptime(file_path: []const u8) [:0]const u8 {
    const original_source = @embedFile(file_path);
    return replaceIncludesComptime(original_source);
}

pub fn replaceIncludesComptime(comptime source: []const u8) [:0]const u8 {
    var final_source: [:0]const u8 = "";
    var splitter = std.mem.tokenize(u8, source, "\n");
    inline while (splitter.next()) |entry| {
        var partial_split_it = std.mem.splitSequence(u8, entry, "#include");
        _ = partial_split_it.next();
        const include_path = partial_split_it.next();
        if (include_path) |replace| {
            var partial_file_it = std.mem.splitSequence(u8, replace, "\"");
            _ = partial_file_it.next();
            if (partial_file_it.next()) |include_file| {
                const partial_path = std.fmt.comptimePrint("../wgsl/{s}", .{ include_file });
                var partial_contents : [:0]const u8 = @embedFile(partial_path);
                if (std.mem.containsAtLeast(u8, partial_contents, 1, "#include")) {
                    partial_contents = replaceIncludesComptime(partial_contents);
                }
                final_source = std.fmt.comptimePrint("{s}\n{s}", .{ final_source, partial_contents });
            }
            continue;
        }
        final_source = std.fmt.comptimePrint("{s}\n{s}", .{ final_source, entry });
    }
    return final_source;
}
