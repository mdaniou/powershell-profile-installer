# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Terraform shortcuts: `t`, `ti`, `tp`, `ta`, `tv`, `tfmt`, `to`, `ts`, `tw`
- Azure CLI shortcuts: `azl`, `azs`, `azacct`, `azg`, `azvm`, `azaks`

## [0.6.0] - 2026-05-12

### Changed
- Refactored git functions for cleaner structure and consistency (PR #6)

## [0.5.0] - 2026-05-12

### Added
- Git-aware prompt: displays current branch and dirty state in the prompt (PR #5)
- Auto-set remote upstream when pushing a new branch (`gacp` and related functions)

## [0.4.0] - 2026-05-12

### Fixed
- `profile script list` showing only the first character when a single path was configured (PR #4)

## [0.3.0] - 2026-05-12

### Added
- Script auto-execute feature: dot-source arbitrary `.ps1` files or folders on every terminal start (PR #3)
- `profile-cli.ps1` — `profile` command with subcommands: `reload`, `script list/add/remove`

## [0.2.0] - 2026-03-18

### Added
- Git worktree helpers: `gwa` (add), `gwd` (delete), `gwl` (list/jump), `gwclean`
- Worktree directories named with `reponame--branchname` double-dash convention

### Changed
- `gacp` now uses a default commit message when none is provided

## [0.1.0] - 2025-12-11

### Added
- Initial release
- Custom PowerShell prompt (elevation, PS version, username, path, timestamp, execution time)
- Navigation shortcuts: `..`, `...`, `....`
- File operations: `touch`, `ff`, `fif`, `dsize`, `big`, `mkcd`, `rmd`, `pwd!`, `open`, `grep`
- Git shortcuts: `g`, `gs`, `gcm`, `gcam`, `gcad`, `glg`, `gb`, `gg`, `gundo`, `gclean`, `gacp`, `gfiles`, `gss`, `gsl`
- Network utilities: `inet`, `myip`, `nsl`, `ports`
- System info: `sysinfo`, `apps`, `uptime`
- PowerShell utilities: `fn`, `helper`
- Smart OneDrive detection with loader pattern (`%LOCALAPPDATA%\PSProfile\` master + lightweight loaders)
- `-Local`, `-Update`, `-Uninstall` flags for `install.ps1`
