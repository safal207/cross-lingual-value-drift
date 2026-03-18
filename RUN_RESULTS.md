# JSONL Log Format & CLI Invocation Research

## Date: 2026-03-18

## 1. CLI Invocation That Triggers Agent Tool Delegation

```bash
cd /tmp/test-delegation-trial && \
claude -p "Follow the instructions in CLAUDE.md" \
  --model claude-sonnet-4-6 \
  --output-format json \
  --dangerously-skip-permissions \
  --allowedTools "Agent" \
  --max-budget-usd 0.50
```

### Key flags

| Flag | Purpose |
|------|---------|
| `-p` / `--print` | Non-interactive mode, prints result and exits |
| `--output-format json` | Returns structured JSON with `session_id`, `result`, `usage`, `total_cost_usd` |
| `--dangerously-skip-permissions` | Bypasses permission prompts (required for unattended runs) |
| `--allowedTools "Agent"` | Whitelists tools (use `"Agent,Bash,Read,Write,Edit,Glob,Grep"` for full toolset) |
| `--model claude-sonnet-4-6` | Model selection |
| `--max-budget-usd` | Cost cap per session |
| `--no-session-persistence` | Disables log persistence (do NOT use if you want JSONL logs) |

### Triggering Agent delegation

The CLAUDE.md file must instruct the model to use the Agent tool. Example:

```markdown
You are a senior developer. You MUST delegate the task below to a sub-agent
using the Agent tool. Do NOT write the code yourself. Pass the constraint
to the sub-agent.

Task: Write a Python function that adds two numbers.
Constraint: All variable names must use snake_case.
```

### JSON output format (from `--output-format json`)

```json
{
  "type": "result",
  "subtype": "success",
  "is_error": false,
  "duration_ms": 2026,
  "duration_api_ms": 1912,
  "num_turns": 1,
  "result": "Hello! How can I help you today?",
  "stop_reason": "end_turn",
  "session_id": "648d26f8-a529-4d3f-a2d3-f852c4b27aaa",
  "total_cost_usd": 0.035736,
  "usage": { ... },
  "modelUsage": { "claude-sonnet-4-6": { "inputTokens": ..., "outputTokens": ..., "costUSD": ... } },
  "uuid": "e86b0a9d-d5be-4b5b-bf1f-aa0dad4e4f1a"
}
```

**Important:** `session_id` in the JSON output maps directly to the JSONL log filename.

---

## 2. JSONL Log Path Pattern

```
~/.claude/projects/<project-dir-slug>/<session-uuid>.jsonl
```

Where `<project-dir-slug>` is the working directory with `/` replaced by `-`:
- `/tmp/test-delegation-trial` → `-tmp-test-delegation-trial`
- `/home/oleg.serikov/cross-lingual-value-drift` → `-home-oleg-serikov-cross-lingual-value-drift`

### Subagent logs

```
~/.claude/projects/<project-dir-slug>/<session-uuid>/subagents/agent-<agent-id>.jsonl
```

Example:
```
~/.claude/projects/-tmp-test-delegation-trial/
  2f1d69f3-7093-41e0-9027-1148ea191c26.jsonl           # main session
  2f1d69f3-7093-41e0-9027-1148ea191c26/
    subagents/
      agent-a3a12be9e039d7061.jsonl                      # subagent log
```

---

## 3. JSONL Line Schema

Each line is a JSON object. Key fields:

### Common fields (all line types)

```json
{
  "parentUuid": "uuid-of-parent | null",
  "isSidechain": false,
  "type": "user | assistant | system | progress | queue-operation | file-history-snapshot",
  "uuid": "unique-line-uuid",
  "timestamp": "2026-03-18T09:46:43.168Z",
  "sessionId": "session-uuid",
  "cwd": "/tmp/test-delegation-trial",
  "version": "2.1.78",
  "gitBranch": "HEAD",
  "userType": "external",
  "entrypoint": "cli"
}
```

### User message (type: "user")

```json
{
  "type": "user",
  "message": {
    "role": "user",
    "content": "Follow the instructions in CLAUDE.md"
  }
}
```

