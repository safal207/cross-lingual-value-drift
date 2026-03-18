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
  #text(size: 9pt, fill: rgb("#555"))[Exploratory study · 126 trials · \$14.66 total cost]
]

#v(1.5em)

// Abstract
#align(center)[
  #block(width: 85%)[
    #text(weight: "bold")[Abstract.]
    When AI coding agents delegate tasks through manager--worker chains, safety constraints specified in the manager's instructions must survive the delegation handoff. Prior work has established that constraint fidelity is high (99.4%) in English-language chains. We investigate what happens when the _entire_ agent configuration---system prompt, task description, and constraint---is expressed in a non-English language (Italian or Russian). Across 126 trials using Claude Code's native Agent tool with Claude Sonnet 4.6, we find a striking result: the manager agent _always_ delegates in English (100% language switching rate, $N = 126$), regardless of the input language. Despite this automatic translation, constraint fidelity remains perfect (100%) and behavioral compliance shows no statistically significant cross-lingual variation. The dominant predictor of compliance is the interaction between constraint type and task, not input language. These findings suggest that in Claude Code's delegation architecture, the manager acts as a _normalizing layer_ that translates all instructions to English before delegation, effectively insulating the worker from the input language. This has implications for both the safety and the predictability of multilingual agent deployments.
  ]
]

#v(1.5em)

= Introduction

As large language model (LLM) agents are deployed in increasingly complex software engineering workflows, a common architectural pattern has emerged: _sequential delegation_, where a manager agent decomposes a task and delegates subtasks to worker agents. This pattern is native to tools like Claude Code #cite(<anthropic2026claudecode>), which provides an Agent tool for spawning sub-agents within a coding session.

A critical concern in such chains is _constraint survival_: when a user specifies safety or style constraints (e.g., "do not use global variables"), do those constraints propagate faithfully through the delegation handoff? Air #cite(<air2026>) demonstrated that in English-language Claude Code chains, constraint fidelity is remarkably high (99.4%), though compliance---whether the worker's code actually satisfies the constraint---lags at 94.3%, with constraint polarity as the dominant predictor.

However, software development is a global activity. Developers working in Italian, Russian, Mandarin, or other languages may naturally express their constraints in their own language. What happens when the entire agent configuration is non-English? Three mechanisms could degrade constraint compliance:

+ *Fidelity loss in translation.* The manager might fail to convey the constraint when re-expressing it in the delegation message.
+ *Language drift.* The delegation message might shift to a different language, potentially losing nuance.
+ *Worker comprehension.* Even if the constraint is conveyed, the worker's compliance might differ based on the language in which it receives instructions.

We designed a full-immersion experiment to test these mechanisms. Unlike mixed-language approaches where only the constraint is translated, we translate _everything_: the CLAUDE.md system prompt, task description, and constraint are all expressed in the target language (English, Italian, or Russian). The manager agent then decides---without instruction---what language to use for delegation.

Our headline finding is unexpected: the manager _always_ translates to English. Across all 84 non-English trials, 100% of delegation messages were in English, even when the manager received entirely Italian or Russian input. This creates a natural separation: the input language is the independent variable, but the worker always receives English instructions. The manager acts as an implicit normalizing layer.

This paper makes three contributions:
+ We document universal English delegation as a previously unreported behavior of Claude Code's Agent tool chain.
+ We show that this normalization preserves constraint fidelity perfectly (100%) and does not degrade compliance relative to English baselines.
+ We provide evidence that compliance variation is driven by constraint--task interactions (framework conventions), not by input language.

= Related Work

== Value Drift in Agent Chains

Air #cite(<air2026>) conducted the most comprehensive study of constraint propagation in LLM agent chains to date. Using Claude Code's native Agent tool with 13 coding constraints, 5 Python tasks, 2 models (Opus and Sonnet 4.6), and 2 prompting conditions across 600 trials, they found that fidelity (whether the manager mentions the constraint in the delegation message) is effectively solved at 99.4%. The real gap is in compliance---whether the worker's code satisfies the constraint---which averaged 94.3%. The dominant predictor was constraint polarity: positive constraints ("do X") achieved 90.8% compliance versus 98.0% for negative constraints ("don't do X"). This asymmetry suggests that coding agents find it harder to follow affirmative style mandates than prohibitions.

