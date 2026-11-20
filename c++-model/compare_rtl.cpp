
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <cstdint>
#include "Quadra.hpp"

int main() {
    std::ifstream file("verification/results.csv");

    if (!file) {
        std::cerr << "ERROR: Run make verify first.\n";
        return 2;
    }

    std::string line;
    std::getline(file, line); // Skip CSV header

    int total = 0;
    int mismatches = 0;

    while (std::getline(file, line)) {
        if (line.empty()) continue;

        std::stringstream ss(line);
        std::string input_hex, rtl_hex;

        std::getline(ss, input_hex, ',');
        std::getline(ss, rtl_hex, ',');

        uint32_t raw_x = std::stoul(input_hex, nullptr, 16);
        uint32_t rtl_y = std::stoul(rtl_hex, nullptr, 16);

        double x = double(raw_x) / double(1U << 23);
        x_fxd_t fixed_x = x;
        y_fxd_t fixed_y = approxFixed(fixed_x);

        uint32_t cpp_y = fixed_y.slc<Y_W>(0).to_uint() & 0x01FFFFFFu;

        ++total;

        if (cpp_y != rtl_y) {
            ++mismatches;

            if (mismatches <= 8) {
                std::cout << std::hex
                          << "Mismatch: x=0x" << raw_x
                          << " C++=0x" << cpp_y
                          << " RTL=0x" << rtl_y
                          << std::dec << "\n";
            }
        }
    }

    std::cout << "\nC++ vs RTL Comparison\n";
    std::cout << "Vectors compared: " << total << "\n";
    std::cout << "Mismatches: " << mismatches << "\n";

    if (total == 0) {
        std::cout << "Result: FAIL (no vectors)\n";
        return 2;
    }

    std::cout << "Result: "
              << (mismatches == 0 ? "PASS" : "FAIL")
              << "\n";

    return mismatches == 0 ? 0 : 1;
}
