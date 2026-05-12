# Copilot Instructions

## Project Overview

A two-file PowerShell profile installer designed for air-gapped Windows servers and enterprise environments. The only two distributable files are `install.ps1` and `profile.ps1` — no internet, no dependencies.

## Architecture: Loader Pattern

The installer implements a **master profile + loader** separation:

1. **Master profile** → copied to `%LOCALAPPDATA%\PSProfile\profile.ps1` (machine-local, never OneDrive-synced)
2. **Loader scripts** → lightweight files dot-sourcing the master profile, created in all standard PowerShell profile locations (Documents\WindowsPowerShell, Documents\PowerShell, VSCode, ISE variants)

`install.ps1` detects whether Documents is OneDrive-redirected (checks if path matches `"OneDrive"`) and creates loaders there. The `-Local` flag bypasses this and forces `$env:USERPROFILE\Documents`.

Loaders are identified by the string `"Auto-generated profile loader"` in their content — this marker prevents them from being backed up when re-installing.

## Key Files

- `install.ps1` — installer/updater/uninstaller; params: `-Update`, `-Uninstall`, `-Local`
- `profile.ps1` — the actual profile loaded at shell startup (9 numbered sections)
- `examples/profile-example.ps1` — stripped-down reference example
- `docs/INSTALLATION.md` — deployment methods (USB, RDP, network share)
- `docs/CONFIGURATION.md` — repo auto-navigation config, machine-specific settings, OneDrive handling

## Conventions

### Output formatting in `install.ps1`
Use the four established helper functions for all console output — do not call `Write-Host` directly for status messages:
- `Write-Step` — Yellow, numbered steps like `"[1/4] Doing something..."`
- `Write-Success` — Green, prefixed with `"      [OK] "`
- `Write-Info` — DarkGray, prefixed with `"      "`
- `Write-Path` — DarkGray, prefixed with `"             "` (path indented under info)

### `profile.ps1` structure
The profile prints numbered loading progress `[1/8]` through `[8/8]` using `Write-Host` directly (the helper functions from `install.ps1` are not available at profile load time). Each section ends with a DarkGray `[OK]` confirmation line.

Sections: `[1]` Prompt, `[2]` Navigation, `[3]` File ops, `[4]` Git, `[5]` Network, `[6]` System info, `[7]` PS utilities, `[8]` Auto-execute scripts, `[9]` Startup (default location).

### `profile` CLI (`profile-cli.ps1`)
`profile-cli.ps1` is a separate file (deployed alongside `profile.ps1`, dot-sourced at end of section [7]) that defines the `profile` command. Bare `profile` shows help; subcommands:
- `profile reload [-Silent]` — reload the profile
- `profile script list/add/remove` — manage `ScriptPaths` config
Internal helpers are prefixed `_profile-*` (private by convention, not by scope).
- Git aliases follow the `g*` prefix: `gs`, `gcm`, `gcam`, `gb`, `gg`, `gacp`, etc.
- Git worktree functions follow the `gw*` prefix: `gwa` (add), `gwd` (delete), `gwl` (list/jump), `gwclean`
- Worktree directories are named `reponame--branchname` (double-dash separator)

### Encoding
All PowerShell scripts must be saved as **UTF-8 without BOM**. Use `Out-File -Encoding UTF8` when writing files programmatically.

### Config resolution order
Repo auto-navigation checks in priority order:
1. `$env:DEV_REPO` environment variable
2. `%LOCALAPPDATA%\PSProfile\config.json` → `RepoFolder` key
3. Auto-detection of common paths (`C:\repo`, `C:\dev`, `D:\repos`, etc.)

### `config.json` schema
`%LOCALAPPDATA%\PSProfile\config.json` is the machine-local config. Current keys:
- `ScriptPaths` — `string[]` — folders or `.ps1` files to dot-source on every terminal start (managed via `profile script add/remove`)
- `RepoFolder` — `string` — dev folder for startup navigation (documented but not yet implemented in profile.ps1)

### Startup location logic
On profile load, the startup section only changes to `C:\repo` if the current directory is one of the known system-default locations (USERPROFILE, Documents, System32, etc.). If the user opened PowerShell in a specific directory, it stays there.

### Error handling
`install.ps1` sets `$ErrorActionPreference = "Stop"` at the top. Individual operations that may legitimately fail (e.g., directory creation per profile location) use `try/catch` with graceful skip + increment of `$skippedCount`.
