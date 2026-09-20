#!/usr/bin/env python3
"""Reconstruct sensitivity candidate sets from saved aggregate MR results.

This script intentionally uses the fixed planned family size requested for the
audit (m = 11,988 per outcome). Scheduled candidates without saved estimates are therefore
equivalent to p = 1 for Benjamini-Hochberg adjustment.

Outputs are descriptive recovery analyses. They do not replace a rerun from
harmonised SNP-level data.
"""

from __future__ import annotations

import csv
import hashlib
import math
import re
import argparse
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable


M_TOTAL = 11_988
IVW = "Inverse variance weighted"
HERE = Path(__file__).resolve().parent
PACKAGE_ROOT = HERE.parents[2]
DEFAULT_MR_ROOT = PACKAGE_ROOT / "source_data" / "mr"
DEFAULT_OLD50_MAP = (
    PACKAGE_ROOT / "derived_data" / "mr" / "alternative_sets" / "old50_id_map.csv"
)


def read_csv(path: Path, delimiter: str = ",") -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", errors="replace", newline="") as handle:
        return list(csv.DictReader(handle, delimiter=delimiter))


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def fmt(value: float | int | str | None) -> str:
    if value is None:
        return ""
    if isinstance(value, float):
        return format(value, ".17g")
    return str(value)


def bh_fixed_m(rows: list[dict[str, str]], m_total: int) -> dict[str, float]:
    """BH q-values with unobserved planned tests represented as p=1."""
    if len(rows) > m_total:
        raise ValueError(f"Observed tests ({len(rows)}) exceed fixed family size ({m_total}).")
    ordered = sorted((float(row["pval"]), row["id.exposure"]) for row in rows)
    q_values: dict[str, float] = {}
    running = 1.0
    for rank in range(len(ordered), 0, -1):
        p_value, exposure_id = ordered[rank - 1]
        running = min(running, p_value * m_total / rank, 1.0)
        q_values[exposure_id] = running
    return q_values


def trait_name(row: dict[str, str]) -> str:
    return re.sub(r" \|\| id:.*$", "", row["exposure"])


def classify_downstream_marker(trait: str) -> str:
    """Conservative, auditable lexical rule for descriptive set C.

    The rule removes obvious medication/treatment variables, diagnosis or
    procedure codes, family/self-reported disease codes, and broad current
    health-status indicators. Psychological symptom traits are deliberately
    retained because set C is a narrow code/marker sensitivity analysis.
    """
    text = trait.lower()

    medication_patterns = (
        "medication",
        "prescription",
        "treatment/medication",
        "number of treatments/medications",
        "drug code",
    )
    if any(pattern in text for pattern in medication_patterns):
        return "Medication or treatment marker"

    procedure_patterns = (
        "operative procedure",
        "opcs",
        "surgical procedure",
        "hospital admission",
        "methods of admission",
        "sources of admission",
    )
    if any(pattern in text for pattern in procedure_patterns):
        return "Procedure or hospital-use marker"

    diagnosis_patterns = (
        "diagnoses -",
        "diagnosed by doctor",
        "icd10",
        "icd-10",
        "non-cancer illness code",
        "self-reported non-cancer illness",
        "illnesses of father",
        "illnesses of mother",
        "illnesses of siblings",
        "major depression",
    )
    if any(pattern in text for pattern in diagnosis_patterns):
        return "Diagnosis, disease-history, or outcome-proxy marker"

    status_patterns = (
        "long-standing illness",
        "disability or infirmity",
        "number of self-reported",
        "other serious medical condition",
        "overall health rating",
        "spells in hospital",
    )
    if any(pattern in text for pattern in status_patterns):
        return "General health-status or multimorbidity marker"

    return ""


def map_old50_ids(
    table_rows: list[dict[str, str]], ihd_rows: list[dict[str, str]]
) -> dict[str, dict[str, str]]:
    """Map the old table's ambiguous trait labels to IDs using exact IHD statistics."""
    by_name: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in ihd_rows:
        by_name[trait_name(row)].append(row)

    mapped: dict[str, dict[str, str]] = {}
    for sequential_rank, old in enumerate(table_rows, start=1):
        candidates = by_name.get(old["Exposure"], [])
        if not candidates:
            candidates = [
                row
                for row in ihd_rows
                if trait_name(row).casefold() == old["Exposure"].casefold()
            ]
        if not candidates:
            raise ValueError(f"Could not map old Table 1 trait: {old['Exposure']}")

        target_or = float(old["OR.IHD"])
        target_p = float(old["pval.IHD"])

        def score(row: dict[str, str]) -> float:
            row_or = math.exp(float(row["b"]))
            return abs(math.log(row_or / target_or)) + abs(
                math.log10(float(row["pval"])) - math.log10(target_p)
            )

        best = min(candidates, key=score)
        if score(best) > 1e-5:
            raise ValueError(
                f"Old Table 1 mapping was not exact for {old['Exposure']}: score={score(best)}"
            )
        old_rank = old.get("Combined_rank", "") or str(sequential_rank)
        mapped[best["id.exposure"]] = {
            "old50_rank": old_rank,
            "old50_trait": old["Exposure"],
        }

    if len(mapped) != 50:
        raise ValueError(f"Expected 50 unique old-table IDs; recovered {len(mapped)}")
    return mapped


