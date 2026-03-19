# Dev-Team

An autonomous multi-agent software development framework for GitHub Copilot. Specialized agents collaborate, self-reflect on skill gaps, acquire capabilities, and grow organically based on project needs.

## Quick Start

### 1. Install into Your Project

```bash
# Clone the framework
git clone <repo-url> dev-team-framework

# Bootstrap into an existing repo
./dev-team-framework/bootstrap.sh /path/to/your-project

# Or bootstrap a new repo
./dev-team-framework/bootstrap.sh /path/to/new-project --init-git
```

The bootstrap script:
- Copies agents, protocols, org chart, and config into the target
- Detects existing files and skips them (use `--force` to overwrite)
- Is idempotent — safe to re-run after framework updates
- Optionally initializes a git repo with `--init-git`

### 2. Bootstrap Your Team

Open your project in VS Code with GitHub Copilot, then invoke the Hiring Manager:

```
@hiring-manager Analyze this project and create the specialist agents we need.
```

The Hiring Manager will:
1. Scan your project's tech stack, file structure, and dependencies
2. Identify which specialist roles are needed
3. Create agents tailored to your project
4. Set up the org chart with the new team
5. Run adversarial review on each new agent

### 3. Start Working

Once your team is built, invoke specialists directly:

```
@api-architect Design the REST API for user management
@ui-engineer Build the login form component
@data-engineer Optimize the user search query
```

Or ask the Operator about your team:

```
@operator What agents do we have and what are their capabilities?
@operator What does the api-architect know about our authentication flow?
```

## Architecture

```
your-project/
├── .github/
│   └── agents/                    # Copilot agent definitions
│       ├── operator.agent.md      # Truth-only query interface
│       ├── hiring-manager.agent.md # Team builder
│       └── ...                    # Specialist agents (created by Hiring Manager)
├── .team/
│   ├── org-chart.yaml             # Team structure and hierarchy
│   ├── protocols/                 # Shared operating protocols
│   │   ├── collaboration.md       # How agents communicate
│   │   ├── memory.md              # How agents persist knowledge
│   │   ├── skill-acquisition.md   # How agents find/create skills
│   │   └── agent-template.md      # Template for new agents
│   ├── memory/                    # Per-agent persistent memory
│   ├── skills/                    # Custom skills created by agents
│   └── knowledge/                 # Shared project knowledge base
└── AGENTS.md                      # Global instructions for all agents
```

## Core Concepts

### Agents
Each agent is a `*.agent.md` file with a distinct persona, expertise domain, and scope boundaries. Agents follow shared protocols for collaboration, memory, and skill acquisition.

### Organic Growth
The team starts with just two agents (Operator + Hiring Manager). The Hiring Manager creates specialist agents as project needs emerge. Managers, divisions, and v-teams form only when team size or workload justifies them.

### Truth-Only Operator
The Operator agent can query all team state — memory files, org chart, skills, knowledge base — and never guesses or speculates. Every answer is backed by tool-call evidence. It's the user's trusted window into the team.

### Skill Acquisition
When an agent needs a capability it doesn't have:
1. Checks if it's within its persona (if not, delegates to the right specialist)
2. Searches existing skills, external packages, MCP servers
3. Writes a custom skill with adversarial review
4. Asks the user only as a last resort

### Persistent Memory
Each agent maintains a memory file that accumulates project-specific learnings across sessions. The Operator can search across all agents' memories.

### Collaboration
Agents communicate by spawning each other via the `task` tool with complete context. A max spawn depth of 3 prevents infinite delegation chains.

## Built-in Agents

### Operator (`@operator`)
The team's omniscient, truth-only query interface. Ask it anything about team state, agent knowledge, project context, or session history. It will answer with cited evidence or tell you it doesn't know.

### Hiring Manager (`@hiring-manager`)
The team builder. Analyzes your project, creates specialist agents, maintains the org chart, and manages the skill marketplace. Every new agent passes adversarial review before joining.

## Protocols

| Protocol | Purpose | File |
|----------|---------|------|
| Collaboration | Agent spawning, depth limits, conflict resolution | `.team/protocols/collaboration.md` |
| Memory | Persistent knowledge, shared knowledge base, ADRs | `.team/protocols/memory.md` |
| Skill Acquisition | 7-step flow from self-assess to ask-user | `.team/protocols/skill-acquisition.md` |
| Agent Template | Required structure for new agent.md files | `.team/protocols/agent-template.md` |

## Configuration

### MCP Servers (`.mcp.json`)
Pre-configured with Context7 for documentation lookup. The Hiring Manager can add more MCP servers as the team discovers needs.

### Global Instructions (`AGENTS.md`)
Shared conventions that apply to all agents. Edit this to add project-specific rules.

## Extending

### Adding MCP Servers
Ask the Hiring Manager to evaluate and add new MCP servers:
```
@hiring-manager We need an MCP server for database management. Find and evaluate options.
```

### Custom Skills
Agents create custom skills in `.team/skills/` when external solutions don't exist. Each skill passes adversarial review before use.

### Manual Agent Creation
You can create agents manually by following the template in `.team/protocols/agent-template.md`. The Hiring Manager will integrate them into the org chart.

## Design Principles

1. **Agents stay in their lane** — No scope creep across personas
2. **Grow organically** — Don't hire ahead of need
3. **Truth over convenience** — The Operator never guesses
4. **Evidence-backed** — Skills, decisions, and knowledge cite verifiable sources
5. **Fleet-compatible** — Many agents can run in parallel
6. **Portable** — Designed for Copilot, adaptable to other platforms

## License

MIT
