# Collaboration Protocol

This protocol governs how agents communicate, delegate work, and resolve dependencies.

## Finding the Right Agent

Before reaching out to another agent, follow this lookup order:

1. **Read `.team/org-chart.yaml`** — Find the agent whose domain covers your need
2. **Check for v-teams** — If a cross-functional v-team exists for the current initiative, prefer its members
3. **Check agent persona** — Read the target agent's description in the org chart to confirm they handle your request
4. **Escalate if unclear** — If no agent covers the domain, contact the Hiring Manager to assess whether a new agent is needed

## Spawning an Agent

Use the `task` tool to spawn another agent. Every spawn must include:

```
agent_type: "{agent-name}"  # From the org chart
prompt: |
  ## Context
  [What you're working on and why you need this agent's help]

  ## Request
  [Specific, actionable request with clear deliverables]

  ## Acceptance Criteria
  [What "done" looks like — be measurable]

  ## Constraints
  [Technical constraints, compatibility requirements, deadlines]

  ## Files
  [Relevant file paths the agent should read]
```

### Spawning Rules

1. **Complete context** — The target agent is stateless. Provide everything it needs.
2. **One request per spawn** — Don't bundle unrelated tasks into one prompt
3. **Specify deliverables** — "Write the function" not "think about the function"
4. **Include file paths** — Always reference specific files, not vague descriptions
5. **State your depth** — Include `Spawn depth: N` so the target agent knows how deep the chain is
6. **Increment depth** — If you received `Spawn depth: N` in your prompt, include `Spawn depth: N+1` in any agents you spawn. If N+1 > 3, do NOT spawn — solve it yourself or return to the caller.

## Spawn Depth Limit

**Maximum spawn depth: 3 levels.**

```
User → Agent A (depth 1) → Agent B (depth 2) → Agent C (depth 3) → STOP
```

At depth 3, the agent must:
- Solve the problem itself if within its persona
- Return to the calling agent with a clear explanation of what it cannot do
- Never spawn another agent

### Enforcement

Spawn depth is self-enforced via the `Spawn depth: N` marker in every spawn prompt:
1. The initiating agent (spawned by the user or @dev-team) sets `Spawn depth: 1`
2. Each subsequent spawn increments: `Spawn depth: 2`, `Spawn depth: 3`
3. At depth 3, the agent MUST NOT spawn. It solves the problem itself or returns with a clear explanation.
4. If a spawn prompt arrives WITHOUT a depth marker, treat it as depth 1 (assume the user or entry point spawned you).

## Delegation Rules

### Implementation Work Routing
- Implementation work MUST go to specialist agents, NEVER to Project Manager
- Project Manager decomposes work into tasks and identifies which specialist handles each
- If no specialist exists for a task, escalate to dev-team → Hiring Manager creates one
- dev-team NEVER falls back to `general-purpose` agents when a template exists

### Specialist Creation Before Work
When dev-team receives implementation work:
1. Check org-chart for matching specialist
2. If none exists → invoke Hiring Manager with the template
3. Hiring Manager creates `.github/agents/{name}.agent.md` from `templates/{name}.template.md`
4. Updates org-chart with new agent
5. THEN route work to the new specialist

### Enforcement Rules

These rules are enforced by dev-team and are non-negotiable:

1. **Implementation work MUST go to specialist agents, NEVER to the Project Manager.** PM plans, decomposes, and gathers requirements. Specialists write code, fix bugs, and implement features. If dev-team routes implementation to PM, PM must refuse and redirect.

2. **If no specialist exists for the required domain, the Hiring Manager must create one BEFORE implementation begins.** Never start coding without the right specialist. The Hiring Manager can create specialists from templates in minutes.

3. **dev-team is responsible for enforcing these routing rules.** dev-team checks the org chart before routing and invokes the Hiring Manager when specialists are missing.

### Handoff Requirements
Every agent completing implementation work MUST:
1. Run build command and report exit code
2. Run test command and report exit code + summary
3. List files modified
4. Write handoff audit entry
5. Write OUTCOME in memory file

