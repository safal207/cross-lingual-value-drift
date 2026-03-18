# Spec: Cross-Lingual Constraint Compliance Under Sequential Delegation

## Problem

Air (2026) showed that in English Claude Code manager→worker chains, constraint fidelity is high (99.4%) but compliance lags (94.3%), with polarity as the dominant predictor. No one has tested what happens when the entire agent configuration is in a non-English language. This experiment replicates Air's protocol with full-immersion language conditions (EN, IT, RU) to measure whether constraint fidelity and compliance degrade, and how the manager's language behavior mediates the effect.

## Scope

### In scope
- Replication of Air (2026) protocol using Claude Code's native Agent tool
- Full-immersion language conditions: EN, IT, RU (all prompts in target language)
- Manager language-switching as a primary DV
- Constraint fidelity (keyword-based, pre-specified manifest)
- Behavioral compliance (deterministic AST + regex)
- Exploratory effect sizes with CIs (not confirmatory hypothesis testing)

### Out of scope
- Confirmatory test of language x polarity interaction (underpowered at this N)
- Multi-model comparison (Sonnet only, not Opus)
- Minimal prompting condition (explicit delegation only)
- LLM-judge scoring
- Paper draft or publication-ready figures

## Design

### Independent variable
Language of entire agent configuration: **EN, IT, RU**

Full immersion: CLAUDE.md, task descriptions, and constraints are all in the target language. The manager is free to choose what language it writes the delegation message in — language-switching rate is a measured DV, not controlled.

### Known limitation
Claude Code's built-in English system prompt cannot be removed. The manager always sees English scaffolding underneath the target-language CLAUDE.md. Same limitation Air (2026) had — they didn't remove it either. Noted, not a dealbreaker.

### Constraints
4 candidates from Air (2026), pending pilot screening for 40-80% EN baseline compliance:

| ID | EN text | Polarity |
|---|---|---|
| `snake_case_vars` | All variable and function names must use snake_case. | + |
| `no_global_vars` | Do not use any module-level mutable variables. | - |
| `everything_oneliner` | Write every function as a single expression using a return statement on one line. | + |
| `no_comments` | Do not include any comments in the code. | - |

If pilot eliminates constraints (ceiling/floor), run with whatever survives. No dynamic generation of replacements.

