"""Main experiment orchestrator: pilot → gate → main run → save."""

import csv
import json
import logging
import pathlib
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from itertools import product

from config import CONSTRAINTS, LANGUAGES, MAIN_REPS, MAX_CONCURRENT, PILOT_REPS, TASKS
from runner import run_trial

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger(__name__)

RESULT_FIELDS = [
    "trial_id", "language", "task_id", "constraint_id", "rep",
    "session_id", "cost_usd", "elapsed_seconds", "cli_error",
    "extraction_method", "parse_success", "fidelity", "compliance",
    "delegation_lang",
]


def run_batch(trials: list[tuple], max_workers: int = 1) -> list[dict]:
    """Run a batch of trials. Each tuple: (language, task_id, constraint_id, rep)."""
    results = []
    if max_workers <= 1:
        for language, task_id, constraint_id, rep in trials:
            logger.info("Running %s/%s/%s/r%d", language, task_id, constraint_id, rep)
            result = run_trial(language, task_id, constraint_id, rep)
            results.append(result)
            _log_result(result)
    else:
        with ThreadPoolExecutor(max_workers=max_workers) as pool:
            future_map = {}
            for language, task_id, constraint_id, rep in trials:
                future = pool.submit(run_trial, language, task_id, constraint_id, rep)
                future_map[future] = (language, task_id, constraint_id, rep)
            for future in as_completed(future_map):
                key = future_map[future]
                try:
                    result = future.result()
                except Exception as e:
                    logger.error("Trial %s raised: %s", key, e)
                    result = {
                        "trial_id": f"{'_'.join(str(x) for x in key)}",
                        "language": key[0], "task_id": key[1],
                        "constraint_id": key[2], "rep": key[3],
                        "cli_error": str(e), "parse_success": False,
                        "fidelity": False, "compliance": None,
                    }
                results.append(result)
                _log_result(result)
    return results


def _log_result(result: dict):
    status = "OK" if result.get("parse_success") else "FAIL"
    comp = result.get("compliance")
    comp_str = f"{comp:.2f}" if isinstance(comp, float) else str(comp)
    logger.info(
        "  %s | parse=%s fidelity=%s compliance=%s cost=$%.3f",
        result.get("trial_id", "?"),
        status,
        result.get("fidelity"),
        comp_str,
        result.get("cost_usd", 0),
    )


def pilot_summary(results: list[dict]) -> dict:
    """Compute pilot summary statistics."""
    total = len(results)
    parsed = sum(1 for r in results if r.get("parse_success"))
    parse_rate = parsed / total if total else 0

    # Per-constraint EN mean compliance (now proportional, 0.0-1.0)
    constraint_stats = {}
    for cid in CONSTRAINTS:
        en_trials = [r for r in results if r["constraint_id"] == cid and r["language"] == "en"]
        vals = [r.get("compliance") for r in en_trials if r.get("compliance") is not None]
        if vals:
            rate = sum(vals) / len(vals)
        else:
            rate = 0.0
        constraint_stats[cid] = rate

    return {
        "total_trials": total,
        "parsed": parsed,
        "parse_rate": parse_rate,
        "constraint_en_compliance": constraint_stats,
    }


def auto_gate(summary: dict) -> list[str]:
    """Decide which constraints survive the pilot gate. Returns list of constraint IDs."""
    parse_rate = summary["parse_rate"]
    compliance = summary["constraint_en_compliance"]

    print("\n=== PILOT SUMMARY ===")
    print(f"Total trials: {summary['total_trials']}")
    print(f"Parse rate: {parse_rate:.1%} ({'PASS' if parse_rate > 0.8 else 'FAIL'})")
    print("EN compliance by constraint:")
    for cid, rate in compliance.items():
        print(f"  {cid}: {rate:.1%}")

    if parse_rate <= 0.8:
        print("\nGATE FAIL: parse rate ≤ 80%")
        print("Cannot proceed to main experiment.")
        return []

    # Primary gate: constraints with mean EN compliance between 20% and 95%
    surviving = [cid for cid, rate in compliance.items() if 0.20 <= rate <= 0.95]
    if len(surviving) >= 2:
        print(f"\nPrimary gate PASS: {len(surviving)} constraints in 20-95% range")
        print(f"Surviving: {surviving}")
        return surviving

    # Relaxed gate: constraints with mean EN compliance < 100% (some variance)
    surviving = [cid for cid, rate in compliance.items() if rate < 1.0]
    if len(surviving) >= 2:
        print(f"\nRelaxed gate PASS: {len(surviving)} constraints with <100% compliance")
        print(f"Surviving: {surviving}")
        return surviving

    # Last resort: use all constraints
    print("\nGate: insufficient variance, using all constraints")
    return list(compliance.keys())


def run_pilot() -> tuple[list[dict], list[str]]:
    """Run pilot: 36 trials (3 langs × 3 tasks × 4 constraints × 1 rep)."""
    print("\n=== PILOT PHASE ===")
    trials = list(product(LANGUAGES, TASKS.keys(), CONSTRAINTS.keys(), range(PILOT_REPS)))
    print(f"Running {len(trials)} pilot trials...")
    results = run_batch(trials, max_workers=1)
    summary = pilot_summary(results)
    surviving = auto_gate(summary)
    return results, surviving


def run_main(surviving_constraints: list[str]) -> list[dict]:
    """Run main experiment: surviving constraints × 5 reps, 5 concurrent."""
    print("\n=== MAIN PHASE ===")
    trials = list(product(
        LANGUAGES,
        TASKS.keys(),
        surviving_constraints,
        range(MAIN_REPS),
    ))
    print(f"Running {len(trials)} main trials ({MAX_CONCURRENT} concurrent)...")
    return run_batch(trials, max_workers=MAX_CONCURRENT)


def save_results(trials: list[dict], base_path: str = "results"):
    """Write results to results.jsonl and results.csv."""
    jsonl_path = pathlib.Path(f"{base_path}.jsonl")
    csv_path = pathlib.Path(f"{base_path}.csv")

    # JSONL — full data
    with open(jsonl_path, "w") as f:
        for trial in trials:
            f.write(json.dumps(trial, default=str, ensure_ascii=False) + "\n")
    print(f"Wrote {len(trials)} trials to {jsonl_path}")

    # CSV — summary fields only (no large text blobs)
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=RESULT_FIELDS, extrasaction="ignore")
        writer.writeheader()
        for trial in trials:
            writer.writerow(trial)
    print(f"Wrote {len(trials)} rows to {csv_path}")


def main():
    pilot_results, surviving = run_pilot()

    if not surviving:
        print("No constraints survived pilot gate. Saving pilot results only.")
        save_results(pilot_results, "results_pilot")
        sys.exit(1)

    main_results = run_main(surviving)

    all_results = pilot_results + main_results
    save_results(all_results)

    total_cost = sum(r.get("cost_usd", 0) for r in all_results)
    print("\n=== DONE ===")
    print(f"Total trials: {len(all_results)}")
    print(f"Total cost: ${total_cost:.2f}")


if __name__ == "__main__":
    main()