def read_old50_id_map(path: Path) -> dict[str, dict[str, str]]:
    """Read the packaged ID map without requiring the superseded manuscript table."""
    rows = read_csv(path)
    mapped = {
        row["id.exposure"]: {
            "old50_rank": row["old50_rank"],
            "old50_trait": row["trait"],
        }
        for row in rows
    }
    if len(mapped) != 50:
        raise ValueError(f"Expected 50 unique old-table IDs; recovered {len(mapped)}")
    return mapped


def candidate_row(
    exposure_id: str,
    ihd: dict[str, str],
    dd: dict[str, str],
    q_ihd: float,
    q_dd: float,
    metadata: dict[str, str],
    old50: dict[str, dict[str, str]],
) -> dict[str, object]:
    b_ihd, se_ihd = float(ihd["b"]), float(ihd["se"])
    b_dd, se_dd = float(dd["b"]), float(dd["se"])
    marker_reason = classify_downstream_marker(trait_name(ihd))
    old = old50.get(exposure_id, {})
    direction = "Positive" if b_ihd > 0 and b_dd > 0 else "Negative"

    return {
        "id.exposure": exposure_id,
        "trait": trait_name(ihd),
        "population": metadata.get("population", ""),
        "source_group": metadata.get("group_name", ""),
        "consortium": metadata.get("consortium", ""),
        "exposure_category": metadata.get("category", ""),
        "exposure_sample_size": metadata.get("sample_size", ""),
        "exposure_ncase": metadata.get("ncase", ""),
        "exposure_ncontrol": metadata.get("ncontrol", ""),
        "direction": direction,
        "IHD.id.outcome": ihd["id.outcome"],
        "IHD.method": ihd["method"],
        "IHD.nsnp": ihd["nsnp"],
        "IHD.b": fmt(b_ihd),
        "IHD.se": fmt(se_ihd),
        "IHD.p": fmt(float(ihd["pval"])),
        "IHD.q_BH_m11988": fmt(q_ihd),
        "IHD.OR": fmt(math.exp(b_ihd)),
        "IHD.CI95_lower": fmt(math.exp(b_ihd - 1.96 * se_ihd)),
        "IHD.CI95_upper": fmt(math.exp(b_ihd + 1.96 * se_ihd)),
        "DD.id.outcome": dd["id.outcome"],
        "DD.method": dd["method"],
        "DD.nsnp": dd["nsnp"],
        "DD.b": fmt(b_dd),
        "DD.se": fmt(se_dd),
        "DD.p": fmt(float(dd["pval"])),
        "DD.q_BH_m11988": fmt(q_dd),
        "DD.OR": fmt(math.exp(b_dd)),
        "DD.CI95_lower": fmt(math.exp(b_dd - 1.96 * se_dd)),
        "DD.CI95_upper": fmt(math.exp(b_dd + 1.96 * se_dd)),
        "old50_overlap": "TRUE" if exposure_id in old50 else "FALSE",
        "old50_rank": old.get("old50_rank", ""),
        "downstream_marker": "TRUE" if marker_reason else "FALSE",
        "downstream_exclusion_reason": marker_reason,
    }


OUTPUT_FIELDS = [
    "set_rank",
    "id.exposure",
    "trait",
    "population",
    "source_group",
    "consortium",
    "exposure_category",
    "exposure_sample_size",
    "exposure_ncase",
    "exposure_ncontrol",
    "direction",
    "IHD.id.outcome",
    "IHD.method",
    "IHD.nsnp",
    "IHD.b",
    "IHD.se",
    "IHD.p",
    "IHD.q_BH_m11988",
    "IHD.OR",
    "IHD.CI95_lower",
    "IHD.CI95_upper",
    "DD.id.outcome",
    "DD.method",
    "DD.nsnp",
    "DD.b",
    "DD.se",
    "DD.p",
    "DD.q_BH_m11988",
    "DD.OR",
    "DD.CI95_lower",
    "DD.CI95_upper",
    "old50_overlap",
    "old50_rank",
    "downstream_marker",
    "downstream_exclusion_reason",
]


