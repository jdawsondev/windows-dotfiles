# PowerShell 7 Profile
# Managed by windows-dotfiles — https://github.com/your-user/windows-dotfiles

# Aliases
Set-Alias -Name which -Value Get-Command

# Quick navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# Prompt
function prompt {
    $path = $executionContext.SessionState.Path.CurrentLocation.Path
    $leaf = Split-Path $path -Leaf
    "PS $leaf> "
}
