const std = @import("std");
const assert = std.debug.assert;


const FreshRange = struct {
    start: u64,
    end: u64,
};

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day5/input.txt", .{});

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try std.heap.page_allocator.alloc(u8, fileSize);
    var fileReader = inputFile.reader(fileContent);
    var reader = &fileReader.interface;

    // 182 is the number of lines containing ranges in the input file
    var buffer: [182]FreshRange = undefined;
    var idRanges: std.ArrayList(FreshRange) = .initBuffer(&buffer);

    while (true) {
        const line = (reader.takeDelimiter('\n') catch unreachable).?; // We shouldnt read the whole file yet.

        var it = std.mem.splitScalar(u8, line, '-');
        const first = it.next().?;
        if (it.peek() == null) {
            // if there is no split it means we
            // are at the end of the ranges and start
            // of ids.
            break;
        }
        const second = it.next().?;

        idRanges.appendAssumeCapacity(.{
            .start = std.fmt.parseInt(u64, first, 10) catch unreachable,
            .end = std.fmt.parseInt(u64, second, 10) catch unreachable,
        });
    }

    var count: u64 = 0;
    while (true) {
        const line = (reader.takeDelimiter('\n') catch |e| {
            if (e == error.EndOfFile) {
                break;
            }
            unreachable;
        });

        if (line == null) break;

        const id = std.fmt.parseInt(u64, line.?, 10) catch unreachable;

        for (idRanges.items) |range| {
            if (id >= range.start and id <= range.end) {
                count += 1;
                break;
            }
        }
    }

    std.debug.print("Result {}\n", .{count});
}
