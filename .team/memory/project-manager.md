# Project Manager Memory

## OUTCOME: Team Coordination Fix Plan — 2025-07-25

**Task**: Create comprehensive plan to fix systemic team coordination failures discovered during nonogram project audit.
**Result**: ACCEPTED — Plan created with 19 todos across 7 parallel groups.
**Branch**: `fix/team-coordination-enforcement` in ~/projects/dev-team

### Key Decisions
1. **ALL agents become templates except dev-team**: ALL 9 non-entry-point agents become `.template.md` files in `templates/`. dev-team is the SOLE plugin-level agent — must remain for bootstrapping to work.
2. **Core agents created during bootstrap**: PM, hiring-manager, tech-lead, operator, auditor templates are copied to `.github/agents/` during bootstrap → every project gets them.
3. **Specialist agents created on-demand**: api-engineer, ui-engineer, qa-engineer, security-analyst templates stored in `.team/templates/` → Hiring Manager copies to `.github/agents/` when needed.
4. **dev-team as enforcer**: dev-team gets "Enforcement Responsibilities" section — specialist-exists check, anti-PM-coding gate, post-completion audit, OUTCOME verification, session-end auditor invocation.
5. **User feedback incorporated**: User requested ALL agents (including core) become templates so projects can customize them. This changed the plan from 6 core agents + 4 specialist templates to 1 plugin agent + 9 templates.

### Findings from Analysis
- dev-team routing table sends ALL implementation work to PM — root cause of PM doing all coding
- bootstrap-project has an audit.md gap: fallback stub loop creates 5 protocols but omits audit
- validate skill only checks 4 protocols (missing audit.md entirely)
- No agent has an enforcement mechanism for audit logging — it's documented but never checked
- Hiring Manager references "pre-built specialists in agents/" but never considers that they might need creation for a project

### Evidence
- Plan: `/home/darin/.copilot/session-state/85678f73-54cc-4eb6-b2cf-9f4c6f73c5d2/plan.md`
- 19 todos in SQL database, 18 with no dependencies (max parallelism), 1 (rewrite-hiring-manager) blocked on 4 template moves
- All 10 agent files, 6 protocols, 3 skills, config.yaml, org-chart.yaml analyzed
