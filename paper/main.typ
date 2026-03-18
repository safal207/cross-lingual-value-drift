// Cross-Lingual Constraint Compliance Under Sequential Delegation
// in AI Agent Chains

#set document(
  title: "Cross-Lingual Constraint Compliance Under Sequential Delegation in AI Agent Chains",
  author: ("Anonymous",),
  date: datetime(year: 2026, month: 3, day: 18),
)

#set page(
  paper: "us-letter",
  margin: (x: 1in, y: 1in),
  numbering: "1",
)

#set text(
  font: "New Computer Modern",
  size: 10pt,
)

#set par(
  justify: true,
  leading: 0.65em,
)

#set heading(numbering: "1.1")

#show heading.where(level: 1): it => {
  v(1.2em)
  text(size: 12pt, weight: "bold", it)
  v(0.6em)
}

#show heading.where(level: 2): it => {
  v(0.8em)
  text(size: 11pt, weight: "bold", it)
  v(0.4em)
}

// Title block
#align(center)[
  #text(size: 16pt, weight: "bold")[
    Cross-Lingual Constraint Compliance Under Sequential Delegation in AI Agent Chains
  ]
  #v(1em)
  #text(size: 11pt)[Anonymous]
  #v(0.3em)
  #text(size: 10pt, style: "italic")[March 18, 2026]
  #v(0.3em)
  #text(size: 9pt, fill: rgb("#555"))[Exploratory study · 252 trials across 2 runs · \$29.24 total cost]
]

#v(1.5em)

// Abstract
#align(center)[
  #block(width: 85%)[
    #text(weight: "bold")[Abstract.]
    When AI coding agents delegate tasks through manager--worker chains, safety constraints specified in the manager's instructions must survive the delegation handoff. Prior work has established high constraint fidelity (99.4%) in English-language chains. We investigate what happens when the _entire_ agent configuration is expressed in a non-English language (Italian or Russian). Across 252 trials in two experimental runs using Claude Code's native Agent tool with Claude Sonnet 4.6, we report three findings. First, the manager's delegation language is sensitive to the _trigger prompt_: when triggered in English ("Follow the instructions"), 100% of delegations are in English; when triggered in the target language, 26% of Italian and 14% of Russian delegations preserve the original language. Second, constraint fidelity remains near-perfect ($gt.eq$98%) regardless of language or trigger. Third, when compliance is measured proportionally (fraction of compliant symbols rather than binary pass/fail), apparent cross-lingual variation collapses: the everything-oneliner constraint achieves $approx$97.5% compliance uniformly across languages, revealing that binary scoring in Run 1 inflated small per-trial differences into large aggregate gaps. The dominant predictor of compliance remains constraint--task interaction (framework conventions), not input language.
  ]
]

#v(1.5em)

= Introduction

As large language model (LLM) agents are deployed in increasingly complex software engineering workflows, a common architectural pattern has emerged: _sequential delegation_, where a manager agent decomposes a task and delegates subtasks to worker agents. This pattern is native to tools like Claude Code, which provides an Agent tool for spawning sub-agents within a coding session.

A critical concern in such chains is _constraint survival_: when a user specifies safety or style constraints (e.g., "do not use global variables"), do those constraints propagate faithfully through the delegation handoff? Air #cite(<air2026>) demonstrated that in English-language Claude Code chains, constraint fidelity is remarkably high (99.4%), though compliance---whether the worker's code actually satisfies the constraint---lags at 94.3%, with constraint polarity as the dominant predictor.

However, software development is a global activity. Developers may naturally express constraints in their own language. What happens when the entire agent configuration is non-English? We designed a full-immersion experiment to test this, running two experimental runs that revealed three unexpected findings:

+ The manager's delegation language is not fixed---it is influenced by the language of the _trigger prompt_ (the `-p` argument to the CLI), creating a previously unreported confound in the experimental design itself.
+ Constraint fidelity is robust across languages ($gt.eq$98%), even when the manager preserves the non-English language in its delegation.
+ Binary compliance scoring (pass/fail per trial) inflates small per-function differences into large aggregate effects. When measured proportionally, cross-lingual compliance variation disappears.

