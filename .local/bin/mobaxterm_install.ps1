# Define installation check function - checks if MobaXterm exists in Program Files
function Is-MobaXtermInstalled {
    $installPath = "$Env:ProgramFiles\MobaXterm\MobaXterm.exe"
    return Test-Path $installPath
}

# Define URL for MobaXterm installer (Free Home Edition, 64-bit)
$installerUrl = "https://download.mobatek.net/2308/MobaXterm_Portable_v25.2.zip"
# Define local paths
$tempDir = "$env:TEMP\MobaXtermInstall"
$installerZip = Join-Path $tempDir "MobaXterm.zip"
$installDir = "$Env:ProgramFiles\MobaXterm"

# Main logic
if (-not (Is-MobaXtermInstalled)) {
    Write-Host "MobaXterm not found. Installing..."

    # Create temp folder
    if (-Not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }

    # Download the portable zip installer
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerZip

    # Extract zip contents to Program Files\mobaXterm (you can change if you want an installed version)
    Expand-Archive -Path $installerZip -DestinationPath $installDir -Force

    # Clean up temp installer
    Remove-Item $installerZip
    Remove-Item $tempDir -Recurse

    Write-Host "MobaXterm installed in $installDir"
} else {
    Write-Host "MobaXterm is already installed. Skipping installation."
}
