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

.EXAMPLE
    .\bootstrap.ps1 C:\Projects\my-app
    .\bootstrap.ps1 C:\Projects\new-app -InitGit
    .\bootstrap.ps1 . -Force
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target = ".",

    [switch]$InitGit,
    [switch]$Force
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

# Ensure .gitkeep files exist in empty dirs
foreach ($subdir in @("memory", "skills", "knowledge")) {
    $gitkeep = Join-Path $Target ".team" $subdir ".gitkeep"
    if (-not (Test-Path $gitkeep)) {
        New-Item -ItemType File -Path $gitkeep -Force | Out-Null
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

Write-Host ""
Write-Host "✅ dev-team framework installed!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. cd $Target"
Write-Host "  2. git add -A; git commit -m 'Add dev-team multi-agent framework'"
Write-Host "  3. Invoke @hiring-manager to build your team:"
Write-Host "     @hiring-manager Analyze this project and create the specialist agents we need."
Write-Host ""
