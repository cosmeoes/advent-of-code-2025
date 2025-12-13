const std = @import("std");

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day10/input.txt", .{});
    var buff: [4096]u8 = undefined;
    var reader = inputFile.reader(&buff);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var result: i64 = 0;
    result = 0;
    while (true) {
        const optLine = try reader.interface.takeDelimiter('\n');
        if (optLine == null) {
            break;
        }
        const line = optLine.?;
        var it = std.mem.splitScalar(u8, line, ' ');
        const diagramStr =  it.next().?;
        const diagram = parseDiagram(diagramStr);
        var buffer: [13]u16 = .{0}**13;
        const buttonMasks = parseButtons(&it, &buffer);
        var memory: std.AutoHashMap(u16, i64) = .init(alloc);
        const minClicks = findMinClicks(0, diagram, buttonMasks, 0, &memory);
        result += minClicks;
    }

    std.debug.print("result is {}\n", .{result});
}

fn parseDiagram(diagramString: []const u8) u16 {
    var res: u16 = 0;
    const mask: u16 = 1;
    for (diagramString[1..diagramString.len-1], 0..) |char, i| {
        if (char == '#') {
            res |= (mask << @as(u4, @intCast(i)));
        }
    }

    return res;
}

fn parseButtons(it: *std.mem.SplitIterator(u8, .scalar), buttonMask: []u16) []u16 {
    var count: usize = 0;
    const mask: u16 = 1;
    while (it.peek()) |buttonStr| {
        if (buttonStr[0] == '{') {
            break;
        }

        var toggleIter = std.mem.splitScalar(u8, buttonStr[1..buttonStr.len-1], ',');
        while (toggleIter.next()) |toggle| {
            std.debug.assert(toggle.len == 1);
            const toggleValue: u4 = @intCast(toggle[0] - 48);
            buttonMask[count] |= (mask << toggleValue);
        }

        count += 1;

        // Advance
        _ = it.next();
    }

    return buttonMask[0..count];
}

test "clicks" {
    const line = "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}";
    var it = std.mem.splitScalar(u8, line, ' ');

    const diagram = parseDiagram(it.next().?);
    try std.testing.expect(diagram == 0b0000000000000110);

    var buffer: [13]u16 = .{0}**13;
    const buttonMasks = parseButtons(&it, &buffer);
    try std.testing.expectEqual(6, buttonMasks.len);
    try std.testing.expectEqual(0b0000000000001000, buttonMasks[0]);
    try std.testing.expectEqual(0b0000000000001010, buttonMasks[1]);
    try std.testing.expectEqual(0b0000000000000100, buttonMasks[2]);
    try std.testing.expectEqual(0b0000000000001100, buttonMasks[3]);
    try std.testing.expectEqual(0b0000000000000101, buttonMasks[4]);
    try std.testing.expectEqual(0b0000000000000011, buttonMasks[5]);

    var state: u16 = 0;
    state ^= buttonMasks[4];
    state ^= buttonMasks[5];
    try std.testing.expect(state == diagram);
}

fn findMinClicks(current: u16, target: u16, buttonMasks: []u16, clicks: i64, memory: *std.AutoHashMap(u16, i64)) i64 {
    if (current == target) {
        return clicks;
    }
    const value = memory.get(current);
    if (value) |v| {
        if (v < 0) {
            return v;
        }

        return v+clicks;
    } else {
        // If we read this value it means we
        // reached an infinite loop
        memory.put(current, -1) catch unreachable;
    }

    var min: i64 = std.math.maxInt(i64);
    for (buttonMasks) |mask| {
        const newCurrent = (current ^ mask);
        const currentMin = findMinClicks(newCurrent, target, buttonMasks, clicks + 1, memory);
        if (currentMin > 0 and currentMin < min) {
            min = currentMin;
        }
    }

    memory.put(current, min-clicks) catch unreachable;
    return min;
}
