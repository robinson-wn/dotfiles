#!/bin/bash

# This script automates the installation of Apache Spark on Windows Subsystem for Linux (WSL).
# It handles Java installation, Spark download and extraction, and environment variable setup.

echo "Starting Apache Spark installation on WSL..."

# --- Configuration Variables ---
# IMPORTANT: Before running, please check the official Apache Spark downloads page
# (https://spark.apache.org/downloads.html) for the latest stable version and
# choose the pre-built package for your desired Hadoop version.
# Update the variables below accordingly.

SPARK_VERSION="spark-4.1.1" # Example: spark-3.5.6, spark-4.1.1
HADOOP_VERSION="hadoop3"    # Example: hadoop3 or hadoop3.3

SPARK_TGZ="${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz"
SPARK_DOWNLOAD_URL="https://downloads.apache.org/spark/${SPARK_VERSION}/${SPARK_TGZ}"
INSTALL_DIR="/opt" # Recommended installation directory

JAVA_VERSION="openjdk-17-jdk" # Recommended Java version for Spark 3.x+

# --- Step 1: Install Java (JDK) ---
echo -e "\n--- Step 1: Installing Java Development Kit ($JAVA_VERSION) ---"
echo "Spark requires Java to run. Checking for Java installation and installing if necessary..."

# Check if Java is already installed
if type -p java > /dev/null; then
    _java=java
elif [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ];  then
    _java="$JAVA_HOME/bin/java"
fi

if [ "$_java" ]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "Found Java version: $version"
    read -p "Java is already installed. Do you want to skip Java installation? (y/n): " skip_java
    if [[ "$skip_java" =~ ^[Yy]$ ]]; then
        echo "Skipping Java installation."
    else
        echo "Proceeding with Java installation/update."
        sudo apt update -y
        sudo apt install -y "$JAVA_VERSION"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install Java. Please check your internet connection or try again."
            exit 1
        fi
        echo "Java installation complete or updated."
    fi
else
    echo "Java not found. Installing $JAVA_VERSION..."
    sudo apt update -y
    sudo apt install -y "$JAVA_VERSION"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Java. Please check your internet connection or try again."
        exit 1
    fi
    echo "Java installation complete."
fi

