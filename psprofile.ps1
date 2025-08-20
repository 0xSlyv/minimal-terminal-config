# --- Ensure running as Administrator ---
Clear-Host
Write-Host "Welcome to the PowerShell Profile Setup Script!" -ForegroundColor Cyan
Write-Host "Autocompletions require PowerShell 7 installed!" -ForegroundColor Red
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

# --- Internet connectivity check ---
function Test-InternetConnection {
    try {
        Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Write-Warning "Internet connection is required but not available."
        return $false
    }
}
if (-not (Test-InternetConnection)) { break }

# --- Arrow key choice function ---
function Show-InlineChoice {
    param(
        [string]$Title,
        [string[]]$Options,
        [int]$DefaultIndex = 0
    )
    
    $index = $DefaultIndex
    $key = $null

    # ANSI escape codes
    $ESC = [char]27
    $UNDERLINE_ON = "$ESC[4m"
    $UNDERLINE_OFF = "$ESC[24m"
    $CYAN = "$ESC[36m"
    $RESET = "$ESC[0m"
    
    # Store initial cursor position
    $initialPos = $Host.UI.RawUI.CursorPosition
    
    # Function to draw the prompt and options
    function Draw-Prompt {
        param($currentIndex)
        
        # Move cursor to start of line
        $Host.UI.RawUI.CursorPosition = $initialPos
        
        # Clear the line by writing spaces
        $lineLength = $Title.Length + ($Options | ForEach-Object { $_.Length + 3 } | Measure-Object -Sum).Sum
        Write-Host (" " * [Math]::Min($lineLength + 10, $Host.UI.RawUI.WindowSize.Width - $initialPos.X)) -NoNewline
        
        # Reset cursor to start of line
        $Host.UI.RawUI.CursorPosition = $initialPos
        
        # Write the title
        Write-Host "$Title " -NoNewline
        
        # Write the options
        for ($i = 0; $i -lt $Options.Length; $i++) {
            if ($i -eq $currentIndex) {
                Write-Host "${CYAN}${UNDERLINE_ON}$($Options[$i])${RESET}" -NoNewline
            } else {
                Write-Host $Options[$i] -NoNewline
            }
            if ($i -lt $Options.Length - 1) { 
                Write-Host " / " -NoNewline 
            }
        }
    }
    
    # Initial draw
    Draw-Prompt $index
    
    # Main input loop
    do {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            37 { # Left Arrow
                if ($index -gt 0) { 
                    $index-- 
                    Draw-Prompt $index
                }
            }
            39 { # Right Arrow
                if ($index -lt $Options.Length - 1) { 
                    $index++ 
                    Draw-Prompt $index
                }
            }
            38 { # Up Arrow (treat as left)
                if ($index -gt 0) { 
                    $index-- 
                    Draw-Prompt $index
                }
            }
            40 { # Down Arrow (treat as right)
                if ($index -lt $Options.Length - 1) { 
                    $index++ 
                    Draw-Prompt $index
                }
            }
            13 { # Enter
                # Final draw to show selected option
                Draw-Prompt $index
                Write-Host "" # Move to next line
                return $Options[$index]
            }
            27 { # Escape (optional - exit without selection)
                Write-Host "" # Move to next line
                return $null
            }
        }
    } while ($true)
}

# === User Configuration Prompts ===
$profileName = Read-Host "Name for the profile? (default: psprofile.ps1)"
if ([string]::IsNullOrWhiteSpace($profileName)) {
    $profileName = "psprofile.ps1"
}

Write-Host " " -ForegroundColor Red
Write-Host "Would you like..." -ForegroundColor Red
$installIcons = Show-InlineChoice "Terminal-Icons module?" @("Yes", "No")
$enablePSReadLine = Show-InlineChoice "Terminal predictions? (PowerShell 7 required)" @("Yes", "No")
$disableTelemetry = Show-InlineChoice "Disable PowerShell telemetry?" @("Yes", "No")
$enableCommands = Show-InlineChoice "Enable UNIX commands?" @("Yes", "No")
$enableCustomTheme = Show-InlineChoice "Apply a custom Windows Terminal theme?" @("Yes", "No")

# === Profile Setup ===
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    $profileDir = Split-Path $PROFILE
    if (!(Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory | Out-Null
    }
    Write-Host "Profile directory created at [$profileDir]" -ForegroundColor Green
} else {
    $backupPath = Join-Path (Split-Path $PROFILE) "${profileName}_backup.ps1"
    Copy-Item -Path $PROFILE -Destination $backupPath -Force
    Write-Host "Old profile backed up to [$backupPath]" -ForegroundColor Yellow
}

# === Handle Terminal-Icons Installation ===
if ($installIcons -eq "Yes") {
    try {
        Write-Host "Installing Terminal-Icons..." -ForegroundColor Cyan
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force -Scope CurrentUser -ErrorAction Stop
        Import-Module -Name Terminal-Icons -Force
        Write-Host "Terminal-Icons installed and loaded successfully!" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Terminal-Icons: $_"
    }
}

# === Build Profile Content ===
$customProfile = @()

# Header
$customProfile += "# PowerShell Profile: $profileName"
$customProfile += "# Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$customProfile += ""

# Terminal Icons
if ($installIcons -eq "Yes") {
    $customProfile += "# === Terminal Icons ==="
    $customProfile += "try {"
    $customProfile += "    Import-Module -Name Terminal-Icons -Force -ErrorAction SilentlyContinue"
    $customProfile += "    Write-Host 'Terminal-Icons loaded' -ForegroundColor Green"
    $customProfile += "} catch {"
    $customProfile += "    Write-Warning 'Failed to load Terminal-Icons'"
    $customProfile += "}"
    $customProfile += ""
}

