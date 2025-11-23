const std = @import("std");

/// Base64 alphabet (standard encoding)
const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/// Encode bytes to base64 string
/// Caller owns returned memory
pub fn encode(allocator: std.mem.Allocator, data: []const u8) ![]u8 {
    if (data.len == 0) return try allocator.alloc(u8, 0);

    // Calculate output size: ((n + 2) / 3) * 4
    const out_len = ((data.len + 2) / 3) * 4;
    var result = try allocator.alloc(u8, out_len);
    var out_idx: usize = 0;

    var i: usize = 0;
    while (i < data.len) : (i += 3) {
        // Read 3 bytes (or remaining)
        const b0 = data[i];
        const b1 = if (i + 1 < data.len) data[i + 1] else 0;
        const b2 = if (i + 2 < data.len) data[i + 2] else 0;

        // Encode to 4 base64 chars
        const n = (@as(u32, b0) << 16) | (@as(u32, b1) << 8) | @as(u32, b2);

        result[out_idx] = alphabet[(n >> 18) & 0x3F];
        result[out_idx + 1] = alphabet[(n >> 12) & 0x3F];
        result[out_idx + 2] = if (i + 1 < data.len) alphabet[(n >> 6) & 0x3F] else '=';
        result[out_idx + 3] = if (i + 2 < data.len) alphabet[n & 0x3F] else '=';

        out_idx += 4;
    }

    return result;
}

test "base64 encode" {
    const allocator = std.testing.allocator;

    // Test empty
    const empty = try encode(allocator, "");
    defer allocator.free(empty);
    try std.testing.expectEqualStrings("", empty);

    // Test "A" -> "QQ=="
    const a = try encode(allocator, "A");
    defer allocator.free(a);
    try std.testing.expectEqualStrings("QQ==", a);

    // Test "Hello" -> "SGVsbG8="
    const hello = try encode(allocator, "Hello");
    defer allocator.free(hello);
    try std.testing.expectEqualStrings("SGVsbG8=", hello);

    // Test binary data
    const binary = [_]u8{0xFF, 0x00, 0xAB};
    const encoded = try encode(allocator, &binary);
    defer allocator.free(encoded);
    try std.testing.expectEqualStrings("/wCr", encoded);
}
