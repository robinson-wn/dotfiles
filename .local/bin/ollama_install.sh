#!/bin/bash

# --- 1. Check if Ollama is already installed ---
if command -v ollama >/dev/null 2>&1; then
    echo "Ollama is already installed. Current version: $(ollama --version)"
else
    echo "Ollama not found. Starting installation..."

    # --- 2. Check for curl dependency ---
    if ! command -v curl >/dev/null 2>&1; then
        echo "curl is required but not installed. Installing curl..."
        sudo apt update && sudo apt install -y curl
    fi

    # --- 3. Run the official installation script ---
    # We use -f to fail silently if the URL is broken and -L for redirects
    if curl -fsSL https://ollama.com/install.sh | sh; then
        echo "Ollama installed successfully."
    else
        echo "Error: Ollama installation failed."
        exit 1
    fi
fi

# --- 4. Post-Install Validation ---
# Ensure the ollama service is running (common for WSL/Linux)
if command -v ollama >/dev/null 2>&1; then
    echo "Verifying installation..."
    ollama --version
else
    echo "Warning: Installation script finished but 'ollama' command not found in PATH."
fi