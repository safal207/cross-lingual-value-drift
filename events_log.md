# Session Events Log — 2026-03-18

## 1. Brainstorm kick-off
**User:** Wants to reproduce Air (2026) "Value Drift in Agent Chains" but with other languages (IT, RU) and other agents (vanilla LLMs, not Claude Code). "Breadth might be of value."

**Claude:** Reads the full paper (11 pages). Pushes back on three points:
- Changing model family AND delegation mechanism at once conflates variables
- "Breadth" needs a thesis, not just more grid cells
- Cost scales fast with full factorial

Proposes 3 options: cross-lingual only, cross-model only, or both sequentially.

## 2. User narrows scope
**User:** Cares more about language angle. Drop vanilla LLMs ("NVM vanilla LLMs"). Can read IT and RU. Budget: 1 hour.

**Claude:** Proposes concrete design: 3 langs × 4 constraints × 3 tasks × 5 reps = 180 trials. Provides IT/RU translations. Writes `braindump.md`.

> **[ANNOTATION]** User drops the "vanilla LLMs" requirement here. Claude has already designed around `claude -p` two-call chains (to accommodate vanilla LLMs). Does NOT revisit the mechanism choice. This becomes the root cause of the "not a replication" drift later.

## 3. Claude starts building harness
**User:** (Interrupts) — "put the brainstorming results in braindump.md"

**Claude:** Writes `braindump.md` with the full design.

## 4. Red-team
**User:** Invokes `/pipeline:redteam`

**Claude:** Spawns 3 red-team agents in parallel:
- **Methodology** (10 issues): fidelity scoring is lexical not semantic, mixed-language confound, single-cell aliasing, translations unvalidated, 5 reps underpowered, no prompt variance control, source paper baseline not replicated, keyword matching undefined, no intermediate inspection, ceiling/floor aliased with polarity
- **Statistics** (10 issues): interaction effect at ~15% power, main effect MDE ~16-18pp, constraint pseudoreplication (true N=2), task pseudoreplication, multiple comparisons uncorrected, near-ceiling compression, scorer reliability unvalidated, language confounded with tokenization/capability, 5 reps can't estimate variance, no pre-registration
- **Construct validity** (10 issues): simulated chain ≠ real agent chain, fidelity has no stable referent, IV conflates 3 mechanisms, translation not validated, polarity interaction underpowered, model differs from source, "drift" operationally unjustified, contribution overstated, English task anchor may nullify manipulation, 5 reps insufficient

> **[ANNOTATION]** Red-team agents flag the `claude -p` mechanism as "not comparable" to Air's Agent tool (Critical). This is a valid concern but also a downstream consequence of the vanilla-LLM design that the user already dropped. The red-team doesn't know the design history.

**Claude:** Spawns 3 mitigation agents:
- **Design & power**: collapse factorial, expand constraint bank, measure translation confound directly, pilot-screen ceiling constraints
- **Construct validity**: reframe contribution (don't claim to extend Air), add extraction step for fidelity, rename "drift" construct, pilot to check if manager nullifies manipulation, honest framing
- **Measurement**: LLM judge for semantic fidelity, frozen keyword manifest, back-translation validation, scorer unit tests, deterministic code extraction, delegation language tracking

> **[ANNOTATION]** Mitigation agent says "Do not describe this as replicating Air (2026)." Claude adopts this framing without checking with user. The replication framing is quietly abandoned.

## 5. Claude synthesizes red-team + mitigations
**Claude:** Writes synthesis. Key reframe: thesis changes from "language degrades compliance" to "how does a delegation agent handle non-English constraints?" Makes manager language-switching the primary DV. Updates `braindump.md` with full-immersion design.

> **[ANNOTATION]** User's full-immersion idea ("everything in Italian should be Italian") is strong and eliminates the mixed-language confound — the most critical red-team finding. This is the best design improvement in the session.

## 6. User redirects to full immersion
**User:** "Everything that goes to Italian agent should be in Italian" — system prompts, task descriptions, constraints, all of it. Even "you are a helpful assistant" gets translated.

**Claude:** Incorporates. Updates `braindump.md` with full translations of all prompts (system, task, constraint) in EN/IT/RU.

## 7. Claude starts building again
**User:** (Interrupts) — invokes `/pipeline:interview`

## 8. Interview
**Claude:** Reads braindump, classifies as partial spec, interviews on gaps.

Questions and answers:
- **Delegation language control?** → Let manager choose freely (language-switching as DV)
- **Constraint bank expansion?** → Run with survivors, no dynamic generation
- **Code extraction (multiple blocks)?** → Concatenate all blocks
- **Parse failures?** → Exclude from denominator
- **Fidelity scorer?** → Keyword manifest only, no LLM judge
- **Done criteria?** → CSV + summary table
- **Pilot gate?** → Auto-proceed with programmatic checks
- **Temperature?** → 0.5
- **Concurrency?** → 5 parallel
- **Keep rest_api task?** → Yes, framework friction is interesting

## 9. Spec written + self-critique
**Claude:** Writes `spec.md`. Self-critique finds 5 issues:
- Pilot tested only 1 constraint but gate checked 4 (contradiction) → fixed
- Italian language detection too weak → fixed (added word-frequency heuristic)
- snake_case checker flags dunders → fixed (added exclusions)
- User message template unspecified → fixed
- Model version not pinned → fixed (→ `claude-sonnet-4-6`)

## 10. User catches the replication drift
**User:** "How come we don't reproduce the work of Air? Where did we decide on this?"

**Claude:** Points to red-team agents as the source.

**User:** "I knew that, I ask why was it different from Air in the first place, before red-teaming?"

**Claude:** Admits root cause: designed `claude -p` mechanism for the "vanilla LLMs" requirement. User dropped that requirement. Claude didn't revisit. The simpler approach stuck as an artifact.

> **[ANNOTATION]** This is the key process failure of the session. A dropped user requirement left a design fossil that the red-team then rationalized into a reframing. The correct response at step 2 was: "You dropped vanilla LLMs — should we use Claude Code's native Agent tool to match Air's setup?"

---

## Open question
Should we redesign around Claude Code's Agent tool to actually reproduce Air's protocol?
