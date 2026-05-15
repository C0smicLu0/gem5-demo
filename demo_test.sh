#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
GEM5_DEMO_ROOT="${GEM5_DEMO_ROOT:-${SCRIPT_DIR}}"
PANNOTIA_LOCAL_DIR="${GEM5_DEMO_ROOT}/tests/gem5/resources/gpu-pannotia"
PANNOTIA_EXTERNAL_DIR="${PANNOTIA_EXTERNAL_DIR:-/home/orange/gem5/tests/gem5/resources/gpu-pannotia}"
PANNOTIA_CONTAINER_DIR="/gem5-demo/tests/gem5/resources/gpu-pannotia"

PANNOTIA_VOLUME=()
if [[ ! -f "${PANNOTIA_LOCAL_DIR}/pannotia-bins/bc.gem5" ]] || \
   [[ ! -f "${PANNOTIA_LOCAL_DIR}/pannotia-bins/color_max.gem5" ]] || \
   [[ ! -f "${PANNOTIA_LOCAL_DIR}/pannotia-bins/color_maxmin.gem5" ]] || \
   [[ ! -f "${PANNOTIA_LOCAL_DIR}/pannotia-bins/mis_hip.gem5" ]] || \
   [[ ! -f "${PANNOTIA_LOCAL_DIR}/pannotia-datasets/1k_128k.gr" ]]; then
    PANNOTIA_VOLUME=(-v "${PANNOTIA_EXTERNAL_DIR}:${PANNOTIA_CONTAINER_DIR}")
fi

cd "${GEM5_DEMO_ROOT}"

if [ "$1" = "list" ]; then
    docker run --rm -it \
    -u $(id -u):$(id -g) \
    -v "${GEM5_DEMO_ROOT}:/gem5-demo" \
    "${PANNOTIA_VOLUME[@]}" \
    -w /gem5-demo/tests \
    ghcr.io/gem5/gcn-gpu:v25-1 \
    ./main.py list --tests \
      --isa VEGA_X86 \
      --variant opt \
      --host gcn_gpu \
      gem5/gpu
fi

if [ "$1" = "quick" ]; then
    docker run --rm -it \
    -u $(id -u):$(id -g) \
    -v "${GEM5_DEMO_ROOT}:/gem5-demo" \
    "${PANNOTIA_VOLUME[@]}" \
    -w /gem5-demo/tests \
    ghcr.io/gem5/gcn-gpu:v25-1 \
    ./main.py run \
      --skip-build \
      --isa VEGA_X86 \
      --variant opt \
      --host gcn_gpu \
      --length quick \
      gem5/gpu
fi

if [ "$1" = "all" ]; then
    for length in quick long very-long; do
        docker run --rm -it \
        -u $(id -u):$(id -g) \
        -v "${GEM5_DEMO_ROOT}:/gem5-demo" \
        "${PANNOTIA_VOLUME[@]}" \
        -w /gem5-demo/tests \
        ghcr.io/gem5/gcn-gpu:v25-1 \
        ./main.py run \
          --skip-build \
          --isa VEGA_X86 \
          --variant opt \
          --host gcn_gpu \
          --length "${length}" \
          gem5/gpu
    done
fi

if [ "$1" = "long" ]; then
    docker run --rm -it \
    -u $(id -u):$(id -g) \
    -v "${GEM5_DEMO_ROOT}:/gem5-demo" \
    "${PANNOTIA_VOLUME[@]}" \
    -w /gem5-demo/tests \
    ghcr.io/gem5/gcn-gpu:v25-1 \
    ./main.py run \
      --skip-build \
      --isa VEGA_X86 \
      --variant opt \
      --host gcn_gpu \
      --length long \
      gem5/gpu
fi

if [ "$1" = "very_long" ]; then
    docker run --rm -it \
    -u $(id -u):$(id -g) \
    -v "${GEM5_DEMO_ROOT}:/gem5-demo" \
    "${PANNOTIA_VOLUME[@]}" \
    -w /gem5-demo/tests \
    ghcr.io/gem5/gcn-gpu:v25-1 \
    ./main.py run \
      --skip-build \
      --isa VEGA_X86 \
      --variant opt \
      --host gcn_gpu \
      --length very-long \
      gem5/gpu
fi

if [ "$1" = "uid" ]; then
    docker run --rm -it \
    -u $(id -u):$(id -g) \
    -v "${GEM5_DEMO_ROOT}:/gem5-demo" \
    -w /gem5-demo/tests \
    ghcr.io/gem5/gcn-gpu:v25-1 \
    ./main.py run \
      --skip-build \
      --uid "$2"
fi
