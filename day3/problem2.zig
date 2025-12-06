const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    const inputFile = try std.fs.cwd().openFile("day3/input.txt", .{});

    const fileSize = (try inputFile.stat()).size;
    const fileContent = try std.heap.page_allocator.alloc(u8, fileSize);
    const readSize = try inputFile.read(fileContent);
    assert(readSize == fileContent.len);

    const content = std.mem.trim(u8, fileContent, "\n");
    var lines = std.mem.splitScalar(u8, content, '\n');

    var sum: i64 = 0;
    while (lines.next()) |line| {
        const lineSum = maxSum(line, 12);
        sum += lineSum; 
    }

    std.debug.print("Result is {}\n", .{sum});
}

const CacheKey = struct {
    chars: []const u8,
    remaning: u8,
};

const Context = struct {
    pub fn hash(_: Context, key: CacheKey) u32 {
        const charsHash = std.array_hash_map.hashString(key.chars);
        return key.remaning+charsHash;
    }

    pub fn eql(_: Context, key1: CacheKey, key2: CacheKey, _: usize) bool {
        return  key1.remaning == key2.remaning and std.mem.eql(u8, key1.chars, key2.chars);
    }
};

var cache: std.array_hash_map.ArrayHashMap(CacheKey, i64, Context, true) = .init(std.heap.page_allocator);

fn maxSum(chars: []const u8, remaning: u8) i64 {
    const cacheKey: CacheKey = .{.chars = chars, .remaning = remaning};
    if (cache.contains(cacheKey)) {
        return cache.get(cacheKey).?;
    }

    if (remaning <= 0 or chars.len < remaning) {
        return 0;
    }
    const currentPow = std.math.pow(i64, 10, remaning-1);
    const digit = chars[0] - 48;
    const maxWithCurrent = (digit*currentPow) + maxSum(chars[1..], remaning - 1);
    const maxWithNext = maxSum(chars[1..], remaning);

    var result = maxWithNext;
    if (maxWithCurrent > maxWithNext) {
        result = maxWithCurrent;
    }

    cache.put(cacheKey, result) catch unreachable;
    return result;
}
