#!/usr/bin/env bash
PYTHON_ENV=$1

if [ -z "$PYTHON_ENV" ]; then
    echo "Usage: pysetup.sh <venv-name>"
    exit 1
fi

VENV_DIR="./$PYTHON_ENV"
MARKER="$VENV_DIR/.deps_installed"

if [ -d "/opt/py_env" ]; then
    # Copy pre-built venv from Docker image and fix paths
    # Only copy if local venv doesn't already exist
    if [ ! -d "$VENV_DIR" ]; then
        cp -a /opt/py_env "$VENV_DIR"
        # Update venv paths to point to the workspace location
        sed -i "s|/opt/py_env|$(pwd)/$PYTHON_ENV|g" "$VENV_DIR/bin/activate"
        sed -i "s|/opt/py_env|$(pwd)/$PYTHON_ENV|g" "$VENV_DIR/bin/pip"*
        sed -i "s|/opt/py_env|$(pwd)/$PYTHON_ENV|g" "$VENV_DIR/pyvenv.cfg" 2>/dev/null || true
    fi
elif [ -f "$MARKER" ]; then
    # Venv already exists and deps were installed — nothing to do
    echo "Virtual environment '$PYTHON_ENV' already set up, skipping."
else
    # Create venv and install from scratch
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    if [ -f "./requirements.txt" ]; then
        pip3 install -r "./requirements.txt"
    else
        pip3 install -r "/workspaces/ai-3in1/requirements/requirements.txt"
    fi
    # Remove NVIDIA CUDA packages to save disk space (no GPU in Codespace)
    pip uninstall -y nvidia-cublas-cu12 nvidia-cuda-cupti-cu12 nvidia-cuda-nvrtc-cu12 \
        nvidia-cuda-runtime-cu12 nvidia-cufft-cu12 nvidia-cufile-cu12 nvidia-curand-cu12 \
        nvidia-cusparse-cu12 nvidia-cusparselt-cu12 nvidia-nccl-cu12 nvidia-nvjitlink-cu12 \
        nvidia-nvshmem-cu12 nvidia-nvtx-cu12 2>/dev/null || true
    # Mark that deps are installed so re-runs skip the install
    touch "$MARKER"
fi

export PATH="$VENV_DIR/bin:$PATH"
grep -qxF "source $(pwd)/$PYTHON_ENV/bin/activate" ~/.bashrc || echo "source $(pwd)/$PYTHON_ENV/bin/activate" >> ~/.bashrc
