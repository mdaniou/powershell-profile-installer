# Configuration Guide

## Repository Auto-Navigation

The profile can automatically navigate to your development folder on startup.

### Priority Order

The profile checks for your repo folder in this order:

1. Environment variable `$env:DEV_REPO`
2. Config file at `%LOCALAPPDATA%\PSProfile\config.json`
3. Auto-detection of common paths

### Method 1: Environment Variable (Recommended)

**Per-user:**
```powershell
[Environment]::SetEnvironmentVariable("DEV_REPO", "C:\dev", "User")
```

**System-wide (requires admin):**
```powershell
[Environment]::SetEnvironmentVariable("DEV_REPO", "D:\repos", "Machine")
```

**Advantages:**
- Survives profile updates
- Simple to set
- Can be set via Group Policy

### Method 2: Config File

Use the helper function provided in the profile:
```powershell
Set-RepoFolder "C:\your\path"
```

Or create manually:
```powershell
$config = @{ RepoFolder = "C:\your\path" }
$configPath = "$env:LOCALAPPDATA\PSProfile\config.json"
$config | ConvertTo-Json | Out-File $configPath -Encoding UTF8
```

**Config file location:** `%LOCALAPPDATA%\PSProfile\config.json`

### Method 3: Auto-Detection

If neither environment variable nor config file is set, the profile searches:

- `C:\repo`
- `C:\repos`
- `C:\dev`
- `C:\projects`
- `D:\repo`
- `D:\repos`
- `$HOME\repo`
- `$HOME\repos`
- `$HOME\source`

## Machine-Specific Settings

### Using Config File

Add custom settings to your config:
```powershell
$config = @{
    RepoFolder = "C:\dev"
    DefaultEditor = "code"
    GitUserName = "John Doe"
}

$configPath = "$env:LOCALAPPDATA\PSProfile\config.json"
$config | ConvertTo-Json | Out-File $configPath -Encoding UTF8
```

### Reading Config in Profile

Add to your `profile.ps1`:
```powershell
# Load machine-specific config
$configPath = Join-Path $env:LOCALAPPDATA "PSProfile\config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    
    # Use config values
    if ($config.DefaultEditor) {
        $env:EDITOR = $config.DefaultEditor
    }
}
```

## Customizing the Profile

### Adding Your Own Functions

Edit `profile.ps1` and add functions:
```powershell
# Custom function example
function my-function {
    param([string]$Parameter)
    Write-Host "Your custom function: $Parameter" -ForegroundColor Green
}
```

### Adding Aliases
```powershell
# Custom aliases
Set-Alias tf terraform
Set-Alias k kubectl
```

### Conditional Loading

Load different settings based on environment:
```powershell
# Load different config for different servers
$hostname = $env:COMPUTERNAME

switch -Wildcard ($hostname) {
    "DEV-*" {
        Write-Host "Development environment detected" -ForegroundColor Yellow
        # Dev-specific settings
    }
    "PROD-*" {
        Write-Host "Production environment" -ForegroundColor Red
        # Prod-specific settings
    }
}
```

## OneDrive Configuration

### Force Local Documents

To always use local Documents (never OneDrive):
```powershell
.\install.ps1 -Local
```

### Understanding OneDrive Behavior

**Master Profile:**
- Always stored in `%LOCALAPPDATA%\PSProfile\`
- Never synced by OneDrive
- Machine-specific

**Loader Scripts:**
- Stored in Documents folder
- May sync via OneDrive if Documents is redirected
- This is OK - loaders just point to local master profile

### Handling OneDrive Sync Conflicts

If you get sync conflicts on loaders:

1. Delete all loaders
2. Run: `.\install.ps1 -Local -Update`
3. This forces local Documents, avoiding sync

## Profile Performance

### Measuring Load Time

The profile displays load time on startup. To benchmark:
```powershell
Measure-Command { . $PROFILE }
```

### Optimizing Load Time

If profile is slow:

1. **Remove unnecessary commands** from startup section
2. **Lazy-load modules:** Load only when needed
3. **Use functions instead of scripts:** Functions are faster

Example lazy-loading:
```powershell
# Don't load module at startup
# function my-command {
#     Import-Module MyModule
#     my-command @args
# }
```

## Security Considerations

### Execution Policy

If you get execution policy errors:
```powershell
# Check current policy
Get-ExecutionPolicy

# Allow local scripts (per-user)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Code Signing

For enterprise environments requiring signed scripts:

1. Obtain code signing certificate
2. Sign the profile:
```powershell
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
Set-AuthenticodeSignature -FilePath $PROFILE -Certificate $cert
```

## Advanced Scenarios

### Multiple Users on Same Machine

Each user gets their own profile in their `%LOCALAPPDATA%`.

### Terminal-Specific Profiles

The installer creates loaders for:
- PowerShell Console
- PowerShell ISE
- VS Code PowerShell Extension
- Windows Terminal

All load the same master profile.

### Version Control Your Profile

Keep `profile.ps1` in Git:
```powershell
cd $env:LOCALAPPDATA\PSProfile
git init
git add profile.ps1
git commit -m "Initial profile"
```

## Troubleshooting

### Config Not Loading

Verify config file exists and is valid JSON:
```powershell
$configPath = "$env:LOCALAPPDATA\PSProfile\config.json"
Test-Path $configPath
Get-Content $configPath | ConvertFrom-Json
```

### Repo Auto-Navigation Not Working

Check what the profile detected:
```powershell
# After profile loads
$env:DEV_REPO  # Check environment variable
```

Manually test the detection function:
```powershell
# Add to profile temporarily
Write-Host "Detected repo: $(Find-RepoFolder)" -ForegroundColor Yellow
```
