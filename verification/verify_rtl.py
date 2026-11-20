#!/usr/bin/env python3
"""Run 2048 RTL vectors, compare to a bit-exact Python model, report sine error."""

from __future__ import annotations

import csv
import math
import random
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HERE = Path(__file__).resolve().parent
RTL = ROOT / "rtl-model"
COUNT = 2048
ORIGINAL_ERROR_TOLERANCE = 2.15e-6


def signed(word: int, bits: int) -> int:
    word &= (1 << bits) - 1
    return word - (1 << bits) if word & (1 << (bits - 1)) else word


def load_rom(name: str, bits: int) -> list[int]:
    return [signed(int(line.strip(), 16), bits)
            for line in (ROOT / name).read_text().splitlines()
            if line.strip()]


def model(raw_x: int, a: list[int], b: list[int], c: list[int]) -> int:
    """Match quadra.sv and quadra.vh, including truncation and RNE rounding."""
    index = raw_x >> 17
    x2 = raw_x & 0x1FFFF
    sq = (x2 * x2) >> 22  # Q46 -> Q24
    t0 = a[index] << 5
    t1 = (b[index] * x2) >> 12
    t2 = (c[index] * sq) >> 7
    sum_q27 = signed(t0 + t1 + t2, 29)
    base = sum_q27 >> 4
    guard = (sum_q27 >> 3) & 1
    sticky = bool(sum_q27 & 0b111)
    increment = bool(guard and (sticky or (base & 1)))
    return (base + int(increment)) & ((1 << 25) - 1)


def vectors() -> list[int]:
    # Endpoints, mathematical midpoints, and both sides of every LUT boundary.
    values = [0x000000, 0x400000, 0x7FFFFF,
              0x800000, 0xC00000, 0xFFFFFF]
    for k in range(128):
        start = k << 17
        for x in (start - 1, start, start + 1, start + 0x1FFFF):
            if 0 <= x <= 0xFFFFFF:
                values.append(x)
    rng = random.Random(20261120)
    seen = set()
    ordered = []
    for x in values:
        if x not in seen:
            ordered.append(x)
            seen.add(x)
    while len(ordered) < COUNT:
        x = rng.randrange(1 << 24)
        if x not in seen:
            seen.add(x)
            ordered.append(x)
    return ordered[:COUNT]


def main() -> int:
    if shutil.which("iverilog") is None or shutil.which("vvp") is None:
        print("ERROR: Icarus Verilog (iverilog and vvp) is not installed.", file=sys.stderr)
        return 2

    a, b, c = (load_rom("a.mem", 23), load_rom("b.mem", 19), load_rom("c.mem", 12))
    if any(len(rom) != 128 for rom in (a, b, c)):
        print("ERROR: Coefficient ROMs must each contain 128 words.", file=sys.stderr)
        return 2

    inputs = vectors()
    vectors_file = ROOT / "vectors.mem"
    sim_file = ROOT / "verify_sim.vvp"

    try:
        vectors_file.write_text("".join(f"{x:06x}\n" for x in inputs))
        command = [
            "iverilog", "-g2012", "-s", "rtl_verify_tb",
            "-I", str(RTL), "-o", str(sim_file),
            str(HERE / "rtl_verify_tb.sv"),
            str(RTL / "quadra_top.sv"),
            str(RTL / "quadra.sv"),
            str(RTL / "lut.sv"),
            str(RTL / "square.sv"),
        ]
        build = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
        if build.returncode:
            print("RTL compile failed:\n" + build.stdout + build.stderr, file=sys.stderr)
            return 2

        run = subprocess.run(["vvp", str(sim_file)], cwd=ROOT,
                             text=True, capture_output=True)
        if run.returncode:
            print("RTL simulation failed:\n" + run.stdout + run.stderr, file=sys.stderr)
            return 2
        outputs = [int(m.group(1), 16) for line in run.stdout.splitlines()
                   if (m := re.fullmatch(r"RESULT\s+([0-9a-fA-F]+)", line.strip()))]
        if len(outputs) != COUNT:
            print(f"ERROR: Expected {COUNT} outputs, got {len(outputs)}", file=sys.stderr)
            print(run.stdout[-1000:], file=sys.stderr)
            return 2

        failures = []
        worst_error = (-1.0, None)
        over_tol = 0
        rows = []
        for x, actual in zip(inputs, outputs):
            expected = model(x, a, b, c)
            if actual != expected:
                failures.append((x, actual, expected))
            x_float = x / (1 << 23)
            rtl_float = signed(actual, 25) / (1 << 23)
            sine = math.sin(2 * x_float - math.pi / 4)
            error = abs(rtl_float - sine)
            over_tol += error >= ORIGINAL_ERROR_TOLERANCE
            if error > worst_error[0]:
                worst_error = (error, x)
            rows.append((f"{x:06x}", f"{actual:07x}",
                         f"{rtl_float:.12f}", f"{sine:.12f}", f"{error:.12g}"))

        with (HERE / "results.csv").open("w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["input_hex", "rtl_output_hex", "rtl_float",
                             "sine_reference", "absolute_error"])
            writer.writerows(rows)
        report = (
            "# RTL verification report\n\n"
            f"- Test vectors: **{COUNT}** (six fixed examples, LUT boundaries, seeded random inputs)\n"
            f"- Bit-exact Python model mismatches: **{len(failures)}**\n"
            f"- Maximum sampled sine error: **{worst_error[0]:.9g}** at input `0x{worst_error[1]:06x}`\n"
            f"- Samples meeting original `2.15e-6` tolerance: **{COUNT - over_tol}/{COUNT}**\n\n"
            "Note: This is sampled functional verification, not an exhaustive proof of accuracy.\n"
            "The arithmetic model is based on the current RTL coefficient widths and rounding.\n"
        )
        (HERE / "verification_report.md").write_text(report)

        print(f"Vectors run: {COUNT}")
        print(f"RTL vs bit-exact model: {'PASS' if not failures else 'FAIL'} ({len(failures)} mismatches)")
        for x, actual, expected in failures[:5]:
            print(f"  mismatch input=0x{x:06x} RTL=0x{actual:07x} model=0x{expected:07x}")
        print(f"Maximum sampled |RTL - sin(2*x-pi/4)|: {worst_error[0]:.9g}")
        print(f"At input: 0x{worst_error[1]:06x}")
        print(f"Original tolerance 2.15e-6 exceeded at {over_tol}/{COUNT} samples")
        print("Reports written to verification/results.csv and verification/verification_report.md")
        return 1 if failures or over_tol else 0
    finally:
        vectors_file.unlink(missing_ok=True)
        sim_file.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
