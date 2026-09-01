<#
.SYNOPSIS
    PowerShell Profile Installer for Air-Gapped Servers
.DESCRIPTION
    Installs profile.ps1 with smart OneDrive detection.
    No internet or external dependencies required.
.USAGE
    .\install.ps1           # Auto-detect and use current Documents folder
    .\install.ps1 -Local    # Force local Documents folder (skip OneDrive)
    .\install.ps1 -Update   # Update existing installation
#>

[CmdletBinding()]
param(
    [switch]$Update,
    [switch]$Uninstall,
    [switch]$Local  # Force local Documents, avoid OneDrive
)

$ErrorActionPreference = "Stop"

# Configuration
$SourceProfile   = Join-Path $PSScriptRoot "profile.ps1"
$SourceCliScript = Join-Path $PSScriptRoot "profile-cli.ps1"

# ==============================================================================
# SMART PATH DETECTION
# ==============================================================================

function Get-DocumentsPath {
    <#
    .SYNOPSIS
        Get the relevant Documents path (OneDrive or Local)
    #>


    param([switch]$Local)
    
    $paths = @{}

    # Standard Documents folder (might be OneDrive-redirected)
    $standardDocs = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)

    # Local Documents folder
    $localDocs = Join-Path $env:USERPROFILE "Documents"

    # Determine which to use based on -Local switch
    if ($Local) {
        $paths.Primary = $localDocs
        $paths.IsOneDrive = $false
        $paths.Message = "Using forced local Documents (OneDrive bypassed)"
    } elseif ($standardDocs -match "OneDrive") {
        $paths.Primary = $standardDocs
        $paths.IsOneDrive = $true
        $paths.Message = "Using OneDrive-redirected Documents"
    } else {
        $paths.Primary = $standardDocs
        $paths.IsOneDrive = $false
        $paths.Message = "Using local Documents"
    }

    return $paths
}

# Get Documents configuration
<<<<<<< HEAD
$docsConfig = Get-DocumentsPath
=======
$docsConfig = Get-DocumentsPath -Local:$Local
>>>>>>> 1229b0908dc8d4e95ccab77191abd0010dbe2261
$DocumentsPath = $docsConfig.Primary

# Master profile location (avoid Documents entirely for master copy)
$MasterProfileDir = Join-Path $env:LOCALAPPDATA "PSProfile"
$MasterProfile = Join-Path $MasterProfileDir "profile.ps1"

