# Installation Guide

## Prerequisites

- Windows with PowerShell 5.1 or later
- No internet connection required
- No administrator privileges required (for standard installation)

## Installation Methods

### Method 1: USB Drive (Air-Gapped Servers)

1. Copy `install.ps1` and `profile.ps1` to a USB drive
2. Insert USB into the target server
3. Open PowerShell
4. Navigate to USB drive: `cd D:\` (adjust drive letter)
5. Run: `.\install.ps1`

### Method 2: RDP Copy-Paste

1. Copy content of `install.ps1` to clipboard
2. RDP into target server
3. Open PowerShell
4. Create file: `notepad install.ps1`
5. Paste content and save
6. Repeat for `profile.ps1`
7. Run: `.\install.ps1`

### Method 3: Network Share

1. Copy files to accessible network share
2. On target server: `\\server\share\install.ps1`

## Installation Options

### Standard Installation
```powershell
.\install.ps1
```

This will:
- Copy master profile to `%LOCALAPPDATA%\PSProfile\`
- Create loaders in all PowerShell profile locations
- Auto-detect OneDrive redirection

### Local Documents (Skip OneDrive)
```powershell
.\install.ps1 -Local
```

Forces use of local Documents folder, bypassing OneDrive.

### Update Existing Profile
```powershell
.\install.ps1 -Update
```

Updates the master profile without recreating loaders.

## Post-Installation

### Verify Installation
```powershell
# Check if profile loads
. $PROFILE

# Test a command
helper
```

### Configure Repository Path

Set your development folder:
```powershell
# Option 1: Use function (after profile loads)
Set-RepoFolder "C:\your\dev\folder"

# Option 2: Set environment variable
[Environment]::SetEnvironmentVariable("DEV_REPO", "C:\your\dev\folder", "User")
```

## Troubleshooting

### Profile Doesn't Load

Check profile location:
```powershell
$PROFILE
Test-Path $PROFILE
```

Manually load:
```powershell
. $PROFILE
```

### Functions Not Available

Profile might be loading in wrong scope. Check if loader is correct:
```powershell
Get-Content $PROFILE
```

Should contain dot-sourcing command: `. 'C:\...\profile.ps1'`

### OneDrive Sync Issues

Use local installation:
```powershell
.\install.ps1 -Local -Update
```

## Uninstallation
```powershell
.\install.ps1 -Uninstall
```

This removes:
- All profile loaders
- Master profile directory
- Does NOT remove config files (in case you want to reinstall)

## Advanced Configuration

### Custom Master Profile Location

Edit `install.ps1` and modify:
```powershell
$MasterProfileDir = Join-Path $env:LOCALAPPDATA "PSProfile"
```

### Multiple Profiles

You can have different profiles per host by editing loader files.
