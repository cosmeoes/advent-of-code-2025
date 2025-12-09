const std = @import("std");
const assert = std.debug.assert;

const Box = struct {
    x: i64,
    y: i64,
    z: i64,
    connections: std.ArrayList(usize),
};
const Connection = struct {
    distance: u64,
    b1: usize,
    b2: usize,
};

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day8/input.txt", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try alloc.alloc(u8, fileSize);
    const readSize = try inputFile.read(fileContent);
    assert(readSize == fileSize);
    var lines = std.mem.splitScalar(u8, fileContent, '\n');

    var boxes: std.ArrayList(Box) = try .initCapacity(alloc, 1000);
    while (lines.next()) |line| {
        var coordenates = std.mem.splitScalar(u8, line, ',');
        const stringX = coordenates.next().?;
        if (coordenates.peek() == null) {
            continue;
        }

        const x = try std.fmt.parseInt(i64, stringX, 10);
        const y = try std.fmt.parseInt(i64, coordenates.next().?, 10);
        const z = try std.fmt.parseInt(i64, coordenates.next().?, 10);

        try boxes.append(alloc, .{
            .x = x, .y = y, .z = z,
            .connections = try .initCapacity(alloc, 100),
        });
    }

    var connections: std.ArrayList(Connection) = .empty;

    for (boxes.items, 0..) |*box1, i| {
        for (boxes.items[i+1..], i+1..) |box2, j| {
            const distance = calculateDistance(box1.*, box2);
            try connections.append(alloc, .{ .b1 = i, .b2 = j, .distance = distance });
        }
    }

    std.mem.sort(Connection, connections.items, .{}, comptime lessThan);
    var visited: std.ArrayList(usize) = try .initCapacity(alloc, boxes.items.len);

    var result: i64 = 0; 
    for (connections.items) |conn| {
        var addB1 = true;
        var addB2 = true;
        for (visited.items) |v| {
            if (v == conn.b1) addB1 = false;
            if (v == conn.b2) addB2 = false;
            if (!addB2 and !addB1) break;
        }

        if (addB1) {
            visited.appendAssumeCapacity(conn.b1);
        }
        if (addB2) {
            visited.appendAssumeCapacity(conn.b2);
        }

        if (visited.items.len == boxes.items.len) {
            std.debug.print("{} {}\n", .{boxes.items[conn.b1].x, boxes.items[conn.b1].y});
            result = boxes.items[conn.b1].x * boxes.items[conn.b2].x;
            break;
        }
    }

    std.debug.print("Result is {}\n", .{result});
}

fn calculateDistance(box1: Box, box2: Box) u64 {
    const x = (box1.x - box2.x)*(box1.x - box2.x);
    const y = (box1.y - box2.y)*(box1.y - box2.y);
    const z = (box1.z - box2.z)*(box1.z - box2.z);
    return std.math.sqrt(@as(u64, @intCast(x + y + z)));
}

fn lessThan(_: @TypeOf(.{}), left: Connection, right: Connection) bool {
        return left.distance < right.distance;
}
