# Dockerfile version: 0.1
# Base image: Ubuntu 24.04 LTS
FROM ubuntu:24.04

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

# Create a virtual environment and ensure pip exists/up-to-date
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/python -m ensurepip --upgrade

# Use venv Python and pip by default
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip inside the virtual environment
RUN pip install --upgrade pip

# Install JupyterLab and classic Jupyter Notebook (pinned major versions)
RUN pip install --no-cache-dir \
    "jupyterlab==4.*" \
    "notebook==7.*"

# Optional: pre-build JupyterLab assets
RUN jupyter lab build || true

# Create a non-root user to run Jupyter
RUN useradd -m -s /bin/bash jupyter

# Copy entrypoint script and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to the new user
USER jupyter
WORKDIR /home/jupyter

# Expose Jupyter port
EXPOSE 8080

# Optional: persist notebooks across runs
# VOLUME ["/home/jupyter"]

# Use entrypoint; default mode = lab
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["lab"]
