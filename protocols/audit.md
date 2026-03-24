# Audit Protocol

The audit log is the team's ground truth. Agent memory files record learnings; the audit log records events. They serve different purposes and neither replaces the other.

Every agent **must** follow this protocol. The Auditor agent is the primary consumer of the log, but any agent or user can read it.

---

## Principles

1. **Append at action time, not recollection time** — Write audit entries *as* you perform actions, not as a summary afterward.
2. **No agent owns the log** — All agents write to the shared session log. No agent may modify or delete existing entries.
3. **Claims require evidence** — Every entry must include verifiable evidence (file paths, command output, exit codes). Prose assertions without evidence are invalid.
4. **Silence is a finding** — A missing audit entry (e.g., no adversarial review for a 🔴 task) is itself an audit failure, surfaced by the Auditor.
5. **One line per event** — Write compact JSON (no pretty-printing). Line-oriented tools must be able to parse the log with `jq`.

---

## Log Location

```
.team/audit/
├── sessions/
│   └── {ISO8601-datetime}.jsonl     # one file per work session
└── index.md                          # human-readable session index, updated by Auditor
```

Session files are named with the UTC timestamp of the first event in that session, e.g. `2026-03-22T14:30:00Z.jsonl`.

**Starting a session:** The first agent to act in a new session creates the file. Check for an existing session file from the current session before creating a new one — use the most recent `.jsonl` file if it exists from the same calendar day and work context.

---

## Event Schema

All events share a common envelope:

```
{"id":"evt_{6-char-hex}","ts":"{ISO8601 UTC}","type":"{event_type}","task_id":"{task_id or null}","agent":"{agent-name}",...type-specific fields...}
```

- Generate `id` as `evt_` followed by 6 random hex characters (e.g. `evt_a3f9b2`)
- Generate `task_id` as `task_` followed by 6 random hex characters when creating a new task
- All timestamps in UTC ISO 8601 format

---

## Event Types

### `task_created`

Written by the agent (usually Project Manager or dev-team) that decomposes a user request into a tracked task.

Required fields: `title`, `assigned_to`, `risk_level` (green/yellow/red), `acceptance_criteria` (array), `customer_intent`

```
{"id":"evt_a1b2c3","ts":"2026-03-22T14:30:01Z","type":"task_created","task_id":"task_7c4d1e","agent":"project-manager","title":"Implement JWT authentication middleware","assigned_to":"api-engineer","risk_level":"red","acceptance_criteria":["All existing auth tests pass","New unit tests cover happy path and token expiry","Build passes clean"],"customer_intent":"Users log in with email/password and receive a JWT valid for 24 hours"}
```

### `task_completed`

Written by the assigned agent when work is done and ready for handoff or delivery.

`disposition` values: `ready_for_handoff`, `delivered_to_user`, `blocked`, `abandoned`

Required fields: `disposition`, `criteria_met` (array), `criteria_unmet` (array), `evidence`

```
{"id":"evt_d4e5f6","ts":"2026-03-22T14:44:00Z","type":"task_completed","task_id":"task_7c4d1e","agent":"api-engineer","disposition":"ready_for_handoff","criteria_met":["All existing auth tests pass","Build passes clean"],"criteria_unmet":[],"evidence":"npm test exit code 0, 94% coverage, build log shows 0 warnings"}
```

### `adversarial_review`

Written by the agent that *requested* the review, immediately after receiving results.

`resolution` values: `fixed_before_handoff`, `accepted_as_known_issue`, `disputed`, `requires_escalation`

Required fields: `reviewer_model`, `review_round`, `findings` (array of `{severity, description, file?, line?}`), `resolution`, `resolution_evidence`

```
{"id":"evt_g7h8i9","ts":"2026-03-22T14:41:10Z","type":"adversarial_review","task_id":"task_7c4d1e","agent":"api-engineer","reviewer_model":"gemini-2.5-pro","review_round":1,"findings":[{"severity":"high","description":"JWT secret read from env with no guard — throws at runtime if var missing","file":"src/auth/jwt.ts","line":12},{"severity":"low","description":"Missing rate limiting on /auth/refresh","file":"src/routes/auth.ts","line":34}],"resolution":"fixed_before_handoff","resolution_evidence":"Added env guard with startup check; rate limiting deferred and logged as known issue","known_issues_logged":["Missing rate limiting on /auth/refresh"]}
```

For Large/🔴 tasks requiring 3 reviewers, write one `adversarial_review` entry per reviewer model.

### `handoff`

Written by the *sending* agent at the moment of handoff. The `claims_verified_by_receiver` field is always `null` here — the receiver fills it in via `handoff_verification`.

Required fields: `from`, `to`, `spawn_depth`, `files_modified`, `build_status`, `build_command`, `build_exit_code`, `tests_run`, `test_exit_code`, `test_summary`, `known_issues`

```
{"id":"evt_j1k2l3","ts":"2026-03-22T14:45:22Z","type":"handoff","task_id":"task_7c4d1e","agent":"api-engineer","from":"api-engineer","to":"qa-engineer","spawn_depth":2,"files_modified":["src/auth/jwt.ts","src/middleware/auth.ts","test/auth.test.ts"],"build_status":"pass","build_command":"npm run build","build_exit_code":0,"tests_run":"npm test -- --testPathPattern=auth","test_exit_code":0,"test_summary":"47 passed, 0 failed","known_issues":["Missing rate limiting on /auth/refresh — deferred, logged in failures.md"],"claims_verified_by_receiver":null}
```

### `handoff_verification`

