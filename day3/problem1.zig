const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day3/input.txt", .{});

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try std.heap.page_allocator.alloc(u8, fileSize);
    const readSize = try inputFile.read(fileContent);
    assert(readSize == fileContent.len);

    const content = std.mem.trim(u8, fileContent, "\n");
    var lines = std.mem.splitScalar(u8, content, '\n');

    var sum: u64 = 0;
    while (lines.next()) |line| {
        var maxDecimal: u8 = 0;
        var maxUnit: u8 = 0;
        for (line, 0..) |char, i| {
            const value = char - 48;
            if (value > maxDecimal and i < line.len - 1) {
                maxDecimal = value;
                maxUnit = 0;
            } else if (value > maxUnit) {
                maxUnit = value;
            }
        }
        sum += maxDecimal*10 + maxUnit;
    }

    std.debug.print("Result is {}\n", .{sum});
}
