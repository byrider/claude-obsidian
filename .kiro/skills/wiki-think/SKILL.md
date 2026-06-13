---
name: wiki-think
description: >
  Apply the OBSERVE-OBSERVE-LISTEN-THINK-CONNECT-CONNECT-FEEL-ACCEPT-CREATE-GROW
  framework to any non-trivial problem. Structured 10-principle thinking loop for
  architectural decisions, audits, post-mortems, and ambiguous requests.
  Triggers on: "/think [problem]", "think this through", "deep think",
  "systematic thinking", "structured reasoning", "walk this through".
allowed-tools: Read Write Edit Glob Grep Bash
---

# Wiki Think — 10-Principle Thinking Loop

A meditation, a discipline, and a checklist. Use when a problem is non-trivial enough that disciplined thinking pays for itself: architectural decisions, post-mortems, ambiguous requests, audits, multi-stakeholder tradeoffs.

## When to Invoke

**Use /think for:**
- Non-trivial architectural decisions
- System audits needing a methodology spine
- Ambiguous user requests needing deeper listening
- Surprising results needing metacognition before adjusting
- Post-mortems after something went sideways
- Closing sessions needing a GROW step

**Do NOT use for:**
- Single-line typo fixes
- Trivial lookups
- Cases where you've already moved through the stages implicitly

## The 10 Principles

### 1. OBSERVE (External Input)
Look at the environment, patterns, and opportunities without immediately solving.

- What are the raw inputs? (Code? Docs? Logs?)
- What have I read in full vs. skimmed vs. assumed?
- What surprises me before I start interpreting?

### 2. OBSERVE (Internal Metacognition)
Observe yourself. Are you biased? Anchored? Targeting a predetermined outcome?

- What am I biased toward? (Ownership, ship-it, novelty, anchoring)
- What outcome am I unconsciously hoping for?
- If a fresh reviewer joined now, what would they question?

### 3. LISTEN (Active Receptivity)
Shut down the ego to absorb external feedback.

- What did the user actually ask? (Quote verbatim.)
- What signals are in the noise? (Word choice, what they did NOT say)
- Whose voice is missing from this decision?

### 4. THINK (Critical Processing)
Break the problem to first principles.

- What are the first principles? (Constraints, invariants, blast radius)
- What alternatives have I NOT considered?
- What's the cheapest experiment that proves me wrong?

### 5. CONNECT (Lateral / Associative)
Find hidden relationships between distinct variables.

- Where else does this pattern show up?
- What unrelated domain solved a structurally similar problem?
- What metaphor unlocks intuition here?

### 6. CONNECT (System Orchestration)
How do individual pieces plug together into a functioning whole?

- How does this integrate with existing wiring? (Hooks, transport, locks)
- What needs updating downstream/upstream?
- What new failure modes does integration create?

### 7. FEEL (Emotional Intelligence + Intuition)
Factor in the human element.

- How does this LAND for the user?
- What emotional state is the user in at this code path?
- Does my intuition say "something is off" even when data says fine?

### 8. ACCEPT (Intellectual Humility)
Embrace constraints. Acknowledge failed hypotheses.

- What is the honest tier of this finding? (No inflation.)
- What sunk cost am I protecting?
- If this were someone else's work, would I be more critical?

### 9. CREATE (Generative Output)
Stop strategizing, start producing. Ship the artifact.

- What is the smallest artifact that ships the decision?
- Are inputs sufficient, or loop back to an earlier stage?
- Ship it.

### 10. GROW (Iterative Loop)
Take what you built, see how it performs, use lessons for next cycle.

- What worked well?
- What would I do differently next time?
- Where should this lesson be stored? (Wiki page? Steering? Learning?)

## Anti-Patterns

The loop fails when:
- **Skipping OBSERVE-internal** — confident wrong answers
- **Skipping ACCEPT** — padding scores, calling YELLOW "GREEN"
- **Skipping GROW** — nothing compounds, same baseline next cycle
- **Analysis paralysis at THINK** — never reaching CREATE
- **Ceremony** — writing all 10 stages for a one-line fix

## Output Format

After walking through the 10 stages, produce:
1. A clear recommendation or decision
2. Key findings from each relevant stage
3. Explicit uncertainties and next steps
4. Offer to `/save` the thinking if it's worth preserving
