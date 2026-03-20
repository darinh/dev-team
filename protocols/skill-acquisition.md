# Skill Acquisition Protocol

This protocol defines how agents discover, evaluate, create, and share skills.

## Overview

Skills are reusable capabilities that extend an agent's functionality. They can be:
- **External**: Libraries, packages, MCP servers, tools discovered from the ecosystem
- **Custom**: Skills written by agents to fill gaps, stored in `.team/skills/`

## The Acquisition Flow

```
┌─────────────────┐
│  1. Self-Assess  │ ← "Do I need a skill I don't have?"
└────────┬────────┘
         │ YES
┌────────▼────────┐
│  2. Scope Check  │ ← "Is this within my persona?"
└────────┬────────┘
    NO ──┤── YES
         │
┌────────▼────────┐    ┌──────────────────────┐
│ Consult org chart│───►│ Spawn appropriate     │
│ & delegate       │    │ specialist agent      │
└──────────────────┘    └──────────────────────┘
         │
         │ (Within persona)
┌────────▼────────────┐
│  3. Search Existing  │ ← Check .team/skills/ registry
└────────┬────────────┘
         │ NOT FOUND
┌────────▼────────────┐
│  4. Search External  │ ← Context7, web_search, GitHub
└────────┬────────────┘
         │ NOT FOUND
┌────────▼────────────┐
│  5. Search MCP       │ ← Known and discoverable MCP servers
└────────┬────────────┘
         │ NOT FOUND
┌────────▼────────────┐
│  6. Write Skill      │ ← Create + adversarial review
└────────┬────────────┘
         │ REVIEW FAILED (after 2 attempts)
┌────────▼────────────┐
│  7. Ask User         │ ← Last resort
└──────────────────────┘
```

## Step 1: Self-Assessment

Before every task, ask yourself:
- Do I have the knowledge to complete this?
- Do I need a tool, library, or capability I don't currently have?
- Is there existing code in the project that does what I need?

If you have what you need, proceed without skill acquisition.

## Step 2: Scope Check

**Critical rule: Only acquire skills within your persona's domain.**

Examples:
| Agent | ✅ In Scope | ❌ Out of Scope |
|-------|-----------|---------------|
| API Architect | REST design, GraphQL, OpenAPI | React components, CSS |
| UI/UX Engineer | React, CSS, accessibility | Database schemas, SQL optimization |
| Data Engineer | SQL, ETL, query optimization | Frontend routing, UI animation |
| Security Analyst | Auth, encryption, OWASP | UI design, business analytics |

If the skill is out of scope:
1. Read `.team/org-chart.yaml` to find the right specialist
2. Spawn them with a clear request (see Collaboration Protocol)
3. Incorporate their result into your work

## Step 3: Search Existing Skills

Check the local skill registry:

```bash
ls .team/skills/
cat .team/skills/{skill-name}/README.md
```

Each custom skill has:
```
.team/skills/{skill-name}/
├── README.md           # What it does, how to use it, review status
├── skill.md            # The skill implementation
└── review-results.md   # Adversarial review findings and resolution
```

## Step 4: Search External Sources

Search in this order:

### 4a. Context7 (Documentation)
```
context7-resolve-library-id → library name
context7-query-docs → specific question about usage
```

### 4b. Web Search
```
web_search → "How to [specific task] in [language/framework]"
```

### 4c. GitHub Repositories
```
github-mcp-server-search_repositories → relevant tools/libraries
github-mcp-server-search_code → implementation patterns
```

### Evidence Requirement
When you find an external solution:
- Verify it exists (don't hallucinate packages)
- Check it's maintained (last update, star count, open issues)
- Verify API compatibility with the project's stack
- Document the source in your memory file

## Step 5: Search MCP Servers

Check known MCP servers for relevant capabilities:
1. Read `.mcp.json` for currently configured servers
2. Search for MCP servers that might provide the needed skill:
   ```
   web_search → "{capability} MCP server"
   github-mcp-server-search_repositories → "{capability} mcp-server"
   ```
3. If found, recommend adding it to `.mcp.json` (but don't modify `.mcp.json` without Hiring Manager approval)

## Step 6: Write a Custom Skill

When no existing solution fits, create one:

### 6a. Design the Skill

Create the skill directory:
```
.team/skills/{skill-name}/
├── README.md
├── skill.md
└── review-results.md  (created during review)
```

**README.md template:**
```markdown
# {Skill Name}

## Purpose
{What this skill does and when to use it}

## Author
{Agent name that created it}

## Status
{Draft | Under Review | Approved | Deprecated}

## Dependencies
{External packages, tools, or other skills required}

## Usage
{How to invoke/use this skill}

## Limitations
{What this skill cannot do}
```

### 6b. Implement the Skill

Write the skill implementation in `skill.md`. This should be a focused, reusable capability.

### 6c. Adversarial Review

**Every custom skill must pass adversarial review before use.**

Spawn 2 review agents (using different models) in parallel:

```
agent_type: "code-review"
model: "gpt-5.3-codex"  (or another model different from yours)
prompt: |
  Review this custom skill for correctness, security, and completeness.

  Skill: {skill-name}
  Purpose: {from README}
  Implementation: {content of skill.md}

  Check for:
  1. Correctness — Does it actually do what it claims?
  2. Security — Any injection, data leak, or privilege escalation risks?
  3. Completeness — Are edge cases handled? Error paths covered?
  4. Scope — Does it stay within the stated purpose or overreach?
  5. Dependencies — Are all required dependencies reasonable and documented?

  For each issue found: what's wrong, why it matters, and how to fix it.
  If nothing wrong, explicitly state "No issues found."
```

### 6d. Address Review Findings

1. Fix all issues identified by reviewers
2. Re-run the review if changes were significant
3. Document the review results in `review-results.md`
4. Update the skill status to "Approved" in README.md

**Max 2 review rounds.** If the skill still has issues after 2 rounds:
- Document remaining concerns in review-results.md
- Set status to "Approved with Caveats"
- Note the caveats prominently in README.md

## Step 7: Ask User (Last Resort)

Only after exhausting steps 1-6:

```
ask_user:
  question: |
    I need a capability for [specific task] but couldn't find it through:
    - Local skill registry (searched .team/skills/)
    - External packages (searched Context7, web, GitHub)
    - MCP servers (searched for relevant servers)
    - Custom skill creation (attempted but [reason it didn't work])

    Can you suggest a tool, library, or approach for this?
  choices:
    - "I know a tool for this (I'll describe it)"
    - "Skip this capability for now"
    - "Let me research and get back to you"
```

## Skill Sharing

When you create a useful skill:
1. Store it in `.team/skills/` with full documentation
2. Update your memory file noting the skill's existence
3. Other agents discover it via Step 3 of this protocol

## Skill Deprecation

When a skill becomes obsolete:
1. Set status to "Deprecated" in its README.md
2. Note the replacement (if any)
3. Don't delete the directory — other agents may still reference it
