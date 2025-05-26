pub fn Mat(comptime R: comptime_int, comptime C: comptime_int) type {
    return struct {
        pub const Rows = R;
        pub const Cols = C;

        comptime rows: comptime_int = R,
        comptime cols: comptime_int = C,

        mat: [R][C]f32
    };
}

fn matrixRows(comptime MatrixType: type) comptime_int {
    const matrix_type_info = @typeInfo(MatrixType);
    return matrix_type_info.@"struct".fields.len;
}

fn matrixCols(comptime MatrixType: type) comptime_int {
    const matrix_type_info = @typeInfo(MatrixType);
    const fields = matrix_type_info.@"struct".fields;

    return @typeInfo(fields[0].type).@"struct".fields.len;
}

pub inline fn new(args: anytype) Mat(matrixRows(@TypeOf(args)), matrixCols(@TypeOf(args))) {
    return .{ .mat = args, };
}

pub fn mul(a: anytype, b: anytype) Mat(a.rows, b.cols) {
    @branchHint(.likely);
    @setRuntimeSafety(false);

    // todo: would be nice to simd or becnh this idk smth would be nice
    var out: Mat(a.rows, b.cols) = .{ .mat = undefined };
    inline for (0..b.cols) |i| {
        inline for (0..a.rows) |j| {
            var sum: f32 = 0.0;
            inline for (0..a.cols) |k| {
                sum += a.mat[k][j] * b.mat[i][k];
            }
            out.mat[i][j] = sum;
        }
    }
    return out;
}
