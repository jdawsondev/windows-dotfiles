# Windows Dotfiles

Windows Terminal + PowerShell 7 configuration with vim-style pane navigation.

## Install

1. Clone this repo
2. Run the install script in an **elevated** (Admin) PowerShell prompt:

```powershell
.\install.ps1
```

3. Restart Windows Terminal

## Keybindings

### Pane Navigation (vim-style)

| Key | Action |
|---|---|
| `ctrl+h` | Focus left |
| `ctrl+j` | Focus down |
| `ctrl+k` | Focus up |
| `ctrl+l` | Focus right |

### Split Panes

| Key | Action |
|---|---|
| `ctrl+\` | Vertical split (side by side) |
| `ctrl+-` | Horizontal split (top/bottom) |
| `alt+shift+d` | Auto split |
| `alt+shift+w` | Close pane |

## What Gets Symlinked

| Source (repo) | Target (system) |
|---|---|
| `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_...\LocalState\settings.json` |
| `powershell/Microsoft.PowerShell_profile.ps1` | `$PROFILE` |
