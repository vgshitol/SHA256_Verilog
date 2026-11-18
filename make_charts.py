#!/usr/bin/env python3
"""Regenerate the SHA256_Verilog README charts from verified data.

All numbers come from the repo itself or from re-running its own
testbench — nothing is invented:

* Cycle counts: measured Nov 18, 2026 by re-running the repo's own
  testbench (ProjectSubmissionFolder/v/MyDesign.v, the submitted
  modular design) under Icarus Verilog 12.0, using the testbench's
  own go->finish clock counter. Messages: 1, 3, 5, 6, 7, 8, 27 and 55
  characters; every digest matched Python's hashlib.sha256.
  The same runs reproduce the 2018 ModelSim transcript exactly
  (91 / 111 / 139 clocks for the 1-, 27- and 55-char TA messages).
  The report's "84 cycles for Hello" is plotted as a separate
  marker: it was NOT reproduced (91 measured for "Hello").
* Area breakdown: parsed from
  ProjectSubmissionFolder/result/cell_report_final.rpt
  (Synopsys Design Compiler, Nangate 45 nm, Dec 3, 2018).
  The parser below re-derives the groups from that file when it is
  supplied with --report; the embedded table is the result of that
  parse and reconciles exactly: 17,607 cells, 36,542.02 um^2.
* Hash rate: derived from the measured cycle counts at the
  synthesized 24 ns clock: 1 / (cycles * 24 ns).

Usage:
    python3 make_charts.py [--report path/to/cell_report_final.rpt]
                           [--out docs]

Outputs (into --out, default "docs"):
    graph1-cycles-vs-length.svg  measured cycles vs. message length
    graph2-area-breakdown.svg    synthesized cell area by cell group
    graph3-hash-rate.svg         hash rate vs. message length (24 ns clk)
    cycles-data.csv              the measured cycle counts + digests
"""
import argparse
import csv
import os
import re
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ---------------------------------------------------------------------------
# Measured data (see module docstring for provenance)
# ---------------------------------------------------------------------------
# (message length in chars, cycles go->finish, sha256 digest, message)
CYCLES = [
    (1, 91, "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb", "a"),
    (3, 91, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "abc"),
    (5, 91, "185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969", "Hello"),
    (6, 91, "69dc6c3210e25e62c5938ff4e841e81ce3c7d2cde583553478a77d7fcb389f30", "AAAAAA"),
    (7, 91, "ab530a13e45914982b79f9b7e3fba994cfd1f3fb22f71cea1afbf02b460c6d1d", "message"),
    (8, 92, "c34ab6abb7b2bb595bc25c3b388c872fd1d575819a8f55cc689510285e212385", "AAAAAAAA"),
    (27, 111, "3b6bd6f4ac0e5f0adcc69f8db8b060b3287d5d1248cfc83284d1e118d2ef04a4", "abcdefghijklmnopqrstuvwxyzA"),
    (55, 139, "d74ba075e4259c6c807c4101e66d281096cf9ff14ba01260dee741b1bdaef326", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ012"),
]
# The project report (and result.txt) claim 84 cycles for "Hello".
REPORT_CLAIM_HELLO_CYCLES = 84

CLOCK_NS = 24.0  # synthesized clock period from setup.tcl / timing reports

# Area groups, parsed from cell_report_final.rpt (see parse_cell_report).
# (group, cells, area um^2). Reconciles to 17,607 cells / 36,542.02 um^2.
AREA_GROUPS = [
    ("Flip-flops\n(DFF_X1 / DFF_X2 / SDFF_X1)", 3339, 15988.46),
    ("AOI / OAI complex gates", 8171, 12018.15),
    ("Simple gates\n(NAND / NOR / AND / OR /\nINV / BUF / XOR / XNOR / HA)", 6079, 5806.25),
    ("DesignWare 32-bit adders\n(18 x DW01_add)", 18, 2729.16),
]

BLUE = "#4285F4"
GREEN = "#34A853"
RED = "#EA4335"
YELLOW = "#FBBC05"
GREY = "#5F6368"


def parse_cell_report(path):
    """Re-derive the area groups from a Design Compiler cell report.

    Returns (groups, total_cells, total_area_um2). The report lists one
    cell per 2-3 lines; plain library cells match
    "<REF> NangateOpenCellLibrary...\\n <AREA>", while the 18 hierarchical
    DesignWare adders appear as "MyDesign_DW01_add_<n>  151.6200  BO, h".
    """
    text = open(path).read()
    by_ref = {}
    counts = {}
    for ref, area in re.findall(
            r"([A-Za-z0-9_]+)\s+NangateOpenCellLibrary[^\n]*\n\s+([\d.]+)", text):
        by_ref[ref] = by_ref.get(ref, 0.0) + float(area)
        counts[ref] = counts.get(ref, 0) + 1
    dw = re.findall(r"MyDesign_DW01_add_\d+\s+([\d.]+)", text)
    dw_cells, dw_area = len(dw), sum(float(a) for a in dw)

    def group(pred, label):
        cells = sum(c for r, c in counts.items() if pred(r))
        area = sum(a for r, a in by_ref.items() if pred(r))
        return (label, cells, round(area, 2))

    groups = [
        group(lambda r: r.startswith("DFF_") or r.startswith("SDFF"), "Flip-flops"),
        group(lambda r: r.startswith("AOI") or r.startswith("OAI"), "AOI / OAI complex gates"),
        group(lambda r: not (r.startswith("DFF_") or r.startswith("SDFF")
                             or r.startswith("AOI") or r.startswith("OAI")),
              "Simple gates"),
        ("DesignWare 32-bit adders", dw_cells, round(dw_area, 2)),
    ]
    total_area = float(re.search(r"Total\s+\d+\s+cells\s+([\d.]+)", text).group(1))
    total_cells = int(re.search(r"Total\s+(\d+)\s+cells", text).group(1))
    assert sum(g[1] for g in groups) == total_cells, "cell count mismatch"
    assert abs(sum(g[2] for g in groups) - total_area) < 0.01, "area mismatch"
    return groups, total_cells, total_area


def style(ax):
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#DADCE0")
    ax.spines["bottom"].set_color("#DADCE0")
    ax.tick_params(colors="#202124", labelsize=11)
    ax.yaxis.grid(True, color="#E8EAED", linewidth=0.8)
    ax.set_axisbelow(True)


def graph1_cycles(out):
    xs = [c[0] for c in CYCLES]
    ys = [c[1] for c in CYCLES]
    fig, ax = plt.subplots(figsize=(8.2, 4.4))
    ax.plot(xs, ys, "o-", color=BLUE, linewidth=2, markersize=8,
            label="Measured (Icarus re-run of the repo testbench)")
    ax.plot([5], [REPORT_CLAIM_HELLO_CYCLES], "x", color=RED, markersize=13,
            markeredgewidth=2.5, label="Report's claim for \"Hello\" (84) — not reproduced")
    for x, y in zip(xs, ys):
        ax.annotate(str(y), (x, y), textcoords="offset points",
                    xytext=(0, 10), ha="center", fontsize=11, color="#202124")
    ax.annotate("84", (5, REPORT_CLAIM_HELLO_CYCLES), textcoords="offset points",
                xytext=(14, -4), fontsize=11, color=RED)
    ax.set_xlabel("Message length (characters, one 512-bit block)", fontsize=12)
    ax.set_ylabel("Clocks, go → finish", fontsize=12)
    ax.set_title("SHA-256: cycles vs. message length (submitted modular design)",
                 fontsize=13, color="#202124")
    ax.set_xlim(0, 58)
    ax.set_ylim(70, 150)
    ax.legend(fontsize=10.5, loc="upper left", frameon=False)
    style(ax)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "graph1-cycles-vs-length.svg"), format="svg")
    plt.close(fig)