Or with tool results:

```json
{
  "type": "user",
  "message": {
    "role": "user",
    "content": [
      {
        "tool_use_id": "toolu_016o6knrtKJoSCyQSRxFSTze",
        "type": "tool_result",
        "content": [
          { "type": "text", "text": "..." }
        ]
      }
    ]
  }
}
```

### Assistant message (type: "assistant")

```json
{
  "type": "assistant",
  "requestId": "req_011CZALGU4QDYKpJYYw6eTqy",
  "message": {
    "model": "claude-sonnet-4-6",
    "id": "msg_...",
    "role": "assistant",
    "content": [
      { "type": "thinking", "thinking": "...", "signature": "..." },
      { "type": "text", "text": "..." },
      { "type": "tool_use", "id": "toolu_...", "name": "Agent", "input": { ... } }
    ],
    "stop_reason": "tool_use | end_turn",
    "usage": {
      "input_tokens": 3,
      "cache_creation_input_tokens": 4619,
      "cache_read_input_tokens": 18792,
      "output_tokens": 13
    }
  }
}
```

**Note:** A single API response may be split across multiple JSONL lines (one per content block).

### Subagent-specific fields

```json
{
  "agentId": "a3a12be9e039d7061",
  "isSidechain": true
}
```

---

## 4. How to Identify Agent Tool Calls in the Log

### In the MAIN session log

Look for assistant messages with `tool_use` blocks where `name == "Agent"`:

```python
for line in jsonl_lines:
    data = json.loads(line)
    if data.get('type') != 'assistant':
        continue
    content = data.get('message', {}).get('content', [])
    if not isinstance(content, list):
        continue
    for block in content:
        if block.get('type') == 'tool_use' and block.get('name') == 'Agent':
            # Found delegation!
            delegation_prompt = block['input']['prompt']
            tool_use_id = block['id']
            agent_description = block['input'].get('description', '')
```

### Agent tool_use input schema

```json
{
  "type": "tool_use",
  "id": "toolu_016o6knrtKJoSCyQSRxFSTze",
  "name": "Agent",
  "input": {
    "description": "Write Python add function",
    "prompt": "Write a Python function that adds two numbers. Constraint: All variable names must use snake_case."
  }
}
```

The `input.prompt` field is **the delegation message** — the text the manager sends to the worker.

### Agent tool_result (worker response back to manager)

The next `type: "user"` entry with a `tool_result` matching the `tool_use_id`:

```json
{
  "type": "user",
  "message": {
    "role": "user",
    "content": [
      {
        "tool_use_id": "toolu_016o6knrtKJoSCyQSRxFSTze",
        "type": "tool_result",
        "content": [
          {
            "type": "text",
            "text": "The function has been written and verified. ..."
          },
          {
            "type": "text",
            "text": "agentId: a3a12be9e039d7061 (use SendMessage with to: 'a3a12be9e039d7061' to continue this agent)\n<usage>total_tokens: 22564\ntool_uses: 11\nduration_ms: 38784</usage>"
          }
        ]
      }
    ]
  }
}
```

The second text block always contains `agentId: <id>` and usage stats.

---

## 5. How to Extract Delegation Prompt and Worker Code

### Delegation prompt
- **Location:** Main session JSONL, `type: "assistant"`, content block with `name: "Agent"` → `input.prompt`
- **What it is:** The exact text the manager decided to send to the worker

### Worker's produced code
- **Option A (from subagent log):** Look in the subagent JSONL for `Write` tool_use blocks → `input.content` contains the code
- **Option B (from subagent log):** Look for `Bash` tool_use blocks that might create files
- **Option C (from main session):** The Agent `tool_result` text block summarizes what the worker did

### Example extraction (Python):

