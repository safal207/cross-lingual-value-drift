"""Parse Claude Code JSONL logs to extract delegation messages and worker code."""

import json
import pathlib


def parse_logs(log_dir: pathlib.Path, session_id: str) -> tuple[str | None, str | None]:
    """Extract delegation message and worker code from JSONL logs.

    Returns (delegation_prompt, worker_code).
    """
    main_log = log_dir / f"{session_id}.jsonl"
    if not main_log.exists():
        return None, None

    delegation_prompt = None
    agent_id = None

    for line in _iter_jsonl(main_log):
        if line.get("type") != "assistant":
            continue
        content = line.get("message", {}).get("content", [])
        if not isinstance(content, list):
            continue
        for block in content:
            if block.get("type") == "tool_use" and block.get("name") == "Agent":
                delegation_prompt = block.get("input", {}).get("prompt")

    # Second pass: find agent ID from tool_result
    for line in _iter_jsonl(main_log):
        content = line.get("message", {}).get("content", [])
        if not isinstance(content, list):
            continue
        for block in content:
            if block.get("type") == "tool_result":
                text_blocks = block.get("content", [])
                if not isinstance(text_blocks, list):
                    continue
                for tb in text_blocks:
                    text = tb.get("text", "")
                    if "agentId:" in text:
                        parts = text.split("agentId: ")
                        if len(parts) > 1:
                            agent_id = parts[1].split()[0].strip()

    # Parse subagent log for Write tool_use
    worker_code = None
    if agent_id:
        subagent_log = log_dir / session_id / "subagents" / f"agent-{agent_id}.jsonl"
        if subagent_log.exists():
            for line in _iter_jsonl(subagent_log):
                if line.get("type") != "assistant":
                    continue
                content = line.get("message", {}).get("content", [])
                if not isinstance(content, list):
                    continue
                for block in content:
                    if block.get("type") == "tool_use" and block.get("name") == "Write":
                        worker_code = block.get("input", {}).get("content", "")

    return delegation_prompt, worker_code


def _iter_jsonl(path: pathlib.Path):
    """Yield parsed JSON objects from a JSONL file, skipping bad lines."""
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue
