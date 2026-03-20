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

## Spawn Depth Limit

**Maximum spawn depth: 3 levels.**

```
User → Agent A (depth 1) → Agent B (depth 2) → Agent C (depth 3) → STOP
```

At depth 3, the agent must:
- Solve the problem itself if within its persona
- Return to the calling agent with a clear explanation of what it cannot do
- Never spawn another agent

## Handling Results

When a spawned agent returns:

1. **Verify the output** — Don't blindly trust. Check that acceptance criteria are met.
2. **Test if applicable** — If the agent produced code, run the relevant tests.
3. **Incorporate or reject** — If the output doesn't meet criteria, re-spawn with clarified requirements (max 2 retries).
4. **Credit the agent** — In your memory file, note which agent helped with what.

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