def rank_rows(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    """Stable evidence ordering by the weaker of the two q-values, then ID."""
    ordered = sorted(
        rows,
        key=lambda row: (
            max(float(str(row["IHD.q_BH_m11988"])), float(str(row["DD.q_BH_m11988"]))),
            str(row["id.exposure"]),
        ),
    )
    for rank, row in enumerate(ordered, start=1):
        row["set_rank"] = rank
    return ordered


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Reconstruct exploratory MR candidate sets from packaged aggregate results."
    )
    parser.add_argument("--mr-root", type=Path, default=DEFAULT_MR_ROOT)
    parser.add_argument("--old50-map", type=Path, default=DEFAULT_OLD50_MAP)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    mr_root = args.mr_root.resolve()
    old50_map_path = args.old50_map.resolve()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=False)

    ao_rows = read_csv(mr_root / "ao.csv")
    ihd_rows = read_csv(mr_root / "IHD" / "bb.csv")
    dd_rows = read_csv(mr_root / "DD" / "bb.csv")

    if len(ao_rows) != 15_703:
        raise ValueError(f"Expected 15,703 catalog rows; found {len(ao_rows)}")
    if sum(row["population"] == "European" for row in ao_rows) != 11_989:
        raise ValueError("European catalog count no longer equals 11,989")

    for label, rows in (("IHD", ihd_rows), ("DD", dd_rows)):
        ids = [row["id.exposure"] for row in rows]
        if len(ids) != len(set(ids)):
            raise ValueError(f"Duplicate exposure IDs in {label} aggregate results")

    q_ihd = bh_fixed_m(ihd_rows, M_TOTAL)
    q_dd = bh_fixed_m(dd_rows, M_TOTAL)
    ihd_by_id = {row["id.exposure"]: row for row in ihd_rows}
    dd_by_id = {row["id.exposure"]: row for row in dd_rows}
    ao_by_id = {row["id"]: row for row in ao_rows}
    old50 = read_old50_id_map(old50_map_path)

    common_ids = set(ihd_by_id).intersection(dd_by_id)
    set_a_ids = sorted(
        exposure_id
        for exposure_id in common_ids
        if ihd_by_id[exposure_id]["method"] == IVW
        and dd_by_id[exposure_id]["method"] == IVW
        and q_ihd[exposure_id] < 0.05
        and q_dd[exposure_id] < 0.05
        and float(ihd_by_id[exposure_id]["b"]) * float(dd_by_id[exposure_id]["b"]) > 0
    )
    set_b_ids = [exposure_id for exposure_id in set_a_ids if not exposure_id.startswith("finn-b-")]

    all_a_rows = [
        candidate_row(
            exposure_id,
            ihd_by_id[exposure_id],
            dd_by_id[exposure_id],
            q_ihd[exposure_id],
            q_dd[exposure_id],
            ao_by_id.get(exposure_id, {}),
            old50,
        )
        for exposure_id in set_a_ids
    ]
    all_a_by_id = {str(row["id.exposure"]): row for row in all_a_rows}
    set_a = rank_rows([dict(all_a_by_id[exposure_id]) for exposure_id in set_a_ids])
    set_b = rank_rows([dict(all_a_by_id[exposure_id]) for exposure_id in set_b_ids])
    set_c = rank_rows(
        [
            dict(all_a_by_id[exposure_id])
            for exposure_id in set_b_ids
            if all_a_by_id[exposure_id]["downstream_marker"] == "FALSE"
        ]
    )
    set_c_excluded = rank_rows(
        [
            dict(all_a_by_id[exposure_id])
            for exposure_id in set_b_ids
            if all_a_by_id[exposure_id]["downstream_marker"] == "TRUE"
        ]
    )

    membership_rows: list[dict[str, object]] = []
    c_ids = {str(row["id.exposure"]) for row in set_c}
    for row in set_a:
        exposure_id = str(row["id.exposure"])
        item = dict(row)
        item["in_set_A"] = "TRUE"
        item["in_set_B"] = "TRUE" if exposure_id in set_b_ids else "FALSE"
        item["in_set_C"] = "TRUE" if exposure_id in c_ids else "FALSE"
        membership_rows.append(item)

    outputs = {
        "set_A_bh_both_direction_consistent_ivw.csv": set_a,
        "set_B_setA_excluding_finn_b_exposures.csv": set_b,
        "set_C_setB_excluding_downstream_codes.csv": set_c,
        "set_C_excluded_downstream_codes.csv": set_c_excluded,
    }
    for filename, rows in outputs.items():
        write_csv(output_dir / filename, rows, OUTPUT_FIELDS)

    membership_fields = OUTPUT_FIELDS + ["in_set_A", "in_set_B", "in_set_C"]
    write_csv(output_dir / "candidate_set_membership.csv", membership_rows, membership_fields)

    set_a_id_lookup = {str(row["id.exposure"]) for row in set_a}
    set_b_id_lookup = {str(row["id.exposure"]) for row in set_b}
    old50_status_rows: list[dict[str, object]] = []
    for exposure_id, old in sorted(old50.items(), key=lambda item: int(item[1]["old50_rank"])):
        ihd = ihd_by_id.get(exposure_id)
        dd = dd_by_id.get(exposure_id)
        failure_reasons: list[str] = []
        if ihd is None:
            failure_reasons.append("Missing IHD aggregate result")
        if dd is None:
            failure_reasons.append("Missing DD aggregate result")
        if ihd is not None and ihd["method"] != IVW:
            failure_reasons.append("IHD method is not IVW")
        if dd is not None and dd["method"] != IVW:
            failure_reasons.append("DD method is not IVW")
        if ihd is not None and q_ihd[exposure_id] >= 0.05:
            failure_reasons.append("IHD BH q>=0.05")
        if dd is not None and q_dd[exposure_id] >= 0.05:
            failure_reasons.append("DD BH q>=0.05")
        if ihd is not None and dd is not None and float(ihd["b"]) * float(dd["b"]) <= 0:
            failure_reasons.append("Effect directions disagree")

        old50_status_rows.append(
            {
                "old50_rank": old["old50_rank"],
                "id.exposure": exposure_id,
                "trait": old["old50_trait"],
                "IHD.method": ihd["method"] if ihd else "",
                "IHD.nsnp": ihd["nsnp"] if ihd else "",
                "IHD.p": fmt(float(ihd["pval"])) if ihd else "",
                "IHD.q_BH_m11988": fmt(q_ihd[exposure_id]) if ihd else "",
                "DD.result_present": "TRUE" if dd else "FALSE",
                "DD.method": dd["method"] if dd else "",
                "DD.nsnp": dd["nsnp"] if dd else "",
                "DD.p": fmt(float(dd["pval"])) if dd else "",
                "DD.q_BH_m11988": fmt(q_dd[exposure_id]) if dd else "",
                "direction_consistent": (
                    "TRUE"
                    if ihd is not None and dd is not None and float(ihd["b"]) * float(dd["b"]) > 0
                    else "FALSE"
                ),
                "in_set_A": "TRUE" if exposure_id in set_a_id_lookup else "FALSE",
                "in_set_B": "TRUE" if exposure_id in set_b_id_lookup else "FALSE",
                "in_set_C": "TRUE" if exposure_id in c_ids else "FALSE",
                "set_A_failure_reasons": "; ".join(failure_reasons),
                "downstream_exclusion_reason": classify_downstream_marker(old["old50_trait"]),
            }
        )
    old50_status_fields = [
        "old50_rank",
        "id.exposure",
        "trait",
        "IHD.method",
        "IHD.nsnp",
        "IHD.p",
        "IHD.q_BH_m11988",
        "DD.result_present",
        "DD.method",
        "DD.nsnp",
        "DD.p",
        "DD.q_BH_m11988",
        "direction_consistent",
        "in_set_A",
        "in_set_B",
        "in_set_C",
        "set_A_failure_reasons",
        "downstream_exclusion_reason",
    ]
    write_csv(output_dir / "old50_status_against_sets.csv", old50_status_rows, old50_status_fields)

    summary_rows = [
        {"metric": "catalog_records", "value": len(ao_rows)},
        {"metric": "european_catalog_records", "value": sum(row["population"] == "European" for row in ao_rows)},
        {"metric": "fixed_BH_family_size_per_outcome", "value": M_TOTAL},
        {"metric": "IHD_saved_primary_results", "value": len(ihd_rows)},
        {"metric": "DD_saved_primary_results", "value": len(dd_rows)},
        {"metric": "set_A_count", "value": len(set_a)},
        {"metric": "set_A_old50_overlap", "value": sum(row["old50_overlap"] == "TRUE" for row in set_a)},
        {"metric": "set_B_count", "value": len(set_b)},
        {"metric": "set_B_old50_overlap", "value": sum(row["old50_overlap"] == "TRUE" for row in set_b)},
        {"metric": "set_C_count", "value": len(set_c)},
        {"metric": "set_C_old50_overlap", "value": sum(row["old50_overlap"] == "TRUE" for row in set_c)},
        {"metric": "set_C_excluded_marker_count", "value": len(set_c_excluded)},
        {"metric": "set_A_positive_direction", "value": sum(row["direction"] == "Positive" for row in set_a)},
        {"metric": "set_A_negative_direction", "value": sum(row["direction"] == "Negative" for row in set_a)},
    ]
    write_csv(output_dir / "summary_counts.csv", summary_rows, ["metric", "value"])

    readme = f"""# Alternative MR candidate sets (aggregate-result recovery)

Generated from the packaged saved aggregate results. No network request is made.

## Fixed analysis rules

- Benjamini-Hochberg adjustment was calculated separately for IHD and DD with a fixed family size of **m = {M_TOTAL:,}**. Scheduled candidates without a saved aggregate estimate were treated as `p = 1`; the exact reason for each missing output was not recorded.
- **Set A:** both outcome-specific BH q-values `< 0.05`, effect directions agree, and both saved methods are inverse-variance weighted.
- **Set B:** Set A after excluding all `finn-b-*` exposure IDs to reduce participant-overlap and same-biobank dependence because both outcomes are FinnGen datasets. This post-screen safeguard is not a universal different-database requirement.
- **Set C:** Set B after the conservative lexical removal of obvious medication/treatment variables, diagnosis/disease-history codes, procedure/hospital-use codes, and broad health-status or multimorbidity markers. This is a descriptive sensitivity set and is not a replacement primary screen.
- `old50_overlap` indicates membership in the manuscript's previous 50-trait table, mapped to exposure IDs by exact matching of its IHD OR and p-value.
- `old50_status_against_sets.csv` lists all previous 50 traits, their current aggregate-result status, and explicit reasons for failing Set A.

## Counts

| Set | Candidates | Overlap with old 50 |
|---|---:|---:|
| A | {len(set_a)} | {sum(row['old50_overlap'] == 'TRUE' for row in set_a)} |
| B | {len(set_b)} | {sum(row['old50_overlap'] == 'TRUE' for row in set_b)} |
| C | {len(set_c)} | {sum(row['old50_overlap'] == 'TRUE' for row in set_c)} |

Set A contains {sum(row['direction'] == 'Positive' for row in set_a)} direction-consistent positive associations and {sum(row['direction'] == 'Negative' for row in set_a)} direction-consistent negative associations. Set C removes {len(set_c_excluded)} downstream/code-like markers from Set B.

## Interpretation limit

These files recover candidate sets from aggregate `b`, `se`, `p`, method, and instrument-count fields. They cannot reconstruct SNP-level harmonisation, instrument strength, heterogeneity, directional pleiotropy, MR-Egger, weighted-median, leave-one-out, MR-PRESSO, or Steiger analyses.

There was no manual phenotype pre-selection before the catalogue-wide screen. Set A is the post-analysis exploratory result set; Sets B and C are explicitly labelled post-screen reporting/sensitivity sets.
"""
    (output_dir / "README.md").write_text(readme, encoding="utf-8")

    generated = [output_dir / name for name in outputs]
    generated += [
        output_dir / "candidate_set_membership.csv",
        output_dir / "old50_status_against_sets.csv",
        output_dir / "summary_counts.csv",
        output_dir / "README.md",
        Path(__file__).resolve(),
        old50_map_path,
    ]
    manifest_lines = [f"{sha256(path)}  {path.name}" for path in sorted(generated)]
    (output_dir / "SHA256SUMS.txt").write_text("\n".join(manifest_lines) + "\n", encoding="ascii")

    print(f"Set A: {len(set_a)} (old50 overlap {sum(row['old50_overlap'] == 'TRUE' for row in set_a)})")
    print(f"Set B: {len(set_b)} (old50 overlap {sum(row['old50_overlap'] == 'TRUE' for row in set_b)})")
    print(f"Set C: {len(set_c)} (old50 overlap {sum(row['old50_overlap'] == 'TRUE' for row in set_c)})")
    print(f"Set C exclusions: {len(set_c_excluded)}")


if __name__ == "__main__":
    main()
