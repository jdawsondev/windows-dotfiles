# PowerShell 7 Profile
# Managed by windows-dotfiles — https://github.com/your-user/windows-dotfiles

# Aliases
Set-Alias -Name g -Value git
Set-Alias -Name which -Value Get-Command

# Quick navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# Git shortcuts
function gs { git status @args }
function ga { git add @args }
function gc { git commit @args }
function gd { git diff @args }
function gl { git log --oneline -20 @args }

# Prompt
function prompt {
    $path = $executionContext.SessionState.Path.CurrentLocation.Path
    $leaf = Split-Path $path -Leaf
    "PS $leaf> "
}
