#!/usr/bin/env bash

set -euo pipefail

DOCKER_IMAGE="${DOCKER_IMAGE:-ghcr.io/gem5/gcn-gpu:v25-1}"
CONTAINER_NAME="${CONTAINER_NAME:-gem5-gcn-v25-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
GEM5_ROOT="${GEM5_ROOT:-$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)}"
WORKDIR_IN_DOCKER="${WORKDIR_IN_DOCKER:-/gem5}"

if ! command -v docker >/dev/null 2>&1; then
    echo "error: docker is not available in PATH" >&2
    exit 1
fi

if [[ ! -d "${GEM5_ROOT}" ]]; then
    echo "error: GEM5_ROOT does not exist: ${GEM5_ROOT}" >&2
    exit 1
fi

echo "docker image: ${DOCKER_IMAGE}"
echo "container name: ${CONTAINER_NAME}"
echo "gem5 root: ${GEM5_ROOT}"
echo "workdir in docker: ${WORKDIR_IN_DOCKER}"

docker run -it --rm \
    --name "${CONTAINER_NAME}" \
    -v "${GEM5_ROOT}:${WORKDIR_IN_DOCKER}" \
    -w "${WORKDIR_IN_DOCKER}" \
    "${DOCKER_IMAGE}" \
    bash
