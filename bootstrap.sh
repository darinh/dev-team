#!/usr/bin/env bash
set -euo pipefail

# dev-team bootstrap script
# Installs the dev-team multi-agent framework into a new or existing repository.
#
# Usage:
#   ./bootstrap.sh /path/to/target-repo
#   ./bootstrap.sh .                        # current directory
#   ./bootstrap.sh /path/to/new-project --init-git

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"
INIT_GIT=false
FORCE=false
EXPORT_PROPOSALS=false

# Parse flags
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --init-git) INIT_GIT=true; shift ;;
    --force)    FORCE=true; shift ;;
    --export-proposals) EXPORT_PROPOSALS=true; shift ;;
    --help|-h)
      cat <<'EOF'
Usage: bootstrap.sh <target-directory> [options]

Options:
  --init-git          Initialize a git repository in the target directory
  --force             Overwrite existing files without prompting
  --export-proposals  Export upstream improvement proposals from the target project
  -h, --help          Show this help message

Examples:
  ./bootstrap.sh /path/to/my-project
  ./bootstrap.sh /path/to/new-project --init-git
  ./bootstrap.sh . --force
  ./bootstrap.sh /path/to/my-project --export-proposals
EOF
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Resolve target to absolute path
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

echo "🔨 dev-team bootstrap"
echo "   Source:  $SCRIPT_DIR"
echo "   Target:  $TARGET"
echo ""

# --- Git initialization ---
if [[ "$INIT_GIT" == true ]]; then
  if [[ -d "$TARGET/.git" ]]; then
    echo "⚠  Target already has a git repository. Skipping --init-git."
  else
    echo "📦 Initializing git repository..."
    git -C "$TARGET" init -b main
    echo ""
  fi
fi

# Verify target is a git repo (warn if not, but don't block)
if [[ ! -d "$TARGET/.git" ]]; then
  echo "⚠  Target is not a git repository. Files will be copied but not committed."
  echo "   Run with --init-git to initialize one, or run 'git init' yourself."
  echo ""
fi

# --- Helper: copy file with conflict detection ---
copy_file() {
  local src="$1"
  local dest="$2"

  if [[ -f "$dest" ]] && [[ "$FORCE" != true ]]; then
    if diff -q "$src" "$dest" > /dev/null 2>&1; then
      echo "   ✓ $(basename "$dest") (already up to date)"
      return 0
    fi
    echo "   ⚠ $(basename "$dest") exists and differs — skipped (use --force to overwrite)"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "   + $(basename "$dest")"
}

# --- Copy framework files ---

echo "📁 Installing agent definitions..."
mkdir -p "$TARGET/.github/agents"
for agent_file in "$SCRIPT_DIR"/.github/agents/*.agent.md; do
  [[ -f "$agent_file" ]] || continue
  copy_file "$agent_file" "$TARGET/.github/agents/$(basename "$agent_file")"
done

echo "📁 Installing team infrastructure..."
mkdir -p "$TARGET/.team/protocols" "$TARGET/.team/memory" "$TARGET/.team/skills" "$TARGET/.team/knowledge"

for protocol_file in "$SCRIPT_DIR"/.team/protocols/*.md; do
  [[ -f "$protocol_file" ]] || continue
  copy_file "$protocol_file" "$TARGET/.team/protocols/$(basename "$protocol_file")"
done

copy_file "$SCRIPT_DIR/.team/org-chart.yaml" "$TARGET/.team/org-chart.yaml"
copy_file "$SCRIPT_DIR/.team/config.yaml" "$TARGET/.team/config.yaml"

# Ensure .gitkeep files exist in empty dirs
for dir in memory skills knowledge; do
  touch "$TARGET/.team/$dir/.gitkeep"
done

# Create knowledge subdirs
mkdir -p "$TARGET/.team/knowledge/upstream-proposals" "$TARGET/.team/knowledge/retrospectives"
touch "$TARGET/.team/knowledge/upstream-proposals/.gitkeep" "$TARGET/.team/knowledge/retrospectives/.gitkeep"

# Copy failure journal template if not exists
if [[ ! -f "$TARGET/.team/knowledge/failures.md" ]]; then
  copy_file "$SCRIPT_DIR/.team/knowledge/failures.md" "$TARGET/.team/knowledge/failures.md"
fi

echo "📁 Installing configuration..."
copy_file "$SCRIPT_DIR/AGENTS.md" "$TARGET/AGENTS.md"
copy_file "$SCRIPT_DIR/plugin.json" "$TARGET/plugin.json"

# .mcp.json: merge if target already has one, otherwise copy
if [[ -f "$TARGET/.mcp.json" ]]; then
  # Check if context7 is already configured
  if grep -q "context7" "$TARGET/.mcp.json" 2>/dev/null; then
    echo "   ✓ .mcp.json (context7 already configured)"
  else
    echo "   ⚠ .mcp.json exists — add context7 manually from $SCRIPT_DIR/.mcp.json"
  fi
else
  copy_file "$SCRIPT_DIR/.mcp.json" "$TARGET/.mcp.json"
fi

# --- Add .team/ to .gitignore entries that should be ignored ---
# (nothing to ignore — all .team/ files should be tracked)

# --- Export upstream proposals ---
if [[ "$EXPORT_PROPOSALS" == true ]]; then
  proposals_dir="$TARGET/.team/knowledge/upstream-proposals"
  if [[ ! -d "$proposals_dir" ]]; then
    echo "⚠  No upstream proposals directory found at $proposals_dir"
    exit 0
  fi

  proposal_files=$(find "$proposals_dir" -name "*.md" ! -name ".gitkeep" 2>/dev/null)
  if [[ -z "$proposal_files" ]]; then
    echo "✅ No upstream proposals to export."
    exit 0
  fi

  echo "📋 Upstream Improvement Proposals"
  echo "================================="
  echo ""

  count=0
  for proposal in $proposal_files; do
    count=$((count + 1))
    name=$(basename "$proposal" .md)
    # Extract key fields
    classification=$(grep -A1 "## Classification" "$proposal" | tail -1 || echo "unknown")
    priority=$(grep "Priority:" "$proposal" | head -1 | sed 's/.*: *//' || echo "unknown")
    status=$(grep "Submitted:" "$proposal" | head -1 | sed 's/.*: *//' || echo "unknown")
    echo "--- Proposal $count: $name ---"
    echo "  Priority: $priority"
    echo "  Status:   $status"
    echo "  File:     $proposal"
    echo ""
  done

  echo "Total proposals: $count"
  echo ""
  echo "To review a proposal: cat <file>"
  echo "To submit as PR: copy the 'Proposed Change' section to the framework repo"
  exit 0
fi

echo ""
echo "✅ dev-team framework installed!"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. git add -A && git commit -m 'Add dev-team multi-agent framework'"
echo "  3. Invoke @hiring-manager to build your team:"
echo "     @hiring-manager Analyze this project and create the specialist agents we need."
echo ""