= Related Work

== Value Drift in Agent Chains

Air #cite(<air2026>) conducted the most comprehensive study of constraint propagation in LLM agent chains to date. Using Claude Code's native Agent tool with 13 coding constraints, 5 Python tasks, 2 models (Opus and Sonnet 4.6), and 2 prompting conditions across 600 trials, they found that fidelity is effectively solved at 99.4%. Compliance averaged 94.3%, with constraint polarity as the dominant predictor: positive constraints ("do X") achieved 90.8% compliance versus 98.0% for negative constraints ("don't do X").

Our study extends this line of inquiry to the cross-lingual setting. We use a similar constraint taxonomy and scoring approach, inducing the same manager$arrow.r$worker chain through Claude Code's Agent tool. Our findings about fidelity ($gt.eq$98%) are consistent with Air's (99.4%), though direct numerical comparison requires caution given differences in constraint selection and trial count.

== Multilingual LLM Capabilities

Evaluation benchmarks consistently show LLM performance degradation on non-English tasks #cite(<ahuja2023mega>), with the gap widening for lower-resource languages. In the coding domain, multilingual code generation benchmarks #cite(<zheng2023codegeex>) show that prompting in English generally yields better code, though the gap has narrowed with newer models. Our study differs in that we do not measure raw code quality---the model generates functional code in all conditions---but whether _auxiliary style constraints_ survive the delegation chain when expressed in non-English languages.

== Principal-Agent Theory and AI Delegation

The manager--worker pattern maps onto classical principal--agent theory #cite(<jensen1976>), where information asymmetry between principal and agent can lead to goal misalignment. The manager's decision to translate constraints to English---rather than passing them through verbatim---is an example of editorial discretion over the communication channel. Whether this preserves or distorts user intent is a core empirical question.

= Method

== Design

We employed a full factorial design across two runs:

- *Language of agent configuration* (3 levels): English (EN), Italian (IT), Russian (RU)
- *Coding constraint* (2 levels after pilot screening): `no_global_vars`, `everything_oneliner`
- *Programming task* (3 levels): `cli_tool`, `data_pipeline`, `rest_api`
- *Trigger language* (2 levels, across runs): English trigger (Run 1) vs. native-language trigger (Run 2)

Each cell received 5 replications in the main run, plus 1 pilot replication. Each run comprised 36 pilot + 90 main = 126 trials, for 252 trials total.

== Full-Immersion Language Manipulation

For each language condition, all natural-language content presented to the manager agent was in the target language:

- The CLAUDE.md system file (role description, delegation instruction)
- The task description
- The constraint specification

For example, the Russian condition for `no_global_vars` with `rest_api` presented:

#block(
  fill: rgb("#f5f5f5"),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
)[
  #text(size: 9pt, font: "DejaVu Sans Mono")[
    Вы --- старший разработчик. Вы ДОЛЖНЫ делегировать задание ниже суб-агенту...

    Задание: Напишите приложение на Python с FastAPI...

    Ограничение: Не используйте изменяемые переменные на уровне модуля.
  ]
]

This eliminates the mixed-language confound present in designs where only the constraint is translated.

*Known limitation.* Claude Code's built-in English system prompt cannot be removed. The manager always sees English scaffolding underneath the target-language CLAUDE.md. This was constant across conditions and also present in Air's English-only study.

== Trigger Prompt: The Between-Run Variable

A key methodological discovery emerged between our two runs. Claude Code is invoked via `claude -p "<trigger>"`, where the trigger prompt bootstraps the session. In Run 1, the trigger was always English:

#block(fill: rgb("#f5f5f5"), inset: 10pt, radius: 4pt, width: 100%)[
  #text(size: 9pt, font: "DejaVu Sans Mono")[
    claude -p "Follow the instructions in CLAUDE.md" ...
  ]
]

In Run 2, the trigger was translated to the target language:

