`include "quadra.vh"

`timescale 1ps/1ps
`define T_CLK 1000

module quadra_tb;

    x_t  x;
    dv_t x_dv;

    y_t  y;
    dv_t y_dv;

    ck_t clk;
    rs_t rst_b;

    quadra_top u0 (
        .clk   (clk),
        .rst_b (rst_b),
        .x     (x),
        .x_dv  (x_dv),
        .y     (y),
        .y_dv  (y_dv)
    );

    // clock
    initial begin
        clk = 1'b0;
        forever #(`T_CLK/2) clk = ~clk;
    end

   
initial begin
    rst_b = 1'b0;
    repeat (3) @(negedge clk);
    rst_b = 1'b1;
end


    // waveform + monitor
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, quadra_tb);

        $display("time   x        x1   x2      a         b         c       sq       y_dv  y");
        $monitor("%0t  %06h  %02h  %05h  %06h  %05h  %03h  %06h   %0b   %07h",
                 $time,
                 x,
                 u0.u_quadra.x1,
                 u0.u_quadra.x2,
                 u0.u_quadra.a,
                 u0.u_quadra.b,
                 u0.u_quadra.c,
                 u0.u_quadra.sq,
                 y_dv,
                 y);
    end

    
initial begin
    $display("Started quadra_tb ...");

    x    = '0;
    x_dv = 1'b0;

    repeat (5) @(negedge clk);

    x = 24'h000000; x_dv = 1'b1; @(negedge clk);
    x = 24'h400000; x_dv = 1'b1; @(negedge clk);
    x = 24'h7fffff; x_dv = 1'b1; @(negedge clk);
    x = 24'h800000; x_dv = 1'b1; @(negedge clk);
    x = 24'hc00000; x_dv = 1'b1; @(negedge clk);
    x = 24'hffffff; x_dv = 1'b1; @(negedge clk);

    x    = '0;
    x_dv = 1'b0;

    repeat (10) @(negedge clk);

    $display("Simulation finished.");
    $finish;
end


endmodule