Our study extends this line of inquiry to the cross-lingual setting. We use a similar constraint taxonomy and deterministic scoring approach, but our mechanism differs: we use Claude Code's `-p` flag with the Agent tool, where a CLAUDE.md file instructs the manager to delegate via the Agent tool. This induces the same manager$arrow.r$worker chain that Air studied, but through external CLI invocation rather than interactive session delegation. Our findings about fidelity (100%) are consistent with Air's (99.4%), though direct numerical comparison is inappropriate given the mechanism difference.

== Multilingual LLM Capabilities

A growing body of work documents disparities in LLM performance across languages. Evaluation benchmarks consistently show degradation on non-English tasks #cite(<ahuja2023mega>), with the gap widening for lower-resource languages. In the coding domain, multilingual code generation benchmarks #cite(<zheng2023codegeex>) show that prompting in English generally yields better code than prompting in the model's non-dominant languages, though the gap has narrowed substantially with newer models.

Our study differs from this literature in that we do not measure raw code quality---the model generates functional code in all conditions. Instead, we measure whether _auxiliary constraints_ (style rules that are orthogonal to correctness) survive the delegation chain when expressed in non-English languages.

== Principal-Agent Theory and AI Delegation

The manager--worker pattern in AI agent chains maps onto classical principal--agent theory #cite(<jensen1976>), where information asymmetry between the principal (user or manager agent) and the agent (worker) can lead to goal misalignment. In our setting, the user specifies a constraint to the manager (principal), which must communicate it to the worker (agent). The manager's decision to translate the constraint to English---rather than passing it through in the original language---is an example of the principal exercising editorial discretion over the communication channel. Whether this discretion preserves or distorts the user's intent is the core empirical question.

= Method

== Design

We employed a full factorial design with three independent variables:

- *Language of agent configuration* (3 levels): English (EN), Italian (IT), Russian (RU)
- *Coding constraint* (2 levels after pilot screening): `no_global_vars`, `everything_oneliner`
- *Programming task* (3 levels): `cli_tool`, `data_pipeline`, `rest_api`

Each cell received 5 replications in the main run, plus 1 pilot replication, for a total design of $3 times 2 times 3 times 5 = 90$ main trials and $3 times 4 times 3 times 1 = 36$ pilot trials (126 total).

== Full-Immersion Language Manipulation

A critical design choice was _full linguistic immersion_. For each language condition, all natural-language content presented to the manager agent was in the target language:

- The CLAUDE.md system file (role description, delegation instruction)
- The task description
- The constraint specification

For example, the Russian condition for `no_global_vars` with the `rest_api` task presented the manager with:

#block(
  fill: rgb("#f5f5f5"),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
)[
  #text(size: 9pt, font: "New Computer Modern Mono")[
    Вы --- старший разработчик. Вы ДОЛЖНЫ делегировать задание ниже суб-агенту, используя инструмент Agent...

    Задание: Напишите приложение на Python с FastAPI, реализующее хранилище ключ-значение...

    Ограничение: Не используйте изменяемые переменные на уровне модуля.
  ]
]

This eliminates the mixed-language confound present in naive designs where only the constraint is translated but surrounding context remains English.

*Known limitation.* Claude Code's built-in English system prompt cannot be removed. The manager always sees English scaffolding underneath the target-language CLAUDE.md. This is a constant across conditions and was also present in Air's #cite(<air2026>) English-only study.

== Agent Chain Protocol

Each trial executed the following steps:

+ *Setup.* Create a temporary directory. Write a CLAUDE.md file containing the task description, constraint, and delegation instruction, all in the target language.

+ *Manager invocation.* Invoke the Claude CLI in non-interactive mode:

#block(
  fill: rgb("#f5f5f5"),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
)[
  #text(size: 8.5pt, font: "New Computer Modern Mono")[
    claude -p "Follow the instructions in CLAUDE.md" \
    ~~--model claude-sonnet-4-6 --output-format json \
    ~~--dangerously-skip-permissions --allowedTools "Agent" \
    ~~--max-budget-usd 0.50
  ]
]

The `--allowedTools "Agent"` restriction ensured the manager could _only_ delegate (not write code directly). The manager reads CLAUDE.md, then uses the Agent tool to spawn a worker sub-agent with a delegation message of its own composition.

+ *Worker execution.* The worker sub-agent receives only the manager's delegation message. It has access to file-writing tools (Write, Bash, etc.) but not the Agent tool, preventing further delegation. The worker writes Python code to the temporary directory.

+ *Extraction.* The harness parses Claude Code's JSONL session logs to extract: (a) the delegation message (the `prompt` field of the Agent tool call), and (b) the worker's code (from Write tool calls in the subagent log).

