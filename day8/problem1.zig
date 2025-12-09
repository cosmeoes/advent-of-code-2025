const std = @import("std");
const assert = std.debug.assert;

const CONNECTIONS = 1000;

const Box = struct {
    x: i64,
    y: i64,
    z: i64,
    connections: std.ArrayList(usize),
};
const Connection = struct {
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


    var distances: std.ArrayList(u64) = try .initCapacity(alloc, CONNECTIONS);
    var connections: std.ArrayList(Connection) = try .initCapacity(alloc, CONNECTIONS);
    for (0..CONNECTIONS) |_| {
        distances.appendAssumeCapacity(0);
        connections.appendAssumeCapacity(.{ .b1 = 0, .b2 = 0});
    }
    for (boxes.items, 0..) |*box1, i| {
        for (boxes.items[i+1..], i+1..) |box2, j| {
            const distance = calculateDistance(box1.*, box2);

            const items = distances.items;
            for (items, 0..) |d, distanceIndex| {
                if (d == 0 or distance < d) {
                    _ = distances.pop();
                    _ = connections.pop();
                    distances.insertAssumeCapacity(distanceIndex, distance);
                    connections.insertAssumeCapacity(distanceIndex, .{ .b1 = i, .b2 = j });
                    break;
                }
            }
        }
    }

    for (connections.items) |connection| {
        var box = &boxes.items[connection.b1];
        var box2 = &boxes.items[connection.b2];
        box.connections.appendAssumeCapacity(connection.b2);
        box2.connections.appendAssumeCapacity(connection.b1);
    }

    var biggestGroups: std.ArrayList(usize) = try .initCapacity(alloc, 3);
    var maxIndexes: std.ArrayList(usize) = try .initCapacity(alloc, 3);
    for (0..3) |_| {
        biggestGroups.appendAssumeCapacity(0);
        maxIndexes.appendAssumeCapacity(0);
    }

    for (connections.items) |connection| {
        const groupSize, const maxIndex = calculateGroupSize(boxes, connection);
        const items = maxIndexes.items;
        if (maxIndex == items[0] or maxIndex == items[1] or maxIndex == items[2]) {
            continue;
        }

        for (biggestGroups.items, 0..) |size, i| {
            if (size < groupSize) {
                _ = biggestGroups.pop();
                _ = maxIndexes.pop();

                biggestGroups.insertAssumeCapacity(i, groupSize);
                maxIndexes.insertAssumeCapacity(i, maxIndex);
                break;
            }
        }
    }

    var result: u64 = 1;
    for (biggestGroups.items) |size| {
        result *= size;
    }

    std.debug.print("Result is {}\n", .{result});
}

fn calculateDistance(box1: Box, box2: Box) u64 {
    const x = (box1.x - box2.x)*(box1.x - box2.x);
    const y = (box1.y - box2.y)*(box1.y - box2.y);
    const z = (box1.z - box2.z)*(box1.z - box2.z);
    return std.math.sqrt(@as(u64, @intCast(x + y + z)));
}

fn calculateGroupSize(boxes: std.ArrayList(Box), connection: Connection) struct { u32, usize } {
    var buffer: [CONNECTIONS]usize = undefined;
    var visited : std.ArrayList(usize) = .initBuffer(&buffer);

    var toVisitBuffer: [CONNECTIONS]usize = undefined;
    var toVisit : std.ArrayList(usize) = .initBuffer(&toVisitBuffer);

    toVisit.appendAssumeCapacity(connection.b1);

    var groupSize: u32 = 1;
    var maxIndex: usize = 0;

    blk:
    while (toVisit.items.len > 0) {
        const index = toVisit.pop().?;
        for (visited.items) |v| {
            if (v == index) continue :blk;
        }
        visited.appendAssumeCapacity(index);
        const boxConnections = boxes.items[index].connections;
        for (boxConnections.items) |i| {
            var exists = false;
            for (toVisit.items) |tv| {
                if (tv == i) {
                    exists = true;
                    break;
                }
            }

            for (visited.items) |tv| {
                if (tv == i) {
                    exists = true;
                    break;
                }
            }

            if (maxIndex < i) {
                maxIndex = i;
            }

            if (!exists) {
                toVisit.appendAssumeCapacity(i);
                groupSize += 1;
            }
        }
    }

    return .{ groupSize, maxIndex };
}
