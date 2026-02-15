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
    $activate = Find-VenvActivate
    if (-not $activate) {
        Write-Host "No virtual environment found in or above this directory."
        return
    }
    $projectRoot = Split-Path (Split-Path (Split-Path $activate))
    $trusted = Get-TrustedVenvs
    if ($trusted -contains $projectRoot) {
        Write-Host "Already trusted: $projectRoot"
    } else {
        Add-Content -Path $Script:TrustedVenvsFile -Value $projectRoot
        Write-Host "Trusted: $projectRoot"
        try {
            & $activate
            $Script:VenvProjectRoot = $projectRoot
        } catch {
            Write-Warning "Failed to activate venv: $($_.Exception.Message)"
        }
    }
}

function Untrust-Venv {
    $activate = Find-VenvActivate
    if ($activate) {
        $projectRoot = Split-Path (Split-Path (Split-Path $activate))
    } else {
        $projectRoot = (Get-Location).Path
    }
    if (Test-Path $Script:TrustedVenvsFile) {
        $lines = Get-Content $Script:TrustedVenvsFile | Where-Object { $_ -ne $projectRoot }
        Set-Content -Path $Script:TrustedVenvsFile -Value $lines
        Write-Host "Removed trust: $projectRoot"
    }
}

$Script:VenvProjectRoot = $null

function Find-VenvActivate {
    $current = (Get-Location).Path
    while ($current -and $current -ne [System.IO.Path]::GetPathRoot($current)) {
        foreach ($dir in '.venv', 'venv', '.env', 'env') {
            $activate = Join-Path $current $dir 'Scripts' 'Activate.ps1'
            if (Test-Path $activate) { return $activate }
        }
        $current = Split-Path $current -Parent
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
                $venvRoot = Split-Path (Split-Path $activate)
                $projectRoot = Split-Path $venvRoot
                $trusted = Get-TrustedVenvs
                if ($trusted -contains $projectRoot) {
                    try {
                        if ($env:VIRTUAL_ENV -ne $venvRoot) {
                            & $activate
                            $Script:VenvProjectRoot = $projectRoot
                        }
                    } catch {
                        Write-Warning "Failed to activate venv: $($_.Exception.Message)"
                    }
                } else {
                    Write-Host "venv found but directory not trusted. Run Trust-Venv to allow activation."
                }
            } elseif ($env:VIRTUAL_ENV) {
                $stillInProject = $Script:VenvProjectRoot -and
                    (Get-Location).Path.StartsWith($Script:VenvProjectRoot,
                        [System.StringComparison]::OrdinalIgnoreCase)
                if (-not $stillInProject) {
                    try {
                        if (Get-Command deactivate -ErrorAction SilentlyContinue) {
                            deactivate
                        }
                    } catch {
                        Write-Warning "Failed to deactivate venv: $($_.Exception.Message)"
                    }
                    $Script:VenvProjectRoot = $null
                }
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
