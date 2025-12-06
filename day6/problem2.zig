const std = @import("std");
const assert = std.debug.assert;

const DIGITS_PER_NUMBER = 4;

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day6/input.txt", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try alloc.alloc(u8, fileSize);
    const readSize = try inputFile.read(fileContent);
    assert(readSize == fileSize);

    const lineSize = std.mem.indexOfScalar(u8, fileContent, '\n').?;
    var i: usize = 0;
    var sum: u64 = 0;
    var currentOperation: u8 = 0;
    var accum: u64 = 0;
    var updateOperation = true;
    while (i < lineSize): (i += 1) {
        if (updateOperation) {
            const operationIndex = i + lineSize*DIGITS_PER_NUMBER + DIGITS_PER_NUMBER;
            currentOperation = fileContent[operationIndex];
            assert(currentOperation == '+' or currentOperation == '*');
            updateOperation = false;
        }

        var currentNum: u64 = 0;
        var exp: u64 = 0;
        for (0..DIGITS_PER_NUMBER) |offset| {
            const row = DIGITS_PER_NUMBER - offset - 1;
            const pos = i + lineSize*row + row;
            const char = fileContent[pos];
            if (char != ' ') {
                const value = char - 48;
                currentNum += value*std.math.pow(u64, 10, exp);
                exp += 1;
            }
        }

        if (currentNum == 0) {
            sum += accum;
            accum = 0;
            updateOperation = true;
            continue;
        }

        if (currentOperation == '+') accum += currentNum;
        if (currentOperation == '*') {
            if (accum == 0) accum = 1;
            accum *= currentNum;
        }
    }
    sum += accum;

    std.debug.print("Result is {}\n", .{sum});
}
