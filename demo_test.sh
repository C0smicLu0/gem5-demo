#!/usr/bin/env bash
#
# Run the demo GPU workloads from the repository root.

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly GEM5_ROOT="$SCRIPT_DIR"
readonly WORKLOAD_RUNNER="$GEM5_ROOT/test_scripts/gem5_workload_runner.sh"
readonly WORKLOAD_CONFIG="$GEM5_ROOT/test_scripts/gem5_workloads.json"
readonly DOCKER_HELP_SCRIPT="$GEM5_ROOT/download_docker.sh"
readonly QUICK_WORKLOAD="square"
readonly QUICK_PROFILE="cores.args1"
readonly DEMO_ALL_WORKLOADS=(
    square
    hacc
    pannotia-bc-1k-128k
    pannotia-color-max-1k-128k
    pannotia-color-maxmin-1k-128k
)

MODE="quick"
RUN_TAG=""
DEBUG_FLAGS=""
DEBUG_START=""

usage()
{
    cat <<EOF
Usage:
  $(basename "$0") [quick|all|checkall] [--run-tag TAG] [--debug-flags CSV]
                 [--debug-start TICK] [--docker-help]

Modes:
  quick               Run square once with profile cores.args1.
                      This is the default mode.
  all                 Run square, hacc, bc, and color for every configured
                      cores.args* profile, plus all configured rodinia-*
                      workloads. This mode runs in parallel by default.
  checkall            Run check for every all-mode configuration and print
                      pass/fail totals. Requires --run-tag TAG.

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
  $(basename "$0") checkall --run-tag nightly
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

run_workload_command_background()
{
    local command="$1"
    local workload="$2"
    local tag="$3"
    shift 3

    local extra_args=("$@")

    printf '\n[START] %s %s (tag=%s)\n' "$command" "$workload" "$tag"
    bash "$WORKLOAD_RUNNER" "$command" "$workload" "$tag" "${extra_args[@]}" &
    background_pids+=("$!")
    background_labels+=("${command}:${workload}:${tag}")
}

monitor_background_runs()
{
    local -a pending_pids=("${background_pids[@]}")
    local -a pending_labels=("${background_labels[@]}")
    CHECKALL_PASSED=0
    CHECKALL_FAILED=0
    CHECKALL_MISSING=0
    CHECKALL_MISSING_LABELS=()

    printf '\nMonitoring %d background runs...\n' "${#pending_pids[@]}"

    while ((${#pending_pids[@]} > 0)); do
        local index

        for index in "${!pending_pids[@]}"; do
            local pid="${pending_pids[$index]}"
            local label="${pending_labels[$index]}"

            if kill -0 "$pid" 2>/dev/null; then
                continue
            fi

            local rc=0
            if wait "$pid"; then
                CHECKALL_PASSED=$((CHECKALL_PASSED + 1))
                printf '[DONE] %s (%d/%d)\n' \
                    "$label" "$CHECKALL_PASSED" "${#background_pids[@]}"
            else
                rc=$?
                if [[ "$MODE" == "checkall" && "$rc" -eq 2 ]]; then
                    CHECKALL_MISSING=$((CHECKALL_MISSING + 1))
                    CHECKALL_MISSING_LABELS+=("$label")
                    printf '[MISS] %s (%d missing)\n' "$label" "$CHECKALL_MISSING" >&2
                else
                    CHECKALL_FAILED=$((CHECKALL_FAILED + 1))
                    printf '[FAIL] %s (%d failed)\n' "$label" "$CHECKALL_FAILED" >&2
                fi
            fi

            unset 'pending_pids[index]'
            unset 'pending_labels[index]'
            pending_pids=("${pending_pids[@]}")
            pending_labels=("${pending_labels[@]}")
            break
        done

        sleep 1
    done

    if ((CHECKALL_FAILED > 0 || CHECKALL_MISSING > 0)); then
        return 1
    fi

    return 0
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

load_rodinia_workloads()
{
    python3 - "$WORKLOAD_CONFIG" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    cfg = json.load(fh)

for name in sorted(cfg.get("workloads", {})):
    if name.startswith("rodinia-") and name != "rodinia-dwt2d":
        print(name)
PY
}

queue_all_mode_runs()
{
    local base_tag="$1"
    shift
    local extra_args=("$@")
    local workload
    local profile_name

    for workload in "${DEMO_ALL_WORKLOADS[@]}"; do
        for profile_name in "${core_profiles[@]}"; do
            run_workload_command_background run "$workload" \
                "${base_tag}-${workload}-${profile_name}" \
                --profile "cores.${profile_name}" "${extra_args[@]}"
        done
    done

    for workload in "${rodinia_workloads[@]}"; do
        for profile_name in "${core_profiles[@]}"; do
            run_workload_command_background run "$workload" \
                "${base_tag}-${workload}-${profile_name}" \
                --profile "cores.${profile_name}" "${extra_args[@]}"
        done
    done
}

queue_all_mode_checks()
{
    local base_tag="$1"
    local workload
    local profile_name

    for workload in "${DEMO_ALL_WORKLOADS[@]}"; do
        for profile_name in "${core_profiles[@]}"; do
            run_workload_command_background check "$workload" \
                "${base_tag}-${workload}-${profile_name}"
        done
    done

    for workload in "${rodinia_workloads[@]}"; do
        for profile_name in "${core_profiles[@]}"; do
            run_workload_command_background check "$workload" \
                "${base_tag}-${workload}-${profile_name}"
        done
    done
}

while (($#)); do
    case "$1" in
        quick|all|checkall)
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
    run_workload "$QUICK_WORKLOAD" "$base_tag" \
        --profile "$QUICK_PROFILE" "${runner_args[@]}"
    printf '\nDemo test completed.\n'
    exit 0
fi

mapfile -t core_profiles < <(load_core_profiles)
((${#core_profiles[@]} > 0)) || die "no cores.args* profiles found in $WORKLOAD_CONFIG"
mapfile -t rodinia_workloads < <(load_rodinia_workloads)

if [[ "$MODE" == "all" ]]; then
    queue_all_mode_runs "$base_tag" "${runner_args[@]}"
    if ! monitor_background_runs; then
        die "${CHECKALL_FAILED} background run(s) failed"
    fi
    printf '\nDemo test completed.\n'
    exit 0
fi

[[ -n "$RUN_TAG" ]] || die "checkall requires --run-tag TAG"
queue_all_mode_checks "$base_tag"
if ! monitor_background_runs; then
    printf '\nCheck summary: %d passed, %d failed.\n' \
        "$CHECKALL_PASSED" "$CHECKALL_FAILED" >&2
    printf 'No-result summary: %d missing.\n' "$CHECKALL_MISSING" >&2
    if ((${#CHECKALL_MISSING_LABELS[@]} > 0)); then
        printf 'No-result runs:\n' >&2
        printf '  %s\n' "${CHECKALL_MISSING_LABELS[@]}" >&2
    fi
    die "checkall completed with failures"
fi

printf '\nCheck summary: %d passed, %d failed.\n' \
    "$CHECKALL_PASSED" "$CHECKALL_FAILED"
printf 'No-result summary: %d missing.\n' "$CHECKALL_MISSING"

printf '\nDemo test completed.\n'
