#!/bin/bash

# Exit on error
set -e

echo "--- Checking Homebrew Installation ---"

# 1. Check if Homebrew is already installed
# We check the default Linuxbrew directory
if [ -d "/home/linuxbrew/.linuxbrew/bin" ] || command -v brew >/dev/null 2>&1; then
    echo "Homebrew is already installed. Skipping installation."
else
    echo "Homebrew not found. Installing..."

    # 2. Install dependencies silently
    # procps and file are required by Homebrew on Linux
    sudo apt update
    sudo apt install -y build-essential procps curl file git unzip

    # 3. Install Homebrew non-interactively
    # Setting NONINTERACTIVE=1 bypasses the "Press ENTER to continue" prompt
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 4. Configure environment for the current session
    # This allows the rest of your bootstrap script to use 'brew' immediately
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# 5. Handle Shell Configuration (Idempotent)
# We check if the line already exists to avoid cluttering your .zshrc or .bashrc
SHELL_CONFIG="$HOME/.zshrc"  # Changed to .zshrc based on your previous prompts
BREW_LINE='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'

if [ -f "$SHELL_CONFIG" ]; then
    if ! grep -Fq "$BREW_LINE" "$SHELL_CONFIG"; then
        echo "Adding Homebrew to $SHELL_CONFIG..."
        echo "" >> "$SHELL_CONFIG"
        echo "# Homebrew" >> "$SHELL_CONFIG"
        echo "$BREW_LINE" >> "$SHELL_CONFIG"
    else
        echo "Homebrew environment already configured in $SHELL_CONFIG."
    fi
fi

echo "Homebrew setup complete."