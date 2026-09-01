# ============================================================================
# PowerShell Profile - Full Example
# ============================================================================
# This is a complete example profile showing all features
# Copy sections you want to your own profile.ps1

$ProfileLoadStart = Get-Date

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Loading PowerShell Profile..." -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# [1/8] PROMPT CUSTOMIZATION
Write-Host "[1/8] " -ForegroundColor DarkGray -NoNewline
Write-Host "Configuring custom prompt..." -ForegroundColor Green

function prompt {
    $host.ui.RawUI.WindowTitle = "Current Folder: $pwd"
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
    $Date = Get-Date -Format 'dd/MM/yyyy hh:mm:ss tt'
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    $version = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"

    $ElapsedTime = "0 sec"
    try {
        $LastCommand = Get-History -Count 1 -ErrorAction Stop
        if ($LastCommand) {
            $RunTime = ($LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime).TotalSeconds
            if ($RunTime -ge 60) {
                $ts = [timespan]::fromseconds($RunTime)
                $min, $sec = ($ts.ToString("mm\:ss")).Split(":")
                $ElapsedTime = -join ($min, " min ", $sec, " sec")
            } else {
                $ElapsedTime = [math]::Round(($RunTime), 2)
                $ElapsedTime = -join (($ElapsedTime.ToString()), " sec")
            }
        }
    } catch { Write-Verbose "Could not get last command run time: $_" }

    Write-Host ""
    Write-Host ($(if ($IsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host "v$version " -BackgroundColor DarkMagenta -ForegroundColor White -NoNewline
    Write-Host "$($CmdPromptUser.Name) " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    if ($CmdPromptCurrentFolder -like "*:*") {
        Write-Host " $CmdPromptCurrentFolder " -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    } else {
        Write-Host " .\$CmdPromptCurrentFolder\ " -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    }
    Write-Host " $date " -ForegroundColor White
    Write-Host "[$elapsedTime] " -NoNewline -ForegroundColor Green
    return "> "
}

Write-Host "      [OK] Custom prompt configured" -ForegroundColor DarkGray

# Add remaining sections here...
# [2/8] Navigation
# [3/8] File Operations
# [4/8] Git
# [5/8] Network
# [6/8] System Info
# [7/8] PowerShell Utilities
# [8/8] Startup

# Display completion
$ProfileLoadTime = ((Get-Date) - $ProfileLoadStart).TotalMilliseconds
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Profile loaded successfully! [OK]" -ForegroundColor Green
Write-Host "  Load time: $([math]::Round($ProfileLoadTime, 2)) ms" -ForegroundColor Yellow
Write-Host "  Type 'helper' for command reference" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
