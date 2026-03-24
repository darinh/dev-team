---
name: upgrade-project
description: Upgrade a project's dev-team framework files to match the current plugin version.
---

# Upgrade Project

Upgrades a project's `.team/` framework files when the plugin version is newer than the project's recorded `framework.version`.

## Prerequisites
- `.team/config.yaml` must exist (project already bootstrapped)
- Plugin installation directory must be discoverable

## Steps

### 1. Detect Plugin Directory
```bash
PLUGIN_DIR=""
for candidate in \
  ~/.copilot/installed-plugins/_direct/darinh--dev-team \
  ~/.copilot/installed-plugins/dev-team \
  ~/.copilot/state/installed-plugins/_direct/darinh--dev-team \
  ~/.copilot/state/installed-plugins/dev-team; do
  if [ -d "$candidate" ]; then
    PLUGIN_DIR="$candidate"
    break
  fi
done
```

### 2. Read Versions
```bash
# Plugin version
PLUGIN_VERSION=$(python3 -c "import json; print(json.load(open('$PLUGIN_DIR/plugin.json'))['version'])" 2>/dev/null || echo "unknown")

# Project version
PROJECT_VERSION=$(python3 -c "import yaml; print(yaml.safe_load(open('.team/config.yaml')).get('framework',{}).get('version','unknown'))" 2>/dev/null || echo "unknown")
```

### 3. Compare Versions
```python
import re

def parse_version(v):
    m = re.match(r'(\d+)\.(\d+)\.(\d+)', v)
    return tuple(int(x) for x in m.groups()) if m else (0,0,0)

plugin = parse_version(PLUGIN_VERSION)
project = parse_version(PROJECT_VERSION)

if plugin == project:
    print("Already up to date")
elif plugin[0] > project[0]:
    print("MAJOR upgrade required")
elif plugin[1] > project[1]:
    print("MINOR upgrade")
else:
    print("PATCH upgrade")
```

### 4. Apply Upgrade

#### For PATCH or MINOR upgrades (auto-apply):
1. Copy updated protocol files from plugin:
   ```bash
   cp "$PLUGIN_DIR"/protocols/*.md .team/protocols/
   ```
2. Update templates in `.github/agents/` from plugin templates:
   ```bash
   if [ -d "$PLUGIN_DIR/templates" ]; then
     for template in "$PLUGIN_DIR"/templates/*.template.md; do
       name=$(basename "$template" .template.md)
       if [ -f ".github/agents/$name.agent.md" ]; then
         cp "$template" ".github/agents/$name.agent.md"
       fi
     done
   fi
   ```
3. Update framework version in config:
   ```python
   import yaml
   with open('.team/config.yaml') as f:
       config = yaml.safe_load(f)
   config.setdefault('framework', {})['version'] = PLUGIN_VERSION
   config['framework']['last_upgraded'] = datetime.date.today().isoformat()
   with open('.team/config.yaml', 'w') as f:
       yaml.dump(config, f, default_flow_style=False)
   ```
4. Report changes to user

#### For MAJOR upgrades (require confirmation):
1. Display breaking changes from UPGRADE.md
2. Ask user for confirmation before proceeding
3. If confirmed:
   - Create any new required directories (e.g., `.team/audit/sessions/`)
   - Copy new protocol files
   - Update agent templates
   - Update config version
4. If declined: skip upgrade, warn that some features may not work

### 5. Commit Changes
```bash
git add .team/ .github/agents/
git commit --author="DevTeam/dev-team <dev-team@dev-team.local>" \
  -m "chore: upgrade dev-team framework to v${PLUGIN_VERSION}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### 6. Report
Output summary: what was upgraded, which files changed, new vs old version.
