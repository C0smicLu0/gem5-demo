#!/usr/bin/env bash
#
# Build the demo gem5 binary and workloads from the repository root.

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly GEM5_ROOT="$SCRIPT_DIR"
readonly GEM5_BUILD_SCRIPT="$GEM5_ROOT/test_scripts/build_gem5_vega_x86.sh"
readonly M5_UTIL_DIR="$GEM5_ROOT/util/m5"
readonly GPU_ROOT="$GEM5_ROOT/tests/gem5/gpu"
readonly SQUARE_BUILD_SCRIPT="$GPU_ROOT/square_modified_src/build_square.sh"
readonly HACC_BUILD_SCRIPT="$GPU_ROOT/hacc_modified_src/build_hacc.sh"
readonly PANNOTIA_BUILD_SCRIPT="$GPU_ROOT/pannotia_modified_src/build_pannotia.sh"
readonly HETEROSYNC_BUILD_SCRIPT="$GPU_ROOT/heterosync_modified_src/build_heterosync.sh"
readonly DOCKER_HELP_SCRIPT="$GEM5_ROOT/download_docker.sh"

RUN_GEM5=1
RUN_WORKLOADS=1
WORKLOADS_IN_CONTAINER=0
DOCKER_IMAGE_OVERRIDE=""
JOBS_OVERRIDE=""
DOCKER_SHIM_DIR=""
DOCKER_INSTALL_SCRIPT=""

declare -a PANNOTIA_BENCHMARKS=()

cleanup()
{
    if [[ -n "$DOCKER_SHIM_DIR" && -d "$DOCKER_SHIM_DIR" ]]; then
        rm -rf -- "$DOCKER_SHIM_DIR"
    fi
    if [[ -n "$DOCKER_INSTALL_SCRIPT" && -f "$DOCKER_INSTALL_SCRIPT" ]]; then
        rm -f -- "$DOCKER_INSTALL_SCRIPT"
    fi
}

trap cleanup EXIT

