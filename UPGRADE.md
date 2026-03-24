# Upgrade Guide

This document describes migration steps when upgrading the dev-team plugin.

## Checking Your Version

Your project's framework version is in `.team/config.yaml`:
```yaml
framework:
  version: "2.1.0"
```

The installed plugin version is in `plugin.json`. If these differ, run the upgrade skill or follow the steps below.

## v2.0.0 → v2.1.0

**Type**: Minor (no breaking changes)

### Changes
- Added `commit-msg` git hook enforcing Conventional Commits format
- Added `framework.version` tracking in project config

### Migration Steps
1. Copy `.githooks/commit-msg` to your project's `.githooks/` (if using git hooks)
2. Add `framework:` section to `.team/config.yaml`:
   ```yaml
   framework:
     version: "2.1.0"
     installed_at: "2026-03-24"
     last_upgraded: null
   ```

## v1.x → v2.0.0

**Type**: Major (BREAKING CHANGES)

### Breaking Changes
- All agents except `dev-team` moved from `agents/` to `templates/`
- Specialist agents no longer auto-load for every project
- Collaboration protocol requires structured handoff schema

### Migration Steps
1. Delete `.team/` directory: `rm -rf .team/`
2. Re-run `@dev-team` to trigger fresh bootstrap with new template system
3. Or manually:
   - Create `templates/` directory
   - Copy agent templates from plugin's `templates/` to project
   - Create `.github/agents/` for project-level agents
   - Create `.team/audit/sessions/` directory
   - Copy `protocols/audit.md` to `.team/protocols/`
   - Update `.team/org-chart.yaml` to reference new agent locations
