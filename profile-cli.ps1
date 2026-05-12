# ============================================================================
# Profile CLI
# Dot-sourced by profile.ps1. Defines the 'profile' command.
#
# Usage:
#   profile                        Show this help
#   profile reload                 Reload the profile
#   profile reload -Silent         Reload without output
#   profile script list            List configured auto-execute script paths
#   profile script add <path>      Add a folder or .ps1 file to auto-execute
#   profile script remove <n>      Remove a path by its list number
# ============================================================================

function profile {
    param(
        [Parameter(Position=0)]
        [string]$Command = '',

        [Parameter(Position=1)]
        [string]$SubCommand = '',

        [Parameter(Position=2)]
        [string]$Arg = '',

        [switch]$Silent
    )

    switch ($Command.ToLower()) {
        ''       { _profile-help }
        'reload' { _profile-reload -Silent:$Silent }
        'script' {
            switch ($SubCommand.ToLower()) {
                'list'   { _profile-script-list }
                'add'    { _profile-script-add $Arg }
                'remove' { _profile-script-remove $Arg }
                ''       { _profile-script-help }
                default  {
                    Write-Host "  Unknown subcommand: $SubCommand" -ForegroundColor Red
                    _profile-script-help
                }
            }
        }
        default {
            Write-Host "  Unknown command: $Command" -ForegroundColor Red
            _profile-help
        }
    }
}

function _profile-help {
    Write-Host ""
    Write-Host "  profile <command>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Commands:" -ForegroundColor White
    Write-Host "    reload         " -NoNewline -ForegroundColor Yellow
    Write-Host "Reload the profile"
    Write-Host "    script         " -NoNewline -ForegroundColor Yellow
    Write-Host "Manage auto-execute script paths"
    Write-Host ""
    Write-Host "  Run " -NoNewline
    Write-Host "profile <command>" -NoNewline -ForegroundColor Yellow
    Write-Host " for subcommand help."
    Write-Host ""
}

function _profile-reload {
    param([switch]$Silent)

    if (-not $Silent) {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "  Reloading PowerShell Profile..." -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
    }

    $reloadStart = Get-Date

    try {
        $Error.Clear()
        & $PROFILE

        if (-not $Silent) {
            $reloadTime = ((Get-Date) - $reloadStart).TotalMilliseconds
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "  Profile reloaded successfully!" -ForegroundColor Green
            Write-Host "  Reload time: " -NoNewline -ForegroundColor White
            Write-Host "$([math]::Round($reloadTime, 2)) ms" -ForegroundColor Yellow
            Write-Host "========================================`n" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "`nError reloading profile: $_" -ForegroundColor Red
    }
}

function _profile-script-help {
    Write-Host ""
    Write-Host "  profile script <subcommand>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Subcommands:" -ForegroundColor White
    Write-Host "    list           " -NoNewline -ForegroundColor Yellow
    Write-Host "List configured auto-execute script paths"
    Write-Host "    add <path>     " -NoNewline -ForegroundColor Yellow
    Write-Host "Add a folder or .ps1 file"
    Write-Host "    remove <n>     " -NoNewline -ForegroundColor Yellow
    Write-Host "Remove a path by number (from list)"
    Write-Host ""
}

function _profile-script-list {
    $paths = @(_profile-config-get-paths)
    Write-Host ""
    if ($paths.Count -eq 0) {
        Write-Host "  No script paths configured." -ForegroundColor DarkGray
        Write-Host "  Use " -NoNewline
        Write-Host "profile script add <path>" -NoNewline -ForegroundColor Yellow
        Write-Host " to add one."
    } else {
        Write-Host "  Auto-execute script paths:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $paths.Count; $i++) {
            $exists = Test-Path $paths[$i]
            $color = if ($exists) { 'Yellow' } else { 'DarkGray' }
            $tag   = if ($exists) { '' } else { '  (not found)' }
            Write-Host "  [$($i+1)] " -NoNewline -ForegroundColor White
            Write-Host "$($paths[$i])$tag" -ForegroundColor $color
        }
    }
    Write-Host ""
}

function _profile-script-add {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Host "  Usage: profile script add <path>" -ForegroundColor Yellow
        return
    }

    $Path = $Path.Trim()
    $paths = @(_profile-config-get-paths)

    if ($paths -contains $Path) {
        Write-Host "  Already configured: $Path" -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path $Path)) {
        Write-Host "  [WARNING] Path not found: $Path" -ForegroundColor Yellow
        Write-Host "            (added anyway - path may be created later)" -ForegroundColor DarkGray
    }

    _profile-config-save-paths (@($paths) + $Path)
    Write-Host "  Added: $Path" -ForegroundColor Green
    Write-Host "  Run " -NoNewline
    Write-Host "profile reload" -NoNewline -ForegroundColor Yellow
    Write-Host " to apply."
}

function _profile-script-remove {
    param([string]$IndexStr)

    if ([string]::IsNullOrWhiteSpace($IndexStr)) {
        Write-Host "  Usage: profile script remove <n>" -ForegroundColor Yellow
        Write-Host "  Run " -NoNewline
        Write-Host "profile script list" -NoNewline -ForegroundColor Yellow
        Write-Host " to see numbers."
        return
    }

    $paths = @(_profile-config-get-paths)

    if ($paths.Count -eq 0) {
        Write-Host "  No paths configured." -ForegroundColor DarkGray
        return
    }

    $idx = [int]$IndexStr - 1
    if ($idx -lt 0 -or $idx -ge $paths.Count) {
        Write-Host "  Invalid number: $IndexStr (valid range: 1-$($paths.Count))" -ForegroundColor Red
        return
    }

    $removed   = $paths[$idx]
    $newPaths  = @(for ($i = 0; $i -lt $paths.Count; $i++) { if ($i -ne $idx) { $paths[$i] } })
    _profile-config-save-paths $newPaths
    Write-Host "  Removed: $removed" -ForegroundColor Green
    Write-Host "  Run " -NoNewline
    Write-Host "profile reload" -NoNewline -ForegroundColor Yellow
    Write-Host " to apply."
}

# ---------------------------------------------------------------------------
# Internal config helpers
# ---------------------------------------------------------------------------

function _profile-config-get-paths {
    $configPath = Join-Path $env:LOCALAPPDATA "PSProfile\config.json"
    if (-not (Test-Path $configPath)) { return @() }
    try {
        $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
        if (Get-Member -InputObject $cfg -Name 'ScriptPaths' -MemberType NoteProperty) {
            return @(@($cfg.ScriptPaths) | Where-Object { $_ })
        }
    } catch {}
    return @()
}

function _profile-config-save-paths {
    param([string[]]$Paths)

    $configPath = Join-Path $env:LOCALAPPDATA "PSProfile\config.json"

    $cfg = [PSCustomObject]@{ ScriptPaths = @() }
    if (Test-Path $configPath) {
        try { $cfg = Get-Content $configPath -Raw | ConvertFrom-Json } catch {}
    }

    if (Get-Member -InputObject $cfg -Name 'ScriptPaths' -MemberType NoteProperty) {
        $cfg.ScriptPaths = @($Paths)
    } else {
        $cfg | Add-Member -NotePropertyName 'ScriptPaths' -NotePropertyValue @($Paths)
    }

    $dir = Split-Path $configPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $cfg | ConvertTo-Json -Depth 5 | Out-File $configPath -Encoding UTF8 -Force
}
