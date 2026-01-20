# Function to check if Docker is installed
function Is-DockerInstalled {
    try {
        $version = docker --version 2>&1
        if ($version -and -not ($version -match 'command not found|is not recognized')) {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# Function to check if winget is available
function Test-WingetAvailable {
    try {
        $null = winget --version 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# Check if running with admin privileges
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host "Checking Docker installation status..."

if (Is-DockerInstalled) {
    Write-Host "Docker is already installed. Skipping installation." -ForegroundColor Green
    docker --version
    exit 0
}

Write-Host "Docker not found. Beginning installation..." -ForegroundColor Yellow

# Check if winget is available
if (-not (Test-WingetAvailable)) {
    Write-Host "ERROR: winget is not available on this system." -ForegroundColor Red
    Write-Host "Please install App Installer from the Microsoft Store or use Windows 10/11." -ForegroundColor Red
    exit 1
}

# Warn if not running as admin (though winget can install user-scoped apps)
if (-not (Test-Administrator)) {
    Write-Host "WARNING: Not running as Administrator. Docker Desktop may require elevated privileges." -ForegroundColor Yellow
    Write-Host "If installation fails, please run this script as Administrator." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

Write-Host "Installing Docker Desktop via winget..." -ForegroundColor Cyan

# Install Docker Desktop with silent flag and better error handling
$installResult = winget install --id=Docker.DockerDesktop `
    --silent `
    --accept-package-agreements `
    --accept-source-agreements `
    2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker Desktop installation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Output: $installResult" -ForegroundColor Red
    Write-Host "`nPlease try:" -ForegroundColor Yellow
    Write-Host "  1. Running this script as Administrator" -ForegroundColor Yellow
    Write-Host "  2. Manually installing from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nDocker Desktop installation completed successfully!" -ForegroundColor Green

# Try to start Docker Desktop
Write-Host "`nAttempting to launch Docker Desktop..." -ForegroundColor Cyan
$dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

if (Test-Path $dockerDesktopPath) {
    try {
        Start-Process -FilePath $dockerDesktopPath -ErrorAction Stop
        Write-Host "Docker Desktop launched. It may take a minute to start up." -ForegroundColor Green
    } catch {
        Write-Host "Could not auto-launch Docker Desktop. Please start it manually from the Start Menu." -ForegroundColor Yellow
    }
} else {
    Write-Host "Docker Desktop executable not found at expected location." -ForegroundColor Yellow
    Write-Host "Please launch Docker Desktop manually from the Start Menu." -ForegroundColor Yellow
}

Write-Host "`n=== IMPORTANT NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. A system restart is REQUIRED for Docker to work properly" -ForegroundColor Yellow
Write-Host "2. After restart, launch Docker Desktop from the Start Menu" -ForegroundColor Yellow
Write-Host "3. Accept the service agreement and wait for Docker to start" -ForegroundColor Yellow
Write-Host "4. If using WSL 2, enable it in Docker Desktop settings:" -ForegroundColor Yellow
Write-Host "   Settings > General > 'Use the WSL 2 based engine'" -ForegroundColor Yellow
Write-Host "5. Enable WSL integration: Settings > Resources > WSL Integration" -ForegroundColor Yellow
Write-Host "`nVerify installation after restart by running: docker --version" -ForegroundColor Cyan