Written by the *receiving* agent after independently verifying the handoff claims. If `claims_verified` is false or `discrepancies` is non-empty, the agent must escalate before proceeding.

Required fields: `handoff_event_id`, `claims_verified`, `verification_steps` (array), `discrepancies` (array), `accepted`

```
{"id":"evt_m4n5o6","ts":"2026-03-22T14:52:10Z","type":"handoff_verification","task_id":"task_7c4d1e","agent":"qa-engineer","handoff_event_id":"evt_j1k2l3","claims_verified":true,"verification_steps":["Ran npm run build — exit code 0","Ran npm test -- --testPathPattern=auth — 47 passed, 0 failed","Reviewed src/auth/jwt.ts — env guard present at line 8"],"discrepancies":[],"accepted":true}
```

### `decision`

Written by any agent when making a non-trivial technical or process decision.

Required fields: `decision`, `rationale`, `alternatives_considered` (array), `evidence`

```
{"id":"evt_p7q8r9","ts":"2026-03-22T14:32:00Z","type":"decision","task_id":"task_7c4d1e","agent":"api-engineer","decision":"Use jose library for JWT instead of jsonwebtoken","rationale":"jose is actively maintained, supports Edge runtime, first-class TS types. jsonwebtoken has 3 unpatched CVEs as of 2026-03.","alternatives_considered":["jsonwebtoken","passport-jwt"],"evidence":"npm audit output, jose GitHub activity log"}
```

### `escalation`

Written when an agent hits a depth limit, cannot complete a task, or overrides normal protocol.

`reason` values: `depth_limit`, `skill_gap`, `conflicting_instructions`, `protocol_override`, `blocked_dependency`

Required fields: `reason`, `detail`, `resolution`

```
{"id":"evt_s1t2u3","ts":"2026-03-22T15:01:00Z","type":"escalation","task_id":"task_7c4d1e","agent":"qa-engineer","reason":"depth_limit","detail":"At spawn depth 3 — cannot spawn security-reviewer for auth audit. Escalating to user.","resolution":"user_intervention_requested"}
```

### `audit_summary`

Written by the Auditor agent at the end of a session or when explicitly invoked. `task_id` is null since this is a session-level event.

```
{"id":"evt_v4w5x6","ts":"2026-03-22T16:00:00Z","type":"audit_summary","task_id":null,"agent":"auditor","session_file":"2026-03-22T14:30:00Z.jsonl","tasks_reviewed":["task_7c4d1e"],"findings":[{"task_id":"task_7c4d1e","passed":true,"adversarial_reviews_required":3,"adversarial_reviews_found":3,"handoffs_with_verification":1,"handoffs_without_verification":0,"criteria_met":true,"customer_intent_addressed":true,"notes":""}],"overall":"pass","recommendations":[]}
```

---

## Required Entries by Task Size

| Task Size | Adversarial Reviews | Required Audit Entries |
|-----------|--------------------|-----------------------|
| Small 🟢  | 0                  | `task_created`, `task_completed` |
| Medium 🟡 | 1                  | Above + `adversarial_review` ×1, `handoff`, `handoff_verification` |
| Large 🔴  | 3                  | Above + `adversarial_review` ×3, all `decision` entries |

🔴 files (auth, crypto, payments, data deletion, schema migrations, public API surface) escalate any task to Large regardless of scope.

---

## Writing to the Log

Use the file append tool. One JSON object per line, no indentation.

```bash
# Correct
echo '{"id":"evt_a1b2c3","ts":"2026-03-22T14:30:01Z","type":"task_created",...}' >> .team/audit/sessions/2026-03-22T14:30:00Z.jsonl

# Wrong — multi-line JSON breaks line-oriented parsing
```

---

## Reading the Log

Query with `jq` for structured analysis:

```bash
# All events for a task
jq 'select(.task_id == "task_7c4d1e")' .team/audit/sessions/*.jsonl

# All adversarial reviews in a session
jq 'select(.type == "adversarial_review")' .team/audit/sessions/2026-03-22T14:30:00Z.jsonl

# Tasks with missing handoff verification
jq 'select(.type == "handoff") | .id' .team/audit/sessions/*.jsonl | while read id; do
  jq --arg id "$id" 'select(.type == "handoff_verification" and .handoff_event_id == $id)' .team/audit/sessions/*.jsonl
done

# Count findings by severity across all sessions
jq '[select(.type == "adversarial_review") | .findings[]] | group_by(.severity) | map({severity: .[0].severity, count: length})' .team/audit/sessions/*.jsonl
```

The Auditor agent is the primary reader of this log. Any agent or user may also read it.

---

## Enforcement

### Primary Enforcer: dev-team
The dev-team agent is the primary audit enforcer:
- Writes `task_created` on every spawn
- Writes `task_completed` on every completion
- Verifies OUTCOME entries exist in agent memory after each task
- Invokes the Auditor at session end to review compliance
- Creates audit session files at `.team/audit/sessions/{ISO-datetime}.jsonl`

### Secondary Enforcer: Auditor
The Auditor agent reviews completed sessions:
- Reads `.team/audit/sessions/*.jsonl`
- Verifies all tasks have required entries (by task size)
- Checks handoff verification exists for all handoffs
- Writes `audit_summary` entry
- Updates `.team/audit/index.md`
- Reports compliance gaps to dev-team

### Minimum Required Entries
Every task, regardless of size, MUST have:
- `task_created` (written by dev-team on spawn)
- `task_completed` (written by dev-team on completion)
- OUTCOME entry in the agent's memory file
