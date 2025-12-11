# PowerShell Profile Installer for Air-Gapped Servers

A smart, portable PowerShell profile installer designed for enterprise environments, air-gapped servers, and OneDrive-aware deployments.

## ✨ Features

- 🚀 **Air-gap friendly** - No internet required, just copy two files
- ☁️ **OneDrive-aware** - Smart detection and handling of OneDrive-redirected Documents
- 🎯 **Portable** - Works on any Windows server with PowerShell 5.1+
- 🔄 **Easy updates** - Simple `.\install.ps1 -Update` command
- 📍 **Smart repo detection** - Auto-finds your dev folder or configure manually
- 🎨 **Rich profile** - Custom prompt, Git shortcuts, network tools, and more
- 💾 **Safe** - Automatically backs up existing profiles
- 🔧 **Configurable** - Per-machine settings via config file or environment variables

## 🚀 Quick Start

### Installation

1. Copy `install.ps1` and `profile.ps1` to your server (USB drive, RDP, network share, etc.)
2. Open PowerShell and navigate to the directory
3. Run the installer:
```powershell
.\install.ps1
```

4. Restart PowerShell or reload your profile:
```powershell
. $PROFILE
```

### Update Profile

To update your profile on a server where it's already installed:
```powershell
# Copy updated profile.ps1 to the server
.\install.ps1 -Update
```

## 📖 How It Works

### Architecture

The installer uses a **loader pattern** to separate concerns:

1. **Master Profile**: Stored in `%LOCALAPPDATA%\PSProfile\profile.ps1`
   - Local to each machine (never synced by OneDrive)
   - Contains all your functions and customizations

2. **Loader Scripts**: Created in standard PowerShell profile locations
   - Lightweight files that dot-source the master profile
   - Work across PowerShell 5.1, 7.x, ISE, VSCode, etc.

### OneDrive Handling

The installer intelligently detects OneDrive-redirected Documents folders:

- **Default behavior**: Uses your current Documents folder (OneDrive or local)
- **`-Local` flag**: Forces local Documents folder, bypassing OneDrive

Master profile is always stored in `%LOCALAPPDATA%`, ensuring:
- No sync conflicts across different machines
- Fast loading (local disk access)
- Machine-specific configurations possible

## 🛠️ Usage

### Basic Commands
```powershell
# Install profile
.\install.ps1

# Update existing profile
.\install.ps1 -Update

# Force local Documents (skip OneDrive)
.\install.ps1 -Local

# Uninstall profile
.\install.ps1 -Uninstall
```

### Configure Repository Auto-Navigation

The profile can automatically navigate to your development folder. Three methods:

**Method 1: Auto-detection** (works out of the box)
- Searches common paths: `C:\repo`, `C:\dev`, `D:\repos`, etc.

**Method 2: Environment variable**
```powershell
[Environment]::SetEnvironmentVariable("DEV_REPO", "C:\your\path", "User")
```

**Method 3: Config file** (via helper function in profile)
```powershell
Set-RepoFolder "C:\your\path"
```

## 📦 What's Included

### Custom Prompt
- Shows elevated status, PowerShell version, username, current folder
- Displays timestamp and command execution time
- Color-coded for easy scanning

### Navigation Shortcuts
- `..` - Go up 1 directory
- `...` - Go up 2 directories  
- `....` - Go up 3 directories

### File Operations
- `touch` - Create files (Unix-style)
- `ff` - Find files by name
- `fif` - Find in files (search content)
- `dsize` - Get directory size
- `big` - List largest files
- `mkcd` - Create directory and cd into it
- `rmd` - Remove directory (with confirmation)
- `pwd!` - Copy current path to clipboard
- `open` - Open directory in Explorer
- `grep` - Alias for Select-String

### Git Shortcuts
- `g` - Alias for git
- `gs` - git status
- `gcm` - git commit -m
- `gcam` - git commit -a -m
- `gcad` - git commit --amend
- `glg` - Pretty git log
- `gb` - List branches by date
- `gg` - Smart git grep
- `gundo` - Undo last commit (keep changes)
- `gclean` - Delete merged branches
- `gacp` - Add, commit, and push
- `gfiles` - Show changed files
- `gss` - Stash with message
- `gsl` - List stashes

### Network Utilities
- `inet` - List local IP addresses
- `myip` - Get public IP (copies to clipboard)
- `nsl` - DNS lookup
- `ports` - Show listening ports

### System Info
- `sysinfo` - Display CPU and memory usage
- `apps` - List installed software
- `uptime` - Show system uptime

### PowerShell Utilities
- `fn` - View function source code
- `profile` - Reload profile (verbose by default)
- `helper` - Display command reference

## 🔧 Customization

### Modify the Profile

Edit `profile.ps1` to add your own functions, aliases, and customizations. Then run:
```powershell
.\install.ps1 -Update
```

### Add Machine-Specific Settings

Use the config file approach for machine-specific settings:
```powershell
# In your profile.ps1, add:
$configPath = Join-Path $env:LOCALAPPDATA "PSProfile\config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    # Use $config.YourSetting
}
```

## 🏢 Enterprise Deployment

### Deploy to Multiple Servers

1. Copy both files to a network share
2. Create a deployment script:
```powershell
$servers = @("server01", "server02", "server03")

foreach ($server in $servers) {
    $session = New-PSSession -ComputerName $server
    
    Copy-Item ".\install.ps1" -Destination "C:\Temp\" -ToSession $session
    Copy-Item ".\profile.ps1" -Destination "C:\Temp\" -ToSession $session
    
    Invoke-Command -Session $session -ScriptBlock {
        Set-Location C:\Temp
        .\install.ps1
    }
    
    Remove-PSSession $session
}
```

### Update Across Fleet

Same script, but use `.\install.ps1 -Update`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by Unix dotfiles management
- Built for sysadmins managing multiple Windows servers
- Designed to work in restricted enterprise environments

## 📞 Support

- 📖 [Installation Guide](docs/INSTALLATION.md)
- 🔧 [Configuration Guide](docs/CONFIGURATION.md)
- 🐛 [Report Issues](../../issues)

## 🗺️ Roadmap

- [ ] PowerShell Gallery module
- [ ] Automated testing
- [ ] Profile themes/presets
- [ ] Web-based profile generator
- [ ] Integration with Windows Terminal settings

---

**Made with ❤️ for the PowerShell community**
