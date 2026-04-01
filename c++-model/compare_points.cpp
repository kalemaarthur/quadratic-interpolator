#include <iostream>
#include <iomanip>
#include <cstdint>
#include "Quadra.hpp"

int main() {
    uint32_t tests[] = {
        0x000000,
        0x400000,
        0x7fffff,
        0x800000,
        0xc00000,
        0xffffff
    };

    std::cout << "m        x_dbl                  y_dbl\n";

    for (uint32_t m : tests) {
        double x_dbl = double(m) / double(0x00800000);
        x_fxd_t x_fxd = x_dbl;
        y_fxd_t y_fxd = approxFixed(x_fxd);

        std::cout << std::hex << std::setw(6) << std::setfill('0') << m
                  << "  "
                  << std::dec << std::fixed << std::setprecision(12)
                  << x_dbl
                  << "  "
                  << y_fxd.to_double()
                  << "\n";
    }

    return 0;
}
