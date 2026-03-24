---
name: validate
description: Validate the dev-team framework and project state for consistency, schema compliance, and drift detection.
---

# Validate

Run checks to ensure the dev-team framework files are consistent and correct. Used as a pre-commit hook and by the Tech Lead during health checks.

## Checks

Run ALL checks. Report pass/fail for each. Exit non-zero if any check fails.

### 1. YAML Schema Validation

```bash
# Validate org-chart.yaml parses and has required fields
python3 -c "
import yaml, sys
try:
    d = yaml.safe_load(open('.team/org-chart.yaml'))
    team = d.get('team', {})
    assert 'agents' in team, 'Missing team.agents'
    assert isinstance(team['agents'], list), 'team.agents must be a list'
    for a in team['agents']:
        assert 'name' in a, f'Agent missing name: {a}'
        assert 'role' in a, f'Agent {a.get(\"name\",\"?\")} missing role'
        assert 'status' in a, f'Agent {a.get(\"name\",\"?\")} missing status'
        assert a['status'] in ('active','probationary','inactive','deprecated'), \
            f'Agent {a[\"name\"]} has invalid status: {a[\"status\"]}'
    print(f'✅ org-chart.yaml: {len(team[\"agents\"])} agents, all valid')
except Exception as e:
    print(f'❌ org-chart.yaml: {e}', file=sys.stderr)
    sys.exit(1)
"

# Validate config.yaml parses and has required fields
python3 -c "
import yaml, sys
try:
    d = yaml.safe_load(open('.team/config.yaml'))
    upstream = d.get('upstream', {})
    assert 'mode' in upstream, 'Missing upstream.mode'
    assert upstream['mode'] in ('auto','manual','off'), f'Invalid upstream.mode: {upstream[\"mode\"]}'
    print(f'✅ config.yaml: upstream.mode={upstream[\"mode\"]}')
except Exception as e:
    print(f'❌ config.yaml: {e}', file=sys.stderr)
    sys.exit(1)
"
```

### 2. Agent Template Compliance

Every `*.agent.md` file must have required sections. Checks plugin-level agents (`agents/`), project-level agents (`.github/agents/`), and template files (`templates/`).

```bash
errors=0
# Check plugin-level agents
for f in agents/*.agent.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  missing=""

  # Check YAML frontmatter
  head -1 "$f" | grep -q '^---$' || missing="$missing frontmatter"

  # Check required sections (case-insensitive grep)
  grep -qi '## Scope' "$f"           || missing="$missing Scope"
  grep -qi '## Working Style' "$f"   || missing="$missing Working-Style"
  grep -qi '## Self-Reflection' "$f" || missing="$missing Self-Reflection"
  grep -qi '## Protocols' "$f"       || missing="$missing Protocols"

  if [ -n "$missing" ]; then
    echo "❌ agents/$name: missing sections:$missing"
    errors=$((errors + 1))
  else
    echo "✅ agents/$name: all required sections present"
  fi
done

# Check project-level agents
for f in .github/agents/*.agent.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  missing=""
  head -1 "$f" | grep -q '^---$' || missing="$missing frontmatter"
  grep -qi '## Scope' "$f"           || missing="$missing Scope"
  grep -qi '## Working Style' "$f"   || missing="$missing Working-Style"
  grep -qi '## Self-Reflection' "$f" || missing="$missing Self-Reflection"
  grep -qi '## Protocols' "$f"       || missing="$missing Protocols"
  if [ -n "$missing" ]; then
    echo "❌ .github/agents/$name: missing sections:$missing"
    errors=$((errors + 1))
  else
    echo "✅ .github/agents/$name: all required sections present"
  fi
done

# Check template files (when in plugin repo)
for f in templates/*.template.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  missing=""
  head -1 "$f" | grep -q '^---$' || missing="$missing frontmatter"
  grep -qi '## Scope' "$f"           || missing="$missing Scope"
  grep -qi '## Working Style' "$f"   || missing="$missing Working-Style"
  grep -qi '## Self-Reflection' "$f" || missing="$missing Self-Reflection"
  grep -qi '## Protocols' "$f"       || missing="$missing Protocols"
  if [ -n "$missing" ]; then
    echo "❌ templates/$name: missing sections:$missing"
    errors=$((errors + 1))
  else
    echo "✅ templates/$name: all required sections present"
  fi
done

[ $errors -eq 0 ] || exit 1
```

### 3. Cross-Reference Integrity

Agents in org chart must have corresponding files. Delegation targets must be real agents.

```bash
errors=0

# Check org chart agents have files (check both locations)
python3 -c "
import yaml, os, sys
d = yaml.safe_load(open('.team/org-chart.yaml'))
errors = 0
for a in d['team']['agents']:
    name = a['name']
    plugin_path = f'agents/{name}.agent.md'
    project_path = f'.github/agents/{name}.agent.md'
    if os.path.exists(plugin_path):
        print(f'✅ {name} → {plugin_path} (plugin-level)')
    elif os.path.exists(project_path):
        print(f'✅ {name} → {project_path} (project-level)')
    else:
        print(f'❌ Org chart lists \"{name}\" but neither {plugin_path} nor {project_path} exists')
        errors += 1
if errors: sys.exit(1)
"

# Check agent files have org chart entries (both locations)
python3 -c "
import yaml, glob, os, sys
d = yaml.safe_load(open('.team/org-chart.yaml'))
chart_names = {a['name'] for a in d['team']['agents']}
warnings = 0
for pattern in ['agents/*.agent.md', '.github/agents/*.agent.md']:
    for f in glob.glob(pattern):
        name = os.path.basename(f).replace('.agent.md','')
        if name not in chart_names:
            print(f'⚠️  {f} exists but {name} is not in org chart (may be a draft)')
            warnings += 1
if warnings == 0:
    print('✅ All agent files have org chart entries')
# Note: orphaned files are warnings, not errors — they may be templates or drafts
"
```

