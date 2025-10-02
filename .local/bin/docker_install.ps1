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

if (-not (Is-DockerInstalled)) {
    Write-Host "Docker not found. Installing Docker Desktop..."

    # Install Docker Desktop using winget silently
    winget install --id=Docker.DockerDesktop --accept-package-agreements --accept-source-agreements

    Write-Host "Docker Desktop installation complete. You might need to restart your computer."
} else {
    Write-Host "Docker is already installed. Skipping installation."
}
