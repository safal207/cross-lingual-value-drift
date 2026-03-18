#!/usr/bin/env python3
"""Analyse cross-lingual value-drift experiment results.

Reads a results CSV and prints summary tables to stdout and summary.txt.
Uses only stdlib (csv, sys, math).
"""

import csv
import math
import sys
from collections import defaultdict


# ── Wilson confidence interval ──────────────────────────────────────────

def wilson_ci(successes, total, z=1.96):
    if total == 0:
        return (0.0, 0.0)
    p = successes / total
    denom = 1 + z**2 / total
    center = (p + z**2 / (2 * total)) / denom
    spread = z * (p * (1 - p) / total + z**2 / (4 * total**2)) ** 0.5 / denom
    return (max(0.0, center - spread), min(1.0, center + spread))


# ── helpers ─────────────────────────────────────────────────────────────

def fmt_rate(successes, total):
    """Format as 'rate (n/N) [lo, hi]'."""
    if total == 0:
        return "  —  "
    rate = successes / total
    lo, hi = wilson_ci(successes, total)
    return f"{rate:.0%} ({successes}/{total}) [{lo:.2f},{hi:.2f}]"


def print_and_write(line, fh):
    print(line)
    fh.write(line + "\n")


def table(rows, headers, fh):
    """Print a fixed-width table. rows is list of lists (strings)."""
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            col_widths[i] = max(col_widths[i], len(cell))

    def fmt_row(cells):
        return " | ".join(c.ljust(col_widths[i]) for i, c in enumerate(cells))

    sep = "-+-".join("-" * w for w in col_widths)
    print_and_write(fmt_row(headers), fh)
    print_and_write(sep, fh)
    for row in rows:
        print_and_write(fmt_row(row), fh)
    print_and_write("", fh)


# ── main ────────────────────────────────────────────────────────────────

def load_csv(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def analyse(rows, out_path="summary.txt"):
    languages = sorted({r["language"] for r in rows})
    constraints = sorted({r["constraint"] for r in rows})

    with open(out_path, "w") as fh:
        # ── a) Compliance by Language × Constraint ──────────────────────
        print_and_write("=" * 72, fh)
        print_and_write("  COMPLIANCE BY LANGUAGE × CONSTRAINT", fh)
        print_and_write("=" * 72, fh)

        headers = ["constraint"] + [l.upper() for l in languages] + ["Overall"]
        tbl_rows = []
        for con in constraints:
            cells = [con]
            overall_s, overall_n = 0, 0
            for lang in languages:
                matching = [r for r in rows
                            if r["constraint"] == con
                            and r["language"] == lang
                            and r["compliance"] != ""]
                s = sum(int(r["compliance"]) for r in matching)
                n = len(matching)
                cells.append(fmt_rate(s, n))
                overall_s += s
                overall_n += n
            cells.append(fmt_rate(overall_s, overall_n))
            tbl_rows.append(cells)
        table(tbl_rows, headers, fh)

        # ── b) Fidelity by Language × Constraint ────────────────────────
        print_and_write("=" * 72, fh)
        print_and_write("  FIDELITY BY LANGUAGE × CONSTRAINT", fh)
        print_and_write("=" * 72, fh)

        tbl_rows = []
        for con in constraints:
            cells = [con]
            overall_s, overall_n = 0, 0
            for lang in languages:
                matching = [r for r in rows
                            if r["constraint"] == con
                            and r["language"] == lang]
                s = sum(int(r["fidelity"]) for r in matching)
                n = len(matching)
                cells.append(fmt_rate(s, n))
                overall_s += s
                overall_n += n
            cells.append(fmt_rate(overall_s, overall_n))
            tbl_rows.append(cells)
        table(tbl_rows, headers, fh)

        # ── c) Delegation Language Switching ─────────────────────────────
        print_and_write("=" * 72, fh)
        print_and_write("  DELEGATION LANGUAGE SWITCHING", fh)
        print_and_write("=" * 72, fh)

        deleg_langs = sorted({r["delegation_lang"] for r in rows})
        d_headers = ["input \\ deleg"] + [d.upper() for d in deleg_langs]
        d_rows = []
        for lang in languages:
            lang_rows = [r for r in rows if r["language"] == lang]
            total = len(lang_rows)
            cells = [lang.upper()]
            for dl in deleg_langs:
                cnt = sum(1 for r in lang_rows if r["delegation_lang"] == dl)
                pct = (cnt / total * 100) if total else 0
                cells.append(f"{cnt} ({pct:.0f}%)")
            d_rows.append(cells)
        table(d_rows, d_headers, fh)

        # ── d) Parse Failure Rates ───────────────────────────────────────
        print_and_write("=" * 72, fh)
        print_and_write("  PARSE FAILURE RATES BY LANGUAGE", fh)
        print_and_write("=" * 72, fh)

        p_headers = ["language", "failures", "total", "failure_rate"]
        p_rows = []
        for lang in languages:
            matching = [r for r in rows if r["language"] == lang]
            n = len(matching)
            failures = sum(1 for r in matching if r["parse_success"] == "0")
            rate = (failures / n * 100) if n else 0
            p_rows.append([lang.upper(), str(failures), str(n), f"{rate:.1f}%"])
        table(p_rows, p_headers, fh)

        # ── e) Overall Statistics ────────────────────────────────────────
        print_and_write("=" * 72, fh)
        print_and_write("  OVERALL STATISTICS", fh)
        print_and_write("=" * 72, fh)

        total_trials = len(rows)
        total_cost = sum(float(r["cost_usd"]) for r in rows)
        scoreable = sum(1 for r in rows if r["compliance"] != "")
        scoreable_rate = (scoreable / total_trials * 100) if total_trials else 0

        print_and_write(f"Total trials:   {total_trials}", fh)
        print_and_write(f"Total cost:     ${total_cost:.4f}", fh)
        print_and_write(f"Scoreable:      {scoreable}/{total_trials} ({scoreable_rate:.1f}%)", fh)
        print_and_write("", fh)

    return out_path


def main():
    csv_path = sys.argv[1] if len(sys.argv) > 1 else "results.csv"
    rows = load_csv(csv_path)
    out = analyse(rows)
    print(f"[written to {out}]")


if __name__ == "__main__":
    main()
