param()

# Guard: run only on Windows (compatible with both PowerShell 5.1 and Core)
if ($PSVersionTable.PSVersion.Major -ge 6) {
    if (-not $IsWindows) {
        Write-Error "This script must be run on Windows." -ErrorAction Stop
    }
} elseif ([Environment]::OSVersion.Platform -eq 'Unix') {
    Write-Error "This script must be run on Windows." -ErrorAction Stop
}

# Guard: require administrator privileges - request elevation if not running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process -FilePath powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -ErrorAction Stop
    exit
}

# Helper: locate an installed MobaXterm executable
function Get-MobaXtermExePath {
    $candidateDirs = @(
        (Join-Path $Env:ProgramFiles 'MobaXterm'),
        (Join-Path $Env:LOCALAPPDATA 'MobaXterm')
    )
    foreach ($dir in $candidateDirs) {
        try {
            $exe = Get-ChildItem -Path $dir -Filter 'MobaXterm*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($exe) { return $exe.FullName }
        } catch { }
    }
    return $null
}

function Is-MobaXtermInstalled {
    return [bool](Get-MobaXtermExePath)
}

# Define URL for MobaXterm installer (Free Home Edition, 64-bit MSI)
$installerUrl = "https://download.mobatek.net/2542025111600034/MobaXterm_Installer_v25.4.zip"

# Define install directory (system-wide, admin is now required)
$installDir = Join-Path $Env:ProgramFiles 'MobaXterm'

# Define local paths
$tempDir = Join-Path $env:TEMP 'MobaXtermInstall'
$installerZip = Join-Path $tempDir 'MobaXterm_installer.zip'
$extractDir = Join-Path $tempDir 'MobaXtermExtracted'

# Main logic
if (-not (Is-MobaXtermInstalled)) {
    Write-Host "MobaXterm not found. Installing to $installDir ..."

    # Ensure TLS 1.2+ (Tls13 not available in PowerShell 5.1)
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } catch { }

    # Create temp folder
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

    # Download the ZIP installer
    try {
        Write-Host "Downloading MobaXterm installer..." -ForegroundColor Green
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerZip -ErrorAction Stop
    } catch {
        Write-Error "Failed to download MobaXterm: $($_.Exception.Message)" -ErrorAction Stop
    }

    # Extract ZIP contents
    try {
        Write-Host "Extracting installer package..." -ForegroundColor Green
        if (-not (Test-Path $extractDir)) { New-Item -ItemType Directory -Path $extractDir -Force | Out-Null }
        Expand-Archive -Path $installerZip -DestinationPath $extractDir -Force -ErrorAction Stop
    } catch {
        Write-Error "Failed to extract MobaXterm archive: $($_.Exception.Message)" -ErrorAction Stop
    }

    # Find the MSI file in the extracted contents
    try {
        $msiFile = Get-ChildItem -Path $extractDir -Filter '*.msi' -Recurse | Select-Object -First 1
        if (-not $msiFile) {
            Write-Error "No .msi file found in the extracted archive" -ErrorAction Stop
        }
        Write-Host "Found MSI: $($msiFile.Name)" -ForegroundColor Green
    } catch {
        Write-Error "Failed to locate MSI file: $($_.Exception.Message)" -ErrorAction Stop
    }

    # Install MSI using msiexec
    try {
        Write-Host "Installing MobaXterm MSI..." -ForegroundColor Green
        $logFile = Join-Path $tempDir 'MobaXterm_install.log'
        $msiProcess = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$($msiFile.FullName)`" /l*v `"$logFile`" /norestart" -Wait -PassThru -NoNewWindow
        Write-Host "MSI process exit code: $($msiProcess.ExitCode)"
        
        if ($msiProcess.ExitCode -ne 0) {
            Write-Host "Installation log:" -ForegroundColor Yellow
            if (Test-Path $logFile) {
                Get-Content $logFile | Select-Object -Last 20
            }
            Write-Error "MSI installation failed with exit code: $($msiProcess.ExitCode)" -ErrorAction Stop
        }
    } catch {
        Write-Error "Failed to install MobaXterm: $($_.Exception.Message)" -ErrorAction Stop
    }

    # Clean up temp installer
    Remove-Item $installerZip -ErrorAction SilentlyContinue
    Remove-Item $extractDir -Recurse -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -ErrorAction SilentlyContinue

    # Report result
    $exePath = Get-MobaXtermExePath
    if ($exePath) {
        Write-Host "MobaXterm installed: $exePath"
    } else {
        Write-Warning "Installation completed, but MobaXterm executable was not found in $installDir. Contents may be in a nested folder."
    }
} else {
    Write-Host "MobaXterm is already installed at $(Get-MobaXtermExePath). Skipping installation."
}
