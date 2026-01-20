#!/bin/bash

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

# --- 1. Idempotency Check ---
if command -v gcloud >/dev/null 2>&1; then
    echo "Google Cloud CLI is already installed. Skipping installation."
else
    echo "Google Cloud CLI not found. Starting installation..."

    # Ensure prerequisites exist
    sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates gnupg curl

    # --- 2. Add GPG Key safely ---
    # Only download if the keyring doesn't exist
    if [ ! -f /usr/share/keyrings/cloud.google.gpg ]; then
        echo "Importing Google Cloud public key..."
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
            sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    fi

    # --- 3. Add Repository safely ---
    # Only add if the list file doesn't exist
    if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
        echo "Adding Google Cloud CLI repository..."
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
            sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
    fi

    # --- 4. Install ---
    echo "Installing Google Cloud CLI package..."
    sudo apt-get update || { echo "ERROR: Failed to update apt package list"; exit 1; }
    sudo apt-get install -y google-cloud-cli || { echo "ERROR: Failed to install google-cloud-cli package"; exit 1; }
    
    # Verify installation succeeded
    if ! command -v gcloud >/dev/null 2>&1; then
        echo "ERROR: gcloud command not found after installation. You may need to refresh your PATH."
        echo "Try running: source ~/.bashrc or source ~/.zshrc"
        echo "Or manually add to PATH: export PATH=\$PATH:/usr/bin"
        exit 1
    fi
    
    echo "Google Cloud CLI installed successfully: $(gcloud --version | head -n1)"
fi

# --- 5. Conditional Initialization ---
# Checking for a configuration directory prevents gcloud init from running 
# every single time you run the bootstrap script.
if [ ! -d "$HOME/.config/gcloud" ]; then
    echo "GCloud is installed but not configured."
    
    # Check if we're in an interactive terminal
    if [ -t 0 ] && [ -t 1 ]; then
        read -p "Run 'gcloud init' now? (y/N): " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            gcloud init
        else
            echo "Skipping initialization. You can run 'gcloud init' later."
        fi
    else
        echo "Non-interactive environment detected. Skipping initialization."
        echo "Run 'gcloud init' manually when ready to configure."
    fi
else
    echo "GCloud configuration found at ~/.config/gcloud."
    echo "Current configuration: $(gcloud config get-value account 2>/dev/null || echo 'No account set')"
fi

echo "Google Cloud CLI setup process complete."