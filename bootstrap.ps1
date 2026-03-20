<#
.SYNOPSIS
    Installs the dev-team multi-agent framework into a new or existing repository.

.DESCRIPTION
    Copies agents, protocols, org chart, and configuration into a target directory.
    Idempotent — safe to re-run. Skips identical files, warns on diffs.

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
    .\bootstrap.ps1 . -Force
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

# Resolve target to absolute path, creating it if needed
if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}
$Target = (Resolve-Path $Target).Path

Write-Host "🔨 dev-team bootstrap"
Write-Host "   Source:  $ScriptDir"
Write-Host "   Target:  $Target"
Write-Host ""

# --- Git initialization ---
if ($InitGit) {
    if (Test-Path (Join-Path $Target ".git")) {
        Write-Host "⚠  Target already has a git repository. Skipping -InitGit."
    }
    else {
        Write-Host "📦 Initializing git repository..."
        git -C $Target init -b main
        Write-Host ""
    }
}

# Verify target is a git repo (warn if not, but don't block)
if (-not (Test-Path (Join-Path $Target ".git"))) {
    Write-Host "⚠  Target is not a git repository. Files will be copied but not committed."
    Write-Host "   Run with -InitGit to initialize one, or run 'git init' yourself."
    Write-Host ""
}

# --- Helper: copy file with conflict detection ---
function Copy-FrameworkFile {
    param(
        [string]$Source,
        [string]$Destination
    )

    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if ((Test-Path $Destination) -and -not $Force) {
        $srcHash = (Get-FileHash $Source -Algorithm SHA256).Hash
        $destHash = (Get-FileHash $Destination -Algorithm SHA256).Hash
        if ($srcHash -eq $destHash) {
            Write-Host "   ✓ $(Split-Path -Leaf $Destination) (already up to date)"
            return
        }
        Write-Host "   ⚠ $(Split-Path -Leaf $Destination) exists and differs — skipped (use -Force to overwrite)"
        return
    }

    Copy-Item -Path $Source -Destination $Destination -Force
    Write-Host "   + $(Split-Path -Leaf $Destination)"
}

# --- Copy framework files ---

Write-Host "📁 Installing agent definitions..."
$agentsDir = Join-Path $Target ".github" "agents"
if (-not (Test-Path $agentsDir)) {
    New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null
}
Get-ChildItem (Join-Path $ScriptDir ".github" "agents" "*.agent.md") -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-FrameworkFile $_.FullName (Join-Path $agentsDir $_.Name)
}

Write-Host "📁 Installing team infrastructure..."
$teamDirs = @(
    (Join-Path $Target ".team" "protocols"),
    (Join-Path $Target ".team" "memory"),
    (Join-Path $Target ".team" "skills"),
    (Join-Path $Target ".team" "knowledge")
)
foreach ($dir in $teamDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Get-ChildItem (Join-Path $ScriptDir ".team" "protocols" "*.md") -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-FrameworkFile $_.FullName (Join-Path $Target ".team" "protocols" $_.Name)
}

Copy-FrameworkFile (Join-Path $ScriptDir ".team" "org-chart.yaml") (Join-Path $Target ".team" "org-chart.yaml")
Copy-FrameworkFile (Join-Path $ScriptDir ".team" "config.yaml") (Join-Path $Target ".team" "config.yaml")

# Ensure .gitkeep files exist in empty dirs
foreach ($subdir in @("memory", "skills", "knowledge")) {
    $gitkeep = Join-Path $Target ".team" $subdir ".gitkeep"
    if (-not (Test-Path $gitkeep)) {
        New-Item -ItemType File -Path $gitkeep -Force | Out-Null
    }
}

# Create knowledge subdirs
foreach ($subdir in @("upstream-proposals", "retrospectives")) {
    $dir = Join-Path $Target ".team" "knowledge" $subdir
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $gitkeep = Join-Path $dir ".gitkeep"
    if (-not (Test-Path $gitkeep)) {
        New-Item -ItemType File -Path $gitkeep -Force | Out-Null
    }
}

# Copy failure journal template if not exists
$failuresTarget = Join-Path $Target ".team" "knowledge" "failures.md"
if (-not (Test-Path $failuresTarget)) {
    $failuresSrc = Join-Path $ScriptDir ".team" "knowledge" "failures.md"
    if (Test-Path $failuresSrc) {
        Copy-FrameworkFile $failuresSrc $failuresTarget
    }
}

Write-Host "📁 Installing configuration..."
Copy-FrameworkFile (Join-Path $ScriptDir "AGENTS.md") (Join-Path $Target "AGENTS.md")
Copy-FrameworkFile (Join-Path $ScriptDir "plugin.json") (Join-Path $Target "plugin.json")

# .mcp.json: merge if target already has one, otherwise copy
$mcpTarget = Join-Path $Target ".mcp.json"
if (Test-Path $mcpTarget) {
    if (Select-String -Path $mcpTarget -Pattern "context7" -Quiet) {
        Write-Host "   ✓ .mcp.json (context7 already configured)"
    }
    else {
        Write-Host "   ⚠ .mcp.json exists — add context7 manually from $(Join-Path $ScriptDir '.mcp.json')"
    }
}
else {
    Copy-FrameworkFile (Join-Path $ScriptDir ".mcp.json") $mcpTarget
}

# --- Export upstream proposals ---
if ($ExportProposals) {
    $proposalsDir = Join-Path $Target ".team" "knowledge" "upstream-proposals"
    if (-not (Test-Path $proposalsDir)) {
        Write-Host "⚠  No upstream proposals directory found."
        exit 0
    }

    $proposals = Get-ChildItem $proposalsDir -Filter "*.md" | Where-Object { $_.Name -ne ".gitkeep" }
    if ($proposals.Count -eq 0) {
        Write-Host "✅ No upstream proposals to export."
        exit 0
    }

    Write-Host "📋 Upstream Improvement Proposals"
    Write-Host "================================="
    Write-Host ""

    $count = 0
    foreach ($proposal in $proposals) {
        $count++
        $content = Get-Content $proposal.FullName -Raw
        $priority = if ($content -match "Priority:\s*(.+)") { $Matches[1].Trim() } else { "unknown" }
        $status = if ($content -match "Submitted:\s*(.+)") { $Matches[1].Trim() } else { "unknown" }
        Write-Host "--- Proposal ${count}: $($proposal.BaseName) ---"
        Write-Host "  Priority: $priority"
        Write-Host "  Status:   $status"
        Write-Host "  File:     $($proposal.FullName)"
        Write-Host ""
    }

    Write-Host "Total proposals: $count"
    Write-Host ""
    Write-Host "To review a proposal: Get-Content <file>"
    exit 0
}

Write-Host ""
Write-Host "✅ dev-team framework installed!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. cd $Target"
Write-Host "  2. git add -A; git commit -m 'Add dev-team multi-agent framework'"
Write-Host "  3. Invoke @hiring-manager to build your team:"
Write-Host "     @hiring-manager Analyze this project and create the specialist agents we need."
Write-Host ""