#block(fill: rgb("#f5f5f5"), inset: 10pt, radius: 4pt, width: 100%)[
  #text(size: 9pt, font: "DejaVu Sans Mono")[
    EN: "Follow the instructions in CLAUDE.md" \
    IT: "Segui le istruzioni nel CLAUDE.md" \
    RU: "Пожалуйста, следуй промпту в CLAUDE.md"
  ]
]

This seemingly minor change had a dramatic effect on delegation language (§4.1).

== Agent Chain Protocol

Each trial executed the following steps:

+ *Setup.* Create a temporary directory. Write CLAUDE.md in the target language.
+ *Manager invocation.* Invoke `claude -p "<trigger>" --model claude-sonnet-4-6 --output-format json --dangerously-skip-permissions --allowedTools "Agent" --max-budget-usd 0.50` in the temporary directory. The `--allowedTools "Agent"` restriction ensured the manager could _only_ delegate.
+ *Worker execution.* The worker sub-agent receives the manager's delegation message and writes Python code.
+ *Extraction.* Parse JSONL session logs to extract the delegation message and worker code.
+ *Scoring.* Score fidelity, compliance, and delegation language deterministically.

Model: Claude Sonnet 4.6. Concurrency: up to 5 parallel trials.

== Tasks

Three Python tasks spanning a range of complexity:

/ `cli_tool`: A command-line word frequency counter using `argparse`.
/ `data_pipeline`: CSV filtering + summary statistics, stdlib only.
/ `rest_api`: FastAPI key-value store with CRUD endpoints. Retained despite known framework friction.

== Constraints

Four candidates from Air's taxonomy, screened by pilot:

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, center),
    [*ID*], [*English text*], [*Polarity*],
    [`snake_case_vars`], [All variable and function names must use snake_case.], [+],
    [`no_global_vars`], [Do not use any module-level mutable variables.], [--],
    [`everything_oneliner`], [Write every function as a single expression using a return statement on one line.], [+],
    [`no_comments`], [Do not include any comments in the code.], [--],
  ),
  caption: [Candidate constraint set.],
) <tab:constraints>

Each was translated into Italian and Russian. Both runs screened identically: `snake_case_vars` and `no_comments` hit 100% ceiling compliance and were excluded; `no_global_vars` and `everything_oneliner` survived.

== Scoring <scoring>

All scoring was deterministic, with no LLM-based judges.

=== Compliance: Binary (Run 1) vs. Proportional (Run 2)

Run 1 used _binary_ compliance: a trial passes only if _every_ symbol satisfies the constraint (matching Air's methodology). Run 2 used _proportional_ compliance: the fraction of compliant elements (e.g., 8/10 functions as one-liners = 0.80). The change was motivated by a concern that binary scoring compresses partial compliance into failure, potentially inflating apparent cross-lingual differences.

Proportional metrics per constraint:
- *`snake_case_vars`*: fraction of variable/function names matching `^[a-z_][a-z0-9_]*$` (excluding dunders, class names).
- *`no_global_vars`*: fraction of module-level assignments that are _not_ mutable (list, dict, set, call).
- *`everything_oneliner`*: fraction of `FunctionDef` bodies that are a single `Return` statement.
- *`no_comments`*: fraction of non-empty lines that are comment-free.

=== Fidelity and Delegation Language

Fidelity: keyword matching against a pre-specified manifest (frozen before trial 1), case-insensitive, covering keywords in all three languages.

Delegation language: heuristic detection (Cyrillic count for Russian, Italian function words + accented characters for Italian, English otherwise).

= Results

252 trials total (126 per run), \$29.24 total cost, 248 scoreable (98.4%).

== Delegation Language: Trigger Sensitivity <deleg_lang>

The most striking finding is the sensitivity of delegation language to the trigger prompt:

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    table.header([], table.cell(colspan: 2)[*Run 1 (English trigger)*], table.cell(colspan: 2)[*Run 2 (Native trigger)*]),
    [*Input*], [*→ EN*], [*→ other*], [*→ EN*], [*→ other*],
    [EN], [42 (100%)], [0], [42 (100%)], [0],
    [IT], [42 (100%)], [0], [31 (74%)], [11 (26%)],
    [RU], [42 (100%)], [0], [36 (86%)], [6 (14%)],
  ),
  caption: [Delegation language by input language and trigger condition. "Other" means the manager delegated in the input language (Italian or Russian).],
) <tab:lang_switch>

