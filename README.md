# Jupyter on Ubuntu 24.04 (Docker Image v0.1)

This repository provides a Docker image that runs **JupyterLab** or the classic **Jupyter Notebook** on top of **Ubuntu 24.04 LTS**.

Python packages (including Jupyter) are installed into a **virtual environment** at `/opt/venv` to comply with Ubuntu’s PEP 668 “externally-managed environment” constraints and to keep the system Python clean.

---

## Features

- Base OS: **Ubuntu 24.04 LTS**
- Python managed in a **virtual environment** (`/opt/venv`)
- **JupyterLab 4.\*** and **Notebook 7.\*** installed via `pip`
- Single image, switchable runtime:
  - `lab` (default) → JupyterLab
  - `notebook` → classic Jupyter Notebook
- Non-root runtime user: `jupyter`
- Default working directory: `/home/jupyter`
- Default port: **8080**
- Jupyter authentication disabled by default (no token, no password) – suitable for local/dev use only

---

## Contents

- `Dockerfile` (version 0.1)
- `entrypoint.sh` (mode selector: `lab` or `notebook`)

---

## Building the Image

From the directory containing the `Dockerfile` and `entrypoint.sh`:

```bash
docker build -t atomycloud/jupyter:0.1 .
```

# Running the Container
1. JupyterLab (default mode)

To run JupyterLab on port 8080:

```bash
docker run --rm -p 8080:8080 atomycloud/jupyter:0.1
```

This is equivalent to:

```bash
docker run --rm -p 8080:8080 atomycloud/jupyter:0.1 lab
```

Then open in your browser:
```bash
http://localhost:8080
```

No token or password will be required.

2. Classic Jupyter Notebook

To start the classic Notebook interface instead of JupyterLab:

docker run --rm -p 8080:8080 jupyter-ubuntu:0.1 notebook


##Open: 

http://localhost:8080

3. Passing Additional Jupyter Arguments

The first argument to the container is the mode (lab or notebook). Any arguments after that are passed directly to the underlying Jupyter command.

Examples:

Change the notebook directory:

```bash
docker run --rm -p 8080:8080 atomycloud/jupyter:0.1 lab --notebook-dir=/home/jupyter/work
```

Change the port:

```bash
docker run --rm -p 9090:9090 atomycloud/jupyter:0.1 notebook --port=9090
```

Note: If you change the internal port with --port, you must also adjust the -p mapping accordingly.

Persistence (Optional)

By default, containers are ephemeral: any notebooks you create will be lost when the container is removed unless you mount a volume.

You can persist notebooks by mounting a host directory or a Docker volume to /home/jupyter:

# Using a named Docker volume
```bash
docker volume create jupyter_data
```

Then run:
```bash
docker run --rm -p 8080:8080 \
  -v jupyter_data:/home/jupyter \
  atomycloud/jupyter:0.1
```

Or:

# Using a host directory
```bash
docker run --rm -p 8080:8080 \
  -v /path/on/host:/home/jupyter \
  atomycloud/jupyter:0.1
```

If desired, you can also uncomment the VOLUME ["/home/jupyter"] line in the Dockerfile to declare this directory as a volume in the image definition.

---
# Security Note

For convenience, this image disables Jupyter authentication:

- JupyterLab: --ServerApp.token='' --ServerApp.password=''

- Notebook: --NotebookApp.token='' --NotebookApp.password=''

Do not expose this container directly to untrusted networks.
For production or shared environments, you should:

Enable tokens or passwords, or

Put Jupyter behind a reverse proxy with proper authentication and TLS, and

Restrict network access appropriately.

You can override the defaults by passing your own Jupyter arguments when starting the container.

Implementation Details

System Python and tools are installed via apt:

python3, python3-venv, python3-dev, build-essential, curl, ca-certificates

A Python virtual environment is created at /opt/venv:

`python3 -m venv /opt/venv`

ensurepip is used to bootstrap and upgrade pip inside the venv

Within the venv:

`pip` is upgraded

Jupyter packages are installed with pinned major versions:

`jupyterlab==4.*`
`notebook==7.*`

JupyterLab assets are pre-built at image build time: `jupyter lab build || true`

Runtime user jupyter is created and used to avoid running Jupyter as root.