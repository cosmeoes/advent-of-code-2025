const std = @import("std");
const assert = std.debug.assert;

const LaserState = struct {
    columns: i192 = 0,

    fn add(self: *LaserState, i: usize) void {
        const index: u8 = @intCast(i);
        self.columns |= @as(i192, 1) << index;
    }

    fn get(self: LaserState, i: usize) bool {
        const index: u8 = @intCast(i);
        return (self.columns >> index & @as(i192, 1)) == 1;
    }

    fn remove(self: *LaserState, i: usize) void {
        const index: u8 = @intCast(i);
        const mask: i192 = ~(@as(i192, 1) << index);
        self.columns &= mask;
    }
};

const Input = struct {
    content: []u8,
    line_width: usize,

    fn line(self: Input, lineNum: usize) []u8 {
        const pos = self.line_width * lineNum;
        return self.content[pos..pos+self.line_width];
    }

    fn hasLine(self: Input, lineNum: usize) bool {
        const pos = self.line_width * lineNum;
        return self.content.len > pos;
    }
};

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day7/input.txt", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try alloc.alloc(u8, fileSize);
    const readSize = try inputFile.read(fileContent);
    assert(readSize == fileSize);
    const lineWidth = std.mem.indexOfScalar(u8, fileContent,'\n').?;
    const input: Input = .{
        .content = fileContent,
        .line_width = lineWidth + 1,
    };

    var laserState: LaserState = .{};
    for (input.line(0), 0..) |char, i| {
        if (char == 'S') {
            laserState.add(i);
            break;
        }
    }

    const result: u64 = timeSplits(laserState, input, 1);

    std.debug.print("Result is {}\n", .{result+1});
}


const Key = struct {
    state: LaserState,
    line: usize,
};

var cache: std.array_hash_map.AutoArrayHashMap(Key, u64) = .init(std.heap.page_allocator);

fn timeSplits(state: LaserState, input: Input, lineNum: usize) u64 {
    if (!input.hasLine(lineNum)) {
        return 0;
    }

    const key: Key = .{ .state = state, .line = lineNum};
    const cached = cache.get(key);
    if (cached) |result| {
        return result;
    }

    var splited = false;
    var count: u64 = 0;
    var currentState = state;
    for (input.line(lineNum), 0..) |char, i| {
        if (char == '^' and currentState.get(i)) {
            currentState.remove(i);

            var rightState = currentState;
            rightState.add(i+1);
            count += timeSplits(rightState, input, lineNum+1);

            var leftState = currentState;
            leftState.add(i-1);
            count += timeSplits(leftState, input, lineNum+1);

            count += 1;
            splited = true;
        }
    }

    if (!splited) {
        count = timeSplits(state, input, lineNum+1);
    }

    cache.put(key, count) catch unreachable;
    return count;
}
