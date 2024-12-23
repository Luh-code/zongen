const std = @import("std");
const fs = std.fs;

const ZigStruct = struct {
    allocator: std.mem.Allocator,
    srcPath: []const u8, // path of the directory of the source file
    fileName: []const u8, // name of the source file and destination file
    structName: []const u8, // name of the struct to be implemented
    definitions: ?[]const u8 = null, // optional additional definitions
    commonName: ?[]const u8 = null, // do not set manually, name of the common module
    destPath: ?[]const u8 = null, // do not set manually, path to be written to

    fn readFile(self: *ZigStruct) ![]const u8 {
        var file = try fs.cwd().openFile(self.srcPath ++ "/" ++ self.fileName ++ ".zon", .{});
        defer file.close();

        return try file.readToEndAlloc(self.allocator, std.math.maxInt(usize));
    }

    fn createFile(self: *ZigStruct) !fs.File {
        const cwd = fs.cwd();
        cwd.makePath(self.?.destPath) catch |err| {
            _ = err;
        };
        var dir = try cwd.openDir(self.?.destPath, .{});
        var file = try dir.createFile(self.fileName ++ ".zig", .{});
        return &file;
    }

    fn writeZigFile(self: *ZigStruct, file: *fs.File, zon: *[]const u8) !void {
        try file.write("const " ++ self.structName ++ " = @import(\"" ++ self.commonName ++ "\")." ++ self.structName ++ ";\n");
        if (self.definitions) |defs| try file.write(defs);

        try file.write("pub const " ++ self.fileName ++ " = " ++ self.structName ++ " {\n");

        try file.write(zon);

        try file.write("};\n");
    }

    pub fn generateFile(self: *ZigStruct, path: []const u8, commonName: []const u8) !void {
        self.path = path;
        self.commonName = commonName;

        const zon = try self.readFile();
        defer self.allocator.free(zon);

        var file = self.createFile();
        defer file.close();

        self.writeZigFile(file, zon);
    }
};
