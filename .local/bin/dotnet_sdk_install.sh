#!/bin/bash

set -e
set -u
set -o pipefail

log() { printf '%s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }

DOTNET_DIR="$HOME/.dotnet"
INSTALL_SCRIPT="$HOME/.local/tmp/dotnet-install.sh"

mkdir -p "$(dirname "$INSTALL_SCRIPT")"

log "Downloading dotnet-install.sh..."
if ! curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$INSTALL_SCRIPT"; then
    warn "Failed to download dotnet-install.sh"
    exit 1
fi

chmod +x "$INSTALL_SCRIPT"

log "Installing .NET SDK (LTS) to $DOTNET_DIR"
"$INSTALL_SCRIPT" --channel LTS --install-dir "$DOTNET_DIR"

add_path_if_missing() {
    local file="$1"
    local line='export PATH="$HOME/.dotnet:$PATH"'

    [ -f "$file" ] || touch "$file"
    if ! grep -Fqs "$line" "$file"; then
        printf '\n%s\n' "$line" >> "$file"
        log "Updated PATH in $file"
    fi
}

add_path_if_missing "$HOME/.profile"
add_path_if_missing "$HOME/.bashrc"
add_path_if_missing "$HOME/.zshrc"

# Set for current session
export DOTNET_ROOT="$DOTNET_DIR"
export PATH="$DOTNET_DIR:$PATH"

log "Verifying dotnet (C# SDK included)..."
if dotnet --version >/dev/null 2>&1; then
    log "dotnet installed: $(dotnet --version)"
else
    warn "dotnet installed but not runnable. Ensure PATH includes $DOTNET_DIR"
fi
