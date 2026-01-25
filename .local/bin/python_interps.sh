#!/bin/bash

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

# --- 1. Configuration ---
PYTHON_INTERP="${PYTHON_INTERP:-s4p3.12}"
SPARK_VERSION="${SPARK_VERSION:-4.1.1}"
CONDA_DIR="$HOME/miniconda3"

# --- 2. Prerequisites ---
if [ ! -d "$CONDA_DIR" ]; then
    echo "Error: Miniconda not found at $CONDA_DIR. Please run minconda_install.sh first."
    exit 1
fi

# Source conda to make it available
if [ -f "$CONDA_DIR/etc/profile.d/conda.sh" ]; then
    source "$CONDA_DIR/etc/profile.d/conda.sh"
else
    echo "Error: Could not find conda.sh to initialize conda."
    exit 1
fi

# --- 3. Idempotency Check ---
if conda env list | grep -q "^${PYTHON_INTERP} "; then
    echo "Conda environment '$PYTHON_INTERP' already exists. Skipping creation."
    conda activate "$PYTHON_INTERP"
    echo "Environment activated. Python: $(python --version 2>&1)"
    exit 0
fi

# --- 4. Create Environment ---
echo "Creating conda environment '$PYTHON_INTERP' with Python 3.12..."
conda create -n "$PYTHON_INTERP" python=3.12 -y \
  numpy \
  pandas \
  scikit-learn \
  matplotlib \
  notebook \
  seaborn \
  jupyterlab \
  ipython \
  scipy \
  tqdm \
  wget \
  flask \
  PyYAML \
  pytest \
  pyflakes \
  colorama \
  jsonschema || {
    echo "Error: Failed to create conda environment."
    exit 1
}

echo "Conda environment '$PYTHON_INTERP' created successfully."

# --- 5. Install Additional Packages ---
echo "Activating environment and installing additional packages..."
conda activate "$PYTHON_INTERP"

# Install PySpark matching the Spark version
echo "Installing pyspark==${SPARK_VERSION} and additional packages..."
pip install "pyspark==${SPARK_VERSION}" graphframes google-cloud-bigquery || {
    echo "Warning: Some pip packages failed to install. Continuing..."
}

echo ""
echo "Python interpreter setup complete!"
echo "Environment: $PYTHON_INTERP"
echo "Python version: $(python --version 2>&1)"
echo "PySpark version: $(python -c 'import pyspark; print(pyspark.__version__)' 2>/dev/null || echo 'not installed')"