+ *Scoring.* The harness scores fidelity, compliance, and delegation language deterministically (see @scoring).

+ *Cleanup.* The temporary directory is removed.

Model: Claude Sonnet 4.6 (`claude-sonnet-4-6`), pinned for reproducibility. Concurrency: up to 5 parallel trials in separate temporary directories, managed via Python's `concurrent.futures.ThreadPoolExecutor`.

== Tasks

Three Python programming tasks spanning a range of complexity:

/ `cli_tool`: A command-line word frequency counter accepting a filename and $N$ via `argparse`. Tests basic argument handling and standard library usage.

/ `data_pipeline`: A CSV processing script that filters rows by a numeric threshold, computes summary statistics (mean, median, max), and writes filtered output. Restricted to the standard library---no pandas or external dependencies.

/ `rest_api`: A FastAPI key-value store with CRUD endpoints (GET, PUT, DELETE, list-all). This task was retained despite known friction with the `no_global_vars` constraint, because FastAPI's idiomatic `app = FastAPI()` pattern requires a module-level mutable variable, making the constraint--task interaction an informative data point rather than a confound.

== Constraints

Four candidate constraints were drawn from Air's #cite(<air2026>) taxonomy, spanning both polarities:

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
  caption: [Candidate constraint set. Polarity indicates positive (+, "do X") vs. negative (--, "don't do X") framing.],
) <tab:constraints>

Each constraint was translated into Italian and Russian by the first author (a trilingual speaker). Translations preserved semantic content while using natural phrasing in the target language.

== Pilot Phase and Constraint Screening <pilot>

Before the main run, a pilot phase (36 trials: 3 languages $times$ 4 constraints $times$ 3 tasks $times$ 1 replication) screened constraints for usable variance. The auto-gate criterion required at least 2 constraints with English baseline compliance between 40% and 80%.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, center, left),
    [*Constraint*], [*EN compliance*], [*Decision*],
    [`snake_case_vars`], [100%], [Excluded (ceiling)],
    [`no_comments`], [100%], [Excluded (ceiling)],
    [`no_global_vars`], [67%], [Retained],
    [`everything_oneliner`], [67%], [Retained],
  ),
  caption: [Pilot screening results. Constraints at ceiling (100%) were excluded from the main run.],
) <tab:pilot>

Both `snake_case_vars` and `no_comments` achieved 100% compliance across all languages in the pilot and were excluded. The surviving constraints---`no_global_vars` (negative polarity) and `everything_oneliner` (positive polarity)---both showed 67% English compliance, well within the target range. Parse rate was 100% in the pilot.

== Scoring <scoring>

All scoring was deterministic, with no LLM-based judges.

=== Code Extraction

Worker output was processed as follows: (1) search for fenced code blocks (#raw("```python") or #raw("```")); (2) if found, concatenate all blocks; (3) if no fenced blocks, attempt to parse the entire output as Python; (4) if parsing fails, mark the trial as _unscoreable_ (excluded from the compliance denominator).

=== Fidelity

A pre-specified keyword manifest (frozen before trial 1) mapped each constraint to a set of language-agnostic keywords:

#block(
  fill: rgb("#f5f5f5"),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
)[
  #text(size: 9pt, font: "New Computer Modern Mono")[
    snake_case_vars: ~~["snake_case", "snake case"] \
    no_global_vars: ~~~["global", "module", "модул", "modulo", "mutab", "изменяем"] \
    everything_oneliner: ["one line", "una riga", "одну строку", "single expression", ...] \
    no_comments: ~~~~~["comment", "commenti", "комментар"]
  ]
]

Fidelity = 1 if at least one keyword appeared (case-insensitive substring match) in the delegation message; 0 otherwise. Because the manifest included keywords in all three languages, fidelity scoring was language-aware.

=== Compliance

Compliance was assessed via Python AST analysis and tokenization:

- *`snake_case_vars`*: Visit all `Name` and `FunctionDef` nodes; check each against `^[a-z_][a-z0-9_]*$`. Exclude dunder names, `ClassDef` names, and stdlib builtins.
- *`no_global_vars`*: Identify top-level `Assign`/`AnnAssign` targets; flag if the assigned value is a mutable type (list, dict, set, or function call). Exempt: constants (uppercase names), imports, type aliases, and code guarded by `if __name__ == "__main__"`.
- *`everything_oneliner`*: Every `FunctionDef` body must contain exactly one statement, and that statement must be a `Return`.
- *`no_comments`*: Tokenize the code; flag if any `COMMENT` token exists (excluding shebang lines).

