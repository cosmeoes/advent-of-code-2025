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
        _ =  it.next().?;

        const buttons = parseButtons(alloc, &it);

        var joltageBuffer: [10]u16 = .{0}**10;
        _ = parseJoltage(it.next().?, &joltageBuffer);

        const minClicks = findMinClicks(alloc, joltageBuffer, buttons); 
        // var initialMin: i64 = 0;
        // for (joltageBuffer) |value| {
        //     initialMin += value;
        // }
        // var memory: std.AutoHashMap([10]u16, i64) = .init(alloc);
        // const minClicks = findMinClicks2(alloc, joltageBuffer, initialMin, buttons, 0, &memory);
        std.debug.print("mincl is {}\n", .{minClicks});
        result += minClicks;
    }

    std.debug.print("result is {}\n", .{result});
}

fn parseButtons(alloc: std.mem.Allocator, it: *std.mem.SplitIterator(u8, .scalar)) [][]u8 {
    var buffer: [][]u8 = alloc.alloc([]u8, 13) catch unreachable;
    var count: usize = 0;
    while (it.peek()) |buttonStr| {
        if (buttonStr[0] == '{') {
            break;
        }

        const numberCount = std.mem.count(u8, buttonStr[1..buttonStr.len-1], ",") + 1;
        var toggleIter = std.mem.splitScalar(u8, buttonStr[1..buttonStr.len-1], ',');
        var numbers = alloc.alloc(u8, numberCount) catch unreachable;
        var i: usize = 0;
        while (toggleIter.next()) |toggle| {
            defer i += 1;
            std.debug.assert(toggle.len == 1);
            const toggleValue: u8 = toggle[0] - 48;
            numbers[i] = toggleValue;
        }
        buffer[count] = numbers;
        count += 1;

        // Advance
        _ = it.next();
    }

    std.mem.sort([]u8, buffer[0..count], {}, struct{
        fn f(_: void,  lhs: []u8, rhs: []u8) bool {
            return lhs.len > rhs.len;
        }
    }.f);

    return buffer[0..count];
}

fn parseJoltage(joltageString: []const u8, buffer: []u16) usize {
    var count: usize = 0;

    var it = std.mem.splitScalar(u8, joltageString[1..joltageString.len-1], ',');
    var min: u16 = 0;
    while (it.next()) |numStr| {
        const num = std.fmt.parseInt(u16, numStr, 10) catch unreachable;
        if (min == 0 or num < min) {
            min = num;
        }
        buffer[count] = num;
        count += 1;
    }

    return count;
}


fn findMinClicks(alloc: std.mem.Allocator, target: [10]u16, buttons: [][]u8) i64 {
    const QueueItem = struct {
        state: [10]u16,
        clicks: i64,
        node: std.DoublyLinkedList.Node = .{},
    };

    var queue: std.DoublyLinkedList = .{};

    var item: QueueItem = .{ .state = target, .clicks = 0 };
    queue.append(&item.node);

    var min: i64 = 0;
    for (target) |value| {
        min += value;
    }

    var seen: std.AutoHashMap([10]u16, void) = .init(alloc);

    while (queue.popFirst()) |node| {
        const currentItem: *QueueItem = @fieldParentPtr("node", node);
        defer alloc.destroy(currentItem);

         if (seen.get(currentItem.state)) |_| {
             continue;
         }

        seen.put(currentItem.state, {}) catch unreachable;

        const zeros: [10]u16 = .{0}**10;
        if (std.mem.eql(u16, &currentItem.state, &zeros)) {
            if (min > currentItem.clicks) {
                min = currentItem.clicks;
                std.debug.print("Found new min {}\n", .{min});
            }
            continue;
        }

        if (currentItem.clicks + 1 > min) {
            continue;
        }

        outter:
        for (buttons) |toggles| {
            var newState = currentItem.state;
            var maxRemaning: u16 = 0;
            var maxRemaningIndex: usize = 0;
            for (newState, 0..) |value, i| {
                if (value > maxRemaning) {
                    maxRemaning = value; 
                    maxRemaningIndex = i;
                }
            }

            var hasMax = false;
            for (toggles) |i| {
                if (newState[i] == 0) {
                    continue :outter;
                }
                if (i == maxRemaningIndex) {
                    hasMax = true;
                }

                newState[@intCast(i)] -= 1;
            }

            if (!hasMax) continue;

            if (maxRemaning - 1 < min - currentItem.clicks+1) {
                const newItem = alloc.create(QueueItem) catch unreachable;
                newItem.* = .{
                    .state = newState,
                    .clicks = currentItem.clicks + 1,
                };
                queue.append(&newItem.node);
            }
        }
    }

    std.debug.assert(min != -1);

    return min;
}

fn findMinClicks2(alloc: std.mem.Allocator, current: [10]u16, prevMin: i64, buttons: [][]u8, clicks: i64, memory: *std.AutoHashMap([10]u16, i64)) i64 {
    const value = memory.get(current);
    if (value) |v| {
        if (v < 0) {
            return v;
        }

        return v+clicks;
    } 

    if (prevMin < clicks) {
        memory.put(current, -1) catch unreachable;
        return -1;
    }

    const zeros: [10]u16 = .{0}**10;
    if (std.mem.eql(u16, &current, &zeros)) {
        return clicks;
    }

    var min: i64 = prevMin;
    var maxNum: u16 = 0;
    var maxNumIndex: usize = 0;
    for (current, 0..) |val, i| {
        if (maxNum < val) {
            maxNum = val;
            maxNumIndex = i;
        }
    }

    if (min - clicks < maxNum) {
        memory.put(current, -1) catch unreachable;
        return -1;
    }

    // var options = try std.ArrayList([10]u16).initCapacity(alloc, buttons.len);
    // defer options.deinit(alloc);

    outter:
    for (buttons) |toggles| {
        var newState = current;
        var hasMaxNumIndex = false;
        for (toggles) |i| {
            if (newState[i] == 0) {
                continue :outter;
            }

            if (i == maxNumIndex) {
                hasMaxNumIndex = true;
            }

            newState[@intCast(i)] -= 1;
        }

        const currentMin = findMinClicks2(alloc, newState, min, buttons, clicks+1, memory);
        if (currentMin > 0 and currentMin < min) {
            std.debug.print("{} {}\n", .{clicks, min});
            min = currentMin;
        }
        //options.appendAssumeCapacity(newState);
    }

    //std.mem.sort

    if (min == prevMin) {
        memory.put(current, -1) catch unreachable;
        return -1;
    }

    memory.put(current, min-clicks) catch unreachable;
    return min;
}
