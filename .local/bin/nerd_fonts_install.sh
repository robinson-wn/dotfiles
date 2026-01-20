#!/bin/bash

# Define the fonts we want
FONTS=("Ubuntu" "UbuntuMono" "UbuntuSans" "Hack" "HeavyData")

# Create a temporary directory on the Windows side for the fonts
WIN_USER=$(cmd.exe /c "echo %USERNAME%" | tr -d '\r')
WIN_FONT_DIR="/mnt/c/Users/$WIN_USER/AppData/Local/Microsoft/Windows/Fonts"
mkdir -p "$WIN_FONT_DIR"

for font in "${FONTS[@]}"; do
    echo "Processing $font..."
    echo "Installing $font Nerd Font to Windows..."
    tmp="/tmp/${font}.tar.xz"
    tmp_extract="/tmp/${font}_extract"

    # 1. Download to a temp location
    if ! curl -fLo "$tmp" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.tar.xz"; then
        echo "Failed to download ${font}, skipping."
        rm -f "$tmp"
        continue
    fi

    # 2. Extract to a temporary directory first
    mkdir -p "$tmp_extract"
    tar -xf "$tmp" -C "$tmp_extract"

    # 3. Copy fonts to Windows folder and register each one with its proper font name
    powershell.exe -ExecutionPolicy Bypass -Command "
        \$shell = New-Object -ComObject Shell.Application;
        \$fontFolder = 'C:\\Users\\$WIN_USER\\AppData\\Local\\Microsoft\\Windows\\Fonts';
        \$tmpExtract = '$(wslpath -w "$tmp_extract")';
        \$registryPath = 'HKCU:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts';

        Get-ChildItem -Path (Join-Path \$tmpExtract '*') -Include '*Mono*.ttf','*Mono*.otf' -Recurse | ForEach-Object {
            \$fontFile = \$_.FullName;
            \$fileName = \$_.Name;
            \$destPath = Join-Path \$fontFolder \$fileName;

            Copy-Item -Path \$fontFile -Destination \$destPath -Force;

            \$folder = \$shell.Namespace(\$fontFolder);
            \$fontItem = \$folder.ParseName(\$fileName);

            if (\$fontItem) {
                \$fontName = \$folder.GetDetailsOf(\$fontItem, 21);
                if (-not \$fontName) { \$fontName = \$fileName -replace '\\.[^.]+\$', '' }

                \$fontType = if (\$fileName -match '\\.otf\$') { 'OpenType' } else { 'TrueType' };
                \$registryName = \"\$fontName (\$fontType)\";

                if (-not (Get-ItemProperty -Path \$registryPath -Name \$registryName -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path \$registryPath -Name \$registryName -Value \$fileName -PropertyType String -Force | Out-Null;
                    Write-Host \"Registered: \$registryName\";
                }
            }
        }
        
        # Refresh font cache
        Add-Type -TypeDefinition @'
            using System;
            using System.Runtime.InteropServices;
            public class FontHelper {
                [DllImport(\"gdi32.dll\")]
                public static extern int AddFontResource(string lpFileName);
                [DllImport(\"user32.dll\", CharSet = CharSet.Auto)]
                public static extern int SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
            }
'@;
        [FontHelper]::SendMessage([IntPtr]0xFFFF, 0x001D, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null;
    "

    rm -rf "$tmp" "$tmp_extract"
done

echo "Fonts installed. Please restart Windows Terminal."
