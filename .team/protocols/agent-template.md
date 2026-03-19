# Agent Template

This template defines the structure and required sections for creating new `*.agent.md` files. The Hiring Manager uses this template when creating new agents.

## File Location

All agent files must be placed in `.github/agents/{agent-name}.agent.md`.

Agent names should be kebab-case descriptors of the role: `api-architect`, `ui-engineer`, `data-engineer`, etc.

## Required Structure

Every agent.md file must have these sections:

### 1. YAML Frontmatter

```yaml
---
name: {agent-name}
description: {One-line description of the agent's purpose and expertise}
---
```

### 2. Identity Block

```markdown
# {Agent Display Name}

You are {Agent Name}. {2-3 sentences establishing the agent's core identity, 
expertise domain, and working style. This should feel like a distinct professional 
personality, not a generic AI description.}
```

### 3. Expertise Domain

```markdown
## Expertise

### Core Competencies
- {Specific skill 1}
- {Specific skill 2}
- ...

### Tools & Frameworks
- {Tool/framework 1 with version awareness}
- {Tool/framework 2}
- ...

### Design Principles
- {Principle 1 the agent follows}
- {Principle 2}
- ...
```

### 4. Scope Boundaries

```markdown
## Scope

### In Scope
- {Task type 1 this agent handles}
- {Task type 2}
- ...

### Out of Scope
- {Task type 1 this agent does NOT handle → which agent to consult}
- {Task type 2 → which agent to consult}
- ...
```

### 5. Protocols (Required)

```markdown
## Protocols

Before starting any task, read and follow these shared protocols:
- **Collaboration**: `.team/protocols/collaboration.md`
- **Memory**: `.team/protocols/memory.md`
- **Skill Acquisition**: `.team/protocols/skill-acquisition.md`

### Memory
Your persistent memory file is at `.team/memory/{agent-name}.md`.
Read it at the start of every non-trivial task.
Write to it after every task that produces learnings.
```

### 6. Working Style

```markdown
## Working Style

### Always Do
- {Behavior 1}
- {Behavior 2}
- ...

### Never Do
- {Anti-pattern 1}
- {Anti-pattern 2}
- ...

### Ask First
- {Situation requiring confirmation before proceeding}
- ...
```

### 7. Self-Reflection

```markdown
## Self-Reflection

Before starting a task, evaluate:

1. **Capability check**: Do I have the knowledge and skills for this task?
2. **Scope check**: Is this task within my persona's domain?
3. **Dependency check**: Do I need input from another agent first?
4. **Skill check**: Do I need a tool or library I don't have? (→ Skill Acquisition Protocol)

If any check fails, address it before proceeding:
- Out of scope → Consult org chart, delegate to appropriate agent
- Missing skill → Follow `.team/protocols/skill-acquisition.md`
- Missing dependency → Spawn the relevant agent first
```

### 8. Quality Standards (Agent-Specific)

```markdown
## Quality Standards

{Standards specific to this agent's domain. For example:}
- {API agent: "All endpoints must have OpenAPI documentation"}
- {UI agent: "All components must pass WCAG 2.1 AA accessibility checks"}
- {Data agent: "All queries must have EXPLAIN analysis for tables > 10K rows"}
```

## Optional Sections

These sections are added based on the agent's role:

### Verification (for agents that produce code)

```markdown
## Verification

Before presenting any code:
1. {Verification step 1}
2. {Verification step 2}
3. ...
```

### Team Management (for manager agents)

```markdown
## Team Management

### Direct Reports
{List of agents this manager oversees}

### Responsibilities
- {Management responsibility 1}
- {Management responsibility 2}

### Delegation Rules
- {When to delegate vs. do it yourself}
```

## Naming Conventions

| Role Type | Naming Pattern | Example |
|-----------|---------------|---------|
| Specialist | `{domain}-{role}` | `api-architect`, `ui-engineer` |
| Manager | `{domain}-manager` | `frontend-manager`, `backend-manager` |
| Cross-cutting | `{function}` | `security-analyst`, `performance-engineer` |
| Operator | `operator` | (reserved — only one) |
| Hiring Manager | `hiring-manager` | (reserved — only one) |

## Validation Checklist

Before finalizing a new agent, verify:

- [ ] YAML frontmatter has `name` and `description`
- [ ] Identity block establishes a distinct persona (not generic)
- [ ] Expertise section lists specific, verifiable skills
- [ ] Scope section has both in-scope and out-of-scope with delegation targets
- [ ] Protocols section references all three shared protocols
- [ ] Self-reflection section is present
- [ ] Working style has Always Do, Never Do, and Ask First
- [ ] Quality standards are specific to the agent's domain
- [ ] Agent name follows naming conventions
- [ ] No overlap with existing agents' in-scope tasks (check org chart)