usage()
{
    cat <<EOF
Usage:
  $(basename "$0") [--gem5-only] [--workload-only]
                 [--workloads-in-container]
                 [--image IMAGE] [--jobs N] [--pannotia BENCH]...
                 [--docker-help]

Build order:
  1. test_scripts/build_gem5_vega_x86.sh
  2. util/m5/build/x86/out/m5
  3. tests/gem5/gpu/{square,hacc,pannotia,heterosync}_modified_src/build_*.sh

Options:
  --gem5-only           Build only gem5.
  --workload-only       Build only the demo workloads.
  --gpu-only            Alias for --workload-only.
  --workloads-in-container
                        Build workloads in the current environment.
  --gpu-in-container    Alias for --workloads-in-container.
  --in-container        Alias for --workloads-in-container.
                        The gem5 build helper still manages its own container.
  --image IMAGE         Use IMAGE for the gem5 and workload docker builds.
  --jobs N              Set JOBS=N for the gem5 scons build.
  --pannotia BENCH      Build one Pannotia benchmark. May be repeated.
                        Defaults to all benchmarks known by build_pannotia.sh.
  --docker-help         Print Docker install guidance and exit.
  -h, --help            Show this help and exit.

Examples:
  $(basename "$0")
  $(basename "$0") --jobs 16
  $(basename "$0") --workload-only --workloads-in-container
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

is_wsl()
{
    [[ -n "${WSL_DISTRO_NAME:-}" ]] && return 0
    grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

is_native_linux()
{
    [[ "$(uname -s)" == "Linux" ]] && ! is_wsl
}

setup_docker_sudo_wrapper()
{
    local real_docker="$1"

    DOCKER_SHIM_DIR="$(mktemp -d)"
    cat > "${DOCKER_SHIM_DIR}/docker" <<EOF
#!/usr/bin/env bash
exec sudo "${real_docker}" "\$@"
EOF
    chmod +x "${DOCKER_SHIM_DIR}/docker"
    export PATH="${DOCKER_SHIM_DIR}:$PATH"
}

ensure_docker_access()
{
    local real_docker

    real_docker="$(command -v docker)"
    if "$real_docker" ps >/dev/null 2>&1; then
        return 0
    fi

    if command -v sudo >/dev/null 2>&1 && sudo "$real_docker" ps >/dev/null 2>&1; then
        setup_docker_sudo_wrapper "$real_docker"
        return 0
    fi

    return 1
}

auto_install_docker_linux()
{
    local downloader=()

    if ! is_native_linux; then
        return 1
    fi

    if command -v curl >/dev/null 2>&1; then
        downloader=(curl -fsSL https://get.docker.com -o)
    elif command -v wget >/dev/null 2>&1; then
        downloader=(wget -qO)
    else
        echo "error: need curl or wget to auto-install docker on Linux" >&2
        return 1
    fi

    DOCKER_INSTALL_SCRIPT="$(mktemp)"
    "${downloader[@]}" "$DOCKER_INSTALL_SCRIPT"

    if command -v sudo >/dev/null 2>&1; then
        sudo sh "$DOCKER_INSTALL_SCRIPT"
        if command -v systemctl >/dev/null 2>&1; then
            sudo systemctl enable --now docker >/dev/null 2>&1 || true
        fi
    else
        sh "$DOCKER_INSTALL_SCRIPT"
        if command -v systemctl >/dev/null 2>&1; then
            systemctl enable --now docker >/dev/null 2>&1 || true
        fi
    fi

    return 0
}

require_docker_for()
{
    local purpose="$1"

    if command -v docker >/dev/null 2>&1; then
        if ensure_docker_access; then
            return 0
        fi
    else
        echo "docker not found in PATH for ${purpose}; attempting automatic install on Linux..." >&2
        if auto_install_docker_linux && command -v docker >/dev/null 2>&1 && ensure_docker_access; then
            return 0
        fi
    fi

    echo "error: docker is required for ${purpose}" >&2
    echo >&2
    docker_help >&2
    exit 1
}

run_step()
{
    local title="$1"
    shift

    printf '\n==> %s\n' "$title"
    "$@"
}

build_libm5()
{
    local -a scons_cmd=(scons build/x86/out/m5)

    if [[ -n "$JOBS_OVERRIDE" ]]; then
        scons_cmd+=(-j "$JOBS_OVERRIDE")
    fi

    if (( WORKLOADS_IN_CONTAINER )); then
        (
            cd -- "$M5_UTIL_DIR"
            "${scons_cmd[@]}"
        )
    else
        local image="${DOCKER_IMAGE_OVERRIDE:-ghcr.io/gem5/gcn-gpu:v25-1}"
        docker run --rm \
            -u "$(id -u):$(id -g)" \
            -v "$GEM5_ROOT":"$GEM5_ROOT" \
            -w "$M5_UTIL_DIR" \
            "$image" \
            "${scons_cmd[@]}"
    fi
}

while (($#)); do
    case "$1" in
        --gem5-only)
            RUN_WORKLOADS=0
            ;;
        --workload-only|--gpu-only)
            RUN_GEM5=0
            ;;
        --skip-gem5)
            RUN_GEM5=0
            ;;
        --skip-workloads|--skip-gpu)
            RUN_WORKLOADS=0
            ;;
        --workloads-in-container|--gpu-in-container|--in-container)
            WORKLOADS_IN_CONTAINER=1
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

if (( ! RUN_GEM5 && ! RUN_WORKLOADS )); then
    die "nothing to build"
fi

require_script "$GEM5_BUILD_SCRIPT"
require_script "$SQUARE_BUILD_SCRIPT"
require_script "$HACC_BUILD_SCRIPT"
require_script "$PANNOTIA_BUILD_SCRIPT"
require_script "$HETEROSYNC_BUILD_SCRIPT"
[[ -d "$M5_UTIL_DIR" ]] || die "util/m5 directory not found: $M5_UTIL_DIR"

if (( RUN_GEM5 )); then
    require_docker_for "gem5 build"
fi

if (( RUN_WORKLOADS && ! WORKLOADS_IN_CONTAINER )); then
    require_docker_for "workload builds"
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

if (( RUN_WORKLOADS )); then
    run_step "Building util/m5 libm5" build_libm5

    gpu_args=()
    if (( WORKLOADS_IN_CONTAINER )); then
        gpu_args+=(--in-container)
    fi
    if [[ -n "$DOCKER_IMAGE_OVERRIDE" ]]; then
        gpu_args+=(--image "$DOCKER_IMAGE_OVERRIDE")
    fi

    run_step "Building square workload" \
        bash "$SQUARE_BUILD_SCRIPT" "${gpu_args[@]}"
    run_step "Building HACC workload" \
        bash "$HACC_BUILD_SCRIPT" "${gpu_args[@]}"
    run_step "Building Pannotia workloads" \
        bash "$PANNOTIA_BUILD_SCRIPT" "${gpu_args[@]}" "${PANNOTIA_BENCHMARKS[@]}"
    run_step "Building HeteroSync workload" \
        bash "$HETEROSYNC_BUILD_SCRIPT" "${gpu_args[@]}"
fi

printf '\nDemo build completed.\n'