# === PSReadLine Configuration ===
if ($enablePSReadLine -eq "Yes") {
    # Check if PowerShell version is 7 or higher
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warning "PSReadLine configuration skipped: PowerShell version $($PSVersionTable.PSVersion) is below 7."
    }
    else {
        try {
            # Try to import available version
            Import-Module PSReadLine -ErrorAction Stop

            # Basic settings (available in all versions)
            Set-PSReadLineOption -EditMode Windows
            Set-PSReadLineOption -BellStyle None

            # Version-specific features
            $psrlVersion = (Get-Module PSReadLine).Version
            if ($psrlVersion -ge [version]"2.1.0") {
                Set-PSReadLineOption -PredictionSource HistoryAndPlugin
                Set-PSReadLineOption -PredictionViewStyle ListView
                Write-Host "PSReadLine prediction features enabled" -ForegroundColor Green
            }
            else {
                Write-Host "PSReadLine $psrlVersion - Prediction features require v2.1.0+" -ForegroundColor Yellow
            }

            # Color settings (available in v2.0.0+)
            if ($psrlVersion -ge [version]"2.0.0") {
                Set-PSReadLineOption -Colors @{
                    Command    = 'Yellow'
                    Parameter  = 'Green'
                    String     = 'Magenta'
                    Operator   = 'Cyan'
                    Variable   = 'White'
                    Number     = 'Blue'
                    Type       = 'Gray'
                    Comment    = 'DarkGreen'
                    Keyword    = 'DarkCyan'
                    Error      = 'Red'
                }
                Write-Host "PSReadLine color settings applied" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "PSReadLine not available: $($_.Exception.Message)"
        }
    }
}

# Telemetry Opt-out
if ($disableTelemetry -eq "Yes") {
    $customProfile += "# === Disable Telemetry ==="
    $customProfile += '$env:POWERSHELL_TELEMETRY_OPTOUT = "1"'
    $customProfile += "Write-Host 'PowerShell telemetry disabled' -ForegroundColor Yellow"
    $customProfile += ""
}

# Custom Commands
if ($enableCommands -eq "Yes") {
    $customProfile += "# === UNIX-like Commands ==="
    $customProfile += "function ll { Get-ChildItem -Force | Format-Table -AutoSize }"
    $customProfile += "function la { Get-ChildItem | Format-Table -AutoSize }"
    $customProfile += "function ls { Get-ChildItem }"
    $customProfile += "function grep(`$regex, `$dir) {"
    $customProfile += "    if (`$dir) {"
    $customProfile += "        Get-ChildItem `$dir -Recurse | Select-String `$regex"
    $customProfile += "    } else {"
    $customProfile += "        `$input | Select-String `$regex"
    $customProfile += "    }"
    $customProfile += "}"
    $customProfile += "function head { param([string]`$Path, [int]`$n=10) Get-Content `$Path -Head `$n }"
    $customProfile += "function tail { param([string]`$Path, [int]`$n=10, [switch]`$f=`$false) Get-Content `$Path -Tail `$n -Wait:`$f }"
    $customProfile += "function df { Get-Volume }"
    $customProfile += "function which(`$name) { Get-Command `$name | Select-Object -ExpandProperty Definition }"
    $customProfile += "function uptime {"
    $customProfile += "    if (`$PSVersionTable.PSVersion.Major -ge 6) {"
    $customProfile += "        (Get-Uptime).ToString()"
    $customProfile += "    } else {"
    $customProfile += "        (Get-CimInstance win32_operatingsystem).LastBootUpTime"
    $customProfile += "    }"
    $customProfile += "}"
    $customProfile += ""
}

# Welcome Message
# $customProfile += "Clear-Host"
# $customProfile += "# === Welcome Message ==="
# $customProfile += "Write-Host 'Custom PowerShell profile loaded successfully!' -ForegroundColor Green"
# $customProfile += "Write-Host 'Available commands: ll, la, ls, grep, head, tail, df, which, uptime' -ForegroundColor Cyan"

# === Apply Windows Terminal Theme ===
if ($enableCustomTheme -eq "Yes") {
    $wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $wtSettings)) {
        $wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    }
    $themeUrl = "https://raw.githubusercontent.com/0xSlyv/powershell-profile/main/settings.json"
}

if (Test-Path $wtSettings) {
    try {
        Write-Host "Applying Windows Terminal theme..." -ForegroundColor Cyan
        $settings = Get-Content $wtSettings -Raw | ConvertFrom-Json
        $response = Invoke-WebRequest -Uri $themeUrl -UseBasicParsing
        $newScheme = $response.Content | ConvertFrom-Json
        
        $existing = $settings.schemes | Where-Object { $_.name -eq $newScheme.name }
        if ($existing) {
            $index = $settings.schemes.IndexOf($existing)
            $settings.schemes[$index] = $newScheme
            Write-Host "Updated scheme: $($newScheme.name)" -ForegroundColor Yellow
        } else {
            $settings.schemes += $newScheme
            Write-Host "Added scheme: $($newScheme.name)" -ForegroundColor Green
        }
        
        $settings | ConvertTo-Json -Depth 100 | Set-Content $wtSettings -Encoding UTF8
        Write-Host "Windows Terminal theme applied successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to fetch or apply Windows Terminal theme: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Windows Terminal settings.json not found - skipping theme application" -ForegroundColor Yellow
}

# === Save Profile ===
$profilePath = $PROFILE.CurrentUserAllHosts
$customProfile -join "`n" | Set-Content -Path $profilePath -Encoding UTF8

Write-Host "`nProfile configuration completed!" -ForegroundColor Green
Write-Host "Profile saved to: $profilePath" -ForegroundColor Cyan
Write-Host "Restart your PowerShell session to see the changes" -ForegroundColor Magenta