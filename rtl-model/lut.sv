`include "quadra.vh"

module lut
(
    input  x1_t x1,
    output a_t  a,
    output b_t  b,
    output c_t  c
);

    a_t a_rom [0:127];
    b_t b_rom [0:127];
    c_t c_rom [0:127];

    initial begin
        $readmemh("a.mem", a_rom);
        $readmemh("b.mem", b_rom);
        $readmemh("c.mem", c_rom);
    end

    always_comb begin
        a = a_rom[x1];
        b = b_rom[x1];
        c = c_rom[x1];
    end

endmodule