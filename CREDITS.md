# Credits

## Development

This project was created by [Your Name] with significant assistance from Claude (Sonnet 4), an AI assistant by Anthropic (https://claude.ai).

**Conversation Date**: December 2024

## AI Contribution

Claude (Sonnet 4) helped with:
- System architecture and design patterns
- PowerShell scripting and best practices
- OneDrive detection and handling logic
- Air-gapped deployment strategies
- Documentation writing and structure
- Project organization and best practices
- Error handling and edge cases
- Git workflow and repository setup

## Technical References

### PowerShell Documentation
- [About Profiles - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles)
- [PowerShell Scripting Best Practices - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)
- [Execution Policies - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

### File System and Environment
- [Environment.SpecialFolder Enum - Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.environment.specialfolder)
- [OneDrive Files On-Demand - Microsoft Learn](https://learn.microsoft.com/en-us/onedrive/files-on-demand-windows)
- [Known Folders - Windows App Development](https://learn.microsoft.com/en-us/windows/win32/shell/knownfolderid)

### Git and Version Control
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Semantic Versioning](https://semver.org/)

### PowerShell Community Resources
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [PowerShell GitHub Repository](https://github.com/PowerShell/PowerShell)
- [r/PowerShell Community](https://www.reddit.com/r/PowerShell/)

## Design Patterns and Concepts

### Dotfiles Management
- Inspired by Unix/Linux dotfiles management practices
- [GitHub's unofficial dotfiles guide](https://dotfiles.github.io/)
- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)

### Enterprise Deployment Patterns
- Centralized configuration management
- Loader pattern for profile separation
- Air-gapped deployment strategies
- Machine-specific configuration via environment variables and config files

### PowerShell Profile Patterns
- [PowerShell Profile Snippets - GitHub Gist](https://gist.github.com/)
- Common PowerShell profile patterns from the community
- Enterprise IT best practices for Windows administration

## Key Design Decisions

### Master Profile in LOCALAPPDATA
**Decision**: Store master profile in `%LOCALAPPDATA%\PSProfile\` instead of Documents folder

**Rationale**:
- Avoids OneDrive sync conflicts
- Keeps profile machine-local (as intended)
- Faster access (local disk vs cloud sync)
- Follows Windows application data conventions

**Reference**: [LOCALAPPDATA - Windows Environment Variables](https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-recognized-environment-variables)

### Loader Pattern
**Decision**: Use lightweight loader scripts that dot-source a central profile

**Rationale**:
- Single source of truth for profile content
- Easy updates without touching all profile locations
- Works across PowerShell 5.1, 7.x, ISE, VSCode
- Maintains correct variable scope

**Reference**: [Dot Sourcing - About Scopes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes#dot-sourcing)

### UTF-8 Encoding Without BOM
**Decision**: Use UTF-8 encoding without BOM for all PowerShell scripts

**Rationale**:
- Compatible with all PowerShell versions
- Avoids encoding-related parsing errors
- Cross-platform compatibility
- Git-friendly (clean diffs)

**Reference**: [UTF-8 Encoding in PowerShell](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding)

### OneDrive Detection Strategy
**Decision**: Auto-detect OneDrive redirection but allow override with `-Local` flag

**Rationale**:
- Respects user's OneDrive configuration by default
- Provides escape hatch for sync issues
- Transparent about what's happening
- Documents folder detection follows Windows conventions

**Reference**: [Folder Redirection - Windows IT Pro Docs](https://learn.microsoft.com/en-us/windows-server/storage/folder-redirection/folder-redirection-rup-overview)

## Tools and Technologies

### Development Tools
- **PowerShell**: 5.1 and 7.x compatibility
- **Git**: Version control
- **Visual Studio Code**: Development environment (optional)
- **PowerShell ISE**: Testing environment

### Testing Environments
- Windows 10/11 Professional
- Windows Server 2019/2022
- OneDrive-synced and local Documents folders
- Air-gapped (offline) servers

## Community Inspiration

### Similar Projects
While this project was developed independently, these projects inspired various aspects:

- **Scoop** (https://scoop.sh/) - Windows package manager installer pattern
- **Chocolatey** (https://chocolatey.org/) - Bootstrap installation concept
- **Oh My Posh** (https://ohmyposh.dev/) - PowerShell prompt customization
- **Posh-Git** (https://github.com/dahlbyk/posh-git) - Git integration patterns

### PowerShell Profile Examples
- Various GitHub dotfiles repositories
- PowerShell Gallery profile scripts
- Enterprise IT PowerShell profiles shared in forums

## Special Thanks

- **Anthropic** for creating Claude and making it accessible
- **Microsoft** for PowerShell and comprehensive documentation
- **PowerShell Community** for sharing knowledge and best practices
- **Open Source Contributors** who inspire better software practices

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


---

*Last Updated: December 2025*