With an English trigger, the manager _always_ delegates in English---100% across all 126 trials, regardless of CLAUDE.md language. With a native-language trigger, 26% of Italian and 14% of Russian delegations preserve the original language. The trigger prompt---a single short sentence---acts as a language prior that the manager follows for its entire output.

This has methodological implications: any experiment measuring cross-lingual delegation behavior must control or vary the trigger language, as it is a confound that can suppress the very effect being studied.

== Fidelity

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    table.header([*Constraint*], [*EN*], [*IT*], [*RU*], [*Overall*]),
    table.cell(colspan: 5)[*Run 1 (binary, English trigger)*],
    [`no_global_vars`], [18/18], [18/18], [18/18], [54/54],
    [`everything_oneliner`], [18/18], [18/18], [18/18], [54/54],
    table.cell(colspan: 5)[*Run 2 (proportional, native trigger)*],
    [`no_global_vars`], [18/18], [18/18], [18/18], [54/54],
    [`everything_oneliner`], [18/18], [18/18], [17/18], [53/54],
  ),
  caption: [Constraint fidelity across runs. Near-perfect in both. One Russian trial in Run 2 dropped the everything\_oneliner constraint.],
) <tab:fidelity>

Fidelity was 100% in Run 1 and 98% in Run 2 (one Russian `everything_oneliner` trial lost the constraint keyword during delegation). This is consistent with Air's 99.4% and confirms that constraint communication is robust across languages.

== Compliance: Binary vs. Proportional Scoring

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, center, center, center),
    table.header([*Constraint*], [*EN*], [*IT*], [*RU*]),
    table.cell(colspan: 4)[*Run 1 — binary scoring (pass/fail)*],
    [`no_global_vars`], [66.7%], [66.7%], [66.7%],
    [`everything_oneliner`], [71%], [82%], [61%],
    table.cell(colspan: 4)[*Run 2 — proportional scoring (fraction compliant)*],
    [`no_global_vars`], [66.7%], [66.7%], [66.7%],
    [`everything_oneliner`], [97.5%], [98.0%], [97.0%],
  ),
  caption: [Compliance by language and constraint across both runs. Binary scoring in Run 1 showed apparent cross-lingual variance for everything\_oneliner (IT 82% > EN 71% > RU 61%). Proportional scoring in Run 2 reveals this was an artifact: mean proportional compliance is $approx$97.5% uniformly.],
) <tab:compliance>

=== The binary scoring artifact

The most instructive comparison across runs is `everything_oneliner`. Under binary scoring (Run 1), the IT > EN > RU pattern (82% > 71% > 61%) appeared to show meaningful cross-lingual variance. Under proportional scoring (Run 2), this collapses to $approx$97.5% uniform compliance with CIs of [0.94, 1.00] across all three languages.

The mechanism: most trials have nearly all functions as one-liners, with 1--2 failures in a file of 5--8 functions. Binary scoring converts "7/8 functions compliant" to 0 (fail), while proportional scoring records 0.875. A trial where Russian produced 6/8 compliant functions and Italian produced 7/8 both look like failures under binary scoring, exaggerating the gap. Proportional scoring reveals that both are near-ceiling.

=== `no_global_vars`: Structural invariance

`no_global_vars` remained at exactly 66.7% across all conditions in both runs. Task-level decomposition reveals the mechanism:

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, center, center, center),
    [*Task*], [*EN*], [*IT*], [*RU*],
    [`cli_tool`], [6/6 (100%)], [6/6 (100%)], [6/6 (100%)],
    [`data_pipeline`], [6/6 (100%)], [6/6 (100%)], [6/6 (100%)],
    [`rest_api`], [0/6 (0%)], [0/6 (0%)], [0/6 (0%)],
  ),
  caption: [`no_global_vars` compliance by task (both runs identical). FastAPI's `app = FastAPI()` drives 100% of violations.],
) <tab:noglobal_task>

