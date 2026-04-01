`include "quadra.vh"

module square
(
    input  x2_t x2,
    output sq_t sq
);

    logic [(2*X2_W)-1:0] sq_full;

    always_comb begin
        sq_full = x2 * x2;          // raw Q46
        sq      = sq_full >> SHIFT_SQ; // truncate to Q24 to match C++
    end

endmodule