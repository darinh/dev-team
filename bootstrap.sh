#!/usr/bin/env bash
set -euo pipefail

# dev-team bootstrap script
# Initializes the .team/ project state directory for a dev-team project.
# The plugin (agents, protocols) is installed separately via:
#   copilot plugin install darinh/dev-team
#
# This script sets up the per-project state that agents need to operate.

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

Initializes .team/ project state for dev-team. Install the plugin first:
  copilot plugin install darinh/dev-team

Options:
  --init-git          Initialize a git repository in the target directory
  --force             Overwrite existing files without prompting
  --export-proposals  Export upstream improvement proposals from the target project
  -h, --help          Show this help message

Examples:
  ./bootstrap.sh /path/to/my-project
  ./bootstrap.sh /path/to/new-project --init-git
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
    priority=$(grep "Priority:" "$proposal" | head -1 | sed 's/.*: *//' || echo "unknown")
    status=$(grep "Submitted:" "$proposal" | head -1 | sed 's/.*: *//' || echo "unknown")
    echo "--- Proposal $count: $name ---"
    echo "  Priority: $priority"
    echo "  Status:   $status"
    echo "  File:     $proposal"
    echo ""
  done

  echo "Total proposals: $count"
  exit 0
fi

# --- Main bootstrap ---
echo "🔨 dev-team project setup"
echo "   Target:  $TARGET"
echo ""

# Git initialization
if [[ "$INIT_GIT" == true ]]; then
  if [[ -d "$TARGET/.git" ]]; then
    echo "⚠  Target already has a git repository. Skipping --init-git."
  else
    echo "📦 Initializing git repository..."
    git -C "$TARGET" init -b main
    echo ""
  fi
fi

# Check if already initialized
if [[ -f "$TARGET/.team/config.yaml" ]] && [[ "$FORCE" != true ]]; then
  echo "✅ Project already initialized (.team/config.yaml exists)."
  echo "   Use --force to reinitialize, or just talk to @dev-team."
  exit 0
fi

# Create directory structure
echo "📁 Creating .team/ directory structure..."
mkdir -p "$TARGET/.team/protocols" \
         "$TARGET/.team/memory" \
         "$TARGET/.team/skills" \
         "$TARGET/.team/knowledge/upstream-proposals" \
         "$TARGET/.team/knowledge/retrospectives" \
         "$TARGET/.team/knowledge/projects"

# Create .gitkeep files
for dir in memory skills knowledge/upstream-proposals knowledge/retrospectives knowledge/projects; do
  touch "$TARGET/.team/$dir/.gitkeep"
done

# Copy protocols from plugin
echo "📁 Copying protocols..."
if [[ -d "$SCRIPT_DIR/protocols" ]]; then
  for protocol_file in "$SCRIPT_DIR"/protocols/*.md; do
    [[ -f "$protocol_file" ]] || continue
    dest="$TARGET/.team/protocols/$(basename "$protocol_file")"
    if [[ -f "$dest" ]] && [[ "$FORCE" != true ]]; then
      echo "   ✓ $(basename "$dest") (already exists)"
    else
      cp "$protocol_file" "$dest"
      echo "   + $(basename "$dest")"
    fi
  done
else
  echo "   ⚠ Protocol files not found at $SCRIPT_DIR/protocols/"
  echo "     They will be copied when @dev-team runs setup."
fi

# Copy default config and org chart
echo "📁 Creating configuration..."
for tmpl in config.yaml org-chart.yaml; do
  src="$SCRIPT_DIR/.team/$tmpl"
  dest="$TARGET/.team/$tmpl"
  if [[ -f "$src" ]]; then
    if [[ -f "$dest" ]] && [[ "$FORCE" != true ]]; then
      echo "   ✓ $tmpl (already exists)"
    else
      cp "$src" "$dest"
      echo "   + $tmpl"
    fi
  fi
done

# Copy failure journal template
if [[ ! -f "$TARGET/.team/knowledge/failures.md" ]] || [[ "$FORCE" == true ]]; then
  src="$SCRIPT_DIR/.team/knowledge/failures.md"
  if [[ -f "$src" ]]; then
    cp "$src" "$TARGET/.team/knowledge/failures.md"
    echo "   + failures.md"
  fi
fi

# Copy AGENTS.md
src="$SCRIPT_DIR/AGENTS.md"
dest="$TARGET/AGENTS.md"
if [[ -f "$src" ]]; then
  if [[ -f "$dest" ]] && [[ "$FORCE" != true ]]; then
    echo "   ✓ AGENTS.md (already exists)"
  else
    cp "$src" "$dest"
    echo "   + AGENTS.md"
  fi
fi

echo ""
echo "✅ Project initialized for dev-team!"
echo ""
echo "Next steps:"
echo "  1. Install the plugin (if you haven't already):"
echo "     copilot plugin install darinh/dev-team"
echo "  2. Start using it:"
echo "     @dev-team I want to build..."
echo ""
