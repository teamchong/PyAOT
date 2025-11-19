// ============================================================================
// DEPRECATED: Library-Specific Patch (To Be Removed)
// ============================================================================
//
// This file implements pandas-specific operations as a workaround.
//
// WHY DEPRECATED:
// - Wrong approach: Patching libraries one-by-one doesn't scale
// - Correct approach: Fix missing Python core features (magic methods, etc.)
// - Once core Python features work, pandas compiles automatically
//
// KEEPING FOR NOW:
// - Reference for testing while implementing core features
// - Will be removed after Python language gaps are filled
//
// RELATED ISSUE: Need to implement __getitem__, __len__, __iter__ in compiler
// ============================================================================

/// Pandas DataFrame → NumPy/BLAS Integration
/// Provides DataFrame operations backed by BLAS for performance
///
/// This module maps pandas DataFrame operations to underlying numpy/BLAS calls
/// to achieve native performance without Python interpreter overhead.

const std = @import("std");
const numpy = @import("numpy.zig");

/// DataFrame column - stores name and f64 data
pub const Column = struct {
    name: []const u8,
    data: []f64,
    allocator: std.mem.Allocator,

    pub fn init(name: []const u8, data: []f64, allocator: std.mem.Allocator) !Column {
        const name_copy = try allocator.dupe(u8, name);
        return Column{
            .name = name_copy,
            .data = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Column) void {
        self.allocator.free(self.name);
        self.allocator.free(self.data);
    }

    /// Sum all values in column using numpy.sum
    pub fn sum(self: *const Column) f64 {
        return numpy.sum(self.data);
    }

    /// Calculate mean using numpy.mean
    pub fn mean(self: *const Column) f64 {
        return numpy.mean(self.data);
    }

    /// Get minimum value
    pub fn min(self: *const Column) f64 {
        if (self.data.len == 0) return 0.0;
        var min_val = self.data[0];
        for (self.data[1..]) |val| {
            if (val < min_val) min_val = val;
        }
        return min_val;
    }

    /// Get maximum value
    pub fn max(self: *const Column) f64 {
        if (self.data.len == 0) return 0.0;
        var max_val = self.data[0];
        for (self.data[1..]) |val| {
            if (val > max_val) max_val = val;
        }
        return max_val;
    }

    /// Calculate standard deviation
    pub fn stdDev(self: *const Column) f64 {
        if (self.data.len == 0) return 0.0;
        const mean_val = self.mean();
        var sum_squared_diff: f64 = 0.0;
        for (self.data) |val| {
            const diff = val - mean_val;
            sum_squared_diff += diff * diff;
        }
        return @sqrt(sum_squared_diff / @as(f64, @floatFromInt(self.data.len)));
    }
};

/// DataFrame - collection of named columns with same length
pub const DataFrame = struct {
    columns: std.ArrayList(Column),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) DataFrame {
        return DataFrame{
            .columns = std.ArrayList(Column){},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *DataFrame) void {
        for (self.columns.items) |*col| {
            col.deinit();
        }
        self.columns.deinit(self.allocator);
    }

    /// Add a column to the DataFrame
    pub fn addColumn(self: *DataFrame, name: []const u8, data: []f64) !void {
        // Validate: all columns must have same length
        if (self.columns.items.len > 0) {
            const first_len = self.columns.items[0].data.len;
            if (data.len != first_len) {
                std.debug.print("Error: Column '{s}' length {} doesn't match DataFrame length {}\n",
                    .{name, data.len, first_len});
                return error.ColumnLengthMismatch;
            }
        }

        const col = try Column.init(name, data, self.allocator);
        try self.columns.append(self.allocator, col);
    }

    /// Get column by name, returns null if not found
    pub fn getColumn(self: *const DataFrame, name: []const u8) ?*const Column {
        for (self.columns.items) |*col| {
            if (std.mem.eql(u8, col.name, name)) {
                return col;
            }
        }
        return null;
    }

    /// Create DataFrame from dict-like structure
    /// Expected format: {"col1": [1,2,3], "col2": [4,5,6]}
    pub fn fromDict(data: anytype, allocator: std.mem.Allocator) !DataFrame {
        var df = DataFrame.init(allocator);

        // Process each field in the struct
        inline for (std.meta.fields(@TypeOf(data))) |field| {
            const col_data = @field(data, field.name);

            // Convert to f64 array
            const f64_data = try allocator.alloc(f64, col_data.len);
            for (col_data, 0..) |val, i| {
                f64_data[i] = switch (@TypeOf(val)) {
                    i64, i32, i16, i8 => @floatFromInt(val),
                    f64, f32 => @floatCast(val),
                    else => @compileError("Unsupported column type"),
                };
            }

            try df.addColumn(field.name, f64_data);
        }

        return df;
    }

    /// Get number of rows
    pub fn len(self: *const DataFrame) usize {
        if (self.columns.items.len == 0) return 0;
        return self.columns.items[0].data.len;
    }

    /// Get number of columns
    pub fn columnCount(self: *const DataFrame) usize {
        return self.columns.items.len;
    }
};

/// Statistics for describe() operation
pub const DescribeStats = struct {
    count: usize,
    mean: f64,
    std: f64,
    min: f64,
    max: f64,
};

/// Compute summary statistics for a column
pub fn describe(col: *const Column) DescribeStats {
    return DescribeStats{
        .count = col.data.len,
        .mean = col.mean(),
        .std = col.stdDev(),
        .min = col.min(),
        .max = col.max(),
    };
}

// Tests
test "column creation and operations" {
    const allocator = std.testing.allocator;

    const data = try allocator.alloc(f64, 5);
    defer allocator.free(data);

    data[0] = 1.0;
    data[1] = 2.0;
    data[2] = 3.0;
    data[3] = 4.0;
    data[4] = 5.0;

    var col = try Column.init("A", data, allocator);
    defer col.deinit();

    try std.testing.expectEqual(@as(f64, 15.0), col.sum());
    try std.testing.expectEqual(@as(f64, 3.0), col.mean());
    try std.testing.expectEqual(@as(f64, 1.0), col.min());
    try std.testing.expectEqual(@as(f64, 5.0), col.max());
}

test "dataframe creation" {
    const allocator = std.testing.allocator;

    var df = DataFrame.init(allocator);
    defer df.deinit();

    const data_a = try allocator.alloc(f64, 3);
    data_a[0] = 1.0;
    data_a[1] = 2.0;
    data_a[2] = 3.0;

    const data_b = try allocator.alloc(f64, 3);
    data_b[0] = 4.0;
    data_b[1] = 5.0;
    data_b[2] = 6.0;

    try df.addColumn("A", data_a);
    try df.addColumn("B", data_b);

    try std.testing.expectEqual(@as(usize, 3), df.len());
    try std.testing.expectEqual(@as(usize, 2), df.columnCount());

    const col_a = df.getColumn("A");
    try std.testing.expect(col_a != null);
    try std.testing.expectEqual(@as(f64, 6.0), col_a.?.sum());
}

test "describe stats" {
    const allocator = std.testing.allocator;

    const data = try allocator.alloc(f64, 5);
    defer allocator.free(data);

    data[0] = 1.0;
    data[1] = 2.0;
    data[2] = 3.0;
    data[3] = 4.0;
    data[4] = 5.0;

    var col = try Column.init("test", data, allocator);
    defer col.deinit();

    const stats = describe(&col);

    try std.testing.expectEqual(@as(usize, 5), stats.count);
    try std.testing.expectEqual(@as(f64, 3.0), stats.mean);
    try std.testing.expectEqual(@as(f64, 1.0), stats.min);
    try std.testing.expectEqual(@as(f64, 5.0), stats.max);
}
