#!/bin/bash

# This script automates the installation and initialization of the Google Cloud CLI
# on a Debian-based Linux distribution (like Ubuntu, which is common in WSL).

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Step 1: Add the Google Cloud CLI Distribution URI to the package list. ---
echo "Adding Google Cloud CLI repository to sources.list..."
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null

# --- Step 2: Import the Google Cloud public key. ---
echo "Importing Google Cloud public key..."
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

# --- Step 3: Update the package list and install the gcloud CLI. ---
echo "Updating package list and installing google-cloud-cli..."
sudo apt-get update && sudo apt-get install google-cloud-cli -y

# --- Step 4: Initialize the gcloud CLI. ---
echo "Installation complete. Initializing the gcloud CLI..."
echo "This will open a browser window for authentication."
gcloud init

echo "Script finished. You are now ready to use gcloud."
