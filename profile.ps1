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
Write-Host "[1/9] " -ForegroundColor DarkGray -NoNewline
Write-Host "Configuring custom prompt..." -ForegroundColor Green

function Get-GitStatus {
    $raw = git status --porcelain=v1 -b 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) { return $null }

    $lines = $raw -split "`n"
    $header = $lines[0]

    $branch = if ($header -match '^## No commits yet on (.+)') { $Matches[1] }
              elseif ($header -match '^## HEAD \(no branch\)')  { 'HEAD' }
              elseif ($header -match '^## ([^.]+)')             { $Matches[1] }
              else { '?' }

    $ahead  = if ($header -match 'ahead (\d+)')  { [int]$Matches[1] } else { 0 }
    $behind = if ($header -match 'behind (\d+)') { [int]$Matches[1] } else { 0 }

    $staged = 0; $modified = 0; $deleted = 0; $untracked = 0
    foreach ($line in $lines[1..($lines.Count - 1)]) {
        if ($line.Length -lt 2) { continue }
        $x = $line[0]; $y = $line[1]
        if ($x -eq '?' -and $y -eq '?') { $untracked++; continue }
        if ($x -in @('A', 'M', 'R', 'C')) { $staged++ }
        if ($y -eq 'M') { $modified++ }
        if ($x -eq 'D' -or $y -eq 'D') { $deleted++ }
    }

    $parts = @()
    if ($staged    -gt 0) { $parts += "+$staged" }
    if ($modified  -gt 0) { $parts += "~$modified" }
    if ($deleted   -gt 0) { $parts += "-$deleted" }
    if ($untracked -gt 0) { $parts += "?$untracked" }
    if ($ahead     -gt 0) { $parts += ([char]0x21E1).ToString() + $ahead }
    if ($behind    -gt 0) { $parts += ([char]0x21E3).ToString() + $behind }

    return [PSCustomObject]@{
        Branch  = $branch.Trim()
        Status  = ($parts -join ' ')
        IsClean = ($parts.Count -eq 0)
    }
}

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

    $git = Get-GitStatus
    if ($git) {
        Write-Host " $($git.Branch) " -BackgroundColor DarkCyan -ForegroundColor White -NoNewline
        if (-not $git.IsClean) {
            Write-Host " $($git.Status) " -BackgroundColor Black -ForegroundColor Yellow -NoNewline
        }
    }

    Write-Host " $date " -ForegroundColor White
    Write-Host "[$elapsedTime] " -NoNewline -ForegroundColor Green
    return "> "
}

Write-Host "      [OK] Custom prompt configured" -ForegroundColor DarkGray


# ============================================================================
# NAVIGATION SHORTCUTS
# ============================================================================
Write-Host "[2/9] " -ForegroundColor DarkGray -NoNewline
Write-Host "Setting up navigation shortcuts..." -ForegroundColor Green

function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

Write-Host "      [OK] Navigation shortcuts: .. ... ...." -ForegroundColor DarkGray


# ============================================================================
# FILE OPERATIONS
# ============================================================================
Write-Host "[3/9] " -ForegroundColor DarkGray -NoNewline
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
Write-Host "[4/9] " -ForegroundColor DarkGray -NoNewline
Write-Host "Setting up Git aliases and functions..." -ForegroundColor Green

# Git alias
Set-Alias g git

# Configure git pretty log format
git config --global alias.lg "log --graph --decorate --date=relative --format=format:'%C(yellow)%h%Creset %C(cyan)%d%Creset %s %C(green)%cr%Creset by %C(bold blue)%an%Creset'" 2>$null

