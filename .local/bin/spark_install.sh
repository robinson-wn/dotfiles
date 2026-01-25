#!/bin/bash

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

echo "Starting Apache Spark installation..."

# --- Configuration Variables ---
SPARK_VERSION="${SPARK_VERSION:-spark-4.1.1}"
HADOOP_VERSION="hadoop3"
SPARK_TGZ="${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz"
SPARK_DOWNLOAD_URL="https://downloads.apache.org/spark/${SPARK_VERSION}/${SPARK_TGZ}"
INSTALL_DIR="/opt"

# --- Step 1: Ensure Java is available ---
echo -e "\n--- Step 1: Ensuring Java is installed ---"

if command -v java >/dev/null 2>&1; then
    version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "Found Java version: $version"
    
    # Use existing JAVA_HOME if set and valid
    if [ -n "${JAVA_HOME:-}" ] && [ -d "$JAVA_HOME" ]; then
        JAVA_HOME_PATH="$JAVA_HOME"
        echo "Using JAVA_HOME from environment: $JAVA_HOME_PATH"
    else
        # Detect JAVA_HOME from current system default
        JAVA_HOME_PATH=$(update-alternatives --query java 2>/dev/null | grep -oP 'Current: \K.*(?=/bin/java)' || true)
        if [ -z "$JAVA_HOME_PATH" ]; then
            # Fallback for common OpenJDK paths
            for path in /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/default-java; do
                if [ -d "$path" ]; then
                    JAVA_HOME_PATH="$path"
                    break
                fi
            done
        fi
        echo "Detected JAVA_HOME: $JAVA_HOME_PATH"
    fi
else
    echo "Error: Java not found. Please install Java before running this script."
    exit 1
fi

# --- Step 2: Download Apache Spark ---
echo -e "\n--- Step 2: Downloading Apache Spark ---"

EXTRACTED_DIR_NAME="${SPARK_VERSION}-bin-${HADOOP_VERSION}"
EXTRACTED_PATH="${INSTALL_DIR}/${EXTRACTED_DIR_NAME}"
SYMLINK_PATH="${INSTALL_DIR}/spark"

# Check if Spark is already installed
if [ -d "$EXTRACTED_PATH" ] || [ -L "$SYMLINK_PATH" ]; then
    echo "Spark already installed at ${EXTRACTED_PATH}"
    echo "Skipping download and extraction."
    SPARK_HOME_PATH="${SYMLINK_PATH}"
else
    echo "Downloading Spark from: $SPARK_DOWNLOAD_URL"
    
    # Create temporary directory for download
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || {
        echo "Error: Could not change to temporary directory."
        exit 1
    }
    
    # Download with curl
    curl -fsSL "$SPARK_DOWNLOAD_URL" -o "$SPARK_TGZ" || {
        echo "Error: Failed to download Spark. Please check the URL or your internet connection."
        rm -rf "$TMP_DIR"
        exit 1
    }
    echo "Spark downloaded successfully."
    
    # --- Step 3: Extract and Place Spark ---
    echo -e "\n--- Step 3: Extracting and placing Spark files ---"
    echo "Extracting ${SPARK_TGZ} to ${INSTALL_DIR}..."
    
    sudo mkdir -p "$INSTALL_DIR"
    sudo tar -xzf "$SPARK_TGZ" -C "$INSTALL_DIR" || {
        echo "Error: Failed to extract Spark."
        rm -rf "$TMP_DIR"
        exit 1
    }
    
    # Create symlink
    if [ -e "$SYMLINK_PATH" ]; then
        BACKUP_PATH="${SYMLINK_PATH}-backup-$(date +%Y%m%d%H%M%S)"
        echo "Backing up existing ${SYMLINK_PATH} to ${BACKUP_PATH}"
        sudo mv "$SYMLINK_PATH" "$BACKUP_PATH"
    fi
    
    echo "Creating symlink ${SYMLINK_PATH} -> ${EXTRACTED_PATH}"
    sudo ln -s "$EXTRACTED_PATH" "$SYMLINK_PATH"
    SPARK_HOME_PATH="$SYMLINK_PATH"
    
    echo "Spark installed at: ${EXTRACTED_PATH} (symlink: ${SPARK_HOME_PATH})"
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    echo "Temporary download files cleaned up."
fi

# --- Step 4: Set Environment Variables ---
echo -e "\n--- Step 4: Setting environment variables ---"
echo "Adding SPARK_HOME, SPARK_VERSION, and PATH to ~/.zshenv"

ZSHENV_FILE="$HOME/.zshenv"
[ ! -f "$ZSHENV_FILE" ] && touch "$ZSHENV_FILE"

# Helper function to update or add environment variables
update_or_add_var() {
    local var_name="$1"
    local var_value="$2"
    
    # Remove old definition if exists
    sed -i "/^export ${var_name}=/d" "$ZSHENV_FILE"
    # Add new definition
    echo "export ${var_name}=${var_value}" >> "$ZSHENV_FILE"
}

# Update environment variables (JAVA_HOME only if not already correctly set)
if ! grep -q "^export JAVA_HOME=${JAVA_HOME_PATH}$" "$ZSHENV_FILE"; then
    update_or_add_var "JAVA_HOME" "$JAVA_HOME_PATH"
fi

update_or_add_var "SPARK_VERSION" "${SPARK_VERSION#spark-}"
update_or_add_var "SPARK_HOME" "$SPARK_HOME_PATH"

# Add PATH if not already present
grep -q "SPARK_HOME/bin" "$ZSHENV_FILE" || echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> "$ZSHENV_FILE"

echo "Environment variables added to ${ZSHENV_FILE}."

# Make scripts executable
sudo chmod +x "${SPARK_HOME_PATH}"/bin/* "${SPARK_HOME_PATH}"/sbin/* 2>/dev/null || true

# --- Installation Complete ---
echo -e "\n--- Installation Complete! ---"
echo "Spark installed at: ${SPARK_HOME_PATH}"
echo "To apply environment variables, run: source ${ZSHENV_FILE}"
echo ""
echo "Verify installation:"
echo "  spark-shell   # Launch Spark Scala shell"
echo "  pyspark       # Launch PySpark (Python) shell"
