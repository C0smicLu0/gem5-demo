#!/usr/bin/env bash
#
# Build the demo gem5 binary and GPU workloads from the repository root.

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly GEM5_ROOT="$SCRIPT_DIR"
readonly GEM5_BUILD_SCRIPT="$GEM5_ROOT/test_scripts/build_gem5_vega_x86.sh"
readonly GPU_ROOT="$GEM5_ROOT/tests/gem5/gpu"
readonly SQUARE_BUILD_SCRIPT="$GPU_ROOT/square_modified_src/build_square.sh"
readonly HACC_BUILD_SCRIPT="$GPU_ROOT/hacc_modified_src/build_hacc.sh"
readonly PANNOTIA_BUILD_SCRIPT="$GPU_ROOT/pannotia_modified_src/build_pannotia.sh"
readonly HETEROSYNC_BUILD_SCRIPT="$GPU_ROOT/heterosync_modified_src/build_heterosync.sh"
readonly DOCKER_HELP_SCRIPT="$GEM5_ROOT/download_docker.sh"

RUN_GEM5=1
RUN_GPU=1
GPU_IN_CONTAINER=0
DOCKER_IMAGE_OVERRIDE=""
JOBS_OVERRIDE=""

declare -a PANNOTIA_BENCHMARKS=()

usage()
{
    cat <<EOF
Usage:
  $(basename "$0") [options]

Build order:
  1. test_scripts/build_gem5_vega_x86.sh
  2. tests/gem5/gpu/{square,hacc,pannotia,heterosync}_modified_src/build_*.sh

Options:
  --gem5-only           Build only gem5.
  --gpu-only            Build only GPU workloads.
  --skip-gem5           Skip the gem5 build.
  --skip-gpu            Skip all GPU workload builds.
  --gpu-in-container    Build GPU workloads in the current environment.
                        The gem5 build helper still manages its own container.
  --image IMAGE         Use IMAGE for the gem5 and GPU docker builds.
  --jobs N              Set JOBS=N for the gem5 scons build.
  --pannotia BENCH      Build one Pannotia benchmark. May be repeated.
                        Defaults to all benchmarks known by build_pannotia.sh.
  --docker-help         Print Docker install guidance and exit.
  -h, --help            Show this help and exit.

Examples:
  $(basename "$0")
  $(basename "$0") --jobs 16
  $(basename "$0") --gpu-only --gpu-in-container
  $(basename "$0") --pannotia bc --pannotia mis_hip
EOF
}

die()
{
    printf 'error: %s\n' "$*" >&2
    exit 2
}

require_script()
{
    local script="$1"

    [[ -f "$script" ]] || die "build script not found: $script"
}

docker_help()
{
    if [[ -f "$DOCKER_HELP_SCRIPT" ]]; then
        bash "$DOCKER_HELP_SCRIPT"
    else
        cat <<EOF
Docker is required for this script.
See:
  https://docs.docker.com/desktop/setup/install/windows-install/
  https://docs.docker.com/engine/install/ubuntu/
EOF
    fi
}

run_step()
{
    local title="$1"
    shift

    printf '\n==> %s\n' "$title"
    "$@"
}

while (($#)); do
    case "$1" in
        --gem5-only)
            RUN_GPU=0
            ;;
        --gpu-only)
            RUN_GEM5=0
            ;;
        --skip-gem5)
            RUN_GEM5=0
            ;;
        --skip-gpu)
            RUN_GPU=0
            ;;
        --gpu-in-container|--in-container)
            GPU_IN_CONTAINER=1
            ;;
        --image)
            shift
            (($#)) || die "--image requires an image name"
            DOCKER_IMAGE_OVERRIDE="$1"
            ;;
        --jobs)
            shift
            (($#)) || die "--jobs requires a value"
            JOBS_OVERRIDE="$1"
            ;;
        --pannotia)
            shift
            (($#)) || die "--pannotia requires a benchmark name"
            PANNOTIA_BENCHMARKS+=("$1")
            ;;
        --docker-help)
            docker_help
            exit 0
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

if (( ! RUN_GEM5 && ! RUN_GPU )); then
    die "nothing to build"
fi

require_script "$GEM5_BUILD_SCRIPT"
require_script "$SQUARE_BUILD_SCRIPT"
require_script "$HACC_BUILD_SCRIPT"
require_script "$PANNOTIA_BUILD_SCRIPT"
require_script "$HETEROSYNC_BUILD_SCRIPT"

if (( RUN_GEM5 )) && ! command -v docker >/dev/null 2>&1; then
    echo "error: docker not found in PATH" >&2
    echo "hint: run 'bash $DOCKER_HELP_SCRIPT'" >&2
    exit 1
fi

if (( RUN_GPU && ! GPU_IN_CONTAINER )) && ! command -v docker >/dev/null 2>&1; then
    echo "error: docker not found in PATH for GPU workload builds" >&2
    echo "hint: run 'bash $DOCKER_HELP_SCRIPT' or use --gpu-in-container" >&2
    exit 1
fi

if (( RUN_GEM5 )); then
    gem5_env=(env "GEM5_ROOT=$GEM5_ROOT")
    if [[ -n "$DOCKER_IMAGE_OVERRIDE" ]]; then
        gem5_env+=("DOCKER_IMAGE=$DOCKER_IMAGE_OVERRIDE")
    fi
    if [[ -n "$JOBS_OVERRIDE" ]]; then
        gem5_env+=("JOBS=$JOBS_OVERRIDE")
    fi

    run_step "Building gem5 VEGA_X86" \
        "${gem5_env[@]}" bash "$GEM5_BUILD_SCRIPT"
fi

if (( RUN_GPU )); then
    gpu_args=()
    if (( GPU_IN_CONTAINER )); then
        gpu_args+=(--in-container)
    fi
    if [[ -n "$DOCKER_IMAGE_OVERRIDE" ]]; then
        gpu_args+=(--image "$DOCKER_IMAGE_OVERRIDE")
    fi

    run_step "Building square GPU workload" \
        bash "$SQUARE_BUILD_SCRIPT" "${gpu_args[@]}"
    run_step "Building HACC GPU workload" \
        bash "$HACC_BUILD_SCRIPT" "${gpu_args[@]}"
    run_step "Building Pannotia GPU workloads" \
        bash "$PANNOTIA_BUILD_SCRIPT" "${gpu_args[@]}" "${PANNOTIA_BENCHMARKS[@]}"
    run_step "Building HeteroSync GPU workload" \
        bash "$HETEROSYNC_BUILD_SCRIPT" "${gpu_args[@]}"
fi

printf '\nDemo build completed.\n'