# Git commit shortcuts
function _Get-GitCommitMessage {
    $branch    = git rev-parse --abbrev-ref HEAD 2>$null
    $porcelain = git status --porcelain
    $added     = ($porcelain | Where-Object { $_ -match '^\?\?|^A' }).Count
    $modified  = ($porcelain | Where-Object { $_ -match '^[ MARC]M|^M' }).Count
    $deleted   = ($porcelain | Where-Object { $_ -match '^[ MARC]D|^D' }).Count
    "$branch | $(Get-Date -Format 'yyyy-MM-dd HH:mm') | +$added ~$modified -$deleted"
}
function gcm {
    param([string]$Message, [Parameter(ValueFromRemainingArguments)][string[]]$ExtraArgs)
    if (-not $Message) { $Message = _Get-GitCommitMessage }
    git commit -m $Message @ExtraArgs
}
function gcam {
    param([string]$Message, [Parameter(ValueFromRemainingArguments)][string[]]$ExtraArgs)
    if (-not $Message) { $Message = _Get-GitCommitMessage }
    git commit -a -m $Message @ExtraArgs
}
function gcad {
    param([string]$Message, [Parameter(ValueFromRemainingArguments)][string[]]$ExtraArgs)
    if (-not $Message) { $Message = _Get-GitCommitMessage }
    git commit -a --amend -m $Message @ExtraArgs
}
function glg { git lg $args }
function gs {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Args)
    if ($Args) { git status @Args } else { git status -s -b }
}

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
    param([Parameter(ValueFromRemainingArguments)][string[]]$Args)
    if ($Args) {
        git branch @Args
    } else {
        git branch --sort=-committerdate --format="%(color:yellow)%(refname:short)%(color:reset)  %(color:green)%(committerdate:relative)%(color:reset)  %(subject)"
    }
}

# Git undo last commit (keep changes)
function gundo {
    git reset --soft HEAD~1
    Write-Host "Last commit undone (changes kept)" -ForegroundColor Green
}

# Git clean branches (interactive selection)
function gclean {
    param(
        [Alias('l')][switch]$Local,
        [Alias('r')][switch]$Remote
    )

    function _gclean-delete {
        param([string]$Branch, [string]$Type)
        if ($Type -eq 'L') {
            git branch -d $Branch 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host ("  Deleted local:  {0}" -f $Branch) -ForegroundColor Green
            } else {
                Write-Host ("  Failed to delete local: {0} (not fully merged?)" -f $Branch) -ForegroundColor Red
            }
        } else {
            $remoteName = $Branch -replace '^origin/', ''
            git push origin --delete $remoteName 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host ("  Deleted remote: {0}" -f $Branch) -ForegroundColor Green
            } else {
                Write-Host ("  Failed to delete remote: {0}" -f $Branch) -ForegroundColor Red
            }
        }
    }

    function _gclean-get-local {
        param([string]$Base)
        git branch --merged $Base 2>$null |
            Where-Object { $_ -notmatch 'main|master|\*' } |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' } |
            ForEach-Object { [PSCustomObject]@{ Name = $_; Type = 'L' } }
    }

    function _gclean-get-remote {
        param([string]$Base)
        git branch -r --merged $Base 2>$null |
            Where-Object { $_ -notmatch 'main|master|\*|HEAD' } |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' } |
            ForEach-Object { [PSCustomObject]@{ Name = $_; Type = 'R' } }
    }

    # Detect default branch (main/master) for consistent --merged comparison
    $defaultBranch = git symbolic-ref refs/remotes/origin/HEAD 2>$null |
        ForEach-Object { $_ -replace 'refs/remotes/origin/', '' }
    if (-not $defaultBranch) { $defaultBranch = 'main' }
    $remoteBase = "origin/$defaultBranch"

    # Determine mode from params; default to both
    $mode = if ($Local) { 'l' } elseif ($Remote) { 'r' } else { 'b' }

    while ($true) {
        $candidates = switch ($mode) {
            'l' { _gclean-get-local $defaultBranch }
            'r' { _gclean-get-remote $remoteBase }
            'b' { @(_gclean-get-local $defaultBranch) + @(_gclean-get-remote $remoteBase) }
        }

        if (-not $candidates) {
            Write-Host "  No merged branches to clean." -ForegroundColor DarkGray
            return
        }

        Write-Host ""
        Write-Host "  Merged branches:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            $tag = if ($mode -eq 'b') { "  [$($candidates[$i].Type)]" } else { '' }
            Write-Host ("  [{0}] {1}{2}" -f ($i + 1), $candidates[$i].Name, $tag) -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "  [1-N] Delete by number" -ForegroundColor Cyan
        Write-Host "  [a]  Delete all" -ForegroundColor Red
        if ($mode -eq 'b') {
            $hasLocal  = $candidates | Where-Object { $_.Type -eq 'L' }
            $hasRemote = $candidates | Where-Object { $_.Type -eq 'R' }
            if ($hasLocal)  { Write-Host "  [al] Delete all local"  -ForegroundColor Red }
            if ($hasRemote) { Write-Host "  [ar] Delete all remote" -ForegroundColor Red }
        }
        Write-Host "  [q]  Quit" -ForegroundColor DarkGray
        Write-Host ""

        $choice = (Read-Host "  Choice").Trim().ToLower()

        if ($choice -eq 'q' -or $choice -eq '') {
            return
        } elseif ($choice -eq 'a') {
            $candidates | ForEach-Object { _gclean-delete $_.Name $_.Type }
        } elseif ($choice -eq 'al' -and $mode -eq 'b') {
            $candidates | Where-Object { $_.Type -eq 'L' } | ForEach-Object { _gclean-delete $_.Name $_.Type }
        } elseif ($choice -eq 'ar' -and $mode -eq 'b') {
            $candidates | Where-Object { $_.Type -eq 'R' } | ForEach-Object { _gclean-delete $_.Name $_.Type }
        } elseif ($choice -match '^\d+$') {
            $idx = [int]$choice - 1
            if ($idx -ge 0 -and $idx -lt $candidates.Count) {
                _gclean-delete $candidates[$idx].Name $candidates[$idx].Type
            } else {
                Write-Host "  Invalid number." -ForegroundColor DarkGray
            }
        } else {
            Write-Host "  Unknown input." -ForegroundColor DarkGray
        }
    }
}

