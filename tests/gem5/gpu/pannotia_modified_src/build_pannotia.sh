#!/usr/bin/env bash
#
# Build the modified Pannotia gem5-fusion workloads and copy them into the
# ignored test resource directory used by test_gpu_pannotia.py.

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly GEM5_ROOT="$(cd -- "$SCRIPT_DIR/../../../.." && pwd -P)"
readonly PANNOTIA_SRC="$SCRIPT_DIR/pannotia"
readonly TEST_BIN_DIR="$GEM5_ROOT/tests/gem5/resources/gpu-pannotia/pannotia-bins"
readonly DEFAULT_DOCKER_IMAGE="ghcr.io/gem5/gcn-gpu:v25-1"

DOCKER_IMAGE="${PANNOTIA_DOCKER_IMAGE:-$DEFAULT_DOCKER_IMAGE}"
IN_CONTAINER=0

readonly BENCHMARKS=(bc color_max color_maxmin mis_hip)
declare -A CLEANED_SOURCE_DIRS=()

usage()
{
    cat <<EOF
Usage:
  $(basename "$0") [options] [all|benchmark...]

Build the modified Pannotia workloads and copy their gem5 binaries to:
  tests/gem5/resources/gpu-pannotia/pannotia-bins

Benchmarks:
  all         Build and copy every registered benchmark.
  bc
  color_max
  color_maxmin
  mis_hip

Options:
  --in-container       Run make in the current environment instead of docker.
  --image IMAGE        Use IMAGE for docker builds.
                       Default: $DEFAULT_DOCKER_IMAGE
  --list               Print registered benchmarks and exit.
  -h, --help           Show this help and exit.

Examples:
  $(basename "$0")
  $(basename "$0") bc mis_hip
  $(basename "$0") --in-container all
  PANNOTIA_DOCKER_IMAGE=ghcr.io/gem5/gcn-gpu:v25-1 $(basename "$0") color_max

Register a new benchmark in benchmark_record() after its source and
Makefile.gem5-fusion have been added under:
  tests/gem5/gpu/pannotia_modified_src/pannotia
EOF
}

die()
{
    printf 'error: %s\n' "$*" >&2
    exit 2
}

list_benchmarks()
{
    printf '%s\n' "${BENCHMARKS[@]}"
}

is_registered_benchmark()
{
    local benchmark="$1"
    local registered

    for registered in "${BENCHMARKS[@]}"; do
        if [[ "$benchmark" == "$registered" ]]; then
            return 0
        fi
    done

    return 1
}

# Record format:
# source directory | make arguments | source binary | copied binary
benchmark_record()
{
    case "$1" in
        bc)
            printf '%s|%s|%s|%s\n' \
                "$PANNOTIA_SRC/bc" \
                "" \
                "bin/bc.gem5" \
                "bc.gem5"
            ;;
        color_max)
            printf '%s|%s|%s|%s\n' \
                "$PANNOTIA_SRC/color" \
                "VARIANT=MAX" \
                "bin/color_max.gem5" \
                "color_max.gem5"
            ;;
        color_maxmin)
            printf '%s|%s|%s|%s\n' \
                "$PANNOTIA_SRC/color" \
                "VARIANT=MAXMIN" \
                "bin/color_maxmin.gem5" \
                "color_maxmin.gem5"
            ;;
        mis_hip)
            printf '%s|%s|%s|%s\n' \
                "$PANNOTIA_SRC/mis" \
                "" \
                "bin/mis_hip.gem5" \
                "mis_hip.gem5"
            ;;
        *)
            die "unregistered benchmark '$1'; use --list to see valid names"
            ;;
    esac
}

parse_record()
{
    local benchmark="$1"
    local record

    record="$(benchmark_record "$benchmark")"
    IFS='|' read -r SOURCE_DIR MAKE_ARGUMENTS SOURCE_BINARY COPIED_BINARY <<<"$record"
}

run_make()
{
    local benchmark="$1"
    local -a make_arguments=()
    local -a clean_command=()
    local clean_marker="skip-clean"

    parse_record "$benchmark"

    [[ -d "$SOURCE_DIR" ]] || die "source directory not found: $SOURCE_DIR"
    [[ -f "$SOURCE_DIR/Makefile.gem5-fusion" ]] ||
        die "fusion makefile not found: $SOURCE_DIR/Makefile.gem5-fusion"

    if [[ -n "$MAKE_ARGUMENTS" ]]; then
        read -r -a make_arguments <<<"$MAKE_ARGUMENTS"
    fi

    # Multiple benchmark records can share a source directory. The color
    # variants both write to color/bin, so cleaning before each variant would
    # remove the binary built by the previous variant.
    if [[ -z "${CLEANED_SOURCE_DIRS[$SOURCE_DIR]:-}" ]]; then
        clean_command=(make -f Makefile.gem5-fusion clean)
        clean_marker="clean"
        CLEANED_SOURCE_DIRS["$SOURCE_DIR"]=1
    fi

    printf 'Building %s\n' "$benchmark"
    if (( IN_CONTAINER )); then
        (
            cd -- "$SOURCE_DIR"
            if ((${#clean_command[@]})); then
                "${clean_command[@]}"
            fi
            make -f Makefile.gem5-fusion GEM5_ROOT="$GEM5_ROOT" \
                "${make_arguments[@]}"
        )
    else
        docker run --rm \
            -u "$(id -u):$(id -g)" \
            -v "$GEM5_ROOT":"$GEM5_ROOT" \
            -w "$SOURCE_DIR" \
            -e GEM5_ROOT="$GEM5_ROOT" \
            "$DOCKER_IMAGE" \
            bash -lc \
            'if [[ "$1" == clean ]]; then
                 make -f Makefile.gem5-fusion clean
             fi
             shift
             make -f Makefile.gem5-fusion GEM5_ROOT="$GEM5_ROOT" "$@"' \
            bash "$clean_marker" "${make_arguments[@]}"
    fi
}

copy_binary()
{
    local benchmark="$1"
    local source_path
    local destination_path

    parse_record "$benchmark"
    source_path="$SOURCE_DIR/$SOURCE_BINARY"
    destination_path="$TEST_BIN_DIR/$COPIED_BINARY"

    [[ -f "$source_path" ]] ||
        die "build did not create expected binary: $source_path"

    mkdir -p -- "$TEST_BIN_DIR"
    cp -- "$source_path" "$destination_path"
    printf 'Copied %s -> %s\n' "$source_path" "$destination_path"
}

build_and_copy()
{
    local benchmark="$1"

    run_make "$benchmark"
    copy_binary "$benchmark"
}

declare -a selected_benchmarks=()

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
        --list)
            list_benchmarks
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            die "unknown option '$1'"
            ;;
        all)
            selected_benchmarks=("${BENCHMARKS[@]}")
            ;;
        *)
            is_registered_benchmark "$1" ||
                die "unregistered benchmark '$1'; use --list to see valid names"
            selected_benchmarks+=("$1")
            ;;
    esac
    shift
done

if ((${#selected_benchmarks[@]} == 0)); then
    selected_benchmarks=("${BENCHMARKS[@]}")
fi

for benchmark in "${selected_benchmarks[@]}"; do
    build_and_copy "$benchmark"
done
