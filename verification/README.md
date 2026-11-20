# Automated RTL verification add-on

Copy the `verification/` directory into the root of your existing
`quadratic-interolator` GitHub clone; do **not** replace the existing
`rtl-model/` or `c++-model/` files.

From your Ubuntu terminal in the repository root:

```bash
python3 verification/verify_rtl.py
```

The script compiles the RTL with Icarus Verilog, drives 2048 deterministic
input patterns (edge cases, LUT boundaries, and random values), and captures
all valid output samples. It checks RTL output words against a bit-accurate
Python transcription of the current SystemVerilog datapath and reports
absolute error against `sin(2*x - pi/4)`.

Generated reports:
- `verification/results.csv`: individual vector results.
- `verification/verification_report.md`: summary suitable for review.

Important: A **PASS** for RTL-versus-reference means your RTL implements its
current fixed-point datapath consistently; it does **not** guarantee the
function-approximation error meets the original C++ project's tolerance.

Requirements: Python 3, `iverilog`, and `vvp` (from Icarus Verilog).
