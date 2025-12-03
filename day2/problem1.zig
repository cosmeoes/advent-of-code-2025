const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day2/input.txt", .{});

    const fileSize = (try inputFile.stat()).size;
    const content = try std.heap.page_allocator.alloc(u8, fileSize);
    const readSize = try inputFile.read(content);
    assert(readSize == content.len);

    var start: u64 = 0;
    var end: u64 = 0;
    // The max num length in the input is 10 digits
    var stringBuff: [10]u8 = undefined;
    var sumOfInvalid: usize = 0;
    for (0..content.len) |i| {
        var rangeFound = false;
        if (content[i] == ',' or i == content.len - 1) {
            end = i;
            rangeFound = true;
        }

        if (rangeFound) {
            assert(start != end);
            var range = std.mem.splitScalar(u8, content[start..end], '-');
            const rs = range.next().?;
            const re = range.next().?;

            const rangeStart = try std.fmt.parseInt(usize, rs, 10);
            const rangeEnd = try std.fmt.parseInt(usize, re, 10);

            for (rangeStart..rangeEnd + 1) |num| {
                const endIndex = std.fmt.printInt(&stringBuff, num, 10, .lower, .{});
                const stringNum = stringBuff[0..endIndex];
                const middleIndex = endIndex / 2;
                const isEvenLength = @mod(@as(f32, @floatFromInt(stringNum.len)), 2.0) == 0.0;
                if (isEvenLength and std.mem.eql(u8, stringNum[0..middleIndex], stringNum[middleIndex..endIndex])) {
                    sumOfInvalid += num;
                }
            }

            start = end + 1;
        }

        rangeFound = false;
    }

    std.debug.print("Result is {}\n", .{sumOfInvalid});
}
