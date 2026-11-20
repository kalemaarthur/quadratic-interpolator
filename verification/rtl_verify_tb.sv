`include "quadra.vh"
`timescale 1ps/1ps

module rtl_verify_tb;
    localparam integer TEST_COUNT = 2048;

    x_t vectors [0:TEST_COUNT-1];
    x_t x = '0;
    dv_t x_dv = 1'b0;
    y_t y;
    dv_t y_dv;
    ck_t clk = 1'b0;
    rs_t rst_b = 1'b0;

    integer n_results = 0;

    quadra_top dut (
        .clk(clk), .rst_b(rst_b),
        .x(x), .x_dv(x_dv), .y(y), .y_dv(y_dv)
    );

    always #500 clk = ~clk;

    initial begin : stimulus
        integer i;
        $readmemh("vectors.mem", vectors);

        // Reset is asserted from time zero, then released away from a rising edge.
        repeat (4) @(negedge clk);
        rst_b = 1'b1;

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            @(negedge clk);
            x = vectors[i];
            x_dv = 1'b1;
        end

        @(negedge clk);
        x = '0;
        x_dv = 1'b0;

        // Allow the three register stages to drain.
        repeat (6) @(negedge clk);
        if (n_results != TEST_COUNT)
            $fatal(1, "Expected %0d valid results; got %0d", TEST_COUNT, n_results);
        $finish;
    end

    // Sampling after nonblocking assignments means the registered output
    // is stable; each RESULT corresponds to the next submitted input.
    always @(posedge clk) begin
        #1;
        if (y_dv) begin
            $display("RESULT %07h", y);
            n_results = n_results + 1;
        end
    end
endmodule