# Quick git add, commit, push
function gp {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    git rev-parse --abbrev-ref '@{u}' 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "      No upstream — pushing and tracking origin/$branch" -ForegroundColor DarkGray
        git push --set-upstream origin $branch
    } else {
        git push
    }
}
Remove-Item Alias:gp -Force -ErrorAction SilentlyContinue

function gacp {
    param([string]$Message, [Parameter(ValueFromRemainingArguments)][string[]]$ExtraArgs)
    if (-not $Message) { $Message = _Get-GitCommitMessage }
    git add .
    git commit -m $Message @ExtraArgs
    gp
}

# Git show changed files
function gfiles {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Args)
    if ($Args) { git diff --name-only @Args } else { git diff --name-only }
}

# Git stash with message
function gss {
    param([string]$Message = "WIP")
    git stash push -m $Message
}

# List git stashes
function gsl {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Args)
    if ($Args) { git stash list @Args } else { git stash list }
}

# Create a new worktree and branch from within current git directory.
function gwa {
    param([string]$Branch)

    if (-not $Branch) {
        Write-Host "Usage: ga [branch name]"
        return
    }

    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not inside a git repository"
        return
    }

    $base = git rev-parse --show-toplevel
    $path = "$base--$Branch"

    Write-Host "Creating worktree " -NoNewline
    Write-Host $path -ForegroundColor Cyan

    git worktree add -b $Branch $path 2>$null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create worktree" -ForegroundColor Red
        return
    }

    Write-Host "Done" -ForegroundColor Green
    Set-Location $path
}

# Remove worktree and branch from within active worktree directory.
function gwd {
    $cwd = (Get-Location).Path
    $worktree = Split-Path -Leaf $cwd
    $parts = $worktree -split '--', 2
    if ($parts.Count -lt 2) {
        Write-Host "Not inside a worktree directory (expected name like 'repo--branch')"
        return
    }
    $root = $parts[0]
    $branch = $parts[1]
    $confirm = Read-Host "Remove worktree and branch '$branch'? (y/N)"
    if ($confirm -eq 'y') {
        Set-Location "..\$root"
        git worktree remove $cwd --force
        if ($LASTEXITCODE -eq 0) {
            git branch -D $branch
        }
    }
}

