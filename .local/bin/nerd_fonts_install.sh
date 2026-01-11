#!/bin/bash

# Define the fonts we want
FONTS=("Ubuntu" "UbuntuMono" "UbuntuSans" "Hack" "HeavyData")

# Create a temporary directory on the Windows side for the fonts
WIN_USER=$(cmd.exe /c "echo %USERNAME%" | tr -d '\r')
WIN_FONT_DIR="/mnt/c/Users/$WIN_USER/AppData/Local/Microsoft/Windows/Fonts"
mkdir -p "$WIN_FONT_DIR"

for font in "${FONTS[@]}"; do
    echo "Installing $font Nerd Font to Windows..."
    
    # 1. Download to a temp location
    curl -fLo "/tmp/${font}.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.tar.xz"
    
    # 2. Extract directly into the Windows User Font folder
    tar -xf "/tmp/${font}.tar.xz" -C "$WIN_FONT_DIR"
    
    # 3. Use PowerShell to register the font in the Windows Registry (so it shows up in settings)
    # This specifically looks for .ttf and .otf files in that folder and registers them
    powershell.exe -ExecutionPolicy Bypass -Command "
        \$fontFolder = 'C:\\Users\\$WIN_USER\\AppData\\Local\\Microsoft\\Windows\\Fonts';
        Get-ChildItem -Path \$fontFolder -Include '*.ttf', '*.otf' | ForEach-Object {
            \$registryPath = 'HKCU:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts';
            \$name = \$_.Name + ' (TrueType)';
            if (-not (Test-Path -Path \"\$registryPath\\\$name\")) {
                New-ItemProperty -Path \$registryPath -Name \$name -Value \$_.Name -PropertyType String -Force
            }
        }"
    
    rm "/tmp/${font}.tar.xz"
done

echo "Fonts installed. Please restart Windows Terminal."