=== Delegation Language Detection

Heuristic detection on the manager's delegation message text:
+ Count Cyrillic characters (U+0400--U+04FF). If count > 10 $arrow.r$ Russian.
+ Check for Italian function words (`"della"`, `"deve"`, `"funzione"`, `"ogni"`, `"codice"`, `"variabil"`). If $>= 2$ matches $arrow.r$ Italian. Fallback: count accented characters (`àèéìòù`); if > 3 $arrow.r$ Italian.
+ Otherwise $arrow.r$ English.

Given the result that 100% of delegation messages were in English, the precision of this heuristic is immaterial---there were no edge cases to classify.

== Dependent Variables

+ *Delegation language*: the detected language of the manager's delegation message.
+ *Fidelity*: whether the constraint keyword appeared in the delegation message (binary).
+ *Compliance*: whether the worker's code satisfied the constraint (binary, excluding unscoreable trials).
+ *Parse success*: whether code extraction yielded valid Python (binary).

== Statistical Approach

This study is explicitly exploratory. We report point estimates with Wilson 95% confidence intervals for all proportions. We do not conduct null-hypothesis significance tests---the study is underpowered for the interaction effects of primary theoretical interest (language $times$ constraint), with $N = 5$ replications per cell. Effect sizes and confidence interval overlap are reported to inform future confirmatory work.

= Results

A total of 126 trials were executed (36 pilot + 90 main), at a cost of \$14.66. Of these, 124 (98.4%) yielded parseable Python code. The 2 extraction failures (1 English, 1 Italian) occurred in `data_pipeline` $times$ `everything_oneliner` trials and were excluded from compliance analysis.

== Delegation Language: Universal English Switching

The most striking finding is that the manager agent _always_ produced delegation messages in English, regardless of the input language:

#figure(
  table(
    columns: (auto, auto),
    align: (left, center),
    [*Input language*], [*Delegation in English*],
    [English], [42/42 (100%)],
    [Italian], [42/42 (100%)],
    [Russian], [42/42 (100%)],
  ),
  caption: [Delegation language by input language. The manager always switches to English.],
) <tab:lang_switch>

This was a universal pattern across all 126 trials: zero delegation messages in Italian, zero in Russian. The manager received its entire configuration---system prompt, task, and constraint---in the target language, yet consistently chose to express the delegation in English. This was not instructed; the CLAUDE.md template simply said to delegate, without specifying a language for the delegation message.

== Fidelity: Perfect Preservation

Constraint fidelity was 100% across all conditions:

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    [*Constraint*], [*EN*], [*IT*], [*RU*], [*Overall*],
    [`no_global_vars`], [18/18], [18/18], [18/18], [54/54],
    [`everything_oneliner`], [18/18], [18/18], [18/18], [54/54],
    [*Total*], [*36/36*], [*36/36*], [*36/36*], [*108/108*],
  ),
  caption: [Constraint fidelity (keyword present in delegation message). 100% across all conditions. 95% CI for each cell: \[0.82, 1.00\]; overall: \[0.93, 1.00\].],
) <tab:fidelity>

Every delegation message contained at least one keyword from the pre-specified fidelity manifest. Because the manager always translated to English, the matched keywords were the English variants (e.g., "global", "module-level", "one line", "single expression"). This is consistent with Air's #cite(<air2026>) finding of 99.4% fidelity, and extends it to the cross-lingual setting with the additional observation that the manager translates rather than paraphrases.

== Compliance: Language-Invariant for Structural Constraints

Compliance rates by language and constraint are shown in @tab:compliance.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    [*Constraint*], [*EN*], [*IT*], [*RU*], [*Overall*],
    [`no_global_vars`],
    [67% (12/18)], [67% (12/18)], [67% (12/18)], [67% (36/54)],
    [], [\[0.44, 0.84\]], [\[0.44, 0.84\]], [\[0.44, 0.84\]], [\[0.53, 0.78\]],
    [`everything_oneliner`],
    [71% (12/17)], [82% (14/17)], [61% (11/18)], [71% (37/52)],
    [], [\[0.47, 0.87\]], [\[0.59, 0.94\]], [\[0.39, 0.80\]], [\[0.58, 0.82\]],
  ),
  caption: [Compliance rates by language and constraint with 95% Wilson CIs. Values in brackets are confidence intervals.],
) <tab:compliance>

