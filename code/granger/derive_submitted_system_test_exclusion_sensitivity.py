"""Recalculate the submitted Granger system-test FDR families after exclusion.

This is an offline transformation of archived aggregate P values. It makes no
network request and does not refit the VAR. The IHD- and DD-labelled columns
remain legacy labels for joint system tests across the other two equations.
"""

from __future__ import annotations

import argparse
import csv
from collections import Counter
from pathlib import Path


def bh_adjust(values: list[float]) -> list[float]:
    n = len(values)
    order = sorted(range(n), key=values.__getitem__)
    adjusted = [0.0] * n
    running = 1.0
    for rank_index in range(n - 1, -1, -1):
        original_index = order[rank_index]
        rank = rank_index + 1
        candidate = values[original_index] * n / rank
        running = min(running, candidate, 1.0)
        adjusted[original_index] = running
    return adjusted


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--submitted-table",
        type=Path,
        default=Path("derived_data/granger/Granger_submitted_vs_corrected.csv"),
    )
    parser.add_argument(
        "--exclusion-list",
        type=Path,
        default=Path("derived_data/granger/small_island_exclusion_list.csv"),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("derived_data/granger/submitted_system_test_small_island_exclusion.csv"),
    )
    parser.add_argument(
        "--counts-output",
        type=Path,
        default=Path("derived_data/granger/submitted_system_test_small_island_exclusion_counts.csv"),
    )
    args = parser.parse_args()

    with args.exclusion_list.open("r", encoding="utf-8-sig", newline="") as handle:
        exclusions = {row["location_name"] for row in csv.DictReader(handle)}
    if len(exclusions) != 45:
        raise RuntimeError(f"Expected 45 exclusions; found {len(exclusions)}")

    with args.submitted_table.open("r", encoding="utf-8-sig", newline="") as handle:
        all_rows = list(csv.DictReader(handle))
    if len(all_rows) != 204:
        raise RuntimeError(f"Expected 204 submitted rows; found {len(all_rows)}")
    retained = [row for row in all_rows if row["location_name"] not in exclusions]
    if len(retained) != 159:
        raise RuntimeError(f"Expected 159 retained rows; found {len(retained)}")
    flag_exclusions = {
        row["location_name"]
        for row in all_rows
        if row.get("small_island_excluded", "").strip().upper() == "TRUE"
    }
    if flag_exclusions != exclusions:
        raise RuntimeError("Exclusion list does not match the archived table flags")

    ihd_p = [float(row["submitted_IHD_to_DD_p"]) for row in retained]
    dd_p = [float(row["submitted_DD_to_IHD_p"]) for row in retained]
    ihd_q = bh_adjust(ihd_p)
    dd_q = bh_adjust(dd_p)

    output_rows: list[dict[str, object]] = []
    for row, q_ihd, q_dd in zip(retained, ihd_q, dd_q):
        ihd_sig = q_ihd < 0.05
        dd_sig = q_dd < 0.05
        if ihd_sig and dd_sig:
            category = "Both labelled families significant"
        elif ihd_sig:
            category = "IHD-labelled family only"
        elif dd_sig:
            category = "DD-labelled family only"
        else:
            category = "Neither labelled family significant"
        output_rows.append(
            {
                "location_name": row["location_name"],
                "submitted_IHD_label_raw_p": row["submitted_IHD_to_DD_p"],
                "submitted_IHD_label_BH_q_among_159": format(q_ihd, ".17g"),
                "submitted_DD_label_raw_p": row["submitted_DD_to_IHD_p"],
                "submitted_DD_label_BH_q_among_159": format(q_dd, ".17g"),
                "legacy_system_test_category": category,
            }
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = list(output_rows[0])
    with args.output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(output_rows)

    counts = Counter(row["legacy_system_test_category"] for row in output_rows)
    order = [
        "Both labelled families significant",
        "IHD-labelled family only",
        "DD-labelled family only",
        "Neither labelled family significant",
    ]
    with args.counts_output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["legacy_system_test_category", "n"])
        for category in order:
            writer.writerow([category, counts[category]])

    observed = [counts[category] for category in order]
    if observed != [71, 13, 60, 15]:
        raise RuntimeError(f"Unexpected category counts: {observed}")
    print(f"PASS: retained=159; counts={observed}")


if __name__ == "__main__":
    main()