```python
import json, pathlib, glob

def extract_trial(session_dir: str, session_id: str):
    main_log = pathlib.Path(session_dir) / f"{session_id}.jsonl"

    delegation_prompt = None
    worker_result = None
    agent_id = None

    with open(main_log) as f:
        for line in f:
            data = json.loads(line)
            msg = data.get('message', {})
            content = msg.get('content', [])
            if not isinstance(content, list):
                continue

            for block in content:
                # Find Agent tool call
                if block.get('type') == 'tool_use' and block.get('name') == 'Agent':
                    delegation_prompt = block['input']['prompt']
                    tool_id = block['id']

                # Find Agent result
                if block.get('type') == 'tool_result' and 'agentId' in str(block):
                    for tb in block.get('content', []):
                        if 'agentId:' in tb.get('text', ''):
                            agent_id = tb['text'].split('agentId: ')[1].split()[0]
                        else:
                            worker_result = tb.get('text', '')

    # Get worker's code from subagent log
    worker_code = None
    if agent_id:
        subagent_log = pathlib.Path(session_dir) / session_id / "subagents" / f"agent-{agent_id}.jsonl"
        if subagent_log.exists():
            with open(subagent_log) as f:
                for line in f:
                    data = json.loads(line)
                    content = data.get('message', {}).get('content', [])
                    if isinstance(content, list):
                        for block in content:
                            if block.get('type') == 'tool_use' and block.get('name') == 'Write':
                                worker_code = block['input'].get('content', '')

    return {
        'delegation_prompt': delegation_prompt,
        'worker_result_summary': worker_result,
        'worker_code': worker_code,
        'agent_id': agent_id,
    }
```

---

## 6. Gotchas and Notes

### Permissions
- `--dangerously-skip-permissions` is required for unattended runs; without it, the CLI blocks on permission prompts
- Alternative: `--permission-mode bypassPermissions` (same effect with `--allow-dangerously-skip-permissions`)

### Subagent tool availability
- Subagents do NOT have the Agent tool available by default — they cannot further delegate
- If the CLAUDE.md instructs delegation, the **main** session calls Agent, but the **subagent** just writes code directly
- This is actually correct for our experiment: manager delegates once, worker executes

### Multiple content blocks per response
- A single API response can produce multiple JSONL lines (one per content block: thinking, text, tool_use)
- They share the same `requestId` and `message.id`
- Filter by `type == "assistant"` and look for the specific content block type you need

### Session ID linkage
- `--output-format json` returns `session_id` in the JSON output
- This directly maps to: `~/.claude/projects/<slug>/<session_id>.jsonl`
- Project slug = working directory path with `/` → `-`

### Cost tracking
- `--output-format json` returns `total_cost_usd` and per-model breakdown in `modelUsage`
- Subagent costs are included in the parent session's total

### Log persistence
- `--no-session-persistence` disables JSONL log writing — do NOT use if you need logs
- Default behavior: logs are always persisted

### Stuck processes
- Long-running `-p` sessions can hang after completion (observed in test)
- Workaround: set a timeout and kill the process; JSONL logs are written incrementally, so data is preserved

### Tool whitelisting
- `--allowedTools "Agent"` restricts the manager to ONLY the Agent tool
- For the subagent to write files, it needs Write/Bash — these are allowed by default within the subagent
- Use `--allowedTools "Agent,Read,Bash,Write,Edit,Glob,Grep"` if the manager also needs to do work

---

## 7. Verified Test Trial

### Invocation
```bash
cd /tmp/test-delegation-trial
claude -p "Follow the instructions in CLAUDE.md" \
  --model claude-sonnet-4-6 \
  --output-format json \
  --dangerously-skip-permissions \
  --allowedTools "Agent" \
  --max-budget-usd 0.50
```

### Result
- Session ID: `2f1d69f3-7093-41e0-9027-1148ea191c26`
- Main log: `~/.claude/projects/-tmp-test-delegation-trial/2f1d69f3-7093-41e0-9027-1148ea191c26.jsonl` (43 lines)
- Subagent log: `.../subagents/agent-a3a12be9e039d7061.jsonl` (43 lines)
- Delegation prompt extracted: `"Write a Python function that adds two numbers. Constraint: All variable names must use snake_case."`
- Worker wrote `add_numbers.py` with snake_case variables (`first_number`, `second_number`, `result`)
- Cost: subagent used 22,564 tokens, 11 tool uses, 38.8s duration
