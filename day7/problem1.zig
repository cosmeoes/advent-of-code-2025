const std = @import("std");
const assert = std.debug.assert;

const LaserState = struct {
    columns: []bool,

    fn add(self: *LaserState, i: usize) void {
        assert(self.columns.len > i);
        self.columns[i] = true;
    }

    fn remove(self: *LaserState, i: usize) void {
        assert(self.columns.len > i);
        self.columns[i] = false;
    }
};

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day7/input.txt", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try alloc.alloc(u8, fileSize);
    const readSize = try inputFile.read(fileContent);
    assert(readSize == fileSize);
    var lines = std.mem.splitScalar(u8, fileContent,'\n');
    const first = lines.first();
    var laserState: LaserState = .{
        .columns = try alloc.alloc(bool, first.len),
    };

    for (first, 0..) |char, i| {
        if (char == 'S') {
            laserState.add(i);
            break;
        }
    }

    var count: u64 = 0;
    while (lines.next()) |line| {
        for (line, 0..) |char, i| {
            if (char == '^' and laserState.columns[i]) {
                laserState.remove(i);
                laserState.add(i-1);
                laserState.add(i+1);
                count += 1;
            }
        }
    }

    std.debug.print("Result is {}\n", .{count});
}