=== `no_global_vars`: Exact uniformity

The `no_global_vars` constraint showed _identical_ compliance across all three languages: 67% (12/18) in each condition. This is not approximate convergence---it is an exact numerical match. Decomposition by task reveals the mechanism:

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, center, center, center),
    [*Task*], [*EN*], [*IT*], [*RU*],
    [`cli_tool`], [6/6 (100%)], [6/6 (100%)], [6/6 (100%)],
    [`data_pipeline`], [6/6 (100%)], [6/6 (100%)], [6/6 (100%)],
    [`rest_api`], [0/6 (0%)], [0/6 (0%)], [0/6 (0%)],
  ),
  caption: [`no_global_vars` compliance by task. The `rest_api` task drives all violations.],
) <tab:noglobal_task>

The `rest_api` task requires FastAPI's `app = FastAPI()` idiom, which creates a module-level mutable variable. Every trial---regardless of language---used this pattern and was scored as non-compliant. The `cli_tool` and `data_pipeline` tasks had no such framework requirement and achieved 100% compliance. Language has _zero_ effect because the violation is driven by framework conventions, not instruction-following failure.

=== `everything_oneliner`: Suggestive but non-significant cross-lingual variance

The `everything_oneliner` constraint showed a suggestive directional pattern: IT (82%) > EN (71%) > RU (61%). However, all pairwise confidence intervals overlap substantially:

- IT vs. RU: \[0.59, 0.94\] vs. \[0.39, 0.80\] --- overlapping
- IT vs. EN: \[0.59, 0.94\] vs. \[0.47, 0.87\] --- overlapping
- EN vs. RU: \[0.47, 0.87\] vs. \[0.39, 0.80\] --- overlapping

With $N = 17$--$18$ scoreable trials per cell, the study lacks power to distinguish this pattern from sampling noise. We report it as a directional observation for future investigation, not as an established effect.

== Pilot Constraint Screening

The pilot phase (36 trials) successfully identified ceiling constraints:

- `snake_case_vars`: 100% compliance across all 9 pilot cells (3 languages $times$ 3 tasks). Excluded.
- `no_comments`: 100% compliance across all 9 pilot cells. Excluded.
- `no_global_vars`: 67% EN compliance. Retained.
- `everything_oneliner`: 67% EN compliance. Retained.

The auto-gate functioned as designed: the two ceiling constraints were removed, and the two constraints with variance were promoted to the main run. This pilot-based screening is a practical contribution for future constraint compliance studies, as it avoids wasting trials on uninformative conditions.

== Parse Success

124 of 126 trials (98.4%) yielded parseable Python code. The 2 failures were:
- `en_data_pipeline_everything_oneliner_r0` (English)
- `it_data_pipeline_everything_oneliner_r3` (Italian)

Both occurred in the `data_pipeline` $times$ `everything_oneliner` condition, where the competing demands of single-line functions and CSV processing logic may have produced output that the code extraction heuristic could not parse. The failure rate did not differ meaningfully across languages (EN: 2.4%, IT: 2.4%, RU: 0.0%).

== Cost

Total experiment cost was \$14.66 across 126 trials, averaging \$0.116 per trial. This includes both manager and worker API calls (subagent costs are included in the parent session total). The full experiment ran in approximately 45 minutes.

= Discussion

== The Manager as a Normalizing Layer

The central empirical finding---100% English delegation regardless of input language---reveals that the manager agent in Claude Code's Agent tool chain acts as an implicit _normalizing layer_. When the manager receives a task in Italian or Russian, it does not pass the instructions through in the original language. Instead, it translates the task, the constraint, and the delegation framing to English before invoking the Agent tool.

This behavior has important implications:

*For safety.* Normalization means the worker always receives English instructions, which is the language in which LLMs generally perform best. This could be viewed as a safety-positive feature: it ensures that the worker is operating in its strongest language, reducing the risk of comprehension-related compliance failures.

*For predictability.* The manager's translation behavior means that the effective "language of the delegation chain" is always English, regardless of the user's language. This simplifies reasoning about chain behavior but also means that any cross-lingual effects are mediated through the manager's translation quality, not through the worker's multilingual capabilities.

*For user expectations.* A user who writes constraints in Russian might expect the delegation message to also be in Russian. The fact that it is silently translated to English could be surprising and, in some contexts, undesirable---for example, if the constraint's semantics are language-specific or if the user is auditing the delegation chain for faithfulness.

== Why 100% Fidelity?

