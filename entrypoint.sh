#!/usr/bin/env bash
set -e

MODE="${1:-lab}"   # default = lab
shift || true      # shift so any extra args can be passed through

if [ "$MODE" = "lab" ]; then
    exec jupyter lab \
        --ip=0.0.0.0 \
        --port=8080 \
        --no-browser \
        --notebook-dir=/home/jupyter \
        --ServerApp.token='' \
        --ServerApp.password='' \
        "$@"
elif [ "$MODE" = "notebook" ]; then
    exec jupyter notebook \
        --ip=0.0.0.0 \
        --port=8080 \
        --no-browser \
        --notebook-dir=/home/jupyter \
        --NotebookApp.token='' \
        --NotebookApp.password='' \
        "$@"
else
    echo "Unknown mode: $MODE"
    echo "Usage: docker run <image> [lab|notebook] [extra jupyter args...]"
    exit 1
fi
