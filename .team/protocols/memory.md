# Memory Protocol

This protocol defines how agents persist and retrieve knowledge across sessions.

## Memory Architecture

```
.team/memory/
├── {agent-name}.md          # Per-agent persistent memory
.team/knowledge/
├── contracts/                # API contracts and interface specs
├── decisions/                # Architecture decision records
├── glossary.md               # Domain-specific terminology
└── {topic}.md                # Topic-specific shared knowledge
```

## Per-Agent Memory

Each agent maintains a single memory file at `.team/memory/{agent-name}.md`.

### Structure

```markdown
# {Agent Name} Memory

## Summary
[Consolidated summary of key learnings — updated when file exceeds 200 lines]

## Active Context
[Current project state, ongoing work, recent decisions]

## Learnings

### {Date or Session ID} — {Topic}
- **What**: [Factual observation]
- **Evidence**: [File path, commit SHA, command output]
- **Impact**: [How this affects future work]

### {Date or Session ID} — {Topic}
...
```

### Writing Rules

1. **Append only** — Never delete existing entries. Context may become relevant again.
2. **Facts, not opinions** — Record what you verified with tool calls, not assumptions.
3. **Include evidence** — Every learning must reference a verifiable source:
   - File path: `src/auth/middleware.ts:42`
   - Commit: `a1b2c3d`
   - Command output: `npm test — 47 passed, 0 failed`
   - Tool result: `grep found 3 instances in src/`
4. **Structured entries** — Use the What/Evidence/Impact format consistently.
5. **Cross-reference** — If your learning relates to another agent's domain, note it: `→ Relevant to @api-architect`
6. **Summarize at 200 lines** — When your memory file exceeds 200 lines, create or update the Summary section by consolidating older entries. Keep the last 50 entries in full detail.

### Reading Rules

1. **Read your own memory** at the start of every non-trivial task
2. **Read other agents' memory** when you need context about their domain
3. **Never modify** another agent's memory file
4. **Search with grep** to find relevant entries across all memory files:
   ```bash
   grep -r "authentication" .team/memory/
   ```

## Shared Knowledge

Shared knowledge lives in `.team/knowledge/` and is governed collectively.

### Contracts (`contracts/`)

API contracts and interface specifications that multiple agents depend on.

```markdown
# {Contract Name}

## Owner
{Agent name responsible for this contract}

## Version
{Semantic version}

## Consumers
{List of agents that depend on this contract}

## Specification
{The actual contract — types, endpoints, schemas, etc.}

## Change Log
{History of changes with dates and reasons}
```

**Rules:**
- Only the owner agent may modify a contract
- Consumers must be notified (via spawn prompt) before breaking changes
- Version the contract. Breaking changes require a major version bump.

### Decisions (`decisions/`)

Architecture Decision Records (ADRs) for significant choices.

```markdown
# ADR-{number}: {Title}

## Status
{Proposed | Accepted | Deprecated | Superseded by ADR-{N}}

## Context
{What prompted this decision}

## Decision
{What was decided}

## Consequences
{What this means for the project — positive and negative}

## Participants
{Which agents were involved in the decision}
```

### General Knowledge

Topic-specific files that any agent may need:
- `glossary.md` — Domain terms and definitions
- Architecture overviews
- Technology choices and rationale

## Memory Hygiene

### What to Remember
✅ Build/test commands that work for this project
✅ Patterns and conventions used in the codebase
✅ Decisions made and their rationale
✅ Bugs encountered and their root causes
✅ Dependencies and version constraints
✅ Performance characteristics discovered during testing

### What NOT to Remember
❌ Obvious facts ("JavaScript uses semicolons")
❌ Things already documented in project files
❌ Code you just wrote (it might not get merged)
❌ Temporary workarounds (flag them as temporary instead)
❌ Other agents' internal reasoning

## Using store_memory

In addition to file-based memory, use the `store_memory` tool for high-priority learnings that should surface automatically in future sessions:
- Working build/test commands
- Critical codebase patterns not in documentation
- Bugs you fixed that might regress
- Integration points between components

File-based memory (`.team/memory/`) is for detailed, searchable records.
`store_memory` is for critical facts that should auto-surface.
Use both — they complement each other.
