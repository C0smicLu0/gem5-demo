#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
GEM5_ROOT="${GEM5_ROOT:-$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)}"   # 规范化

DOCKER_IMAGE="${DOCKER_IMAGE:-ghcr.io/gem5/gcn-gpu:v25-1}"
CCACHE_DIR="${CCACHE_DIR:-${HOME}/.ccache}"
BUILD_ISA="${BUILD_ISA:-VEGA_X86}"
BUILD_TARGET="${BUILD_TARGET:-build/${BUILD_ISA}/gem5.opt}"
JOBS="${JOBS:-$(nproc)}"

# 前置检查
if [[ ! -f "${GEM5_ROOT}/SConstruct" ]]; then
    echo "error: not a gem5 source tree: ${GEM5_ROOT}" >&2
    exit 1
fi

if [[ "${BUILD_ISA}" != "VEGA_X86" ]]; then
    echo "error: BUILD_ISA must be VEGA_X86" >&2
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "error: docker not found in PATH" >&2
    exit 1
fi

if ! docker ps >/dev/null 2>&1; then
    echo "error: docker daemon not running or permission denied" >&2
    exit 1
fi

mkdir -p "$CCACHE_DIR"

echo "gem5 root: ${GEM5_ROOT}"
echo "docker image: ${DOCKER_IMAGE}"
echo "target: ${BUILD_TARGET}"
echo "jobs: ${JOBS}"

docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "${GEM5_ROOT}:${GEM5_ROOT}" \
    -v "${CCACHE_DIR}:/home/user/.ccache" \
    -e CCACHE_DIR=/home/user/.ccache \
    -w "${GEM5_ROOT}" \
    "${DOCKER_IMAGE}" \
    scons -sQ -j"${JOBS}" "${BUILD_TARGET}" --ignore-style ${SCONS_EXTRA_ARGS:-}

echo "built: ${GEM5_ROOT}/${BUILD_TARGET}"