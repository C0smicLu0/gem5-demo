#!/usr/bin/env bash
#
# Run the demo Square GPU workload from the repository root.

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly GEM5_ROOT="$SCRIPT_DIR"
readonly WORKLOAD_RUNNER="$GEM5_ROOT/test_scripts/gem5_workload_runner.sh"
readonly WORKLOAD_CONFIG="$GEM5_ROOT/test_scripts/gem5_workloads.json"
readonly DOCKER_HELP_SCRIPT="$GEM5_ROOT/download_docker.sh"

MODE="quick"
RUN_TAG=""
DEBUG_FLAGS=""
DEBUG_START=""

usage()
{
    cat <<EOF
Usage:
  $(basename "$0") [quick|all] [options]

Modes:
  quick               Run square once with profile cores.args1.
                      This is the default mode.
  all                 Run square for every configured cores.args* profile.
                      This mode runs in parallel by default.

Options:
  --run-tag TAG       Use TAG as the run tag prefix. A per-workload suffix is
                      added automatically in all mode.
  --debug-flags CSV   Forward --debug-flags to gem5.
  --debug-start TICK  Forward --debug-start to gem5.
  --docker-help       Print Docker install guidance and exit.
  -h, --help          Show this help and exit.

Examples:
  $(basename "$0")
  $(basename "$0") quick --run-tag smoke
  $(basename "$0") all --run-tag nightly
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

    [[ -f "$script" ]] || die "script not found: $script"
}

require_file()
{
    local path="$1"

    [[ -f "$path" ]] || die "file not found: $path"
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

timestamp_tag()
{
    date '+%Y%m%d-%H%M%S'
}

build_runner_args()
{
    local -n out_ref="$1"
    out_ref=()

    if [[ -n "$DEBUG_FLAGS" ]]; then
        out_ref+=(--debug-flags "$DEBUG_FLAGS")
    fi
    if [[ -n "$DEBUG_START" ]]; then
        out_ref+=(--debug-start "$DEBUG_START")
    fi
}

run_workload()
{
    local workload="$1"
    local tag="$2"
    shift 2

    local extra_args=("$@")

    printf '\n==> Running %s (tag=%s)\n' "$workload" "$tag"
    bash "$WORKLOAD_RUNNER" run "$workload" "$tag" "${extra_args[@]}"
}

run_workload_background()
{
    local workload="$1"
    local tag="$2"
    shift 2

    local extra_args=("$@")

    printf '\n[START] %s (tag=%s)\n' "$workload" "$tag"
    bash "$WORKLOAD_RUNNER" run "$workload" "$tag" "${extra_args[@]}" &
    background_pids+=("$!")
    background_labels+=("${workload}:${tag}")
}

monitor_background_runs()
{
    local -a pending_pids=("${background_pids[@]}")
    local -a pending_labels=("${background_labels[@]}")
    local completed=0
    local failed=0

    printf '\nMonitoring %d background runs...\n' "${#pending_pids[@]}"

    while ((${#pending_pids[@]} > 0)); do
        local index

        for index in "${!pending_pids[@]}"; do
            local pid="${pending_pids[$index]}"
            local label="${pending_labels[$index]}"

            if kill -0 "$pid" 2>/dev/null; then
                continue
            fi

            if wait "$pid"; then
                completed=$((completed + 1))
                printf '[DONE] %s (%d/%d)\n' \
                    "$label" "$completed" "${#background_pids[@]}"
            else
                failed=$((failed + 1))
                printf '[FAIL] %s (%d failed)\n' "$label" "$failed" >&2
            fi

            unset 'pending_pids[index]'
            unset 'pending_labels[index]'
            pending_pids=("${pending_pids[@]}")
            pending_labels=("${pending_labels[@]}")
            break
        done

        sleep 1
    done

    if ((failed > 0)); then
        die "${failed} background run(s) failed"
    fi
}

load_core_profiles()
{
    python3 - "$WORKLOAD_CONFIG" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    cfg = json.load(fh)

cores = cfg.get("config_profiles", {}).get("cores", {})
names = sorted(
    name for name, value in cores.items()
    if name.startswith("args") and str(value).strip()
)

for name in names:
    print(name)
PY
}

while (($#)); do
    case "$1" in
        quick|all)
            MODE="$1"
            ;;
        --run-tag)
            shift
            (($#)) || die "--run-tag requires a value"
            RUN_TAG="$1"
            ;;
        --debug-flags)
            shift
            (($#)) || die "--debug-flags requires a value"
            DEBUG_FLAGS="$1"
            ;;
        --debug-start)
            shift
            (($#)) || die "--debug-start requires a value"
            DEBUG_START="$1"
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

require_script "$WORKLOAD_RUNNER"
require_file "$WORKLOAD_CONFIG"

if ! command -v docker >/dev/null 2>&1; then
    echo "error: docker not found in PATH" >&2
    echo "hint: run 'bash $DOCKER_HELP_SCRIPT'" >&2
    exit 1
fi

base_tag="${RUN_TAG:-$(timestamp_tag)}"
runner_args=()
build_runner_args runner_args
background_pids=()
background_labels=()

if [[ "$MODE" == "quick" ]]; then
    run_workload square "$base_tag" --profile cores.args1 "${runner_args[@]}"
    printf '\nDemo test completed.\n'
    exit 0
fi

mapfile -t core_profiles < <(load_core_profiles)
((${#core_profiles[@]} > 0)) || die "no cores.args* profiles found in $WORKLOAD_CONFIG"

for profile_name in "${core_profiles[@]}"; do
    run_workload_background square "${base_tag}-${profile_name}" \
        --profile "cores.${profile_name}" "${runner_args[@]}"
done

monitor_background_runs

printf '\nDemo test completed.\n'
