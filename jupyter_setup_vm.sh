#!/usr/bin/env bash
#
# Monolithic installer + launcher for JupyterLab / Jupyter Notebook
# Target OS: Ubuntu 24.04 LTS (e.g., AWS EC2)
#
# Usage:
#   sudo ./jupyter_setup_vm.sh           # default: lab on port 8080
#   sudo ./jupyter_setup_vm.sh lab
#   sudo ./jupyter_setup_vm.sh notebook
#
# Optional environment variables:
#   PORT=9090 sudo ./jupyter_setup_vm.sh lab

set -euo pipefail

MODE="${1:-lab}"          # lab (default) or notebook
PORT="${PORT:-8080}"      # can override via env: PORT=9090 ./script ...
JUPYTER_USER="jupyter"
VENV_DIR="/opt/jupyter-venv"
NOTEBOOK_DIR="/home/${JUPYTER_USER}"

###############################################################################
# 0. Preconditions
###############################################################################

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: This script must be run as root (e.g., via sudo)." >&2
    exit 1
fi

case "$MODE" in
    lab|notebook)
        ;;
    *)
        echo "ERROR: Invalid mode '$MODE'. Use: lab or notebook." >&2
        echo "Usage: $0 [lab|notebook]" >&2
        exit 1
        ;;
esac

###############################################################################
# 1. Install system dependencies
###############################################################################

echo "==> Installing system dependencies (python3, python3.12-venv, build tools, etc.)..."
apt-get update

# python3.12-venv provides the venv module for the default Python 3.12 on Ubuntu 24.04
apt-get install -y \
    python3 \
    python3.12-venv \
    python3-dev \
    build-essential \
    curl \
    ca-certificates

###############################################################################
# 2. Create non-root Jupyter user (if not exists)
###############################################################################

if id -u "$JUPYTER_USER" &>/dev/null; then
    echo "==> User '$JUPYTER_USER' already exists. Skipping creation."
else
    echo "==> Creating user '$JUPYTER_USER'..."
    useradd -m -s /bin/bash "$JUPYTER_USER"
fi

# Ensure home directory exists
if [[ ! -d "$NOTEBOOK_DIR" ]]; then
    echo "==> Creating home directory for '$JUPYTER_USER' at $NOTEBOOK_DIR..."
    mkdir -p "$NOTEBOOK_DIR"
    chown "$JUPYTER_USER:$JUPYTER_USER" "$NOTEBOOK_DIR"
fi

###############################################################################
# 3. Create Python virtual environment and install Jupyter
###############################################################################

if [[ ! -d "$VENV_DIR" ]]; then
    echo "==> Creating Python virtual environment at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"

    echo "==> Bootstrapping pip in the virtual environment..."
    "$VENV_DIR/bin/python" -m ensurepip --upgrade

    echo "==> Upgrading pip inside the virtual environment..."
    "$VENV_DIR/bin/pip" install --upgrade pip

    echo "==> Installing JupyterLab 4.* and Notebook 7.* into the virtual environment..."
    "$VENV_DIR/bin/pip" install --no-cache-dir \
        "jupyterlab==4.*" \
        "notebook==7.*"

    echo "==> (Optional) Pre-building JupyterLab assets..."
    "$VENV_DIR/bin/jupyter" lab build || true
else
    echo "==> Virtual environment already exists at $VENV_DIR. Skipping creation and install."
fi

###############################################################################
# 4. Start Jupyter as non-root user
###############################################################################

echo "==> Starting Jupyter in mode: $MODE on port: $PORT"
echo "    Notebook directory: $NOTEBOOK_DIR"
echo "    Virtualenv:         $VENV_DIR"
echo

if [[ "$MODE" == "lab" ]]; then
    JUPYTER_CMD="PATH=$VENV_DIR/bin:\$PATH jupyter lab \
        --ip=0.0.0.0 \
        --port=${PORT} \
        --no-browser \
        --notebook-dir=${NOTEBOOK_DIR} \
        --ServerApp.token='' \
        --ServerApp.password=''"
else
    JUPYTER_CMD="PATH=$VENV_DIR/bin:\$PATH jupyter notebook \
        --ip=0.0.0.0 \
        --port=${PORT} \
        --no-browser \
        --notebook-dir=${NOTEBOOK_DIR} \
        --NotebookApp.token='' \
        --NotebookApp.password=''"
fi

echo "==> Running as user '$JUPYTER_USER'..."
echo "    To stop Jupyter, press Ctrl+C in this terminal."
echo

exec su - "$JUPYTER_USER" -c "$JUPYTER_CMD"
