const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const inputFile = try std.fs.cwd().openFile("day9/input.txt", .{});
    var buff: [4096]u8 = undefined;
    var reader = inputFile.reader(&buff);

    var positions: std.ArrayList(struct { x: i64, y: i64 }) = .empty;

    while (true) {
        const optLine = reader.interface.takeDelimiter('\n') catch unreachable;
        if (optLine == null) {
            break;
        }
        const line = optLine.?;
        var it = std.mem.splitScalar(u8, line, ',');

        const x = try std.fmt.parseInt(i64, it.next().?, 10);
        const y = try std.fmt.parseInt(i64, it.next().?, 10);
        try positions.append(alloc, .{ 
            .x = x,
            .y = y,
        });
    }

    var maxArea: i64 = 0;
    // This is slow but it's instant on my computer so...
    for (positions.items, 0..) |pos1, i| {
        for (positions.items[i+1..]) |pos2| {
            var diffX: i64 = pos1.x - pos2.x;
            if (diffX < 0) {
                diffX *= -1;
            }
            diffX += 1;
            var diffY: i64 = pos1.y - pos2.y;
            if (diffY < 0) {
                diffY *= -1;
            }
            diffY += 1;
            const area = diffX * diffY;

            if (area > maxArea) {
                maxArea = area;
            }
        }
    }

    std.debug.print("Result is {}\n", .{maxArea});
}
