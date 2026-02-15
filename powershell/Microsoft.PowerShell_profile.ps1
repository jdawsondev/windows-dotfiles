# PowerShell 7 Profile
# Managed by windows-dotfiles — https://github.com/your-user/windows-dotfiles

# Aliases
Set-Alias -Name which -Value Get-Command
Set-Alias -Name c -Value clear

# Quick navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# Auto-activate Python virtual environments on directory change
# Requires explicit trust per directory (like direnv) so that a cloned
# repo containing a malicious Activate.ps1 cannot execute on cd.
$Script:TrustedVenvsFile = Join-Path $env:LOCALAPPDATA 'trusted-venvs.txt'

function Get-TrustedVenvs {
    if (Test-Path $Script:TrustedVenvsFile) {
        Get-Content $Script:TrustedVenvsFile | Where-Object { $_ -ne '' }
    }
}

function Trust-Venv {
    $dir = (Get-Location).Path
    $trusted = Get-TrustedVenvs
    if ($trusted -contains $dir) {
        Write-Host "Already trusted: $dir"
    } else {
        Add-Content -Path $Script:TrustedVenvsFile -Value $dir
        Write-Host "Trusted: $dir"
        # Activate immediately now that the directory is trusted
        $activate = Find-VenvActivate
        if ($activate) { & $activate }
    }
}

function Untrust-Venv {
    $dir = (Get-Location).Path
    if (Test-Path $Script:TrustedVenvsFile) {
        $lines = Get-Content $Script:TrustedVenvsFile | Where-Object { $_ -ne $dir }
        Set-Content -Path $Script:TrustedVenvsFile -Value $lines
        Write-Host "Removed trust: $dir"
    }
}

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
                $trusted = Get-TrustedVenvs
                if ($trusted -contains (Get-Location).Path) {
                    if ($env:VIRTUAL_ENV -ne (Split-Path (Split-Path $activate))) {
                        & $activate
                    }
                } else {
                    Write-Host "venv found but directory not trusted. Run Trust-Venv to allow activation."
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