## Structured Handoff Schema

When passing work between agents, use this required format in your spawn prompt. This prevents context loss and ensures the receiving agent can independently verify claims.

```yaml
handoff:
  task_id: "task_{6-char-hex}"          # from audit log task_created entry
  from: "{sending-agent}"
  to: "{receiving-agent}"
  spawn_depth: N
  files_modified:
    - "path/to/file1"
    - "path/to/file2"
  build_command: "npm run build"
  build_exit_code: 0
  tests_run: "npm test -- --testPathPattern=auth"
  test_exit_code: 0
  test_summary: "47 passed, 0 failed"
  known_issues:
    - "Description of any known issue — or empty list"
  acceptance_criteria:
    - "Criterion 1 from the original task"
    - "Criterion 2"
  audit_handoff_event_id: "evt_{6-char-hex}"  # the handoff event written to the audit log
```

The receiving agent **must**:
1. Run the stated `build_command` and `tests_run` independently
2. Verify exit codes and summaries match
3. Write a `handoff_verification` audit entry before proceeding

## Audit Log Requirements

Every agent must write to the audit log at `.team/audit/sessions/` per `.team/protocols/audit.md`:

- Write `task_created` when beginning any tracked task
- Write `adversarial_review` after every adversarial review (one entry per reviewer model)
- Write `handoff` before sending work to another agent
- Write `handoff_verification` after independently verifying a received handoff
- Write `decision` for non-trivial choices on Large/🔴 tasks
- Write `escalation` when hitting depth limits or protocol overrides

**These are not optional.** Missing audit entries for required events are protocol violations, surfaced by the Auditor.

## Handling Results

When a spawned agent returns:

1. **Verify the output** — Don't blindly trust. Check that acceptance criteria are met.
2. **Run the tests yourself** — If the agent produced code, run the stated build and test commands independently. Don't trust claimed exit codes without verifying.
3. **Write a handoff_verification audit entry** — Record what you ran, what you found, and whether claims matched before proceeding.
4. **Incorporate or reject** — If the output doesn't meet criteria, re-spawn with clarified requirements (max 2 retries).
5. **Credit the agent** — In your memory file, note which agent helped with what.

## Escalation

When collaboration fails:

1. **Retry with clarification** — Re-spawn with a more specific prompt (1 retry allowed)
2. **Escalate to manager** — If the agent's manager exists in the org chart, escalate to them
3. **Escalate to Hiring Manager** — If no manager, or the manager can't resolve, go to the Hiring Manager
4. **Escalate to user** — Only after all agent-level escalation is exhausted

### Loop Prevention

**PM ↔ HM special case:** The Project Manager and Hiring Manager have a direct working relationship. If an escalation bounces between them (PM escalates to HM, HM escalates back to PM), the second agent must escalate directly to the **user** instead of back to the first agent. One hop max between PM and HM before user escalation.

## Parallel Collaboration

When you need multiple agents simultaneously:

1. **Launch in parallel** — Spawn independent agents in the same response using multiple `task` calls
2. **Define interfaces first** — If agents' outputs must be compatible, document the interface in `.team/knowledge/contracts/` first
3. **Aggregate results** — After all agents return, integrate their outputs and run integration verification

## Conflict Resolution

When two agents disagree on an approach:

1. **Evidence wins** — The approach with tool-verified evidence takes precedence
2. **Domain expertise wins** — If both have evidence, the domain specialist's opinion takes precedence
3. **Manager arbitrates** — If still unresolved, the relevant manager (or Hiring Manager) decides
4. **Document the decision** — Record the disagreement and resolution in `.team/knowledge/decisions/`

## Anti-Patterns

❌ **Shotgun spawning** — Spawning many agents hoping one will solve your problem
❌ **Context hoarding** — Not providing enough context to the spawned agent
❌ **Infinite delegation** — Passing work down without adding value at each level
❌ **Scope creep in spawns** — Asking an agent to do things outside its persona
❌ **Ignoring results** — Not verifying spawned agent output before using it
