# CLAUDE.md

Windows dotfiles repo managing Windows Terminal and PowerShell 7 configuration.

## Structure

- `windows-terminal/settings.json` — Windows Terminal config (keybindings, profiles, appearance)
- `powershell/Microsoft.PowerShell_profile.ps1` — PowerShell 7 profile (aliases, prompt, shell functions)
- `install.ps1` — Symlink installer (requires Admin)

## Conventions

- Config files live in their named subdirectory and get symlinked to system paths via `install.ps1`
- Windows Terminal keybindings use vim-style navigation (ctrl+hjkl)
- Split panes use `splitMode: duplicate` to inherit the working directory
- The PowerShell prompt emits OSC 9;9 so Windows Terminal tracks the current directory
- Commit messages are imperative, short, and describe the "why"
