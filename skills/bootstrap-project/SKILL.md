---
name: bootstrap-project
description: Initialize a project for dev-team by creating the .team/ directory structure with protocols, config, org chart, and failure journal.
---

# Bootstrap Project

Initialize a new project for dev-team. Creates the `.team/` directory with all state files and sensible defaults. The `@dev-team` agent triggers this automatically when `.team/config.yaml` doesn't exist.

## Steps

### 1. Create Directory Structure

```bash
mkdir -p .team/protocols \
         .team/memory \
         .team/skills \
         .team/audit/sessions \
         .team/knowledge/upstream-proposals \
         .team/knowledge/retrospectives \
         .team/knowledge/projects \
         .github/agents

for dir in .team/memory .team/skills .team/audit/sessions .team/knowledge/upstream-proposals .team/knowledge/retrospectives .team/knowledge/projects; do
  touch "$dir/.gitkeep"
done
```

### 2. Copy Protocol Files

Copy each protocol file from the plugin's `protocols/` directory. Try these locations in order:

```bash
# Try to find the plugin install directory
PLUGIN_DIR=""
for candidate in \
  ~/.copilot/installed-plugins/_direct/darinh--dev-team \
  ~/.copilot/installed-plugins/dev-team \
  ~/.copilot/state/installed-plugins/_direct/darinh--dev-team \
  ~/.copilot/state/installed-plugins/dev-team; do
  if [ -d "$candidate/protocols" ]; then
    PLUGIN_DIR="$candidate"
    break
  fi
done

if [ -n "$PLUGIN_DIR" ]; then
  cp "$PLUGIN_DIR"/protocols/*.md .team/protocols/
else
  echo "Plugin protocols directory not found — will create minimal protocols"
fi
```

If the plugin directory isn't found, create minimal protocol stubs with a reference to the full versions:

```bash
for proto in collaboration memory skill-acquisition agent-template retrospective audit; do
  cat > ".team/protocols/$proto.md" << EOF
# ${proto} Protocol

See the full protocol in the dev-team plugin: https://github.com/darinh/dev-team/tree/main/protocols/${proto}.md

Install or update the plugin to get the latest protocols:
  copilot plugin install darinh/dev-team
  copilot plugin update dev-team
EOF
done
```

### 3. Create Core Agents

Copy core agent templates to the project's `.github/agents/` directory:

```bash
TEMPLATE_DIR="$PLUGIN_DIR/templates"
if [ -d "$TEMPLATE_DIR" ]; then
  for template in project-manager hiring-manager tech-lead operator auditor; do
    if [ -f "$TEMPLATE_DIR/$template.template.md" ]; then
      cp "$TEMPLATE_DIR/$template.template.md" ".github/agents/$template.agent.md"
    fi
  done
fi
```

### 4. Create `.team/config.yaml`

Use the project info extracted by `@dev-team` from the user's message. Default upstream mode to `manual`.

```yaml
# Dev-Team Project Configuration
# Edit this file to change settings at any time.

# Project info (extracted from user's description)
project:
  name: "{project-name}"
  description: "{one-line description}"
  stack: ["{language}", "{framework}"]

# Upstream contribution settings
# Controls how improvements flow back to the framework repo.
upstream:
  mode: "manual"       # auto | manual | off
  repo: "darinh/dev-team"
  auto_pr: false
  auto_issue: false
  require_proof: true

# Agent probation settings
probation:
  required_tasks: 3
  require_tech_lead_review: true

# Retrospective settings
retrospective:
  failure_threshold: 3
  trigger_on_repeat: true
```

### 5. Create `.team/org-chart.yaml`

The org chart lists `dev-team` as the sole plugin agent. Core agents (project-manager, hiring-manager, tech-lead, operator, auditor) are project-level agents created from templates in `.github/agents/`.

