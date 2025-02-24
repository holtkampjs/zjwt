const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

//                    Table 1: The Base 64 Alphabet
//
//   Value Encoding  Value Encoding  Value Encoding  Value Encoding
//       0 A            17 R            34 i            51 z
//       1 B            18 S            35 j            52 0
//       2 C            19 T            36 k            53 1
//       3 D            20 U            37 l            54 2
//       4 E            21 V            38 m            55 3
//       5 F            22 W            39 n            56 4
//       6 G            23 X            40 o            57 5
//       7 H            24 Y            41 p            58 6
//       8 I            25 Z            42 q            59 7
//       9 J            26 a            43 r            60 8
//      10 K            27 b            44 s            61 9
//      11 L            28 c            45 t            62 +
//      12 M            29 d            46 u            63 /
//      13 N            30 e            47 v
//      14 O            31 f            48 w         (pad) =
//      15 P            32 g            49 x
//      16 Q            33 h            50 y

const byte_size_in_bits = std.mem.byte_size_in_bits;
const encoding_map = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// Pseudocode:
// Take input bytes and treat as "stream of bits"
// For each 6 bits of data, treat as unsigned integer
// Map unsigned integers to mapped values
// Pad as appropriate

fn encode(data: []const u8) []const u8 {
    const alloc = std.heap.page_allocator;

    const bit_count = data.len * byte_size_in_bits;
    _ = bit_count; // autofix
    const sextets = split_into_sextets(data, alloc);
    _ = sextets; // autofix
    // const acc: u6 = 0;
    // for (0..bit_count) |index| {
    //     // Bit shift by 3 bits to the right is the same as divide by 8
    //     const arr_idx = index >> 3;
    //     // Extract individual bit
    //     // d: data[0] == h -> 0b01101000
    //     // b: d >> ((8-1) - (0%6)) & 1
    //     // b == 0
    //     const bit = data[arr_idx] >> ((byte_size_in_bits - 1) - (index % 6)) & 1;
    //     acc |= bit << (index % 6);
    //     if (index % 6 == 5) {
    //         arr.append(acc);
    //         acc = 0;
    //     }
    // }
    return data;
}

// TODO: Refactor. Idea single loop with bit index as counter. Math to compute all values
// TODO: Use typeinfo of u6 rather than magical 6s
fn split_into_sextets(bytes: []const u8, allocator: Allocator) ArrayList(u6) {
    var arr = std.ArrayList(u6).init(allocator);

    var acc: u6 = 0;
    var bits_filled: u3 = 0;
    for (0..bytes.len) |byte_index| {
        for (0..byte_size_in_bits) |bit_index| {
            const bit: u1 = @intCast(bytes[byte_index] >> @intCast(7 - bit_index) & 1);
            acc = acc << 1 | bit;
            bits_filled += 1;
            if (bits_filled == 6) {
                arr.append(acc) catch unreachable;
                acc = 0;
                bits_filled = 0;
            }
        }
    }

    // Pad incomplete sextet with zeros
    if (bits_filled != 0) {
        arr.append(acc << 6 - bits_filled) catch unreachable;
    }
    return arr;
}

test "split_into_sextets" {
    const alloc = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    // Handle divisible by 3 inputs
    {
        const data: []const u8 = "ABC";
        // Hex: 0x41 0x42 0x43
        // Bin: 0b01000001 0b01000010 0b01000011
        // Sextets: 010000 010100 001001 000011
        const result = split_into_sextets(data, alloc);
        defer result.deinit();

        try expectEqual(4, result.items.len);
        try expectEqual(0b010000, result.items[0]);
        try expectEqual(0b010100, result.items[1]);
        try expectEqual(0b001001, result.items[2]);
        try expectEqual(0b000011, result.items[3]);
    }
    {
        const data: []const u8 = "AAC";
        const result = split_into_sextets(data, alloc);
        defer result.deinit();

        try expectEqual(4, result.items.len);
        try expectEqual(0b010000, result.items[0]);
        try expectEqual(0b010100, result.items[1]);
        try expectEqual(0b000101, result.items[2]);
        try expectEqual(0b000011, result.items[3]);
    }

    // Handle non-divisible by 3 inputs
    {
        const data: []const u8 = "A";
        const result = split_into_sextets(data, alloc);
        defer result.deinit();

        try expectEqual(2, result.items.len);
        try expectEqual(0b010000, result.items[0]);
        try expectEqual(0b010000, result.items[1]);
    }
    {
        const data: []const u8 = "AB";
        const result = split_into_sextets(data, alloc);
        defer result.deinit();

        try expectEqual(3, result.items.len);
        try expectEqual(0b010000, result.items[0]);
        try expectEqual(0b010100, result.items[1]);
        try expectEqual(0b001000, result.items[2]);
    }

    // Trivial case
    {
        const data: []const u8 = "";
        const result = split_into_sextets(data, alloc);
        defer result.deinit();

        try expectEqual(0, result.items.len);
    }
}

// test "encode a" {
//     const text = "a";
//     const expected = "YQ==";

//     const encoded_str = encode(text);

//     try std.testing.expectEqualStrings(expected, encoded_str);
// }

// test "Encode hi" {
//     const text = "hi";
//     const expected = "aGk=";

//     const encoded_str = encode(text);

//     try std.testing.expectEqualStrings(expected, encoded_str);
// }

// hello
// h -> 0x68 -> 0b01101000
// e -> 0x65 -> 0b01100101
// l -> 0x6c -> 0b01101100
// l -> 0x6c -> 0b01101100
// o -> 0x6f -> 0b01101111
// Stream: 0110100001100101011011000110110001101111

// Sextets:
// 011010 -> 26 -> a
// 000110 ->  6 -> G
// 010101 -> 21 -> V
// 101100 -> 44 -> s
// 011011 -> 27 -> b
// 000110 ->  6 -> G
// 111100 -> 60 -> 8

// Encoded "hello" = "aGVsbG8="

// test "Encode hello" {
//     const text = "hello";
//     const expected = "aGVsbG8=";

//     const encoded_str = encode(text);

//     try std.testing.expectEqualStrings(expected, encoded_str);
// }