def graph2_area(out, groups):
    labels = [g[0] for g in groups]
    areas = [g[2] for g in groups]
    total = sum(areas)
    colors = [BLUE, GREEN, YELLOW, RED]
    fig, ax = plt.subplots(figsize=(8.2, 4.4))
    bars = ax.barh(labels, areas, color=colors, height=0.55)
    for bar, area in zip(bars, areas):
        ax.text(bar.get_width() + 400, bar.get_y() + bar.get_height() / 2,
                f"{area:,.2f} µm²  ({100 * area / total:.1f}%)",
                va="center", fontsize=11, color="#202124")
    ax.set_xlabel("Cell area (µm²)", fontsize=12)
    ax.set_title(f"Synthesized cell area by group — total {total:,.2f} µm², "
                 f"{sum(g[1] for g in groups):,} cells (Nangate 45 nm, slow corner)",
                 fontsize=12, color="#202124")
    ax.set_xlim(0, max(areas) * 1.45)
    ax.invert_yaxis()
    style(ax)
    ax.xaxis.grid(True, color="#E8EAED", linewidth=0.8)
    ax.yaxis.grid(False)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "graph2-area-breakdown.svg"), format="svg")
    plt.close(fig)


def graph3_hash_rate(out):
    xs = [c[0] for c in CYCLES]
    # one 512-bit block hashed per run: hash rate = 1 / (cycles * 24 ns)
    ys = [1e9 / (c[1] * CLOCK_NS) / 1000.0 for c in CYCLES]  # khash/s
    fig, ax = plt.subplots(figsize=(8.2, 4.4))
    ax.plot(xs, ys, "o-", color=GREEN, linewidth=2, markersize=8)
    for x, y in zip(xs, ys):
        ax.annotate(f"{y:.0f}", (x, y), textcoords="offset points",
                    xytext=(0, 10), ha="center", fontsize=11, color="#202124")
    ax.set_xlabel("Message length (characters, one 512-bit block)", fontsize=12)
    ax.set_ylabel("Hash rate (khash/s)", fontsize=12)
    ax.set_title(f"Hash rate vs. message length at the synthesized {CLOCK_NS:.0f} ns clock",
                 fontsize=13, color="#202124")
    ax.set_xlim(0, 58)
    ax.set_ylim(250, 520)
    style(ax)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "graph3-hash-rate.svg"), format="svg")
    plt.close(fig)


def write_cycles_csv(out):
    with open(os.path.join(out, "cycles-data.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["message_length_chars", "message", "cycles_go_to_finish",
                    "sha256_digest", "digest_matches_hashlib"])
        for length, cycles, digest, msg in CYCLES:
            w.writerow([length, msg, cycles, digest, "yes"])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", default=None,
                    help="cell_report_final.rpt to re-parse (default: use embedded table)")
    ap.add_argument("--out", default="docs")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    groups = AREA_GROUPS
    if args.report:
        groups, total_cells, total_area = parse_cell_report(args.report)
        print(f"parsed {args.report}: {total_cells} cells, {total_area} um^2")
    graph1_cycles(args.out)
    graph2_area(args.out, groups)
    graph3_hash_rate(args.out)
    write_cycles_csv(args.out)
    print("wrote graph1-cycles-vs-length.svg, graph2-area-breakdown.svg, "
          "graph3-hash-rate.svg, cycles-data.csv into", args.out)


if __name__ == "__main__":
    sys.exit(main())
