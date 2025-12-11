# ============================================================================
# PowerShell Profile Configuration
# ============================================================================
# Profile Location: $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#
# To create profile if it doesn't exist, run in PowerShell (not ISE):
# if ( !(Test-Path $profile) -and $Host.Name -eq 'ConsoleHost' ) {
#     New-Item -Path (Split-Path $profile -Parent) -Name (Split-Path $profile -Leaf) -Force
# }
# notepad $profile
# ============================================================================

$ProfileLoadStart = Get-Date

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Loading PowerShell Profile..." -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan


# ============================================================================
# PROMPT CUSTOMIZATION
# ============================================================================
Write-Host "[1/8] " -ForegroundColor DarkGray -NoNewline
Write-Host "Configuring custom prompt..." -ForegroundColor Green

function prompt {
  
    # Assign Windows Title Text
    $host.ui.RawUI.WindowTitle = "Current Folder: $pwd"

    # Configure current user, current folder and date outputs
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
    $Date = Get-Date -Format 'dd/MM/yyyy hh:mm:ss tt'

    # Test for Admin / Elevated
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    # Get PowerShell version
    $version = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"

    # Calculate execution time of last command
    $LastCommand = $null
    $RunTime = 0
    $ElapsedTime = "0 sec"

    try {
        $LastCommand = Get-History -Count 1 -ErrorAction Stop
        if ($lastCommand) { 
            $RunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime).TotalSeconds 
            
            if ($RunTime -ge 60) {
                $ts = [timespan]::fromseconds($RunTime)
                $min, $sec = ($ts.ToString("mm\:ss")).Split(":")
                $ElapsedTime = -join ($min, " min ", $sec, " sec")
            }
            else {
                $ElapsedTime = [math]::Round(($RunTime), 2)
                $ElapsedTime = -join (($ElapsedTime.ToString()), " sec")
            }
        }
    }
    catch {
        # First command in session - no history yet
        $ElapsedTime = "0 sec"
    }

    # Decorate the CMD Prompt
    Write-Host ""
    Write-Host ($(if ($IsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host "v$version " -BackgroundColor DarkMagenta -ForegroundColor White -NoNewline
    Write-Host "$($CmdPromptUser.Name) " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    If ($CmdPromptCurrentFolder -like "*:*") {
        Write-Host " $CmdPromptCurrentFolder " -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    }
    else {
        Write-Host " .\$CmdPromptCurrentFolder\ " -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    }

    Write-Host " $date " -ForegroundColor White
    Write-Host "[$elapsedTime] " -NoNewline -ForegroundColor Green
    return "> "
}

Write-Host "      [OK] Custom prompt configured" -ForegroundColor DarkGray


# ============================================================================
# NAVIGATION SHORTCUTS
# ============================================================================
Write-Host "[2/8] " -ForegroundColor DarkGray -NoNewline
Write-Host "Setting up navigation shortcuts..." -ForegroundColor Green

function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

Write-Host "      [OK] Navigation shortcuts: .. ... ...." -ForegroundColor DarkGray


# ============================================================================
# FILE OPERATIONS
# ============================================================================
Write-Host "[3/8] " -ForegroundColor DarkGray -NoNewline
Write-Host "Configuring file operations..." -ForegroundColor Green

# Create new file (Unix-style touch command)
function touch { 
    param ($file = 'NewFile.txt') 
    New-Item $file -Force | Out-Null 
}

# Grep alias for Select-String
Set-Alias grep Select-String

# Find files by name (like Unix find)
function ff {
    param([Parameter(Mandatory=$true)]$Pattern)
    Get-ChildItem -Recurse -Filter "*$Pattern*" -ErrorAction SilentlyContinue | Select-Object FullName
}

# Find files by content (grep in files)
function fif {
    param(
        [Parameter(Mandatory=$true)]$Pattern,
        [string]$Path = "."
    )
    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
        Select-String -Pattern $Pattern | 
        Select-Object Path, LineNumber, Line
}

# Quick directory size
function dsize {
    param([string]$Path = ".")
    Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum | 
        Select-Object @{Name="Size(MB)";Expression={[math]::Round($_.Sum / 1MB, 2)}}
}

# List largest files in current directory
function big {
    param([int]$Top = 10)
    Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue | 
        Sort-Object Length -Descending | 
        Select-Object -First $Top | 
        Select-Object @{Name="Size(MB)";Expression={[math]::Round($_.Length / 1MB, 2)}}, FullName
}

# Create directory and cd into it
function mkcd {
    param([Parameter(Mandatory=$true)]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

# Quick delete (like rm -rf but safer with confirmation)
function rmd {
    param([Parameter(Mandatory=$true)]$Path)
    Remove-Item -Path $Path -Recurse -Force -Confirm
}

# Copy current path to clipboard
function pwd! {
    $pwd.Path | Set-Clipboard
    Write-Host "Path copied to clipboard: $($pwd.Path)" -ForegroundColor Green
}

# Open current directory in File Explorer
function open {
    param([string]$Path = ".")
    Invoke-Item $Path
}

Write-Host "      [OK] File operations: touch, grep, ff, fif, dsize, big, mkcd, rmd, pwd!, open" -ForegroundColor DarkGray


# ============================================================================
# GIT CONFIGURATION
# ============================================================================
Write-Host "[4/8] " -ForegroundColor DarkGray -NoNewline
Write-Host "Setting up Git aliases and functions..." -ForegroundColor Green

# Git alias
Set-Alias g git

# Configure git pretty log format
git config --global alias.lg "log --graph --decorate --date=relative --format=format:'%C(yellow)%h%Creset %C(cyan)%d%Creset %s %C(green)%cr%Creset by %C(bold blue)%an%Creset'" 2>$null

# Git commit shortcuts
function gcm { git commit -m $args }
function gcam { git commit -a -m $args }
function gcad { git commit -a --amend $args }
function glg { git lg $args }
function gs { git status }

# Git grep with enhanced formatting and color
function gg {
    [CmdletBinding()]
    param(
        # Search pattern
        [Parameter(Position = 0, Mandatory = $true)]
        $Pattern,

        # Optional glob(s) or extra git-grep args
        [Parameter(ValueFromRemainingArguments = $true)]
        $ExtraArgs,

        # Include ignored files as well
        [switch] $All
    )

    # Base options
    $opts = @(
        "--line-number"     # show line numbers
        "--ignore-case"     # case insensitive
        "--color=always"    # keep colors
        "-I"                # ignore binary files
        "--heading"         # group output by file
        "--break"           # add blank line between files
    )

    # Extend search to untracked + ignored if user asks
    if ($All) {
        $opts += "--untracked"
        $opts += "--no-index"   # enables full-tree search (tracked+untracked+ignored)
    } else {
        $opts += "--untracked"  # include untracked by default
    }

    git grep @opts -- $Pattern @ExtraArgs
}

Set-Alias gitgrep gg

# List branches sorted by last commit date
function gb {
    git branch --sort=-committerdate --format="%(color:yellow)%(refname:short)%(color:reset)  %(color:green)%(committerdate:relative)%(color:reset)  %(subject)"
}

# Git undo last commit (keep changes)
function gundo {
    git reset --soft HEAD~1
    Write-Host "Last commit undone (changes kept)" -ForegroundColor Green
}

# Git clean branches (delete merged branches)
function gclean {
    git branch --merged | Where-Object { $_ -notmatch "main|master|\*" } | ForEach-Object { git branch -d $_.Trim() }
    Write-Host "Cleaned merged branches" -ForegroundColor Green
}

# Quick git add, commit, push
function gacp {
    param([Parameter(Mandatory=$true)]$Message)
    git add .
    git commit -m $Message
    git push
}

# Git show changed files
function gfiles {
    git diff --name-only
}

# Git stash with message
function gss {
    param([string]$Message = "WIP")
    git stash push -m $Message
}

# List git stashes
function gsl {
    git stash list
}

Write-Host "      [OK] Git: g, gs, gcm, gcam, gcad, glg, gb, gg, gundo, gclean, gacp, gfiles, gss, gsl" -ForegroundColor DarkGray


# ============================================================================
# NETWORK UTILITIES
# ============================================================================
Write-Host "[5/8] " -ForegroundColor DarkGray -NoNewline
Write-Host "Loading network utilities..." -ForegroundColor Green

# List all local IP addresses
function inet {
    Get-NetIPAddress | 
        Where-Object {$_.AddressFamily -eq "IPv4" -and $_.IPAddress -NotLike "169.*" -and $_.IPAddress -NotLike "127.*"} |
        Select-Object IPAddress, InterfaceAlias
}

# Show all listening ports
function ports {
    Get-NetTCPConnection -State Listen |
        Select-Object LocalAddress, LocalPort, OwningProcess |
        Sort-Object LocalPort
}

# Get public IP
function myip {
    try {
        $ip = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip
        Write-Host "Public IP: $ip" -ForegroundColor Cyan
        $ip | Set-Clipboard
        Write-Host "Copied to clipboard!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to get public IP" -ForegroundColor Red
    }
}

# Quick DNS lookup
function nsl {
    param([Parameter(Mandatory=$true)]$Domain)
    Resolve-DnsName $Domain | Select-Object Name, Type, IPAddress
}

Write-Host "      [OK] Network: inet, ports, myip, nsl" -ForegroundColor DarkGray


# ============================================================================
# SYSTEM INFORMATION
# ============================================================================
Write-Host "[6/8] " -ForegroundColor DarkGray -NoNewline
Write-Host "Loading system information utilities..." -ForegroundColor Green

# System resource usage
function sysinfo {
    $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
    $mem = Get-CimInstance Win32_OperatingSystem
    $memUsed = [math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / 1MB, 2)
    $memTotal = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
    $memPercent = [math]::Round(($memUsed / $memTotal) * 100, 2)
    
    Write-Host "`nSystem Resources:" -ForegroundColor Cyan
    Write-Host "  CPU Usage: $cpu%" -ForegroundColor Yellow
    Write-Host ("  Memory: {0} MB / {1} MB {2}%" -f $memUsed, $memTotal, $memPercent) -ForegroundColor Yellow
    Write-Host ""
}

# List installed software
function apps {
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
        Select-Object DisplayName, DisplayVersion, Publisher | 
        Where-Object DisplayName -ne $null | 
        Sort-Object DisplayName
}

# Uptime
function uptime {
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-Host "System uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -ForegroundColor Green
}

Write-Host "      [OK] System info: sysinfo, apps, uptime" -ForegroundColor DarkGray


# ============================================================================
# POWERSHELL UTILITIES
# ============================================================================
Write-Host "[7/8] " -ForegroundColor DarkGray -NoNewline
Write-Host "Configuring PowerShell utilities..." -ForegroundColor Green

# View function source code quickly
function fn {
    param([Parameter(Mandatory=$true)]$Name)
    (Get-Command $Name).ScriptBlock
}

# Reload profile without restarting PowerShell (verbose by default)
function profile { 
    param([switch]$Silent)
    
    if (-not $Silent) {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "  Reloading PowerShell Profile..." -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
    }
    
    $reloadStart = Get-Date
    
    try {
        # Clear any previous errors
        $Error.Clear()
        
        # Force reload the profile
        & $PROFILE
        
        if (-not $Silent) {
            $reloadTime = ((Get-Date) - $reloadStart).TotalMilliseconds
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "  Profile reloaded successfully!" -ForegroundColor Green
            Write-Host "  Reload time: " -NoNewline -ForegroundColor White
            Write-Host "$([math]::Round($reloadTime, 2)) ms" -ForegroundColor Yellow
            Write-Host "========================================`n" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "`nError reloading profile: $_" -ForegroundColor Red
    }
}

# Display helper summary of all custom commands
function helper {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "              PowerShell Profile - Command Reference                     " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  NAVIGATION" -ForegroundColor Magenta
    Write-Host "  .." -ForegroundColor Yellow -NoNewline; Write-Host "          Go up 1 directory"
    Write-Host "  ..." -ForegroundColor Yellow -NoNewline; Write-Host "         Go up 2 directories"
    Write-Host "  ...." -ForegroundColor Yellow -NoNewline; Write-Host "        Go up 3 directories"
    Write-Host ""
    
    Write-Host "  FILE OPERATIONS" -ForegroundColor Magenta
    Write-Host "  touch" -ForegroundColor Yellow -NoNewline; Write-Host "       Create a file (Unix-style)"
    Write-Host "  ff" -ForegroundColor Yellow -NoNewline; Write-Host "          Find files by name: ff PATTERN"
    Write-Host "  fif" -ForegroundColor Yellow -NoNewline; Write-Host "         Find in files (search content): fif PATTERN [path]"
    Write-Host "  dsize" -ForegroundColor Yellow -NoNewline; Write-Host "       Get directory size: dsize [path]"
    Write-Host "  big" -ForegroundColor Yellow -NoNewline; Write-Host "         List largest files: big [top-n]"
    Write-Host "  mkcd" -ForegroundColor Yellow -NoNewline; Write-Host "        Create directory and enter it: mkcd PATH"
    Write-Host "  rmd" -ForegroundColor Yellow -NoNewline; Write-Host "         Remove directory (with confirmation): rmd PATH"
    Write-Host "  pwd!" -ForegroundColor Yellow -NoNewline; Write-Host "        Copy current path to clipboard"
    Write-Host "  open" -ForegroundColor Yellow -NoNewline; Write-Host "        Open directory in Explorer: open [path]"
    Write-Host "  grep" -ForegroundColor Yellow -NoNewline; Write-Host "        Alias for Select-String"
    Write-Host ""
    
    Write-Host "  GIT COMMANDS" -ForegroundColor Magenta
    Write-Host "  g" -ForegroundColor Yellow -NoNewline; Write-Host "           Alias for git"
    Write-Host "  gs" -ForegroundColor Yellow -NoNewline; Write-Host "          git status"
    Write-Host "  gcm" -ForegroundColor Yellow -NoNewline; Write-Host "         git commit -m MESSAGE"
    Write-Host "  gcam" -ForegroundColor Yellow -NoNewline; Write-Host "        git commit -a -m MESSAGE"
    Write-Host "  gcad" -ForegroundColor Yellow -NoNewline; Write-Host "        git commit -a --amend"
    Write-Host "  glg" -ForegroundColor Yellow -NoNewline; Write-Host "         git lg (pretty git log)"
    Write-Host "  gb" -ForegroundColor Yellow -NoNewline; Write-Host "          List branches sorted by last commit date"
    Write-Host "  gg" -ForegroundColor Yellow -NoNewline; Write-Host "          Smart git grep: gg PATTERN [--All for ignored files]"
    Write-Host "  gundo" -ForegroundColor Yellow -NoNewline; Write-Host "       Undo last commit (keep changes)"
    Write-Host "  gclean" -ForegroundColor Yellow -NoNewline; Write-Host "      Delete merged branches"
    Write-Host "  gacp" -ForegroundColor Yellow -NoNewline; Write-Host "        Git add, commit, push: gacp MESSAGE"
    Write-Host "  gfiles" -ForegroundColor Yellow -NoNewline; Write-Host "      Show changed files"
    Write-Host "  gss" -ForegroundColor Yellow -NoNewline; Write-Host "         Git stash with message: gss [message]"
    Write-Host "  gsl" -ForegroundColor Yellow -NoNewline; Write-Host "         List git stashes"
    Write-Host ""
    
    Write-Host "  NETWORK" -ForegroundColor Magenta
    Write-Host "  inet" -ForegroundColor Yellow -NoNewline; Write-Host "        List all local IP addresses"
    Write-Host "  myip" -ForegroundColor Yellow -NoNewline; Write-Host "        Get public IP (copied to clipboard)"
    Write-Host "  nsl" -ForegroundColor Yellow -NoNewline; Write-Host "         DNS lookup: nsl DOMAIN"
    Write-Host "  ports" -ForegroundColor Yellow -NoNewline; Write-Host "       Show all listening ports"
    Write-Host ""
    
    Write-Host "  SYSTEM INFO" -ForegroundColor Magenta
    Write-Host "  sysinfo" -ForegroundColor Yellow -NoNewline; Write-Host "     Display CPU and memory usage"
    Write-Host "  apps" -ForegroundColor Yellow -NoNewline; Write-Host "        List installed software"
    Write-Host "  uptime" -ForegroundColor Yellow -NoNewline; Write-Host "      Show system uptime"
    Write-Host ""
    
    Write-Host "  POWERSHELL" -ForegroundColor Magenta
    Write-Host "  fn" -ForegroundColor Yellow -NoNewline; Write-Host "          View function source: fn FUNCTION-NAME"
    Write-Host "  profile" -ForegroundColor Yellow -NoNewline; Write-Host "     Reload PowerShell profile (verbose by default)"
    Write-Host "               Use " -NoNewline; Write-Host "profile -Silent" -ForegroundColor Yellow -NoNewline; Write-Host " for quiet reload"
    Write-Host ""
    
    Write-Host "  TIP: " -ForegroundColor Cyan -NoNewline
    Write-Host "Use " -NoNewline
    Write-Host "fn FUNCTION-NAME" -ForegroundColor Yellow -NoNewline
    Write-Host " to view any function's source code"
    Write-Host ""
}

Write-Host "      [OK] PowerShell utilities: fn, profile, helper" -ForegroundColor DarkGray


# ============================================================================
# STARTUP
# ============================================================================
Write-Host "[8/8] " -ForegroundColor DarkGray -NoNewline
Write-Host "Setting default location..." -ForegroundColor Green

# Detect if we're in a "user-selected" directory
# User-selected = anywhere other than system defaults
$defaultLocations = @(
    $env:USERPROFILE,
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\OneDrive\Documents",
    "$env:SystemRoot\System32",
    "$env:SystemRoot\System32\WindowsPowerShell\v1.0",
    "C:\Windows\System32"
)

$currentLocation = (Get-Location).Path
$isDefaultLocation = $false

foreach ($defaultLoc in $defaultLocations) {
    if ($currentLocation -eq $defaultLoc) {
        $isDefaultLocation = $true
        break
    }
}

# Only change to C:\repo if we're in a default location
if ($isDefaultLocation) {
    if (Test-Path "C:\repo") {
        Set-Location C:\repo
        Write-Host "      [OK] Changed to C:\repo" -ForegroundColor DarkGray
    } else {
        Write-Host "      ! C:\repo not found, staying in default location" -ForegroundColor Yellow
    }
} else {
    # User opened PowerShell in a specific directory - respect their choice
    Write-Host "      [OK] Staying in: $currentLocation" -ForegroundColor DarkGray
}

# Calculate and display load time
$ProfileLoadTime = ((Get-Date) - $ProfileLoadStart).TotalMilliseconds

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Profile loaded successfully! " -NoNewline -ForegroundColor Green
Write-Host "[OK]" -ForegroundColor Green
Write-Host "  Load time: " -NoNewline -ForegroundColor White
Write-Host "$([math]::Round($ProfileLoadTime, 2)) ms" -ForegroundColor Yellow
Write-Host "  Type " -NoNewline -ForegroundColor White
Write-Host "'helper'" -ForegroundColor Yellow -NoNewline
Write-Host " for command reference" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""