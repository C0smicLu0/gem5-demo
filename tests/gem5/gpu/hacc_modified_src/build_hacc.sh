#!/usr/bin/env bash
#
# Build the modified HACC ForceTree gem5-fusion workload in-place.

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly GEM5_ROOT="$(cd -- "$SCRIPT_DIR/../../../.." && pwd -P)"
readonly HACC_SRC="$SCRIPT_DIR/halo-finder/src"
readonly HACC_BINARY="$HACC_SRC/hip/ForceTreeTest"
readonly DEFAULT_DOCKER_IMAGE="ghcr.io/gem5/gcn-gpu:v25-1"

DOCKER_IMAGE="${HACC_DOCKER_IMAGE:-$DEFAULT_DOCKER_IMAGE}"
IN_CONTAINER=0

usage()
{
    cat <<EOF
Usage:
  $(basename "$0") [options]

Build the modified HACC ForceTree binary consumed by the workload runner:
  tests/gem5/gpu/hacc_modified_src/halo-finder/src/hip/ForceTreeTest

Options:
  --in-container       Run make in the current environment instead of docker.
  --image IMAGE        Use IMAGE for docker builds.
                       Default: $DEFAULT_DOCKER_IMAGE
  -h, --help           Show this help and exit.
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

[[ -f "$HACC_SRC/Makefile.gem5-fusion" ]] ||
    die "fusion makefile not found: $HACC_SRC/Makefile.gem5-fusion"

printf 'Building hacc ForceTreeTest\n'
if (( IN_CONTAINER )); then
    (
        cd -- "$HACC_SRC"
        make -f Makefile.gem5-fusion clean
        make -f Makefile.gem5-fusion fusion GEM5_ROOT="$GEM5_ROOT"
    )
else
    docker run --rm \
        -v "$GEM5_ROOT":"$GEM5_ROOT" \
        -w "$HACC_SRC" \
        -e GEM5_ROOT="$GEM5_ROOT" \
        "$DOCKER_IMAGE" \
        bash -lc \
        'make -f Makefile.gem5-fusion clean
         make -f Makefile.gem5-fusion fusion GEM5_ROOT="$GEM5_ROOT"'
fi

[[ -f "$HACC_BINARY" ]] ||
    die "build did not create expected binary: $HACC_BINARY"
printf 'Built %s\n' "$HACC_BINARY"
