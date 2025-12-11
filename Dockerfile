# Base image: Ubuntu 24.04 LTS
FROM ubuntu:24.04

# Non-interactive installs and basic environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# System dependencies and Python
RUN apt-get update && apt-get install -y \
    python3 \
    python3-venv \
    python3-dev \
    build-essential \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a virtual environment for Python packages
RUN python3 -m venv /opt/venv

# Make sure venv python/pip are used by default
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip inside the virtual environment
RUN pip install --upgrade pip

# Install JupyterLab and classic Jupyter Notebook in the venv
RUN pip install --no-cache-dir \
    jupyterlab \
    notebook

# Optional: pre-build JupyterLab assets (can be skipped if not needed)
RUN jupyter lab build || true

# Create a non-root user to run Jupyter
RUN useradd -m -s /bin/bash jupyter

# Switch to the new user
USER jupyter
WORKDIR /home/jupyter
# Expose Jupyter default port
EXPOSE 8080

# Default command: start JupyterLab
# NOTE: This disables auth (token/password) for convenience inside Docker.
# For production use, configure proper authentication.
CMD ["bash", "-lc", "jupyter lab --ip=0.0.0.0 --port=8080 --no-browser --notebook-dir=/home/jupyter --ServerApp.token='' --ServerApp.password=''"]
