`ifndef QUADRA_VH
`define QUADRA_VH

typedef logic ck_t; // clock
typedef logic rs_t; // reset
typedef logic dv_t; // data valid

// --------------------------------------------------------------------------------
// I/O precision
// --------------------------------------------------------------------------------

// x in [0,2) -> u1.23
localparam int X_I = 1;
localparam int X_F = 23;
localparam int X_W = X_I + X_F;   // 24

typedef logic [X_W-1:0] x_t;

// y in [-2,2) -> s2.23
localparam int Y_I = 2;
localparam int Y_F = 23;
localparam int Y_W = Y_I + Y_F;   // 25

typedef logic signed [Y_W-1:0] y_t;

// --------------------------------------------------------------------------------
// Segment split
// --------------------------------------------------------------------------------

localparam int X1_W = 7;   // x[23:17]
localparam int X2_W = 17;  // x[16:0]

typedef logic [X1_W-1:0] x1_t;
typedef logic [X2_W-1:0] x2_t;

// x2 is effectively u(-6).23 in the C++ model
localparam int X2_FRAC = 23;

// --------------------------------------------------------------------------------
// Optimized coefficient widths
// Must match Quadra.hpp
// --------------------------------------------------------------------------------

// a = s1.22
localparam int A_I = 1;
localparam int A_F = 22;
localparam int A_W = A_I + A_F;   // 23
typedef logic signed [A_W-1:0] a_t;

// b = s3.16
// IMPORTANT: use 3 integer bits to safely cover b > 2.0 in CoeffTable
localparam int B_I = 3;
localparam int B_F = 16;
localparam int B_W = B_I + B_F;   // 19
typedef logic signed [B_W-1:0] b_t;

// c = s2.10
localparam int C_I = 2;
localparam int C_F = 10;
localparam int C_W = C_I + C_F;   // 12
typedef logic signed [C_W-1:0] c_t;

// --------------------------------------------------------------------------------
// Internal precision to match Quadra.hpp
// --------------------------------------------------------------------------------

// s_fxd_t uses 4 extra guard fractional bits:
// S_F = Y_F + 4 = 27
localparam int R_F = 4;
localparam int S_I = Y_I;
localparam int S_F = Y_F + R_F;   // 27
localparam int S_W = S_I + S_F;   // 29

typedef logic signed [S_W-1:0] sum_t;

// sq_fxd_t in C++ uses SQ_F = 24 when FULL_PRECISION is not defined
localparam int SQ_F = 24;
localparam int SQ_W = SQ_F;       // SQ_I = 0, so width = 24

typedef logic [SQ_W-1:0] sq_t;

// Signed helper types for multiplication
typedef logic signed [X2_W:0] x2s_t;   // prepend 0 sign bit
typedef logic signed [SQ_W:0] sqs_t;   // prepend 0 sign bit

// Full raw product widths
localparam int T1_FULL_W = B_W + X2_W + 1; // b * signed(x2)
localparam int T2_FULL_W = C_W + SQ_W + 1; // c * signed(sq)

typedef logic signed [T1_FULL_W-1:0] t1_full_t;
typedef logic signed [T2_FULL_W-1:0] t2_full_t;

// Aligned intermediate terms in Q27
typedef logic signed [S_W-1:0] t0_t;
typedef logic signed [S_W-1:0] t1_t;
typedef logic signed [S_W-1:0] t2_t;

// --------------------------------------------------------------------------------
// Binary-point alignment shifts
// --------------------------------------------------------------------------------

// a: Q22 -> Q27
localparam int SHIFT_A = S_F - A_F;  // 5

// b*x2: Q(16+23)=Q39 -> Q27
localparam int SHIFT_T1 = (B_F + X2_FRAC) - S_F;  // 12

// x2^2 full raw is Q46, but sq_fxd_t truncates it to Q24 first.
// then c*sq is Q(10+24)=Q34 -> Q27
localparam int SHIFT_SQ = (2*X2_FRAC) - SQ_F;     // 22
localparam int SHIFT_T2 = (C_F + SQ_F) - S_F;     // 7

// final output: Q27 -> Q23
localparam int SHIFT_Y = S_F - Y_F;               // 4

`endif