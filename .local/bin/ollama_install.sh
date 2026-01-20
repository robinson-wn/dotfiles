#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

have_cmd() { command -v "$1" >/dev/null 2>&1; }
is_root() { [ "${EUID:-$(id -u)}" -eq 0 ]; }
SUDO=""
if ! is_root && have_cmd sudo; then SUDO="sudo"; fi

# Ensure /usr/local/bin is in PATH for current session
if [ -d /usr/local/bin ] && ! echo ":$PATH:" | grep -q ":/usr/local/bin:"; then
    export PATH="/usr/local/bin:$PATH"
fi

install_curl() {
    echo "curl is required but not installed. Installing curl..."
    if have_cmd apt || have_cmd apt-get; then
        $SUDO apt update -y && $SUDO apt install -y curl
    elif have_cmd dnf; then
        $SUDO dnf install -y curl
    elif have_cmd yum; then
        $SUDO yum install -y curl
    elif have_cmd pacman; then
        $SUDO pacman -Sy --noconfirm curl
    elif have_cmd zypper; then
        $SUDO zypper refresh && $SUDO zypper install -y curl
    else
        echo "Error: Unsupported package manager. Please install 'curl' manually and re-run." >&2
        exit 1
    fi
}

run_install() {
    echo "Ollama not found. Starting installation..."
    if ! have_cmd curl; then install_curl; fi
    # Use -f to fail if URL is broken and -L for redirects
    if curl -fsSL https://ollama.com/install.sh | sh; then
        echo "Ollama installed successfully."
    else
        echo "Error: Ollama installation failed." >&2
        exit 1
    fi
}

is_systemd() { [ -d /run/systemd/system ] && have_cmd systemctl; }

start_service() {
    if is_systemd; then
        echo "Starting Ollama via systemd..."
        if $SUDO systemctl enable --now ollama; then
            echo "Ollama service enabled and started."
        else
            echo "Warning: systemd failed to start Ollama. Attempting fallback." >&2
            fallback_start
        fi
    else
        fallback_start
    fi
}

fallback_start() {
    echo "Starting Ollama in the background (no systemd)..."
    mkdir -p "$HOME/.ollama"
    nohup ollama serve >"$HOME/.ollama/serve.log" 2>&1 &
    sleep 2 || true
}

verify_install() {
    echo "Verifying installation..."
    if ! have_cmd ollama; then
        echo "Warning: Installation finished but 'ollama' not found in PATH." >&2
        echo "Try opening a new shell, or ensure /usr/local/bin is in PATH." >&2
        exit 1
    fi
    ollama --version || {
        echo "Error: 'ollama' command exists but failed to run." >&2
        exit 1
    }
}

# --- Main ---
if have_cmd ollama; then
    echo "Ollama is already installed. Current version: $(ollama --version)"
else
    run_install
fi

start_service
verify_install
echo "Done."