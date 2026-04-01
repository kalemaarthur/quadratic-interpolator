`include "quadra.vh"

module quadra
(
    input  x_t x,
    output y_t y
);

    x1_t x1;
    x2_t x2;

    a_t a;
    b_t b;
    c_t c;

    sq_t sq;

    x2s_t x2_s;
    sqs_t sq_s;

    t1_full_t t1_full;
    t2_full_t t2_full;

    t0_t t0;
    t1_t t1;
    t2_t t2;

    logic signed [S_W:0] sum_ext;
    sum_t sum_q27;

    // ------------------------------------------------------------------------
    // Split input
    // ------------------------------------------------------------------------
    always_comb begin
        x1 = x[X_W-1:X2_W];   // x[23:17]
        x2 = x[X2_W-1:0];     // x[16:0]
    end

    // ------------------------------------------------------------------------
    // LUT and square
    // ------------------------------------------------------------------------
    lut    u_lut (.x1(x1), .a(a), .b(b), .c(c));
    square u_sq  (.x2(x2), .sq(sq));

    // ------------------------------------------------------------------------
    // Unsigned positive local values -> signed for multiplies
    // ------------------------------------------------------------------------
    always_comb begin
        x2_s = $signed({1'b0, x2});
        sq_s = $signed({1'b0, sq});
    end

    // ------------------------------------------------------------------------
    // Full products
    // ------------------------------------------------------------------------
    always_comb begin
        t1_full = b * x2_s;   // full Q39
        t2_full = c * sq_s;   // full Q34 (because sq is already Q24)
    end

    // ------------------------------------------------------------------------
    // Align to Q27 like C++ internal t0/t1/t2
    // ------------------------------------------------------------------------
    always_comb begin
        t0 = $signed(a) <<< SHIFT_A;   // Q22 -> Q27
        t1 = t1_full >>> SHIFT_T1;     // Q39 -> Q27
        t2 = t2_full >>> SHIFT_T2;     // Q34 -> Q27
    end

    // ------------------------------------------------------------------------
    // Sum in Q27
    // ------------------------------------------------------------------------
    always_comb begin
        sum_ext = t0 + t1 + t2;
        sum_q27 = sum_ext[S_W-1:0];
    end

    // ------------------------------------------------------------------------
    // Final output rounding: Q27 -> Q23
    // Implement round-to-nearest-even to match y_rnd_t (AC_RND_CONV)
    // ------------------------------------------------------------------------
    function automatic y_t round_q27_to_q23(input sum_t val);
        logic signed [S_W-1:0] base_ext;
        logic guard_bit;
        logic sticky_bit;
        logic lsb_bit;
        logic round_up;
        logic signed [S_W-1:0] rounded_ext;
        begin
            base_ext   = val >>> SHIFT_Y;
            guard_bit  = val[SHIFT_Y-1];
            sticky_bit = |val[SHIFT_Y-2:0];
            lsb_bit    = base_ext[0];

            // convergent rounding (round to nearest even)
            round_up   = guard_bit && (sticky_bit || lsb_bit);

            rounded_ext = base_ext + (round_up ? 1 : 0);
            round_q27_to_q23 = rounded_ext[Y_W-1:0];
        end
    endfunction

    always_comb begin
        y = round_q27_to_q23(sum_q27);
    end

endmodule