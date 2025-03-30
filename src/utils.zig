const std = @import("std");

const SextetIndexer = struct {
    const Self = @This();

    bytes: []const u8,

    fn get(self: Self, index: usize) u6 {
        const byte_index = index * 6 / std.mem.byte_size_in_bits;
        return switch (index % 4) {
            0 => @intCast(self.bytes[byte_index] >> 2),
            1 => {
                const first_two = self.bytes[byte_index] << 4 & 0b110000;
                const last_four = (self.bytes[byte_index + 1] >> 4) & 0b001111;
                return @intCast(first_two | last_four);
            },
            2 => {
                const first_four = self.bytes[byte_index] << 2 & 0b111100;
                const last_two = (self.bytes[byte_index + 1] >> 6) & 0b000011;
                return @intCast(first_four | last_two);
            },
            3 => @intCast(self.bytes[byte_index] & 0b111111),
            else => unreachable,
        };
    }
};

const testing = std.testing;
test "Simple iteration" {
    {
        const data = "abc"; // 011000 010110 001001 100011
        const indexer = SextetIndexer{ .bytes = data };

        try testing.expectEqual(0b011000, indexer.get(0));
        try testing.expectEqual(0b010110, indexer.get(1));
        try testing.expectEqual(0b001001, indexer.get(2));
        try testing.expectEqual(0b100011, indexer.get(3));
    }
    {
        const data = "abcabc"; // 011000 010110 001001 100011
        const indexer = SextetIndexer{ .bytes = data };

        try testing.expectEqual(0b011000, indexer.get(0));
        try testing.expectEqual(0b010110, indexer.get(1));
        try testing.expectEqual(0b001001, indexer.get(2));
        try testing.expectEqual(0b100011, indexer.get(3));
        try testing.expectEqual(0b011000, indexer.get(4));
        try testing.expectEqual(0b010110, indexer.get(5));
        try testing.expectEqual(0b001001, indexer.get(6));
        try testing.expectEqual(0b100011, indexer.get(7));
    }
}

test "Non-divisible by 3" {}
