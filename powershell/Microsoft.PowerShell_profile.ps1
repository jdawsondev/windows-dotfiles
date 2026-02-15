# PowerShell 7 Profile
# Managed by windows-dotfiles — https://github.com/your-user/windows-dotfiles

# Aliases
Set-Alias -Name which -Value Get-Command
Set-Alias -Name c -Value clear

# Quick navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# Auto-activate Python virtual environments on directory change
function Find-VenvActivate {
    foreach ($dir in '.venv', 'venv', '.env', 'env') {
        $activate = Join-Path $PWD $dir 'Scripts' 'Activate.ps1'
        if (Test-Path $activate) { return $activate }
    }
}

$ExecutionContext.InvokeCommand.PostCommandLookupAction = {
    param($name, $event)
    if ($name -eq 'Set-Location') {
        $event.CommandScriptBlock = {
            param([Parameter(ValueFromPipeline)]$path)
            if ($path) { Microsoft.PowerShell.Management\Set-Location $path }
            else       { Microsoft.PowerShell.Management\Set-Location ~ }

            $activate = Find-VenvActivate
            if ($activate) {
                if ($env:VIRTUAL_ENV -ne (Split-Path (Split-Path $activate))) {
                    & $activate
                }
            } elseif ($env:VIRTUAL_ENV) {
                deactivate
            }
        }.GetNewClosure()
    }
}

# Prompt
Import-Module posh-git
function prompt {
    $path = $executionContext.SessionState.Path.CurrentLocation.Path
    $leaf = Split-Path $path -Leaf
    "$([char]27)]9;9;$path$([char]27)\PS $leaf$(Write-VcsStatus)> "
}