# Determine JAVA_HOME path
JAVA_HOME_PATH=$(update-alternatives --query java | grep -oP 'Current: \K.*(?=/bin/java)')
if [ -z "$JAVA_HOME_PATH" ]; then
    # Fallback for common OpenJDK paths - check 17 first, then 21, then default
    if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
        JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64"
    elif [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
        JAVA_HOME_PATH="/usr/lib/jvm/java-21-openjdk-amd64"
    elif [ -d "/usr/lib/jvm/default-java" ]; then
        JAVA_HOME_PATH="/usr/lib/jvm/default-java"
    else
        echo "Warning: Could not automatically determine JAVA_HOME path. Please set it manually if issues arise."
        JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64" # Defaulting for script
    fi
fi
echo "Detected JAVA_HOME: $JAVA_HOME_PATH"


# --- Step 2: Download Apache Spark ---
echo -e "\n--- Step 2: Downloading Apache Spark ---"
echo "Downloading Spark from: $SPARK_DOWNLOAD_URL"

# Create a temporary directory for download
mkdir -p /tmp/spark_install
cd /tmp/spark_install || { echo "Error: Could not change to temporary directory."; exit 1; }

wget "$SPARK_DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download Spark. Please check the URL or your internet connection."
    exit 1
fi
echo "Spark downloaded successfully."

# --- Step 3: Extract and Place Spark ---
echo -e "\n--- Step 3: Extracting and Placing Spark Files ---"
echo "Extracting ${SPARK_TGZ} to ${INSTALL_DIR}..."

# Create installation directory if it doesn't exist
sudo mkdir -p "$INSTALL_DIR"

# Extract and move
sudo tar -xvzf "$SPARK_TGZ" -C "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to extract Spark. Please check the downloaded file."
    exit 1
fi

# Keep the extracted directory with its original name and create/update a
# symbolic link at /opt/spark that points to it. This preserves the original
# versioned directory (e.g., /opt/spark-4.0.1-bin-hadoop3) while providing a
# stable path at /opt/spark.
EXTRACTED_DIR_NAME=$(basename "$SPARK_TGZ" .tgz)
EXTRACTED_PATH="${INSTALL_DIR}/${EXTRACTED_DIR_NAME}"

if [ -d "$EXTRACTED_PATH" ]; then
    echo "Found extracted Spark directory: ${EXTRACTED_PATH}"
    # Prepare symlink target
    SYMLINK_PATH="${INSTALL_DIR}/spark"

    # If the symlink already exists and points to the same location, do nothing
    if [ -L "$SYMLINK_PATH" ]; then
        CURRENT_TARGET=$(readlink -f "$SYMLINK_PATH")
        if [ "$CURRENT_TARGET" = "$EXTRACTED_PATH" ]; then
            echo "Symlink ${SYMLINK_PATH} already points to ${EXTRACTED_PATH}."
            SPARK_HOME_PATH="$SYMLINK_PATH"
        else
            echo "Updating existing symlink ${SYMLINK_PATH} to point to ${EXTRACTED_PATH}"
            sudo ln -sfn "$EXTRACTED_PATH" "$SYMLINK_PATH"
            SPARK_HOME_PATH="$SYMLINK_PATH"
        fi
    else
        # If there is a non-symlink file/dir at /opt/spark, back it up
        if [ -e "$SYMLINK_PATH" ]; then
            BACKUP_PATH="${SYMLINK_PATH}-backup-$(date +%Y%m%d%H%M%S)"
            echo "Backing up existing ${SYMLINK_PATH} to ${BACKUP_PATH}"
            sudo mv "$SYMLINK_PATH" "$BACKUP_PATH"
        fi
        echo "Creating symlink ${SYMLINK_PATH} -> ${EXTRACTED_PATH}"
        sudo ln -s "$EXTRACTED_PATH" "$SYMLINK_PATH"
        SPARK_HOME_PATH="$SYMLINK_PATH"
    fi
    echo "Spark available at: ${EXTRACTED_PATH} (symlink: ${SPARK_HOME_PATH})"
else
    echo "Error: Extracted Spark directory not found at ${EXTRACTED_PATH}. Manual intervention might be needed."
    SPARK_HOME_PATH="$EXTRACTED_PATH" # Fallback
fi

# Remove temporary download files
cd - > /dev/null # Go back to previous directory
rm -rf /tmp/spark_install
echo "Temporary download files cleaned up."


# --- Step 4: Set Environment Variables ---
echo -e "\n--- Step 4: Setting Environment Variables ---"
echo "Adding JAVA_HOME, SPARK_HOME, and PATH to your ~/.zshenv file."

ZSHENV_FILE="$HOME/.zshenv"

# Check if the .zshenv file exists, if not, create it
if [ ! -f "$ZSHENV_FILE" ]; then
    touch "$ZSHENV_FILE"
    echo "Created ~/.zshenv file."
fi

# Append environment variables if not already present
grep -qxF "export JAVA_HOME=${JAVA_HOME_PATH}" "$ZSHENV_FILE" || echo "export JAVA_HOME=${JAVA_HOME_PATH}" >> "$ZSHENV_FILE"
grep -qxF "export SPARK_HOME=${SPARK_HOME_PATH}" "$ZSHENV_FILE" || echo "export SPARK_HOME=${SPARK_HOME_PATH}" >> "$ZSHENV_FILE"
# Check if Spark bin/sbin are already in PATH to avoid duplicates
grep -q "SPARK_HOME/bin" "$ZSHENV_FILE" || echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> "$ZSHENV_FILE"

echo "Environment variables added to ${ZSHENV_FILE}."

# --- Final Steps and Verification ---
echo -e "\n--- Installation Complete! ---"
echo "To apply the environment variables, please run the following command in your terminal:"
echo "source ${ZSHENV_FILE}"
echo ""
echo "After sourcing, you can verify your Spark installation by running:"
echo "spark-shell"
echo ""
echo "This should launch the interactive Spark Scala shell. If you prefer PySpark (Python), run:"
echo "pyspark"
echo ""
echo "If you encounter 'Permission denied' errors, you might need to make some scripts executable:"
echo "sudo chmod +x ${SPARK_HOME_PATH}/bin/*"
echo "sudo chmod +x ${SPARK_HOME_PATH}/sbin/*"
echo ""
echo "Enjoy using Apache Spark on WSL! 🚀"
