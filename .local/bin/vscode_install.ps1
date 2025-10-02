$vsCodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"

if (-Not (Test-Path $vsCodePath)) {
    Write-Host "VS Code not found. Installing..."

    $vsCodeInstallerUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
    $installerPath = "$env:TEMP\VSCodeSetup.exe"

    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `"Invoke-WebRequest -Uri '$vsCodeInstallerUrl' -OutFile '$installerPath'; Start-Process -FilePath '$installerPath' -ArgumentList '/silent', '/mergetasks=!runcode' -Wait; Remove-Item '$installerPath' -Force`""
} else {
    Write-Host "VS Code is already installed."
}