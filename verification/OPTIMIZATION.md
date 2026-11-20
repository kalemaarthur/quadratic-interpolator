# Fixed-point coefficient optimization

This add-on improves the coefficients without editing the existing SystemVerilog datapath.
It uses three-point quadratic interpolation on each of the 128 segments of the
function `f(x) = sin(2*x - pi/4)` over `0 <= x < 2`.

## Usage from the repository root

```bash
python3 verification/optimize_coefficients.py              # Preview, no changes
python3 verification/optimize_coefficients.py --apply      # Back up and update tables
python3 verification/verify_rtl.py                        # Resimulate and check
```

The `--apply` command updates the root and `rtl-model` copies of `a.mem`, `b.mem`,
`c.mem`, and regenerates the C++ coefficient table `c++-model/CoeffTable.hpp`.
It preserves the signed fixed-point formats a=s1.22, b=s3.16, c=s2.10,
and updates no SystemVerilog source files. The original files are backed up
once to `verification/backup-original-coefficients/`; do not commit that backup.

The updated coefficients can change the numerical outputs; this is intentional.
The existing verification script checks the bit-exact RTL implementation
against a fixed-point Python model and measures sine approximation error.

## Validation scope

A sampled error below the threshold does **not** prove the bound over all 2^24
possible input values. For portfolio claims, use language such as
"maximum observed error over 2,048 tests" unless exhaustive testing is done.

The legacy C++ reference model also uses Algorithmic C Datatypes and may
need dependency configuration to compile. Regenerating its coefficient table
keeps coefficient values in sync but does not alone establish C++/RTL equivalence.
