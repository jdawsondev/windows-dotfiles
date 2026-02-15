# PowerShell 7 Profile
# Managed by windows-dotfiles — https://github.com/your-user/windows-dotfiles

# Aliases
Set-Alias -Name which -Value Get-Command
Set-Alias -Name c -Value clear

# Quick navigation
function .. { cd .. }
function ... { cd ../.. }

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
        AutoActivateVirtualenv
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

function AutoActivateVirtualenv {
    if ($env:VIRTUAL_ENV) {
        $currentVenvParent = Split-Path $env:VIRTUAL_ENV -Parent
        if (-not $PWD.Path.StartsWith($currentVenvParent, [System.StringComparison]::OrdinalIgnoreCase)) {
            # Inline deactivation — restore PATH, prompt, and remove venv env vars
            if (Test-Path Function:_OLD_VIRTUAL_PROMPT) {
                Copy-Item Function:_OLD_VIRTUAL_PROMPT Function:prompt
                Remove-Item Function:_OLD_VIRTUAL_PROMPT
            }
            if (Test-Path Env:_OLD_VIRTUAL_PATH) {
                $env:PATH = $env:_OLD_VIRTUAL_PATH
                Remove-Item Env:_OLD_VIRTUAL_PATH
            }
            if (Test-Path Env:_OLD_VIRTUAL_PYTHONHOME) {
                $env:PYTHONHOME = $env:_OLD_VIRTUAL_PYTHONHOME
                Remove-Item Env:_OLD_VIRTUAL_PYTHONHOME
            }
            Remove-Item Env:VIRTUAL_ENV -ErrorAction SilentlyContinue
            Remove-Item Env:VIRTUAL_ENV_PROMPT -ErrorAction SilentlyContinue
        }
    }

    $activate = Find-VenvActivate
    if ($activate) {
        $venvRoot = Split-Path (Split-Path $activate)
        $projectRoot = Split-Path $venvRoot
        if ($env:VIRTUAL_ENV -ne $venvRoot) {
            $trusted = Get-TrustedVenvs
            if ($trusted -contains $projectRoot) {
                . $activate
            } else {
                Write-Host "venv found but directory not trusted. Run Trust-Venv to allow activation."
            }
        }
    }
}

Remove-Item Alias:cd -Force -ErrorAction SilentlyContinue
function cd {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Path
    )
    if ($Path) { Set-Location @Path }
    else       { Set-Location ~ }
    AutoActivateVirtualenv
}

# Prompt
Import-Module posh-git
function prompt {
    $path = $executionContext.SessionState.Path.CurrentLocation.Path
    $leaf = Split-Path $path -Leaf
    "$([char]27)]9;9;$path$([char]27)\PS $leaf$(Write-VcsStatus)> "
}
