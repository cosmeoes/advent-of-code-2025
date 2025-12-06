const std = @import("std");
const assert = std.debug.assert;

const Grid = struct {
    content: []u8,
    line_length: u8,
    alloc: std.mem.Allocator,
    to_remove: std.ArrayList(usize),

    fn getAt(self: Grid, x: i32, y: i32) u8 {
        if (x < 0 or y < 0) {
            return '.'; // sentinel
        }

        const pos = self.getPosFor(x, y);
        if (pos >= self.content.len) {
            return '.'; // sentinel
        }

        return self.content[pos];
    }

    fn getPosFor(self: Grid, x: i32, y: i32) usize {
        return @intCast(x + (y * self.line_length) + y); // + y to offset new line chars
    }

    fn countNeighbours(grid: Grid, x: i32, y: i32) u8 {
        var neighbourCount: u8 = 0;
        var i: i32 = -1;
        while (i < 2) : (i += 1) {
            var j: i32 = -1;
            while (j < 2) : (j += 1) {
                if (i == 0 and j == 0) continue;

                if (grid.getAt(x - j, y - i) == '@') {
                    neighbourCount += 1;
                }
            }
        }

        return neighbourCount;
    }

    fn markForRemoval(self: *Grid, x: i32, y: i32) void {
        const pos = self.getPosFor(x, y);
        self.to_remove.append(self.alloc, pos) catch unreachable;
    }

    fn removeMarked(self: *Grid) void {
        for (self.to_remove.items) |pos| {
            self.content[pos] = '.';
        }

        self.to_remove.clearRetainingCapacity();
    }
};

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day4/input.txt", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try allocator.alloc(u8, fileSize);
    const readSize = try inputFile.read(fileContent);
    assert(readSize == fileSize);
    var lineLength: u8 = 0;
    for (fileContent, 0..) |char, i| {
        if (char == '\n') {
            lineLength = @intCast(i);
            break;
        }
    }
    assert(lineLength != 0);

    var grid: Grid = .{
        .content = @constCast(std.mem.trim(u8, fileContent, "\n")),
        .line_length = lineLength,
        .alloc = allocator,
        .to_remove = try .initCapacity(allocator, 100),
    };

    var sum: u32 = 0;
    var count: u32 = 0;
    var y: i32 = 0;
    while (true) {
        var x: i32 = 0;
        while (x < grid.line_length) : (x += 1) {
            if (grid.getAt(x, y) != '@') {
                continue;
            }

            if (grid.countNeighbours(x, y) < 4) {
                count += 1;
                grid.markForRemoval(x, y);
            }
        }

        y += 1;
        if (grid.content.len < y * grid.line_length + y) {
            if (count == 0) {
                break;
            }
            sum += count;
            y = 0;
            count = 0;
            grid.removeMarked();
        }
    }

    std.debug.print("Result is {}\n", .{sum});
}