### 4. Protocol References

Every agent must reference all required protocols.

```bash
required_protocols="collaboration.md memory.md skill-acquisition.md retrospective.md audit.md"
errors=0

for f in agents/*.agent.md .github/agents/*.agent.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  for proto in $required_protocols; do
    if ! grep -q "$proto" "$f"; then
      echo "❌ $name: missing reference to $proto"
      errors=$((errors + 1))
    fi
  done
done

if [ $errors -eq 0 ]; then
  echo "✅ All agents reference all required protocols"
else
  exit 1
fi
```

### 5. Memory Format Check (project-level only)

If memory files exist, check they follow the expected format.

```bash
for f in .team/memory/*.md; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = ".gitkeep" ] && continue
  name=$(basename "$f" .md)

  # Check for at least one structured entry (### header)
  if [ -s "$f" ] && ! grep -q '^### ' "$f"; then
    echo "⚠️  $name memory: has content but no structured entries (### headers)"
  fi
done
echo "✅ Memory format check complete"
```

### 6. Config Consistency

```bash
# Check for contradictory upstream settings
python3 -c "
import yaml, sys
try:
    d = yaml.safe_load(open('.team/config.yaml'))
    upstream = d.get('upstream', {})
    mode = upstream.get('mode', 'off')
    auto_pr = upstream.get('auto_pr', False)
    auto_issue = upstream.get('auto_issue', False)
    
    if mode == 'auto' and not auto_pr and not auto_issue:
        print('⚠️  config.yaml: upstream.mode is \"auto\" but both auto_pr and auto_issue are false')
        print('   Proposals will be written locally but never submitted.')
        print('   Set at least one to true, or change mode to \"manual\".')
    else:
        print(f'✅ config.yaml: upstream settings consistent (mode={mode})')
except Exception as e:
    print(f'❌ config.yaml consistency: {e}', file=sys.stderr)
    sys.exit(1)
"
```

### 7. Entry Point Verification

```bash
# Verify dev-team agent exists in org chart and has an agent file
python3 -c "
import yaml, sys
d = yaml.safe_load(open('.team/org-chart.yaml'))
agent_names = [a['name'] for a in d['team']['agents']]
if 'dev-team' not in agent_names:
    print('⚠️  org-chart: no dev-team entry point agent found')
else:
    print('✅ org-chart: dev-team entry point present')
"
```

### 8. Audit Directory Structure

Verify the `.team/audit/` directory exists with the required structure.

```bash
errors=0

if [ ! -d ".team/audit" ]; then
  echo "❌ .team/audit/ directory does not exist"
  errors=$((errors + 1))
else
  echo "✅ .team/audit/ directory exists"
fi

if [ ! -d ".team/audit/sessions" ]; then
  echo "❌ .team/audit/sessions/ directory does not exist"
  errors=$((errors + 1))
else
  echo "✅ .team/audit/sessions/ directory exists"
fi

if [ ! -f ".team/audit/index.md" ]; then
  echo "❌ .team/audit/index.md does not exist"
  errors=$((errors + 1))
else
  echo "✅ .team/audit/index.md exists"
fi

[ $errors -eq 0 ] || exit 1
```

### 9. Audit Protocol Exists

Verify `audit.md` exists in `.team/protocols/`.

```bash
if [ ! -f ".team/protocols/audit.md" ]; then
  echo "❌ .team/protocols/audit.md does not exist — audit enforcement requires this protocol"
  exit 1
else
  echo "✅ .team/protocols/audit.md exists"
fi
```

### 10. Template Verification

```bash
# When running in the plugin repo, verify templates exist
if [ -d "templates" ]; then
  template_count=$(ls templates/*.template.md 2>/dev/null | wc -l)
  if [ "$template_count" -eq 0 ]; then
    echo "⚠️  templates/ directory exists but contains no .template.md files"
  else
    echo "✅ templates/: $template_count template files found"
  fi
fi

# When running in a project, verify .team/templates/ has specialist templates
if [ -d ".team/templates" ]; then
  specialist_count=$(ls .team/templates/*.template.md 2>/dev/null | wc -l)
  if [ "$specialist_count" -eq 0 ]; then
    echo "⚠️  .team/templates/ exists but contains no specialist templates"
  else
    echo "✅ .team/templates/: $specialist_count specialist templates available"
  fi
fi

# When running in a project, verify core agents exist in .github/agents/
if [ -d ".github/agents" ]; then
  core_agents="project-manager hiring-manager tech-lead operator auditor"
  missing_core=0
  for agent in $core_agents; do
    if [ ! -f ".github/agents/${agent}.agent.md" ]; then
      echo "⚠️  Missing core agent: .github/agents/${agent}.agent.md"
      missing_core=$((missing_core + 1))
    fi
  done
  if [ "$missing_core" -eq 0 ]; then
    echo "✅ All core agents present in .github/agents/"
  fi
fi
```

## Exit Code

- `0` — all checks passed
- `1` — one or more checks failed (blocks commit)

## Usage

Run manually:
```bash
bash -c "$(cat skills/validate/SKILL.md | sed -n '/^```bash$/,/^```$/p' | grep -v '^```')"
```

Or via the pre-commit hook (see `.githooks/pre-commit`).
