`include "quadra.vh"

module quadra_top
(
    input  ck_t clk,
    input  rs_t rst_b,
    input  x_t  x,
    input  dv_t x_dv,
    output y_t  y,
    output dv_t y_dv
);

    // valid pipeline
    dv_t dv_p0, dv_p1, dv_p2;

    // datapath output pipeline
    y_t y_comb;
    y_t y_p0, y_p1, y_p2;

    quadra u_quadra (
        .x (x),
        .y (y_comb)
    );

    always_ff @(posedge clk) begin
        if (!rst_b) begin
            dv_p0 <= '0;
            dv_p1 <= '0;
            dv_p2 <= '0;

            y_p0  <= '0;
            y_p1  <= '0;
            y_p2  <= '0;
        end
        else begin
            dv_p0 <= x_dv;
            dv_p1 <= dv_p0;
            dv_p2 <= dv_p1;

            y_p0  <= y_comb;
            y_p1  <= y_p0;
            y_p2  <= y_p1;
        end
    end

    assign y    = y_p2;
    assign y_dv = dv_p2;

endmodule