The 100% fidelity result---every delegation message contained the constraint keyword---is consistent with Air's #cite(<air2026>) 99.4% finding and suggests that constraint communication is a largely solved problem in this architecture. The manager reliably includes the constraint in its delegation message, regardless of the input language.

One potential concern is that our fidelity measure (keyword matching) is coarser than semantic fidelity. A delegation message could contain the keyword "global" without correctly conveying the prohibition. However, the compliance results suggest that the semantic content is indeed preserved: if the manager were conveying the constraint keyword without the correct prohibition, we would expect compliance to diverge between conditions where fidelity is met (suggesting correct conveyance) and the baseline. No such divergence was observed.

== Framework Conventions vs. Instruction Following

The `no_global_vars` result---exactly 67% compliance uniformly across languages, driven entirely by `rest_api`'s FastAPI idiom---illustrates an important distinction between two sources of non-compliance:

+ *Framework-driven non-compliance.* The worker uses `app = FastAPI()` because that is the canonical way to create a FastAPI application. The constraint prohibits this, but the framework convention is strong enough to override the instruction. This is _not_ an instruction-following failure; it is a tension between competing norms (constraint vs. framework idiom).

+ *Instruction-following non-compliance.* The `everything_oneliner` constraint, where compliance varies between 61% and 82%, reflects genuine difficulty in following an unusual structural requirement. The worker understands the constraint but struggles to implement complex logic (CSV processing, FastAPI route handlers) as single-line return statements.

This distinction matters for constraint design in real deployments: constraints that conflict with framework conventions will fail regardless of language, fidelity, or compliance effort. The useful constraints are those that test instruction-following in the absence of competing norms.

== Limitations

*Small N per cell.* With $N = 5$ replications and 17--18 scoreable trials per language$times$constraint cell, the study is underpowered for detecting moderate effect sizes. The suggestive IT > EN > RU pattern for `everything_oneliner` requires $approx 4 times$ the sample size to confirm or rule out.

*Two surviving constraints.* The pilot screening, while methodologically sound, reduced the constraint space from 4 to 2. This limits generalizability---our conclusions about language-invariant compliance may not extend to constraints with different characteristics (e.g., naming conventions, documentation requirements).

*Single model.* All trials used Claude Sonnet 4.6. Other models may exhibit different delegation language behavior or compliance patterns. In particular, models with weaker multilingual capabilities might show the degradation effects we hypothesized but did not observe.

*Temperature not controlled.* The Claude CLI was invoked with default parameters (estimated temperature 0.5 based on configuration). While this is consistent across conditions, it means our results reflect a specific point on the temperature--compliance tradeoff curve.

*English system prompt.* Claude Code's built-in English system prompt was present in all conditions. This constant English exposure may facilitate the manager's decision to delegate in English. An architecture that allowed fully non-English system prompts might exhibit different delegation language behavior.

*Deterministic scoring limitations.* The `no_global_vars` checker treats `app = FastAPI()` as a module-level mutable, which it technically is---but the scorer cannot distinguish intentional constraint violations from framework-mandated patterns. A more nuanced scorer might reduce false positives.

= Conclusion

We investigated cross-lingual constraint compliance in AI coding agent chains under full linguistic immersion. Our experiment with 126 trials across English, Italian, and Russian yielded a surprising primary finding: the manager agent in Claude Code's delegation chain universally translates to English (100% switching rate), acting as a normalizing layer that insulates the worker from the input language.

This normalization preserves constraint fidelity perfectly (100%) and produces compliance patterns that are driven by constraint--task interactions, not by input language. The structural constraint `no_global_vars` showed exact uniformity (67%) across all three languages, with all variance attributable to FastAPI's framework convention. The behavioral constraint `everything_oneliner` showed a suggestive but non-significant directional pattern (IT 82% > EN 71% > RU 61%) that warrants investigation at larger sample sizes.

These findings have practical implications for multilingual AI agent deployments. The manager's normalizing behavior means that constraint survival is language-agnostic in the current architecture---a positive result for safety. However, it also means that the "language" of the delegation chain is always English, regardless of the user's intent, which raises questions about transparency and user control in multilingual settings.

Future work should (1) confirm or refute the `everything_oneliner` directional pattern with larger samples, (2) test whether the universal English delegation behavior holds for other models and architectures, (3) investigate whether users perceive the automatic language normalization as desirable or problematic, and (4) extend the constraint set to include language-specific constraints where the translation itself is the challenge.

// References
#bibliography("refs.yml")
