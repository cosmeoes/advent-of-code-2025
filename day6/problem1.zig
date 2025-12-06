const std = @import("std");
const assert = std.debug.assert;

const NUMBERS_PER_PROBLEM = 4;

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day6/input.txt", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try alloc.alloc(u8, fileSize);
    const readSize = try inputFile.read(fileContent);
    assert(readSize == fileSize);

    var numbers: std.ArrayList([NUMBERS_PER_PROBLEM]u64) = try .initCapacity(alloc, 1000);

    var i: usize = 0;
    var problemIndex: usize = 0;
    var rowIndex: usize = 0;
    var numberBuffer: std.ArrayList(u8) = try .initCapacity(alloc, 3);

    // Parse numbers
    while (i < fileSize): (i += 1) {
        const char = fileContent[i];
        switch (char) {
            ' ', '+', '*', '\n' => {
                if (numberBuffer.items.len > 0) {
                    if (numbers.items.len < problemIndex + 1) {
                        try numbers.append(alloc, .{0} ** NUMBERS_PER_PROBLEM);
                    }
                    numbers.items[problemIndex][rowIndex] = try std.fmt.parseInt(u64, numberBuffer.items, 10);
                    numberBuffer.clearRetainingCapacity();
                    problemIndex += 1;
                }

                if (char == '+' or char == '*') {
                    break;
                } 

                if (char == '\n') {
                    problemIndex = 0;
                    rowIndex += 1;
                }
            },
            else => {
                try numberBuffer.append(alloc, char);
            },
        }
    }

    var sum: u64 = 0;
    problemIndex = 0;
    // parse operations
    while (i < fileSize): (i += 1) {
        const char = fileContent[i];
        switch (char) {
            '+' => {
                var problemResult: u64 = 0;
                for (numbers.items[problemIndex]) |value| {
                    problemResult += value;
                }
                sum += problemResult;
                problemIndex += 1;
            },
            '*' => {
                var problemResult: u64 = 1;
                for (numbers.items[problemIndex]) |value| {
                    problemResult *= value;
                }
                sum += problemResult;
                problemIndex += 1;
            },
            else => continue,
        }
    }

    std.debug.print("Result is {}\n", .{sum});
}
