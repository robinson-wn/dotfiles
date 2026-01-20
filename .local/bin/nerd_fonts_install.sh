#!/bin/bash

set -euo pipefail

# Define the fonts we want (Mono variants only)
FONTS=("UbuntuMono" "Hack" "HeavyData")

# Use a specific release if FONT_VERSION is provided; otherwise use the latest.
FONT_VERSION=${FONT_VERSION:-latest}

# Prepare temp workspace and cleanup on exit
TMP_ROOT=$(mktemp -d)
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

# Fetch checksum file for integrity verification
release_root="https://github.com/ryanoasis/nerd-fonts/releases"
release_url=$([[ "$FONT_VERSION" == "latest" ]] && echo "$release_root/latest/download" || echo "$release_root/download/$FONT_VERSION")

# Nerd Fonts renamed the checksum asset to SHA-256.txt; fall back to older names
CHECKSUM_CANDIDATES=("SHA-256.txt" "SHA256SUMS" "SHA256SUMS.md")
CHECKSUM_FILE="$TMP_ROOT/nerd-fonts-checksums.txt"
downloaded_checksum=""

for asset in "${CHECKSUM_CANDIDATES[@]}"; do
    if curl -fLsSo "$CHECKSUM_FILE" "$release_url/$asset"; then
        downloaded_checksum="$asset"
        break
    fi
done

if [[ -z "$downloaded_checksum" ]]; then
    echo "Could not download checksum file for release '$FONT_VERSION' (tried: ${CHECKSUM_CANDIDATES[*]}). Aborting."
    exit 1
fi

# Create a temporary directory on the Windows side for the fonts
WIN_USER=$(cmd.exe /c "echo %USERNAME%" | tr -d '\r')
WIN_FONT_DIR="/mnt/c/Users/$WIN_USER/AppData/Local/Microsoft/Windows/Fonts"
mkdir -p "$WIN_FONT_DIR"

for font in "${FONTS[@]}"; do
    echo "Processing $font..."
    tmp="$TMP_ROOT/${font}.tar.xz"
    tmp_extract="$TMP_ROOT/${font}_extract"

    # 1. Download to a temp location
    if ! curl -fLo "$tmp" "$release_url/${font}.tar.xz"; then
        echo "Failed to download ${font}, skipping."
        rm -f "$tmp"
        continue
    fi

    # 1b. Verify checksum
    expected=$(grep -E " ${font}\.tar\.xz$" "$CHECKSUM_FILE" | awk '{print $1}' | head -n1 || true)
    if [[ -z "$expected" ]]; then
        echo "No checksum entry for ${font}.tar.xz in $CHECKSUM_FILE; skipping."
        rm -f "$tmp"
        continue
    fi
    actual=$(sha256sum "$tmp" | awk '{print $1}')
    if [[ "$expected" != "$actual" ]]; then
        echo "Checksum mismatch for ${font}.tar.xz; expected $expected got $actual. Skipping."
        rm -f "$tmp"
        continue
    fi

    # 2. Extract to a temporary directory first
    mkdir -p "$tmp_extract"
    tar -xf "$tmp" -C "$tmp_extract"

    # 3. Copy Mono fonts to Windows folder (no registry edits or COM calls)
    if ! powershell.exe -NoLogo -NoProfile -Command "
        Set-Location C:\\; 
        \$tmpExtract = '$(wslpath -w "$tmp_extract")';
        \$fontFolder = 'C:\\Users\\$WIN_USER\\AppData\\Local\\Microsoft\\Windows\\Fonts';
        Get-ChildItem -Path (Join-Path \$tmpExtract '*') -Include '*Mono*.ttf','*Mono*.otf' -Recurse |
            Copy-Item -Destination \$fontFolder -Force
    "; then
        echo "Failed to copy fonts for $font; skipping."
        rm -rf "$tmp" "$tmp_extract"
        continue
    fi

    rm -rf "$tmp" "$tmp_extract"
done

echo "Mono fonts copied. Log off/on Windows to refresh the font list."
