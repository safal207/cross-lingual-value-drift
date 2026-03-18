"""Trial execution: create temp dir, invoke Claude CLI, parse logs, score."""

import json
import logging
import pathlib
import shutil
import subprocess
import tempfile
import time

from config import (
    CLAUDE_MD_TEMPLATES,
    CONSTRAINTS,
    MAX_BUDGET_USD,
    MODEL,
    TASKS,
    TRIAL_TIMEOUT_SECONDS,
)
from log_parser import parse_logs
from scoring import score_trial

logger = logging.getLogger(__name__)


def _make_slug(path: str) -> str:
    """Convert a directory path to a Claude project slug (/ → -)."""
    return path.replace("/", "-")


def run_trial(
    language: str,
    task_id: str,
    constraint_id: str,
    rep: int,
    timeout: int = TRIAL_TIMEOUT_SECONDS,
) -> dict:
    """Run a single manager→worker trial. Returns dict with all results."""
    trial_id = f"{language}_{task_id}_{constraint_id}_r{rep}"
    trial_dir = tempfile.mkdtemp(prefix=f"trial_{trial_id}_")

    try:
        return _execute_trial(language, task_id, constraint_id, rep, trial_id, trial_dir, timeout)
    except Exception as e:
        logger.error("Trial %s failed with exception: %s", trial_id, e)
        return _error_result(language, task_id, constraint_id, rep, trial_id, str(e))
    finally:
        shutil.rmtree(trial_dir, ignore_errors=True)


def _execute_trial(
    language: str,
    task_id: str,
    constraint_id: str,
    rep: int,
    trial_id: str,
    trial_dir: str,
    timeout: int,
) -> dict:
    template = CLAUDE_MD_TEMPLATES[language]
    task_desc = TASKS[task_id][language]
    constraint_text = CONSTRAINTS[constraint_id][language]
    claude_md = template.format(task_description=task_desc, constraint=constraint_text)
    (pathlib.Path(trial_dir) / "CLAUDE.md").write_text(claude_md, encoding="utf-8")

    cmd = [
        "claude",
        "-p", "Follow the instructions in CLAUDE.md",
        "--model", MODEL,
        "--output-format", "json",
        "--dangerously-skip-permissions",
        "--allowedTools", "Agent",
        "--max-budget-usd", str(MAX_BUDGET_USD),
    ]

    start_time = time.monotonic()
    session_id = ""
    cost = 0.0
    cli_error = None

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=trial_dir,
        )
        try:
            output = json.loads(result.stdout)
            session_id = output.get("session_id", "")
            cost = output.get("total_cost_usd", 0.0)
        except json.JSONDecodeError:
            cli_error = f"JSON parse error. stdout={result.stdout[:500]}, stderr={result.stderr[:500]}"
    except subprocess.TimeoutExpired:
        cli_error = f"timeout after {timeout}s"
    except FileNotFoundError:
        cli_error = "claude CLI not found"

    elapsed = time.monotonic() - start_time

    # Parse logs
    delegation_msg = None
    worker_code = None
    if session_id and not cli_error:
        slug = _make_slug(trial_dir)
        log_dir = pathlib.Path.home() / ".claude" / "projects" / slug
        try:
            delegation_msg, worker_code = parse_logs(log_dir, session_id)
        except Exception as e:
            logger.warning("Log parsing failed for %s: %s", trial_id, e)

    # Score
    scores = {}
    if delegation_msg is not None and worker_code is not None:
        scores = score_trial(constraint_id, delegation_msg, worker_code)
    else:
        scores = {
            "code": None,
            "extraction_method": "no_output",
            "parse_success": False,
            "fidelity": False,
            "compliance": None,
            "delegation_lang": None,
        }

    return {
        "trial_id": trial_id,
        "language": language,
        "task_id": task_id,
        "constraint_id": constraint_id,
        "rep": rep,
        "session_id": session_id,
        "cost_usd": cost,
        "elapsed_seconds": round(elapsed, 1),
        "cli_error": cli_error,
        "delegation_msg": delegation_msg,
        "worker_code": worker_code,
        **scores,
    }


def _error_result(
    language: str,
    task_id: str,
    constraint_id: str,
    rep: int,
    trial_id: str,
    error: str,
) -> dict:
    return {
        "trial_id": trial_id,
        "language": language,
        "task_id": task_id,
        "constraint_id": constraint_id,
        "rep": rep,
        "session_id": "",
        "cost_usd": 0.0,
        "elapsed_seconds": 0.0,
        "cli_error": error,
        "delegation_msg": None,
        "worker_code": None,
        "code": None,
        "extraction_method": "error",
        "parse_success": False,
        "fidelity": False,
        "compliance": None,
        "delegation_lang": None,
    }
