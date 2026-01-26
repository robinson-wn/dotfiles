# WSL Development Environment Dotfiles

A yadm-managed dotfiles repository with an automated bootstrap script for setting up a complete development environment on Windows Subsystem for Linux (WSL).

## Prerequisites

- Windows 10/11 with WSL2 installed
- Ubuntu 20.04+ or Debian 11+ on WSL
- Git installed in WSL

## Quick Start

### 1. Install yadm in WSL

Open your WSL terminal and run:

```bash
sudo apt update && sudo apt install yadm
```

### 2. Clone your dotfiles

Replace `robinson-wn` with your GitHub username:

```bash
yadm clone https://github.com/robinson-wn/dotfiles.git
```

yadm will prompt you to answer a few questions. For the bootstrap question, answer **yes** (or run it manually after).

### 3. Run the bootstrap script

The bootstrap will run automatically, or run manually:

```bash
bash ~/.config/yadm/bootstrap
```

The script will take 10-15 minutes depending on your internet speed and system performance.

## What Gets Installed

The bootstrap script installs and configures:

### System Layer
- **zsh** - Modern shell with oh-my-zsh compatibility
- **Build tools** - build-essential, git, curl, wget, zip, lsb-release
- **Utilities** - btop, file, ca-certificates, gnupg

### Development Tools
- **yadm** - Dotfiles manager
- **direnv** - Environment variable manager
- **fzf** - Fuzzy finder for command line
- **Starship** - Cross-platform prompt

### Programming Languages & Build Tools
- **Java** - OpenJDK 17 (system package)
- **Maven** - Build tool for Java projects
- **Node.js** - Via NVM (Node Version Manager)
- **Python** - Miniconda (via local scripts)

### Data & Big Data Tools
- **Apache Spark** - Big data processing framework
- **Google Cloud SDK** - For cloud development

### Optional Tools
- **Ollama** - Local LLM support
- **Nerd Fonts** - Enhanced terminal fonts
- **MobaXterm** - Windows terminal (WSL only)

## Windows Integration Features

The bootstrap automatically detects WSL and:
- **PowerShell Profiles** - Installs Starship prompt in PowerShell 5.1 and 7+
- **Configuration Sync** - Copies Starship configuration from WSL to Windows
- **Docker Integration** - Detects and prompts to install Docker Desktop
- **VS Code Integration** - Works seamlessly with VS Code's WSL extension

## Interactive Setup

The bootstrap runs in interactive mode and prompts for:
- **Docker Desktop**: Install the Windows Docker Desktop for WSL2?
- **Optional Tools**: Spark, Google Cloud SDK, Ollama (skip if not needed)
- **Java Version**: Choose between OpenJDK 11, 17, or 21 (default: 17)

Just answer **y** or **n** to each prompt. You can always re-run the bootstrap later to install skipped tools.

## Customization

### Modify the Bootstrap Script

Edit `~/.config/yadm/bootstrap` to:
- Add new tools or packages
- Change default versions (e.g., Java version)
- Add custom shell configuration
- Include additional setup scripts

### Add Local Setup Scripts

Place executable scripts in `~/.local/bin/` with these naming patterns:
- `*_install.sh` - Required scripts (always run)
- Other scripts - Optional (prompt for each)

The bootstrap detects the file type automatically (.sh, .ps1).

## Troubleshooting

### Bootstrap fails to run

Make the script executable:
```bash
chmod +x ~/.config/yadm/bootstrap
```

Then re-run it:
```bash
bash ~/.config/yadm/bootstrap
```

### Java not found

Verify installation:
```bash
java -version
javac -version
```

Change Java version (interactive menu):
```bash
sudo update-alternatives --config java
```

### PowerShell profile not configured (Windows)

Manually set it up in PowerShell:
```powershell
$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir = Split-Path -Parent $profilePath
New-Item -ItemType Directory -Path $profileDir -Force
New-Item -ItemType File -Path $profilePath -Force
Add-Content -Path $profilePath -Value 'Invoke-Expression (&starship init powershell)'
```

### Environment variables not loading

Reload your shell:
```bash
source ~/.zshenv
source ~/.zshrc
exec $SHELL
```

### VS Code not finding tools

In VS Code, open command palette and select **"Remote-Containers: Reopen in Container"** or restart the WSL terminal.
source ~/.zshrc
```

## Re-running Bootstrap

After pulling changes from GitHub, re-run bootstrap to update your environment:

```bash
bash ~/.config/yadm/bootstrap
```

It's safe to run multiple times—tools already installed are skipped.

## Basic yadm Workflow

Track changes to your dotfiles:

```bash
# Check what changed
yadm status

# Add modified file
yadm add ~/.zshrc

# Commit your changes
yadm commit -m "Update zsh configuration"

# Push to GitHub
yadm push
```

## Repository Structure

```
~/
├── README.md                          ← This file
├── .config/yadm/
│   └── bootstrap                      ← Main setup script
├── .local/bin/
│   ├── minconda_install.sh           ← Python environment
│   ├── python_interps.sh             ← Python versions
│   ├── nerd_fonts_install.sh         ← Terminal fonts
│   ├── spark_install.sh              ← Big data framework
│   ├── ollama_install.sh             ← Local AI models
│   ├── gcloud_install_init.sh        ← Google Cloud tools
│   ├── starship_install_windows.ps1  ← Windows prompt setup
│   └── mobaxterm_install.ps1         ← Windows terminal (optional)
├── .zshenv                            ← Environment variables
├── .zshrc                             ← Shell configuration
└── ... (other dotfiles)
```

## Getting Help

**WSL-specific issues:**
- [WSL Documentation](https://learn.microsoft.com/en-us/windows/wsl/)
- [WSL Troubleshooting](https://learn.microsoft.com/en-us/windows/wsl/troubleshooting)

**Tool Documentation:**
- [yadm](https://yadm.io)
- [zsh](https://www.zsh.org)
- [Starship](https://starship.rs)
- [NVM](https://github.com/nvm-sh/nvm)
- [Apache Spark](https://spark.apache.org)
- [Google Cloud SDK](https://cloud.google.com/sdk)

## Tips for WSL Development

- **Terminal Emulator**: Use Windows Terminal for best WSL experience
- **VS Code**: Install the "Remote - WSL" extension for seamless integration
- **File Access**: Access Windows files at `/mnt/c/` from WSL
- **Performance**: Keep files in WSL filesystem (`~`) not Windows (`/mnt/c/`) for speed
- **Docker**: Requires Docker Desktop with WSL2 backend enabled

## License

These dotfiles are personal configuration. Feel free to fork and adapt for your own use.

## References

- [yadm documentation](https://yadm.io)
- [NVM (Node Version Manager)](https://github.com/nvm-sh/nvm)
- [Starship Prompt](https://starship.rs)
- [Apache Spark](https://spark.apache.org)
- [Google Cloud SDK](https://cloud.google.com/sdk)
