# PowerShell Profile Setup Script

> Inspired by [ChrisTitusTech/powershell-profile](https://github.com/ChrisTitusTech/powershell-profile)  
> Theme used [0xSlyv/powershell-profile](https://github.com/0xSlyv/powershell-profile)

## Prerequisites

- Windows 10 or 11
- PowerShell 7+ (for full PSReadLine predictions)
- Internet connection for module installations and theme download

---

---
## How to Use

1. Run the following command **as Administrator** with Powershell 7:
```powershell
    irm "https://raw.githubusercontent.com/0xSlyv/minimal-terminal-config/refs/heads/main/psprofile.ps1" | iex
```
2. Follow the interactive prompts to:
   - Name your profile file
   - Choose which modules and features to enable
4. The script will create or backup your profile, install optional modules, configure PSReadLine, and optionally apply your Windows Terminal theme.
5. Restart your PowerShell session to see the changes.

---

## Overview

This PowerShell script sets up a fully customized PowerShell environment for Windows.  
It handles profile creation, optional module installations, terminal enhancements, and Windows Terminal theme application.

Features include:

- Custom profile creation with backup of existing profiles
- Terminal-Icons module installation
- PSReadLine configuration with predictions (PowerShell 7 required)
- UNIX-like commands (`ll`, `la`, `ls`, `grep`, `head`, `tail`, `df`, `which`, `uptime`)
- Telemetry opt-out
- Optional Windows Terminal theme application
- Interactive arrow-key selection for choices during setup

---



## Current Work-in-Progress Features

The following features are planned or partially implemented:

- CaskadyaCove Nerd Font Mono
- Auto GitHub login
- Automatic `mise` installation
- Auto/select `mise` modules to install
- Transparent/acrylic Explorer auto install
- Cleanup commands like `ctt` or Talon selection
- AutoHotkey keybinds
- Docker CLI / LazyDocker auto install
- File manager integration (e.g., Yazi, if possible)
- FFmpeg installation with shortened TUI commands
- Preview of changes before applying

---


