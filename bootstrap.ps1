<#
.SYNOPSIS
    Initializes .team/ project state for dev-team.

.DESCRIPTION
    Sets up the per-project state directory that dev-team agents need.
    Install the plugin first: copilot plugin install darinh/dev-team

.PARAMETER Target
    Path to the target repository. Defaults to the current directory.

.PARAMETER InitGit
    Initialize a git repository in the target directory.

.PARAMETER Force
    Overwrite existing files without prompting.

.PARAMETER ExportProposals
    Export upstream improvement proposals from the target project.

.EXAMPLE
    .\bootstrap.ps1 C:\Projects\my-app
    .\bootstrap.ps1 C:\Projects\new-app -InitGit
    .\bootstrap.ps1 C:\Projects\my-app -ExportProposals
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target = ".",

    [switch]$InitGit,
    [switch]$Force,
    [switch]$ExportProposals
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Resolve target
if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}
$Target = (Resolve-Path $Target).Path

# --- Export proposals ---
if ($ExportProposals) {
    $proposalsDir = Join-Path $Target ".team" "knowledge" "upstream-proposals"
    if (-not (Test-Path $proposalsDir)) {
        Write-Host "No upstream proposals directory found."
        exit 0
    }

    $proposals = Get-ChildItem $proposalsDir -Filter "*.md" | Where-Object { $_.Name -ne ".gitkeep" }
    if ($proposals.Count -eq 0) {
        Write-Host "No upstream proposals to export."
        exit 0
    }

    Write-Host "Upstream Improvement Proposals"
    Write-Host "=============================="
    $count = 0
    foreach ($p in $proposals) {
        $count++
        $content = Get-Content $p.FullName -Raw
        $priority = if ($content -match "Priority:\s*(.+)") { $Matches[1].Trim() } else { "unknown" }
        $status = if ($content -match "Submitted:\s*(.+)") { $Matches[1].Trim() } else { "unknown" }
        Write-Host "--- Proposal ${count}: $($p.BaseName) ---"
        Write-Host "  Priority: $priority"
        Write-Host "  Status:   $status"
        Write-Host "  File:     $($p.FullName)"
        Write-Host ""
    }
    Write-Host "Total proposals: $count"
    exit 0
}

# --- Main bootstrap ---
Write-Host "dev-team project setup"
Write-Host "   Target:  $Target"
Write-Host ""

# Git init
if ($InitGit) {
    if (Test-Path (Join-Path $Target ".git")) {
        Write-Host "Target already has a git repository. Skipping -InitGit."
    } else {
        Write-Host "Initializing git repository..."
        git -C $Target init -b main
        Write-Host ""
    }
}

# Check if already initialized
$configPath = Join-Path $Target ".team" "config.yaml"
if ((Test-Path $configPath) -and -not $Force) {
    Write-Host "Project already initialized (.team/config.yaml exists)."
    Write-Host "   Use -Force to reinitialize, or just talk to @dev-team."
    exit 0
}

# Create directories
Write-Host "Creating .team/ directory structure..."
$dirs = @(
    ".team/protocols", ".team/memory", ".team/skills",
    ".team/knowledge/upstream-proposals", ".team/knowledge/retrospectives",
    ".team/knowledge/projects"
)
foreach ($d in $dirs) {
    $path = Join-Path $Target $d
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    $gk = Join-Path $path ".gitkeep"
    if (-not (Test-Path $gk)) {
        New-Item -ItemType File -Path $gk -Force | Out-Null
    }
}

# Helper
function Copy-If-Needed {
    param([string]$Src, [string]$Dst)
    if (-not (Test-Path $Src)) { return }
    if ((Test-Path $Dst) -and -not $Force) {
        Write-Host "   $(Split-Path -Leaf $Dst) (already exists)"
        return
    }
    $parent = Split-Path -Parent $Dst
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item $Src $Dst -Force
    Write-Host "   + $(Split-Path -Leaf $Dst)"
}

# Copy protocols
Write-Host "Copying protocols..."
$protoSrc = Join-Path $ScriptDir "protocols"
if (Test-Path $protoSrc) {
    Get-ChildItem $protoSrc -Filter "*.md" | ForEach-Object {
        Copy-If-Needed $_.FullName (Join-Path $Target ".team" "protocols" $_.Name)
    }
}

# Copy config and org chart
Write-Host "Creating configuration..."
Copy-If-Needed (Join-Path $ScriptDir ".team" "config.yaml") (Join-Path $Target ".team" "config.yaml")
Copy-If-Needed (Join-Path $ScriptDir ".team" "org-chart.yaml") (Join-Path $Target ".team" "org-chart.yaml")
Copy-If-Needed (Join-Path $ScriptDir ".team" "knowledge" "failures.md") (Join-Path $Target ".team" "knowledge" "failures.md")
Copy-If-Needed (Join-Path $ScriptDir "AGENTS.md") (Join-Path $Target "AGENTS.md")

Write-Host ""
Write-Host "Project initialized for dev-team!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Install the plugin: copilot plugin install darinh/dev-team"
Write-Host "  2. Start using it: @dev-team I want to build..."
