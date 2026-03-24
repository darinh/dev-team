# Retrospective Protocol

This protocol defines how the team learns from experience, records outcomes, and proposes improvements — both within a project and upstream to the framework.

## Post-Task Outcome Recording

**This is mandatory for all agents. No exceptions.**

After completing any task (whether the user accepts, rejects, or asks for revisions), append an outcome entry to your memory file:

```markdown
### OUTCOME — {date or session context}
- **Task**: {one-line description of what you did}
- **Result**: accepted | rejected | revised
- **Detail**: {if rejected/revised: why, and what you'd do differently}
```

### When Output Is Rejected

If the user rejects your output or asks you to redo work, you MUST record a detailed failure entry:

```markdown
### FAILURE — {date or session context}
- **Task**: {what you were asked to do}
- **What you produced**: {summary of your output}
- **Why it was rejected**: {user's feedback, as specifically as possible}
- **Root cause**: {your honest assessment — wrong assumption? missed requirement? skill gap? scope error?}
- **What to do differently**: {concrete change for next time}
```

This is not optional. Failures are the highest-value learning signal the team has.

## Failure Journal

All significant failures are also recorded in a shared, append-only journal at `.team/knowledge/failures.md`.

### Who Writes to It
- Any agent that experiences a rejection or produces output that causes problems for another agent
- The Tech Lead, when aggregating patterns from individual agent memory files

### Format

```markdown
# Failure Journal

## {Date} — {Agent Name} — {One-line summary}
- **Task**: {description}
- **Root cause**: {category}: {detail}
- **Impact**: {what went wrong downstream, if anything}
- **Resolution**: {how it was fixed}
- **Preventable?**: {yes/no — if yes, what protocol/instruction change would prevent it}
```

### Root Cause Categories
- `scope-violation` — Agent operated outside its defined scope
- `missing-requirement` — Requirement was incomplete or ambiguous
- `wrong-assumption` — Agent assumed something that wasn't true
- `skill-gap` — Agent lacked knowledge for the task
- `protocol-violation` — Agent didn't follow a team protocol
- `communication-failure` — Agent didn't provide enough context to a collaborator
- `stale-knowledge` — Agent used outdated information from memory

### Rules
1. **Append-only** — Never edit or delete existing entries
2. **Honest** — Record the actual root cause, not a face-saving version
3. **Actionable** — Every entry must answer "what would prevent this next time?"
4. **No blame** — Failures are learning opportunities, not indictments

## Upstream Proposals

When the Tech Lead (or any agent) identifies an improvement that would benefit ALL projects using the framework — not just the current project — they create an upstream proposal.

### When to Create an Upstream Proposal
- A protocol has a gap that caused a failure (and the gap exists in the framework, not just this project's customization)
- A new pattern was discovered that should be part of the agent template
- A shared protocol needs a new rule or clarification
- An agent archetype is missing from the Hiring Manager's knowledge

### Proposal Format

Create a file in `.team/knowledge/upstream-proposals/{id}.md`:

```markdown
# Upstream Proposal: {id}

## Classification
- **Type**: bug-fix | quality-improvement | recommendation
- **Priority**: high | medium | low
- **Scope**: {which framework file(s) would change}

## Problem
{What's wrong or missing, with evidence from the failure journal or agent memory}

## Evidence
- Failure journal entries: {references}
- Agent memory entries: {references}
- Frequency: {how often this has occurred}
- Impact: {what goes wrong when this isn't fixed}

## Proposed Change
{Exact content or diff to apply to the framework file(s)}

## Verification
{How to verify the change works — test scenario with expected outcome}
- **Before**: {current behavior with this gap}
- **After**: {expected behavior with the fix}
- **Test**: {specific steps to validate}

## Status
- **Created**: {date}
- **Created by**: {agent name}
- **Submitted**: {date PR/issue was created, or "pending"}
- **PR/Issue**: {URL if submitted}
```

### Submission

Read `.team/config.yaml` to determine the upstream mode:

- **`auto`**: Submit directly via GitHub MCP tools:
  - For changes with exact diffs → create a PR on the upstream repo
  - For recommendations without specific diffs → create a GitHub issue
  - Always include the full proposal content (problem, evidence, verification steps)
- **`manual`**: Leave the proposal file for the user to review and submit
- **`off`**: Still write the proposal file (for project records), but don't submit

## Retrospective Process

The Tech Lead drives retrospectives. They are demand-driven, not scheduled.

### Triggers
- 3+ new entries in the failure journal since the last retrospective
- A repeated root cause category (same category appears 2+ times)
- User requests a retrospective
- A new agent has completed its probationary period

### Auto-Trigger by dev-team
dev-team checks after each session:
- Count new failure entries since last retrospective
- If >= threshold (default: 3) → spawn Tech Lead for retrospective
- If same root cause appears 2+ times → spawn Tech Lead immediately
- Record retrospective trigger in audit log

### Process
1. **Gather data**: Read failure journal, all agent memory files (recent outcomes)
2. **Identify patterns**: Group failures by root cause category
3. **Propose fixes**: For each pattern, determine if it's:
   - A project-local fix (update this project's agent instructions)
   - An upstream fix (create an upstream proposal)
   - A team structure issue (recommend to Hiring Manager)
4. **Document**: Write a retrospective summary to `.team/knowledge/retrospectives/{date}.md`
5. **Act**: Create improvement proposals (upstream or local) for the highest-impact patterns

### Retrospective Summary Format

```markdown
# Retrospective — {date}

## Period
{From last retro date to now}

## Failures Reviewed
{Count and list of failure journal entries}

## Patterns Found
### Pattern: {name}
- **Root cause category**: {category}
- **Frequency**: {count}
- **Affected agents**: {list}
- **Proposed fix**: {description}
- **Fix type**: project-local | upstream proposal

## Actions Taken
- {Action 1: what was changed or proposed}
- {Action 2}

## Metrics
- Total failures this period: {N}
- Recurring patterns: {N}
- Upstream proposals created: {N}
- Agents on probation: {N}
```

## Improvement Lifecycle

```
Failure occurs
  → Agent records OUTCOME + FAILURE in memory
  → Agent appends to failure journal
  → (threshold reached)
  → Tech Lead runs retrospective
  → Pattern identified
  → Improvement proposed (local or upstream)
  → If upstream: proposal submitted per config.yaml mode
  → Change applied + verified
  → Future agents benefit
```