Every `rest_api` trial uses `app = FastAPI()` at module level---the only way to create a FastAPI application. This framework convention overrides the constraint in 100% of cases, regardless of language.

== Parse Success and Cost

Parse success: 248/252 (98.4%) across both runs, with no language-dependent pattern. Total cost: \$29.24 (\$14.66 Run 1, \$14.58 Run 2), averaging \$0.116/trial.

= Discussion

== Trigger Prompt as Language Prior

Our most unexpected finding is methodological: the language of the trigger prompt (`claude -p "<trigger>"`) acts as a strong prior for the manager's output language. An English trigger produced 100% English delegation even when all other content was Italian or Russian. A native-language trigger allowed 14--26% of delegations to preserve the input language.

This has implications beyond our experiment. Any measurement of multilingual agent behavior that uses a fixed English trigger risks suppressing the phenomenon it aims to study. The trigger is easy to overlook---it is infrastructure, not content---but it sets the language frame for the entire session.

== Binary Scoring Inflates Cross-Lingual Differences

The Run 1 → Run 2 comparison demonstrates how binary compliance scoring can create spurious patterns. The `everything_oneliner` constraint showed IT 82% > EN 71% > RU 61% under binary scoring---a 21 percentage point spread that looked like meaningful cross-lingual variance. Under proportional scoring, this collapses to a 1 percentage point spread (97.0%--98.0%), well within noise.

The inflation mechanism is straightforward: when most trials are near-ceiling (e.g., 7/8 functions compliant), binary scoring is maximally sensitive to small absolute differences. One additional non-compliant function flips the entire trial from pass to fail. Air #cite(<air2026>) used binary scoring, which was appropriate for their research question (constraint survival as a safety property). But for measuring _degree_ of compliance across conditions, proportional scoring provides more accurate estimates.

== Framework Conventions Dominate

Across both runs, the dominant compliance predictor was the constraint × task interaction, not input language. The `no_global_vars` constraint showed _exact_ numerical uniformity (67%) across all six language × run conditions, with all variance attributable to FastAPI's `app = FastAPI()` idiom. This is not an instruction-following failure---it is a structural incompatibility between the constraint and the framework.

This has practical implications for constraint design: constraints that conflict with framework conventions will fail at the same rate regardless of language, fidelity, or prompting strategy. Effective constraints must be _feasible_ given the task's framework requirements.

== Limitations

*Small N per cell.* With $N = 5$ replications and 17--18 scoreable trials per language×constraint cell, the study lacks power for moderate effects. However, the near-uniformity of proportional compliance ($approx$97.5%) suggests that any real cross-lingual effect is small.

*Two surviving constraints.* Pilot screening reduced the constraint space from 4 to 2, limiting generalizability.

*Single model.* All trials used Claude Sonnet 4.6. Other models may exhibit different delegation language behavior.

*Between-run confound.* The trigger language and scoring metric changed simultaneously between runs. While we attribute the compliance difference to scoring (the data support this interpretation), a fully controlled design would vary these independently.

*English system prompt.* Claude Code's built-in English system prompt was present in all conditions and may facilitate English delegation.

= Conclusion

Across 252 trials in two runs, we found that cross-lingual constraint compliance in AI agent chains is shaped more by methodology than by language. The trigger prompt language determines whether the manager delegates in English or preserves the input language. Binary scoring inflates small per-function differences into apparent cross-lingual gaps that disappear under proportional measurement. And the dominant compliance predictor is the structural interaction between constraint and task framework, not the language of instruction.

For practitioners deploying multilingual agent chains: constraint fidelity is robust ($gt.eq$98%) regardless of language, and proportional compliance shows no meaningful cross-lingual degradation. The manager acts as a normalizing layer that translates and preserves constraint content. The practical risk is not that constraints are lost in translation, but that they conflict with framework conventions---a language-independent failure mode.

For researchers: trigger prompt language is a confound that must be controlled, and binary compliance scoring can create artifacts in cross-condition comparisons. We recommend proportional scoring as the default for constraint compliance measurement.

// References
#bibliography("refs.yml")