# Profile locations to configure
$ProfileLocations = @(
    (Join-Path $DocumentsPath "WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
    (Join-Path $DocumentsPath "PowerShell\Microsoft.PowerShell_profile.ps1")
    (Join-Path $DocumentsPath "WindowsPowerShell\Microsoft.VSCode_profile.ps1")
    (Join-Path $DocumentsPath "PowerShell\Microsoft.VSCode_profile.ps1")
    (Join-Path $DocumentsPath "WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1")
)

# ==============================================================================
# FUNCTIONS
# ==============================================================================

function Write-Step {
    param([string]$Message, [string]$Color = "Yellow")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "      [OK] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "      $Message" -ForegroundColor DarkGray
}

function Write-Path {
    param([string]$Message)
    Write-Host "             $Message" -ForegroundColor DarkGray
}

function Show-Configuration {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Configuration Detection" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "  Documents Folder: " -ForegroundColor White
    Write-Path "$DocumentsPath"

    if ($docsConfig.IsOneDrive) {
        Write-Host "      [INFO] OneDrive-redirected Documents detected" -ForegroundColor Cyan
        Write-Host "             Loaders will be created in OneDrive folder" -ForegroundColor DarkGray
        Write-Host "             (they will sync across devices with same OneDrive account)" -ForegroundColor DarkGray
    } else {
        Write-Host "      [INFO] Local Documents folder" -ForegroundColor Green
    }

    Write-Host "`n  Master Profile Location (Local, not synced): " -ForegroundColor White
    Write-Path "$MasterProfile"
    Write-Path "(Stored in %LOCALAPPDATA%, never synced by OneDrive)"

    Write-Host "`n  Profile Loaders Will Be Created At:" -ForegroundColor White
    foreach ($location in $ProfileLocations) {
        Write-Path "$location"
    }
    Write-Host ""
}

function Uninstall-Profile {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Uninstalling Profile" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Remove loader files
    $removedCount = 0
    foreach ($location in $ProfileLocations) {
        if (Test-Path $location) {
            Remove-Item $location -Force
            Write-Success "Removed loader"
            Write-Path "$location"
            $removedCount++
        }
    }

    if ($removedCount -eq 0) {
        Write-Info "No loaders found to remove"
    }

    # Remove master profile
    if (Test-Path $MasterProfileDir) {
        Remove-Item $MasterProfileDir -Recurse -Force
        Write-Success "Removed master profile"
        Write-Path "$MasterProfileDir"
    } else {
        Write-Info "Master profile directory not found"
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Uninstall Complete!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
}

# ==============================================================================
# MAIN INSTALLATION
# ==============================================================================

# Handle uninstall
if ($Uninstall) {
    Uninstall-Profile
    exit 0
}

# Display header
Write-Host "`n========================================" -ForegroundColor Cyan
if ($Update) {
    Write-Host "  Updating PowerShell Profile" -ForegroundColor Cyan
} else {
    Write-Host "  Installing PowerShell Profile" -ForegroundColor Cyan
}
Write-Host "========================================`n" -ForegroundColor Cyan

# Show configuration
Show-Configuration

# [1] Validate source files exist
Write-Step "[1/5] Validating source profile..."

if (!(Test-Path $SourceProfile)) {
    Write-Host "      [ERROR] profile.ps1 not found in current directory!" -ForegroundColor Red
    Write-Path "$SourceProfile"
    Write-Host "`n      Make sure profile.ps1 is in the same folder as install.ps1" -ForegroundColor Yellow
    exit 1
}

if (!(Test-Path $SourceCliScript)) {
    Write-Host "      [ERROR] profile-cli.ps1 not found in current directory!" -ForegroundColor Red
    Write-Path "$SourceCliScript"
    Write-Host "`n      Make sure profile-cli.ps1 is in the same folder as install.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Success "Source profile found"
Write-Path "$SourceProfile"
Write-Success "Profile CLI found"
Write-Path "$SourceCliScript"

# [2] Copy master profile to %LOCALAPPDATA%
Write-Step "[2/5] Installing master profile..."

if (!(Test-Path $MasterProfileDir)) {
    New-Item -ItemType Directory -Path $MasterProfileDir -Force | Out-Null
    Write-Info "Created directory"
    Write-Path "$MasterProfileDir"
}

Copy-Item $SourceProfile    $MasterProfile -Force
Copy-Item $SourceCliScript (Join-Path $MasterProfileDir "profile-cli.ps1") -Force
Write-Success "Master profile installed"
Write-Path "$MasterProfile"
Write-Success "Profile CLI installed"
Write-Path "$(Join-Path $MasterProfileDir 'profile-cli.ps1')"
Write-Info "Stored in LOCALAPPDATA (local to this machine, never synced)"

# [3] Create loader scripts
Write-Step "[3/5] Configuring profile loaders..."

$LoaderScript = @"
# Auto-generated profile loader
# Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Master profile: $MasterProfile
#
# This is just a loader. The actual profile is stored in:
# %LOCALAPPDATA%\PSProfile\profile.ps1 (local to machine, not synced)
#
# To update: Copy new profile.ps1 and run: .\install.ps1 -Update

if (Test-Path '$MasterProfile') {
    . '$MasterProfile'
} else {
    Write-Warning 'Profile not found at: $MasterProfile'
    Write-Warning 'Run install.ps1 to reinstall'
}
"@

$installedCount = 0
$skippedCount = 0

foreach ($location in $ProfileLocations) {
    $dir = Split-Path $location

    # Create directory if needed
    if (!(Test-Path $dir)) {
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Info "Created directory"
            Write-Path "$dir"
        } catch {
            Write-Info "Skipped (cannot create directory)"
            Write-Path "$location"
            $skippedCount++
            continue
        }
    }

    # Backup existing profile if it's not a loader
    if (Test-Path $location) {
        $content = Get-Content $location -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -notmatch "Auto-generated profile loader") {
            $backup = "$location.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item $location $backup -Force
            Write-Info "Backed up existing profile"
            Write-Path "$backup"
        }
    }

    # Install loader
    try {
        $LoaderScript | Out-File $location -Encoding UTF8 -Force
        Write-Success "Installed loader"
        Write-Path "$location"
        $installedCount++
    } catch {
        Write-Info "Skipped (error writing file)"
        Write-Path "$location"
        Write-Info "Error: $_"
        $skippedCount++
    }
}

Write-Host ""
Write-Success "Installed loaders to $installedCount locations"
if ($skippedCount -gt 0) {
    Write-Host "      [WARNING] Skipped $skippedCount locations (see errors above)" -ForegroundColor Yellow
}

# [4/5] Configure auto-execute scripts
Write-Step "[4/5] Configuring auto-execute scripts..."

$configPath = Join-Path $MasterProfileDir "config.json"

# Load existing config or initialize a fresh one
$psConfig = [PSCustomObject]@{ ScriptPaths = @() }
if (Test-Path $configPath) {
    try {
        $psConfig = Get-Content $configPath -Raw | ConvertFrom-Json
        if (-not (Get-Member -InputObject $psConfig -Name 'ScriptPaths' -MemberType NoteProperty)) {
            $psConfig | Add-Member -NotePropertyName 'ScriptPaths' -NotePropertyValue @()
        }
    } catch {
        Write-Info "Could not read existing config, starting fresh"
    }
}

$existingPaths = @($psConfig.ScriptPaths) | Where-Object { $_ }

if ($Update) {
    # On update: show existing paths for info, skip re-prompt
    if ($existingPaths.Count -gt 0) {
        Write-Info "Configured auto-execute paths (unchanged):"
        foreach ($p in $existingPaths) {
            Write-Path $p
        }
        Write-Success "Script paths preserved (use 'profile script add/remove' to modify)"
    } else {
        Write-Info "No auto-execute paths configured"
        Write-Info "(Use 'profile script add <path>' to add paths)"
    }
} else {
    # Fresh install: prompt interactively
    Write-Host ""
    Write-Host "      Auto-Execute Scripts (optional)" -ForegroundColor Cyan
    Write-Info "Enter folders or .ps1 files to dot-source on every terminal start."
    Write-Info "Paths are machine-local and will not be committed to the repository."
    Write-Host "      Press " -NoNewline -ForegroundColor DarkGray
    Write-Host "Enter" -NoNewline -ForegroundColor Yellow
    Write-Host " with no input to skip." -ForegroundColor DarkGray
    Write-Host ""

    $newPaths = [System.Collections.ArrayList]::new()
    $promptNum = 1
    while ($true) {
        $pathEntry = Read-Host "      Path $promptNum"
        if ([string]::IsNullOrWhiteSpace($pathEntry)) { break }

        $pathEntry = $pathEntry.Trim()
        if (-not (Test-Path $pathEntry)) {
            Write-Host "      [WARNING] Path not found: $pathEntry" -ForegroundColor Yellow
            Write-Host "               (saved anyway - path may be created later)" -ForegroundColor DarkGray
        } else {
            Write-Success "Found: $pathEntry"
        }
        [void]$newPaths.Add($pathEntry)
        $promptNum++
    }

    if ($newPaths.Count -gt 0) {
        $psConfig.ScriptPaths = @($newPaths)
        $psConfig | ConvertTo-Json -Depth 5 | Out-File $configPath -Encoding UTF8 -Force
        Write-Success "Saved $($newPaths.Count) path(s) to config"
        Write-Path $configPath
    } else {
        Write-Info "No paths configured (skipped)"
        Write-Info "Use 'profile script add <path>' after loading your profile to add paths later"
    }
}

# [5/5] Test profile load
Write-Step "[5/5] Testing profile..."

try {
    $loadTime = Measure-Command { . $MasterProfile }
    Write-Success "Profile loads successfully in $([math]::Round($loadTime.TotalMilliseconds, 2)) ms"
} catch {
    Write-Host "      [WARNING] Profile has errors: $_" -ForegroundColor Yellow
}

# Display completion
Write-Host "`n========================================" -ForegroundColor Cyan
if ($Update) {
    Write-Host "  Profile Updated Successfully!" -ForegroundColor Green
} else {
    Write-Host "  Installation Complete!" -ForegroundColor Green
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Master Profile (local to this machine): " -ForegroundColor White
Write-Path "$MasterProfile"
Write-Host ""

if ($docsConfig.IsOneDrive) {
    Write-Host "  Loaders (in OneDrive, will sync): " -ForegroundColor White
    Write-Host "      [INFO] Profile loaders are in OneDrive" -ForegroundColor Cyan
    Write-Host "             They will sync across devices" -ForegroundColor DarkGray
    Write-Host "             But master profile stays local to each machine" -ForegroundColor DarkGray
} else {
    Write-Host "  Loaders (local): " -ForegroundColor White
}

Write-Host ""
Write-Host "  Loaders Created: " -NoNewline -ForegroundColor White
Write-Host "$installedCount" -ForegroundColor Yellow
if ($skippedCount -gt 0) {
    Write-Host "  Loaders Skipped: " -NoNewline -ForegroundColor White
    Write-Host "$skippedCount (see errors above)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  Commands:" -ForegroundColor White
Write-Host "    Update:    " -NoNewline -ForegroundColor DarkGray
Write-Host ".\install.ps1 -Update" -ForegroundColor Cyan
Write-Host "    Local:     " -NoNewline -ForegroundColor DarkGray
Write-Host ".\install.ps1 -Local" -ForegroundColor Cyan
Write-Host "               (forces local Documents, skips OneDrive)" -ForegroundColor DarkGray
Write-Host "    Uninstall: " -NoNewline -ForegroundColor DarkGray
Write-Host ".\install.ps1 -Uninstall" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Profile CLI:" -ForegroundColor White
Write-Host "    profile                  " -NoNewline -ForegroundColor DarkGray
Write-Host "Show help" -ForegroundColor Cyan
Write-Host "    profile reload           " -NoNewline -ForegroundColor DarkGray
Write-Host "Reload the profile" -ForegroundColor Cyan
Write-Host "    profile script list      " -NoNewline -ForegroundColor DarkGray
Write-Host "List auto-execute script paths" -ForegroundColor Cyan
Write-Host "    profile script add <path>" -NoNewline -ForegroundColor DarkGray
Write-Host " Add a path" -ForegroundColor Cyan
Write-Host "    profile script remove <n>" -NoNewline -ForegroundColor DarkGray
Write-Host " Remove a path by number" -ForegroundColor Cyan
Write-Host ""
Write-Host "  To activate in current session:" -ForegroundColor White
Write-Host "    " -NoNewline
Write-Host ". `$PROFILE" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan