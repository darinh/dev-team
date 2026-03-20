---
name: bootstrap-project
description: Initialize a project for dev-team by creating the .team/ directory structure, copying protocols, and configuring project settings.
---

# Bootstrap Project

Initialize a new project for dev-team. This creates the `.team/` directory with all necessary state files, copies protocol templates from the plugin, and configures project settings based on user preferences.

## When to Use

The `@dev-team` agent triggers this skill automatically when it detects that `.team/config.yaml` doesn't exist in the current project. It can also be triggered manually if the user wants to reinitialize.

## Steps

### 1. Create Directory Structure

```bash
mkdir -p .team/protocols \
         .team/memory \
         .team/skills \
         .team/knowledge/upstream-proposals \
         .team/knowledge/retrospectives \
         .team/knowledge/projects
```

Create `.gitkeep` files in empty directories:

```bash
for dir in .team/memory .team/skills .team/knowledge/upstream-proposals .team/knowledge/retrospectives .team/knowledge/projects; do
  touch "$dir/.gitkeep"
done
```

### 2. Copy Protocols from Plugin

The plugin's protocol files are the source of truth. Copy them into the project's `.team/protocols/` directory so agents can reference them at known paths.

Locate the plugin's `protocols/` directory (installed at `~/.copilot/installed-plugins/` or available relative to the agent) and copy:
- `collaboration.md`
- `memory.md`
- `skill-acquisition.md`
- `agent-template.md`
- `retrospective.md`

If the plugin directory isn't directly accessible, recreate the protocol files from the agent's knowledge of their content. The key protocols are referenced in `AGENTS.md`.

### 3. Ask Configuration Questions

Use `ask_user` for each question (one at a time):

**Question 1: Upstream contributions**
```
ask_user:
  question: "Want improvements discovered in this project to be proposed back to the dev-team framework?"
  choices:
    - "Yes, automatically submit PRs/issues"
    - "Yes, but I'll review first (Recommended)"
    - "No"
```

Map answers to config values:
- "Yes, automatically" → `mode: auto`, `auto_pr: true`, `auto_issue: true`
- "Yes, but I'll review" → `mode: manual`, `auto_pr: false`, `auto_issue: false`
- "No" → `mode: off`, `auto_pr: false`, `auto_issue: false`

### 4. Create `.team/config.yaml`

```yaml
# Dev-Team Project Configuration
upstream:
  mode: "{from question 1}"
  repo: "darinh/dev-team"
  auto_pr: {from question 1}
  auto_issue: {from question 1}
  require_proof: true

probation:
  required_tasks: 3
  require_tech_lead_review: true

retrospective:
  failure_threshold: 3
  trigger_on_repeat: true
```

### 5. Create `.team/org-chart.yaml`

```yaml
team:
  name: "Dev Team"
  version: 1
  operator: "operator"
  hiring_manager: "hiring-manager"
  project_manager: "project-manager"

  agents:
    - name: "operator"
      role: "Operator"
      domain: "Team operations and state queries"
      reports_to: null
      status: active
      created: "{today's date}"
      skills:
        - "Cross-agent state queries"
        - "Memory search and aggregation"
        - "Org chart navigation"
        - "Truth-verified reporting"

    - name: "project-manager"
      role: "Project Manager"
      domain: "Requirements, planning, brainstorming, project coordination"
      reports_to: null
      status: active
      created: "{today's date}"
      skills:
        - "Requirements elicitation and documentation"
        - "Product thinking and MVP scoping"
        - "Project decomposition and planning"
        - "Brainstorming facilitation"
        - "Stakeholder communication"
        - "Cross-agent work coordination"

    - name: "hiring-manager"
      role: "Hiring Manager"
      domain: "Agent creation, onboarding, team structure, skill marketplace"
      reports_to: "project-manager"
      status: active
      created: "{today's date}"
      skills:
        - "Agent design and creation"
        - "External agent onboarding and interview"
        - "Organizational structure management"
        - "Skill gap analysis"
        - "Adversarial review coordination"
        - "Workforce planning"

    - name: "tech-lead"
      role: "Tech Lead"
      domain: "Work quality, team health, retrospectives, agent probation, framework improvements"
      reports_to: null
      status: active
      created: "{today's date}"
      skills:
        - "Work quality assessment"
        - "Failure pattern analysis"
        - "Protocol design and refinement"
        - "Agent probation management"
        - "Retrospective facilitation"
        - "Upstream contribution management"

  divisions: []
  v_teams: []
```

### 6. Create Failure Journal

Create `.team/knowledge/failures.md`:

```markdown
# Failure Journal

This is an append-only log of significant failures across the team.
See `.team/protocols/retrospective.md` for the format and rules.

<!-- Entries below this line. Do not edit or delete existing entries. -->
```

### 7. Copy AGENTS.md

Copy the plugin's `AGENTS.md` to the project root. This provides global instructions that apply to all agents working in this project.

### 8. Commit

```bash
git add .team/ AGENTS.md
git commit --author="DevTeam/dev-team <dev-team@dev-team.local>" -m "Initialize dev-team for this project

Created .team/ directory with:
- protocols/ (collaboration, memory, skill-acquisition, retrospective, agent-template)
- config.yaml (upstream mode: {mode})
- org-chart.yaml (4 core agents)
- knowledge/failures.md (empty failure journal)
- memory/, skills/, knowledge/ directories

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### 9. Report Success

Tell the user:
"✅ Project initialized! Your dev-team is ready. What would you like to build?"
