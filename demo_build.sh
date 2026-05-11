#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

GEM5_ROOT="${GEM5_ROOT:-${SCRIPT_DIR}}"
DOCKER_IMAGE="${DOCKER_IMAGE:-ghcr.io/gem5/gcn-gpu:v25-1}"
CCACHE_DIR="${CCACHE_DIR:-${HOME}/.ccache}"
BUILD_ISA="${BUILD_ISA:-VEGA_X86}"
BUILD_TARGET="${BUILD_TARGET:-build/${BUILD_ISA}/gem5.opt}"
JOBS="${JOBS:-$(nproc)}"

if [[ ! -f "${GEM5_ROOT}/SConstruct" ]]; then
    echo "error: GEM5_ROOT does not look like a gem5 source tree: ${GEM5_ROOT}" >&2
    exit 1
fi

if [[ "${BUILD_ISA}" != "VEGA_X86" ]]; then
    echo "error: this script is intended for BUILD_ISA=VEGA_X86, got ${BUILD_ISA}" >&2
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "error: docker is not available in PATH" >&2
    exit 1
fi

echo "gem5 root: ${GEM5_ROOT}"
echo "docker image: ${DOCKER_IMAGE}"
echo "target: ${BUILD_TARGET}"
echo "jobs: ${JOBS}"

docker run \
    --rm \
    --volume "${GEM5_ROOT}:${GEM5_ROOT}" \
    --volume "${CCACHE_DIR}:/root/.ccache" \
    --env CCACHE_DIR=/root/.ccache \
    --workdir "${GEM5_ROOT}" \
    "${DOCKER_IMAGE}" \
    scons -sQ -j"${JOBS}" "${BUILD_TARGET}" --ignore-style

echo "built: ${GEM5_ROOT}/${BUILD_TARGET}"
