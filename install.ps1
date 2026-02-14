#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs windows-dotfiles by symlinking configs to their system locations.
.DESCRIPTION
    Creates symbolic links from this repo's config files to the paths where
    Windows Terminal and PowerShell expect them. Must be run as Administrator.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = $PSScriptRoot

# --- Helpers ---

function New-SafeSymlink {
    param(
        [string]$LinkPath,
        [string]$TargetPath
    )

    if (-not (Test-Path $TargetPath)) {
        Write-Error "Source file not found: $TargetPath"
        return $false
    }

    # Ensure parent directory exists
    $parentDir = Split-Path $LinkPath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        Write-Host "  Created directory: $parentDir"
    }

    # Back up existing file (skip if already a symlink)
    if (Test-Path $LinkPath) {
        $item = Get-Item $LinkPath -Force
        if ($item.LinkType -eq "SymbolicLink") {
            Remove-Item $LinkPath -Force
            Write-Host "  Removed existing symlink: $LinkPath"
        } else {
            $backup = "$LinkPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Move-Item $LinkPath $backup
            Write-Host "  Backed up existing file to: $backup"
        }
    }

    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath | Out-Null
    Write-Host "  Linked: $LinkPath -> $TargetPath"
    return $true
}

# --- Windows Terminal ---

Write-Host "`n=== Windows Terminal ===" -ForegroundColor Cyan

$wtSource = Join-Path $RepoRoot "windows-terminal\settings.json"

# Check Store install first, then scoop/standalone
$wtPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)

$wtInstalled = $false
foreach ($wtDest in $wtPaths) {
    $wtDir = Split-Path $wtDest -Parent
    if (Test-Path $wtDir) {
        if (New-SafeSymlink -LinkPath $wtDest -TargetPath $wtSource) {
            $wtInstalled = $true
            break
        }
    }
}

if (-not $wtInstalled) {
    Write-Warning "Windows Terminal settings directory not found. Is Windows Terminal installed?"
}

# --- PowerShell Profile ---

Write-Host "`n=== PowerShell Profile ===" -ForegroundColor Cyan

$profileSource = Join-Path $RepoRoot "powershell\Microsoft.PowerShell_profile.ps1"
$profileDest = $PROFILE.CurrentUserCurrentHost

if (New-SafeSymlink -LinkPath $profileDest -TargetPath $profileSource) {
    Write-Host "  PowerShell profile installed."
}

# --- Done ---

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Restart Windows Terminal for changes to take effect."
