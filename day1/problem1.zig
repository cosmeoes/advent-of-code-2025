const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    const cwd = std.fs.cwd();
    const inputFile = try cwd.openFile("day1/input.txt", .{});

    const content = try std.heap.page_allocator.alloc(u8, (try inputFile.stat()).size);
    const readSize = try inputFile.read(content);
    assert(readSize == content.len);

    var lines = std.mem.splitScalar(u8, content, '\n');
    var pos: i64 = 50;
    var zeroCount: i64 = 0;
    while (lines.next()) |line| {
        if (line.len < 2) {
            continue; // last line
        }

        const side = line[0];
        var value = try std.fmt.parseInt(i64, line[1..], 10);

        if (side == 'L') {
            value = value*-1;
        }

        pos += value;

        while (pos < 0) {
            pos = 99 + pos + 1;
        } 

        while (pos > 99) {
            pos = pos - 99 - 1;
        }

        if (pos == 0) {
            zeroCount += 1;
        }

        assert(pos >= 0);
        assert(pos <= 99);
    }
}
