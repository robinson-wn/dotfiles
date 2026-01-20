#!/bin/bash

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

# --- 1. Variables ---
CONDA_DIR="$HOME/miniconda3"
INSTALLER_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
INSTALLER_PATH="/tmp/miniconda_installer.sh"

# --- 2. Check for Prerequisites ---
if ! command -v wget >/dev/null 2>&1; then
    echo "wget not found. Installing..."
    sudo apt update || { echo "ERROR: Failed to update apt"; exit 1; }
    sudo apt install -y wget || { echo "ERROR: Failed to install wget"; exit 1; }
fi

# --- 3. Idempotent Installation Logic ---
if [ ! -d "$CONDA_DIR" ]; then
    echo "Miniconda not found. Starting installation..."

    # Download the installer
    echo "Downloading installer..."
    wget "$INSTALLER_URL" -O "$INSTALLER_PATH"

    # Run in batch mode
    # -b: Batch mode (no prompts, accepts license)
    # -p: Installation prefix path
    echo "Running installer (batch mode)..."
    bash "$INSTALLER_PATH" -b -p "$CONDA_DIR"

    # Cleanup
    rm "$INSTALLER_PATH"

    # --- 4. Initialization ---
    echo "Initializing Conda for Zsh..."
    
    # This allows us to use the 'conda' command immediately within this script
    source "$CONDA_DIR/etc/profile.d/conda.sh"
    
    # This adds the initialization block to your .zshrc for future sessions
    "$CONDA_DIR/bin/conda" init zsh

    echo "Miniconda installation complete."
else
    echo "Miniconda is already installed at $CONDA_DIR. Skipping installation."
fi

# --- 5. Final validation ---
if [ -f "$CONDA_DIR/bin/conda" ]; then
    VERSION=$("$CONDA_DIR/bin/conda" --version)
    echo "Success: $VERSION is ready."
fi
