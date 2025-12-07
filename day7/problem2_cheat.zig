// I saw an animation of this solution on the advent of code subreddit 
// so I decided to implemented because it feets better with the way I was 
// trying to solve the problem but couldn't figure out own my own :(
const std = @import("std");
const assert = std.debug.assert;

const LaserState = struct {
    columns: []u64,

    fn add(self: *LaserState, i: usize, amount: u64) void {
        assert(self.columns.len > i);
        self.columns[i] += amount;
    }

    fn remove(self: *LaserState, i: usize) void {
        assert(self.columns.len > i);
        self.columns[i] = 0;
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
        .columns = try alloc.alloc(u64, first.len),
    };
    @memset(laserState.columns, 0);

    for (first, 0..) |char, i| {
        if (char == 'S') {
            laserState.add(i, 1);
            break;
        }
    }

    while (lines.next()) |line| {
        for (line, 0..) |char, i| {
            if (char == '^' and laserState.columns[i] > 0) {
                laserState.add(i-1, laserState.columns[i]);
                laserState.add(i+1, laserState.columns[i]);

                laserState.remove(i);
            }
        }
    }

    var count: u64 = 0;
    for (laserState.columns) |value| {
        count += value;
    }
    std.debug.print("Result is {}\n", .{count});
}
