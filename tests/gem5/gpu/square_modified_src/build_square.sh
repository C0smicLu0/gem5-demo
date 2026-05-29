#!/usr/bin/env bash
#
# Build the modified Square gem5-fusion workload and copy it to the ignored
# test resource path consumed by test_gpu_apu_se.py.

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly GEM5_ROOT="$(cd -- "$SCRIPT_DIR/../../../.." && pwd -P)"
readonly SQUARE_SRC="$SCRIPT_DIR/square"
readonly SQUARE_BINARY="$SQUARE_SRC/bin/square-gpu-test"
readonly TEST_BINARY="$GEM5_ROOT/tests/gem5/resources/square-gpu-test"
readonly DEFAULT_DOCKER_IMAGE="ghcr.io/gem5/gcn-gpu:v25-1"

DOCKER_IMAGE="${SQUARE_DOCKER_IMAGE:-$DEFAULT_DOCKER_IMAGE}"
IN_CONTAINER=0

usage()
{
    cat <<EOF
Usage:
  $(basename "$0") [options]

Build the modified Square workload and copy it to:
  tests/gem5/resources/square-gpu-test

Options:
  --in-container       Run make in the current environment instead of docker.
  --image IMAGE        Use IMAGE for docker builds.
                       Default: $DEFAULT_DOCKER_IMAGE
  -h, --help           Show this help and exit.

Examples:
  $(basename "$0")
  $(basename "$0") --in-container
  SQUARE_DOCKER_IMAGE=ghcr.io/gem5/gcn-gpu:v25-1 $(basename "$0")
EOF
}

die()
{
    printf 'error: %s\n' "$*" >&2
    exit 2
}

while (($#)); do
    case "$1" in
        --in-container)
            IN_CONTAINER=1
            ;;
        --image)
            shift
            (($#)) || die "--image requires an image name"
            DOCKER_IMAGE="$1"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown option '$1'"
            ;;
    esac
    shift
done

[[ -f "$SQUARE_SRC/Makefile.gem5-fusion" ]] ||
    die "fusion makefile not found: $SQUARE_SRC/Makefile.gem5-fusion"

printf 'Building square\n'
if (( IN_CONTAINER )); then
    (
        cd -- "$SQUARE_SRC"
        make -f Makefile.gem5-fusion clean
        make -f Makefile.gem5-fusion GEM5_ROOT="$GEM5_ROOT"
    )
else
    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$GEM5_ROOT":"$GEM5_ROOT" \
        -w "$SQUARE_SRC" \
        -e GEM5_ROOT="$GEM5_ROOT" \
        "$DOCKER_IMAGE" \
        bash -lc \
        'make -f Makefile.gem5-fusion clean
         make -f Makefile.gem5-fusion GEM5_ROOT="$GEM5_ROOT"'
fi

[[ -f "$SQUARE_BINARY" ]] ||
    die "build did not create expected binary: $SQUARE_BINARY"

mkdir -p -- "$(dirname -- "$TEST_BINARY")"
cp -- "$SQUARE_BINARY" "$TEST_BINARY"
printf 'Copied %s -> %s\n' "$SQUARE_BINARY" "$TEST_BINARY"
