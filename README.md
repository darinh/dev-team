# Dev-Team

An autonomous multi-agent software development framework for GitHub Copilot. Install the plugin, talk to `@dev-team`, and let specialized agents handle the rest.

## Quick Start

### 1. Install the Plugin

```bash
copilot plugin install darinh/dev-team
```

### 2. Start Using It

Open any project and invoke `@dev-team`:

```
@dev-team I want to build a task management app with a REST API and React frontend.
```

On first use in a project, `@dev-team` will:
1. Ask a few questions about your project and preferences
2. Initialize a `.team/` directory for project-specific state
3. Bring in the Hiring Manager to create specialist agents for your stack

After setup, just keep talking to `@dev-team`. It routes your requests to the right specialist behind the scenes:

```
@dev-team Let's brainstorm the data model for this app.
@dev-team How's the team doing? Any issues?
@dev-team We need a specialist for database optimization.
```

## How It Works

You talk to one agent (`@dev-team`). It delegates to specialists:

| You say... | Behind the scenes |
|------------|-------------------|
| "I want to build..." | → Project Manager brainstorms with you |
| "Create a specialist for..." | → Hiring Manager builds the agent |
| "What does the team know about...?" | → Operator queries all team state |
| "Run a health check" | → Tech Lead reviews quality & failures |
| "Fix this bug" / "Build this feature" | → Project Manager decomposes → specialists execute |

## Architecture

```
Plugin (installed once, shared):
├── agents/                        # Agent definitions
│   ├── dev-team.agent.md          # Entry point — you talk to this one
│   ├── project-manager.agent.md   # Requirements, planning, brainstorming
│   ├── hiring-manager.agent.md    # Creates/onboards agents
│   ├── operator.agent.md          # Truth-only queries
│   ├── tech-lead.agent.md         # Quality, retrospectives, improvement
│   └── ...                        # Specialist agents (created per-project)
├── protocols/                     # Protocol templates
│   ├── collaboration.md
│   ├── memory.md
│   ├── skill-acquisition.md
│   ├── agent-template.md
│   └── retrospective.md
├── plugin.json
└── .mcp.json

Project (per-repo state, created by @dev-team on first use):
└── .team/
    ├── config.yaml                # Project settings (upstream mode, etc.)
    ├── org-chart.yaml             # Team structure
    ├── protocols/                 # Local copies of protocols
    ├── memory/                    # Per-agent persistent memory
    ├── skills/                    # Custom skills
    └── knowledge/                 # Project knowledge, failures, proposals
```

## Git Identity

Each agent commits with a recognizable identity:

```
a1b2c3d DevTeam/api-architect  Add REST endpoints for user management
d4e5f6a DevTeam/ui-engineer    Build login form component
g7h8i9j DevTeam/tech-lead      Update protocol from retrospective findings
```

## Built-in Agents

### Dev-Team (`@dev-team`)
Your single point of contact. Handles project setup, routes requests to specialists, and presents results. You rarely need to invoke other agents directly.

### Project Manager
Brainstorms with you, gathers requirements, writes project briefs, creates phased plans with acceptance criteria, and coordinates specialists.

### Hiring Manager
Creates specialist agents tailored to your project's tech stack. Can onboard external agents with protocol compliance testing. New agents start on probation.

### Operator
Truth-only query interface. Asks it anything about team state, agent knowledge, or project context. Every answer backed by evidence. Never guesses.

### Tech Lead
Reviews actual work quality (git diffs, not plans). Runs team health checks, drives retrospectives, manages agent probation, and proposes framework improvements.

## Continuous Improvement

The framework improves over time through two feedback loops:

### Project-Level
Agents record task outcomes and failures. The Tech Lead reviews patterns and improves agent instructions and protocols.

### Framework-Level (Upstream)
Improvements that benefit ALL projects flow back to this repo. Configure per-project in `.team/config.yaml`:

- **`auto`**: Tech Lead submits PRs/issues to `darinh/dev-team` with evidence and test scenarios
- **`manual`**: Proposals written locally for your review before submitting
- **`off`**: No upstream contributions

## Protocols

| Protocol | Purpose |
|----------|---------|
| Collaboration | Agent spawning, depth limits, conflict resolution |
| Memory | Persistent knowledge, shared knowledge base, ADRs |
| Skill Acquisition | 7-step flow from self-assess to ask-user |
| Agent Template | Required structure for new agent.md files |
| Retrospective | Outcome recording, failure journal, upstream proposals |

## Configuration

After setup, edit `.team/config.yaml` in your project to change:
- Upstream contribution mode (auto/manual/off)
- Probation requirements (task count, review requirements)
- Retrospective thresholds

## Acknowledgments

Inspired by [Anvil](https://github.com/burkeholland/anvil) by Burke Holland, which pioneered the adversarial multi-model review pattern for Copilot agents.

## License

MIT
