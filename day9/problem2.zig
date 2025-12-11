const std = @import("std");

const Grid = struct {
    buffer: std.DynamicBitSet,
    offsetX: u64,
    offsetY: u64,
    width: u64,
    height: u64,

    pub fn set(self: *Grid, x: usize, y: usize) void {
        const pos = self.getPos(x, y);

        self.buffer.set(pos);
    }

    pub fn get(self: Grid, x: usize, y: usize) bool {
        return self.buffer.isSet(self.getPos(x, y));
    }

    pub fn print(self: Grid) void {
        for (self.offsetY..self.offsetY+self.height) |y| {
            for (self.offsetX..self.offsetX+self.width) |x| {
                var char: u8 = '.';
                if (self.get(x, y)) {
                    char = 'x';
                }
                std.debug.print(" {c} ", .{char});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn getPos(self: Grid, x: usize, y: usize) usize {
        return (x - self.offsetX) + (y - self.offsetY)*self.width;
    }
};

const Position = struct {
    x: i64,
    y: i64,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const inputFile = try std.fs.cwd().openFile("day9/input.txt", .{});
    var buff: [4096]u8 = undefined;
    var reader = inputFile.reader(&buff);

    var positions: std.ArrayList(Position) = .empty;

    var maxX: i64 = 0;
    var minX: i64 = std.math.maxInt(i64);
    var maxY: i64 = 0;
    var minY: i64 = std.math.maxInt(i64);
    while (true) {
        const optLine = reader.interface.takeDelimiter('\n') catch unreachable;
        if (optLine == null) {
            break;
        }
        const line = optLine.?;
        var it = std.mem.splitScalar(u8, line, ',');

        const x = try std.fmt.parseInt(i64, it.next().?, 10);
        const y = try std.fmt.parseInt(i64, it.next().?, 10);
        if (maxX < x) {
            maxX = x;
        }
        if (minX > x) {
            minX = x;
        }
        if (maxY < y) {
            maxY = y;
        }
        if (minY > y) {
            minY = y;
        }

        try positions.append(alloc, .{ 
            .x = x,
            .y = y,
        });
    }

    const width: usize = @intCast(maxX+1 - minX);
    const height: usize = @intCast(maxY+1 - minY);
    var grid = Grid{
        .buffer = try .initEmpty(alloc, width*height),
        .offsetX = @intCast(minX),
        .offsetY = @intCast(minY),
        .width = width,
        .height = height,
    };

    for (positions.items, 0..) |pos, i| {
        const x: usize = @intCast(pos.x);
        const y: usize = @intCast(pos.y);
        grid.set(x, y);
        var next: usize = i+1;
        if (next > positions.items.len - 1) {
            next = 0;
        }

        const pos2 = positions.items[next];
        var x1 = x;
        var x2: usize = @intCast(pos2.x);
        var y1 = y;
        var y2: usize = @intCast(pos2.y);
        if (x1 > x2) {
            const tmp = x2;
            x2 = x1;
            x1 = tmp;
        }
        if (y1 > y2) {
            const tmp = y2;
            y2 = y1;
            y1 = tmp;
        }

        if (x1 != x2) {
            for (x1+1..x2) |gx| {
                grid.set(gx, @intCast(pos.y));
            }
        }
        if (y1 != y2) {
            for (y1+1..y2) |gy| {
                grid.set(@intCast(pos.x), gy);
            }
        }
    }

    const bitSet = try grid.buffer.clone(alloc);
    var inside = false;
    for (0..bitSet.capacity()) |i| {
        if (i > 0 and bitSet.isSet(i-1) and !bitSet.isSet(i)) {
            inside = !inside;
        }

        if (i > 0 and i%grid.width == 0) {
            inside = false;
        }

        if (inside) {
            grid.buffer.set(i);
        }
    }

    var maxArea: i64 = 0;
    var p1: Position = undefined;
    var p2: Position = undefined;
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

            if (area > maxArea and validRect(grid, pos1, pos2)) {
                maxArea = area;
                p1 = pos1;
                p2 = pos2;
            }
        }
    }

    std.debug.print("Result is {}\n", .{maxArea});
}

fn validRect(grid: Grid, pos1: Position, pos2: Position) bool {
    const minX: usize = @intCast(@min(pos1.x, pos2.x));
    const maxX: usize = @intCast(@max(pos1.x, pos2.x) + 1);

    const minY: usize = @intCast(@min(pos1.y, pos2.y));
    const maxY: usize = @intCast(@max(pos1.y, pos2.y) + 1);

    for (minX..maxX) |x| {
        if (!grid.get(x, @intCast(pos1.y))) {
            return false;
        }

        if (!grid.get(x, @intCast(pos2.y))) {
            return false;
        }
    }
    for (minY..maxY) |y| {
        if (!grid.get(@intCast(pos1.x), y)) {
            return false;
        }
        if (!grid.get(@intCast(pos2.x), y)) {
            return false;
        }
    }

    return true;
}
