const std = @import("std");
const assert = std.debug.assert;

const Grid = struct {
    content: []const u8,
    line_length: u8,

    fn getAt(self: Grid, x: i32, y: i32) u8 {
        const pos = x + (y*self.line_length) + y; // + y to offset new line chars
        if (pos >= self.content.len or x < 0 or y < 0) {
            return '.'; // sentinel
        }

        return self.content[@intCast(pos)];
    }

    fn countNeighbours(grid: Grid, x: i32, y: i32) u8 {
        var neighbourCount: u8 = 0;
        var i: i32 = -1;
        while (i < 2): (i += 1) {
            var j: i32 = -1;
            while (j < 2): (j += 1) {
                if (i == 0 and j == 0) continue;

                if (grid.getAt(x - j, y - i) == '@') {
                    neighbourCount += 1;
                }
            }
        }

        return neighbourCount;
    }
};

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day4/input.txt", .{});

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try std.heap.page_allocator.alloc(u8, fileSize);
    const readSize =  try inputFile.read(fileContent);
    assert(readSize == fileSize);
    var lineLength: u8 = 0;
    for (fileContent, 0..) |char, i| {
        if (char == '\n') {
            lineLength = @intCast(i);
            break;
        }
    }
    assert(lineLength != 0);

    const grid: Grid = .{
        .content = std.mem.trim(u8, fileContent, "\n"),
        .line_length = lineLength,
    };

    var count: u32 = 0;
    var y: i32 = 0;
    while (true) {
        var x: i32 = 0;
        while (x < grid.line_length): (x+=1) {
            if (grid.getAt(x, y) != '@') {
                continue;
            }

            if (grid.countNeighbours(x, y) < 4) {
                count += 1;
            }
        }

        y += 1;

        if (grid.content.len < y*grid.line_length+y) {
            break;
        }
    }

    std.debug.print("Result is {}\n", .{count});
}
