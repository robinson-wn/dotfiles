$ErrorActionPreference = 'Stop'
param()

# Guard: run only on Windows
if (-not $IsWindows) {
    Write-Error "This script must be run on Windows." -ErrorAction Stop
}

# Ensure TLS 1.2+/1.3 for downloads
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch { }

$vsCodePath = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'

if (-Not (Test-Path $vsCodePath)) {
    Write-Host "VS Code not found. Installing..."

    $vsCodeInstallerUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
    $tempDir = Join-Path $env:TEMP 'VSCodeInstall'
    $installerPath = Join-Path $tempDir 'VSCodeSetup.exe'

    # Create temp folder
    if (-Not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

    # Download installer
    try {
        Invoke-WebRequest -Uri $vsCodeInstallerUrl -OutFile $installerPath -ErrorAction Stop
    } catch {
        Write-Error "Failed to download VS Code: $($_.Exception.Message)" -ErrorAction Stop
    }

    # Run user installer silently (no elevation required)
    try {
        Start-Process -FilePath $installerPath -ArgumentList '/silent','/mergetasks=!runcode','/norestart' -Wait -ErrorAction Stop
    } catch {
        Write-Error "VS Code installer failed: $($_.Exception.Message)" -ErrorAction Stop
    }

    # Clean up installer
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

    # Verify installation
    if (Test-Path $vsCodePath) {
        Write-Host "VS Code installed successfully: $vsCodePath"
    } else {
        Write-Warning "Installer completed, but VS Code executable not found at expected path. Try launching VS Code from Start Menu or check installation logs."
    }
} else {
    Write-Host "VS Code is already installed at $vsCodePath."
}
$vsCodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"

if (-Not (Test-Path $vsCodePath)) {
    Write-Host "VS Code not found. Installing..."

    $vsCodeInstallerUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
    $installerPath = "$env:TEMP\VSCodeSetup.exe"

    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `"Invoke-WebRequest -Uri '$vsCodeInstallerUrl' -OutFile '$installerPath'; Start-Process -FilePath '$installerPath' -ArgumentList '/silent', '/mergetasks=!runcode' -Wait; Remove-Item '$installerPath' -Force`""
} else {
    Write-Host "VS Code is already installed."
}