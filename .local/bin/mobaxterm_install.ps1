param()

# Guard: run only on Windows
if (-not $IsWindows) {
    Write-Error "This script must be run on Windows." -ErrorAction Stop
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

# Define URL for MobaXterm installer (Free Home Edition, 64-bit)
$installerUrl = "https://download.mobatek.net/2308/MobaXterm_Portable_v25.2.zip"

# Choose install directory based on admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
$installDir = if ($isAdmin) { Join-Path $Env:ProgramFiles 'MobaXterm' } else { Join-Path $Env:LOCALAPPDATA 'MobaXterm' }

# Define local paths
$tempDir = Join-Path $env:TEMP 'MobaXtermInstall'
$installerZip = Join-Path $tempDir 'MobaXterm.zip'

# Main logic
if (-not (Is-MobaXtermInstalled)) {
    Write-Host "MobaXterm not found. Installing to $installDir ..."

    # Ensure TLS 1.2+
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    } catch { }

    # Create temp and install folders
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
    if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }

    # Download the portable zip installer
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerZip -ErrorAction Stop
    } catch {
        Write-Error "Failed to download MobaXterm: $($_.Exception.Message)" -ErrorAction Stop
    }

    # Extract zip contents
    try {
        Expand-Archive -Path $installerZip -DestinationPath $installDir -Force -ErrorAction Stop
    } catch {
        Write-Error "Failed to extract MobaXterm archive: $($_.Exception.Message)" -ErrorAction Stop
    }

    # Clean up temp installer
    Remove-Item $installerZip -ErrorAction SilentlyContinue
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