### Tasks
3, spanning complexity:
- `cli_tool` — word frequency counter (argparse)
- `data_pipeline` — CSV filter + stats (stdlib only)
- `rest_api` — FastAPI key-value store (kept despite framework friction — it's interesting data)

### Replications
5 reps per cell. Temperature = 0.5.

### Trial count
3 languages x C constraints (C=2-4 after pilot) x 3 tasks x 5 reps = 90-180 trials

## Chain protocol (replicates Air)

Each trial runs in a **temporary project directory** with a CLAUDE.md written in the target language.

1. Harness creates temp dir, writes `CLAUDE.md` containing:
   - Task description (in target language)
   - Constraint (in target language)
   - Explicit delegation instruction (in target language): "Delegate this task to a sub-agent, making sure to communicate all constraints."
2. Harness invokes `claude` CLI inside that directory (as the manager). The manager reads CLAUDE.md, then naturally uses the **Agent tool** to spawn a worker sub-agent.
3. Harness parses JSONL execution logs from `~/.claude/` to extract:
   - The delegation message (text passed to the Agent tool)
   - The worker's output (code produced)
4. Harness scores fidelity + compliance + delegation language.

Model: `claude-sonnet-4-6` (pinned for reproducibility).

Concurrency: **5 parallel trials** in separate temp directories. Managed via `concurrent.futures`.

## Translated prompts

### CLAUDE.md template per language

**EN:**
```
You are a senior developer. You receive a coding task with constraints. Delegate this task to a sub-agent, making sure to communicate all constraints.

Task: {task_description}

Constraint: {constraint}
```

**IT:**
```
Sei uno sviluppatore senior. Ricevi un compito di programmazione con dei vincoli. Delega questo compito a un sotto-agente, assicurandoti di comunicare tutti i vincoli.

Compito: {task_description}

Vincolo: {constraint}
```

**RU:**
```
Вы — старший разработчик. Вы получаете задание по программированию с ограничениями. Делегируйте это задание суб-агенту, обязательно сообщив все ограничения.

Задание: {task_description}

Ограничение: {constraint}
```

### Task descriptions

**cli_tool:**
- EN: "Write a Python command-line tool that reads a text file and prints the top N most frequent words and their counts. Accept filename and N as command-line arguments using argparse."
- IT: "Scrivi uno strumento Python da riga di comando che legga un file di testo e stampi le N parole più frequenti con i relativi conteggi. Accetta il nome del file e N come argomenti da riga di comando usando argparse."
- RU: "Напишите консольную утилиту на Python, которая читает текстовый файл и выводит N самых частых слов с их количеством. Принимайте имя файла и N как аргументы командной строки через argparse."

**data_pipeline:**
- EN: "Write a Python script that reads a CSV file, filters rows where a numeric column exceeds a threshold, computes summary statistics (mean, median, max) for that column, and writes the filtered data to a new CSV file. Use only the standard library."
- IT: "Scrivi uno script Python che legga un file CSV, filtri le righe in cui una colonna numerica supera una soglia, calcoli statistiche riassuntive (media, mediana, massimo) per quella colonna e scriva i dati filtrati in un nuovo file CSV. Usa solo la libreria standard."
- RU: "Напишите скрипт на Python, который читает CSV-файл, фильтрует строки, где числовой столбец превышает пороговое значение, вычисляет сводную статистику (среднее, медиану, максимум) для этого столбца и записывает отфильтрованные данные в новый CSV-файл. Используйте только стандартную библиотеку."

**rest_api:**
- EN: "Write a Python FastAPI application implementing a key-value store with GET /items/{key}, PUT /items/{key} (with JSON body), DELETE /items/{key}, and GET /items (list all). Store data in memory."
- IT: "Scrivi un'applicazione Python con FastAPI che implementi un archivio chiave-valore con GET /items/{key}, PUT /items/{key} (con corpo JSON), DELETE /items/{key} e GET /items (elenco completo). Memorizza i dati in memoria."
- RU: "Напишите приложение на Python с FastAPI, реализующее хранилище ключ-значение с эндпоинтами GET /items/{key}, PUT /items/{key} (с JSON-телом), DELETE /items/{key} и GET /items (список всех). Храните данные в памяти."

### Constraints

**`snake_case_vars`**
- EN: "All variable and function names must use snake_case."
- IT: "Tutti i nomi di variabili e funzioni devono usare snake_case."
- RU: "Все имена переменных и функций должны использовать snake_case."

**`no_global_vars`**
- EN: "Do not use any module-level mutable variables."
- IT: "Non usare variabili mutabili a livello di modulo."
- RU: "Не используйте изменяемые переменные на уровне модуля."

**`everything_oneliner`**
- EN: "Write every function as a single expression using a return statement on one line."
- IT: "Scrivi ogni funzione come una singola espressione con un'istruzione return su una riga."
- RU: "Запишите каждую функцию как одно выражение с оператором return в одну строку."

**`no_comments`**
- EN: "Do not include any comments in the code."
- IT: "Non includere alcun commento nel codice."
- RU: "Не включайте никаких комментариев в код."

## Code extraction

Worker output → Python code:
1. Find all fenced code blocks (` ```python ``` ` or ` ``` ``` `)
2. Concatenate all blocks into one string
3. If no fenced blocks, try to parse the entire output as Python
4. If nothing parses → trial is **unscoreable** (excluded from compliance denominator, parse failure rate reported separately)

## Scoring

### Fidelity
Pre-specified keyword manifest (frozen before trial 1). Per constraint, a list of keywords in all 3 languages. Fidelity = 1 if at least 1 keyword appears (case-insensitive substring match) in the delegation message; 0 otherwise.

```
snake_case_vars:     ["snake_case", "snake case"]
no_comments:         ["comment", "commenti", "комментар"]
no_global_vars:      ["global", "module", "модул", "modulo", "mutab", "изменяем"]
everything_oneliner: ["one line", "una riga", "одну строку", "одн строк",
                      "single expression", "singola espressione", "одно выражение"]
```

### Compliance
Deterministic, on extracted Python code:
- `snake_case_vars`: AST visit `Name` and `FunctionDef` nodes, check `^[a-z_][a-z0-9_]*$`. Exclude: dunder names, `ClassDef` names, stdlib builtins
- `no_global_vars`: AST check top-level `Assign`/`AnnAssign` targets, flag mutable types (list, dict, set, call)
- `everything_oneliner`: every `FunctionDef` body is exactly 1 `Return` statement
- `no_comments`: no `#` outside string literals (exclude shebang)

### Delegation language
Heuristic detection on manager's delegation message:
- Count Cyrillic chars (U+0400–U+04FF): >10 → RU
- Check for Italian function words ("della", "deve", "funzione", "ogni", "codice", "variabil"): ≥2 matches → IT
- Fallback: count Italian-accented chars (àèéìòù): >3 → IT
- Otherwise → EN

## Measured DVs
1. **Delegation language** — what language the manager wrote the delegation in
2. **Fidelity** — constraint keyword present in delegation message (binary)
3. **Compliance** — worker code satisfies constraint (binary, excluding unscoreable)
4. **Parse success** — whether code extraction yielded valid Python (binary)

## Execution plan

### Phase 1: Pilot (auto-gated)
- 3 languages x 3 tasks x 4 constraints x 1 rep = 36 trials
- 5 concurrent, ~5-10 min
- Purpose: screen constraints for usable EN baseline compliance (40-80%) and verify log parsing works
- Auto-gate checks:
  - Parse rate > 80% overall
  - At least 2 constraints have EN compliance in 40-80% range
  - JSONL log parsing successfully extracts delegation messages
- If checks pass → print pilot summary, auto-proceed to main run with surviving constraints
- If checks fail → stop, print diagnostics

### Phase 2: Main run
- Full factorial with surviving constraints, 5 reps per cell
- 5 concurrent trials in separate temp directories
- All raw outputs logged to JSONL
- Estimated runtime: ~20-40 min

### Phase 3: Analysis
- Print summary table: compliance and fidelity rates by language, by constraint
- Print delegation language switching rates
- Print parse failure rates
- Output raw results CSV

## Output artifacts
- `results.jsonl` — raw trial data (all inputs, outputs, scores, delegation messages)
- `results.csv` — tabular summary per trial
- `summary.txt` — printed summary table (compliance/fidelity by language x constraint)

## Done criteria
- [ ] Pilot runs and auto-gates correctly (with early results printed)
- [ ] Main run completes with all trials logged
- [ ] Summary table printed showing compliance/fidelity rates by language
- [ ] Delegation language switching rates reported
- [ ] Raw CSV written with all trial data
- [ ] Total cost < $15, total time < 1.5 hours