# move to the other worktrees
function gwl {
    param([string]$Path)

    if (-not $Path) {
        $worktrees = git worktree list --porcelain |
            Select-String "^worktree" |
            ForEach-Object { $_.Line -replace "^worktree ", "" }

        $current = (Get-Location).Path.TrimEnd('\').Replace('\', '/')
        $idx = 0
        for ($i = 0; $i -lt $worktrees.Count; $i++) {
            if ($worktrees[$i].TrimEnd('/') -ieq $current) {
                $idx = $i
                break
            }
        }

        $next = $worktrees[($idx + 1) % $worktrees.Count]
        Set-Location $next
        Write-Host $next -ForegroundColor Cyan
        return
    }

    Set-Location $Path
}

# delete all worktress
function gwclean {
    $worktrees = git worktree list --porcelain |
        Select-String "^worktree" |
        ForEach-Object { $_.Line -replace "^worktree ", "" }

    $main = $worktrees[0]
    $others = $worktrees | Select-Object -Skip 1

    if ($others.Count -eq 0) {
        Write-Host "No worktrees to clean up" -ForegroundColor Cyan
        return
    }

    Write-Host "About to remove $($others.Count) worktree(s):" -ForegroundColor Yellow
    $others | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    $confirm = Read-Host "Confirm? (y/N)"

    if ($confirm -ne 'y') { return }

    Set-Location $main

    foreach ($wt in $others) {
        $branch = (git worktree list --porcelain |
            Select-String -Pattern "worktree $($wt -replace '/','\/')" -Context 0,2).Context.PostContext |
            Select-String "^branch" |
            ForEach-Object { $_.Line -replace "^branch refs/heads/", "" }

        Write-Host "Removing $wt " -NoNewline
        git worktree remove $wt --force 2>$null
        if ($LASTEXITCODE -eq 0) {
            git branch -D $branch 2>$null
            Write-Host "done" -ForegroundColor Green
        } else {
            Write-Host "failed" -ForegroundColor Red
        }
    }
}

# add worktree tab
Register-ArgumentCompleter -CommandName gs -ParameterName Path -ScriptBlock {
    git worktree list --porcelain |
        Select-String "^worktree" |
        ForEach-Object { $_.Line -replace "^worktree ", "" } |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

Write-Host "      [OK] Git: g, gs, gcm, gcam, gcad, glg, gb, gg, gundo, gclean, gacp, gfiles, gss, gsl, gwa, gwd, gwl, gwclean" -ForegroundColor DarkGray


# ============================================================================
# NETWORK UTILITIES
# ============================================================================
Write-Host "[5/9] " -ForegroundColor DarkGray -NoNewline
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
Write-Host "[6/9] " -ForegroundColor DarkGray -NoNewline
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
Write-Host "[7/9] " -ForegroundColor DarkGray -NoNewline
Write-Host "Configuring PowerShell utilities..." -ForegroundColor Green

# View function source code quickly
function fn {
    param([Parameter(Mandatory=$true)]$Name)
    (Get-Command $Name).ScriptBlock
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
    Write-Host "  gwa" -ForegroundColor Yellow -NoNewline; Write-Host "         Create a new worktree and branch from within current git directory."
    Write-Host "  gwd" -ForegroundColor Yellow -NoNewline; Write-Host "         Remove worktree and branch from within active worktree directory"
    Write-Host "  gwl" -ForegroundColor Yellow -NoNewline; Write-Host "         Move to the other worktrees."
    Write-Host "  gwclean" -ForegroundColor Yellow -NoNewline; Write-Host "     Delete all worktress."
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
    Write-Host "  fn" -ForegroundColor Yellow -NoNewline; Write-Host "                    View function source: fn FUNCTION-NAME"
    Write-Host "  helper" -ForegroundColor Yellow -NoNewline; Write-Host "                Display this command reference"
    Write-Host "  profile" -ForegroundColor Yellow -NoNewline; Write-Host "               Show profile CLI help"
    Write-Host "  profile reload" -ForegroundColor Yellow -NoNewline; Write-Host "        Reload the profile"
    Write-Host "  profile reload -Silent" -ForegroundColor Yellow -NoNewline; Write-Host " Reload without output"
    Write-Host "  profile script list" -ForegroundColor Yellow -NoNewline; Write-Host "   List auto-execute script paths"
    Write-Host "  profile script add" -ForegroundColor Yellow -NoNewline; Write-Host "    Add a folder or .ps1 file: profile script add <path>"
    Write-Host "  profile script remove" -ForegroundColor Yellow -NoNewline; Write-Host " Remove a path by number:    profile script remove <n>"
    Write-Host ""
    
    Write-Host "  TIP: " -ForegroundColor Cyan -NoNewline
    Write-Host "Use " -NoNewline
    Write-Host "fn FUNCTION-NAME" -ForegroundColor Yellow -NoNewline
    Write-Host " to view any function's source code"
    Write-Host ""
}

# Load the profile CLI (profile reload, profile script add/list/remove)
$_cliScript = Join-Path $env:LOCALAPPDATA "PSProfile\profile-cli.ps1"
if (Test-Path $_cliScript) {
    . $_cliScript
} else {
    Write-Host "      [WARNING] profile-cli.ps1 not found - run install.ps1 to fix" -ForegroundColor Yellow
}
Remove-Variable _cliScript

Write-Host "      [OK] PowerShell utilities: fn, helper, profile" -ForegroundColor DarkGray


# ============================================================================
# AUTO-EXECUTE SCRIPTS
# ============================================================================
Write-Host "[8/9] " -ForegroundColor DarkGray -NoNewline
Write-Host "Loading auto-execute scripts..." -ForegroundColor Green

$psConfigPath = Join-Path $env:LOCALAPPDATA "PSProfile\config.json"
$autoExecPaths = @()

if (Test-Path $psConfigPath) {
    try {
        $psProfileConfig = Get-Content $psConfigPath -Raw | ConvertFrom-Json
        if (Get-Member -InputObject $psProfileConfig -Name 'ScriptPaths' -MemberType NoteProperty) {
            $autoExecPaths = @($psProfileConfig.ScriptPaths) | Where-Object { $_ }
        }
    } catch {
        Write-Host "      [WARNING] Could not read config: $_" -ForegroundColor Yellow
    }
}

if ($autoExecPaths.Count -eq 0) {
    Write-Host "      [OK] No scripts configured" -ForegroundColor DarkGray
} else {
    $autoLoadedCount = 0
    foreach ($autoPath in $autoExecPaths) {
        if (-not (Test-Path $autoPath)) {
            Write-Host "      [WARNING] Path not found: $autoPath" -ForegroundColor Yellow
            continue
        }
        $autoItem = Get-Item $autoPath -ErrorAction SilentlyContinue
        if ($autoItem.PSIsContainer) {
            $autoScripts = Get-ChildItem -Path $autoPath -Filter "*.ps1" -File -ErrorAction SilentlyContinue |
                Sort-Object Name
            foreach ($autoScript in $autoScripts) {
                try {
                    . $autoScript.FullName
                    $autoLoadedCount++
                } catch {
                    Write-Host "      [WARNING] Error in $($autoScript.Name): $_" -ForegroundColor Yellow
                }
            }
        } else {
            try {
                . $autoPath
                $autoLoadedCount++
            } catch {
                Write-Host "      [WARNING] Error in $(Split-Path $autoPath -Leaf): $_" -ForegroundColor Yellow
            }
        }
    }
    Write-Host "      [OK] Loaded $autoLoadedCount script(s) from $($autoExecPaths.Count) path(s)" -ForegroundColor DarkGray
}


# ============================================================================
# STARTUP
# ============================================================================
Write-Host "[9/9] " -ForegroundColor DarkGray -NoNewline
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