```yaml
# Dev-Team Organizational Structure
# Maintained by: hiring-manager (sole writer)
# Readable by: all agents

team:
  name: "Dev Team"
  version: 1
  operator: "operator"
  hiring_manager: "hiring-manager"
  project_manager: "project-manager"

  # Plugin agent (installed via copilot plugin)
  plugin_agents:
    - name: "dev-team"
      role: "Entry Point"
      domain: "Team orchestration and session routing"
      status: active

  # Project-level agents (created from templates in .github/agents/)
  agents:
    - name: "operator"
      role: "Operator"
      domain: "Team operations and state queries"
      reports_to: null
      status: active
      source: ".github/agents/operator.agent.md"
      skills:
        - "Cross-agent state queries"
        - "Truth-verified reporting"

    - name: "project-manager"
      role: "Project Manager"
      domain: "Requirements, planning, brainstorming"
      reports_to: null
      status: active
      source: ".github/agents/project-manager.agent.md"
      skills:
        - "Requirements elicitation"
        - "Project decomposition"
        - "Brainstorming facilitation"

    - name: "hiring-manager"
      role: "Hiring Manager"
      domain: "Agent creation, onboarding, team structure"
      reports_to: "project-manager"
      status: active
      source: ".github/agents/hiring-manager.agent.md"
      skills:
        - "Agent design and creation"
        - "Organizational structure management"

    - name: "tech-lead"
      role: "Tech Lead"
      domain: "Work quality, retrospectives, agent probation"
      reports_to: null
      status: active
      source: ".github/agents/tech-lead.agent.md"
      skills:
        - "Work quality assessment"
        - "Failure pattern analysis"
        - "Retrospective facilitation"

    - name: "auditor"
      role: "Auditor"
      domain: "Session audit, protocol compliance verification, handoff integrity"
      reports_to: null
      status: active
      source: ".github/agents/auditor.agent.md"
      skills:
        - "Audit log parsing and event chain reconstruction"
        - "Protocol compliance verification"
        - "Handoff integrity checking"
        - "Customer intent traceability"

  divisions: []
  v_teams: []
```

### 6. Create `.team/audit/index.md`

```markdown
# Audit Session Index

| Date | Session File | Tasks Reviewed | Overall | Summary |
|------|-------------|----------------|---------|---------|
```

### 7. Copy audit protocol

```bash
if [ -n "$PLUGIN_DIR" ] && [ -f "$PLUGIN_DIR/protocols/audit.md" ]; then
  cp "$PLUGIN_DIR/protocols/audit.md" .team/protocols/audit.md
else
  cat > .team/protocols/audit.md << 'EOF'
# Audit Protocol

See the full protocol in the dev-team plugin: https://github.com/darinh/dev-team/tree/main/protocols/audit.md

Install or update the plugin to get the latest protocols:
  copilot plugin install darinh/dev-team
  copilot plugin update dev-team
EOF
fi
```

### 8. Create `.team/knowledge/failures.md`

```markdown
# Failure Journal

This is an append-only log of significant failures across the team.
See `.team/protocols/retrospective.md` for the format and rules.

<!-- Entries below this line. Do not edit or delete existing entries. -->
```

### 9. Copy AGENTS.md

Copy the plugin's `AGENTS.md` to the project root:

```bash
if [ -n "$PLUGIN_DIR" ] && [ -f "$PLUGIN_DIR/AGENTS.md" ]; then
  cp "$PLUGIN_DIR/AGENTS.md" ./AGENTS.md
fi
```

If not found, create a minimal version that references the plugin:

```markdown
# Dev-Team Global Instructions

All agents in this project follow the shared protocols in `.team/protocols/`.
See the full instructions in the dev-team plugin: https://github.com/darinh/dev-team
```

### 10. Commit

```bash
git add .team/ .github/agents/ AGENTS.md
git commit --author="DevTeam/dev-team <dev-team@dev-team.local>" -m "Initialize dev-team for this project

Created .team/ with protocols, config, org chart, and failure journal.
Created .github/agents/ with core agents from templates.
Project: {project-name} | Stack: {stack}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### 11. Report Success

Tell the user: "✅ Project initialized! Your dev-team is ready."
Then proceed with team assessment and next-step options.
