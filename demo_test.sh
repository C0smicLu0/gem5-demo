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
CHECKALL_RECORDS=()
CHECKALL_EXPECTED_MISSING=()

color_enabled()
{
    [[ -z "${NO_COLOR:-}" && ( -t 1 || -n "${FORCE_COLOR:-}" || "${TERM:-}" != "dumb" ) ]]
}

color_text()
{
    local code="$1"
    shift
    local text="$*"

    if color_enabled; then
        printf '\033[%sm%s\033[0m' "$code" "$text"
    else
        printf '%s' "$text"
    fi
}

status_badge()
{
    case "$1" in
        PASS) color_text "1;32" "[PASS]" ;;
        FAIL) color_text "1;31" "[FAIL]" ;;
        MISS) color_text "1;33" "[MISS]" ;;
        *) printf '[%s]' "$1" ;;
    esac
}

section_title()
{
    color_text "1;36" "$1"
}

summary_label()
{
    color_text "1;34" "$1"
}

extract_profile_name()
{
    local tag="$1"

    if [[ "$tag" =~ (args[^-]+)$ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
    else
        printf '%s' "$tag"
    fi
}

join_by_comma()
{
    local IFS=", "
    printf '%s' "$*"
}

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
                      pass/fail totals. With --run-tag TAG, only that batch is
                      checked. Without --run-tag, all matching result
                      directories are checked.

Options:
  --run-tag TAG       Use TAG as the run tag prefix. A per-workload suffix is
                      added automatically in all mode.
  --debug-flags CSV   Forward --debug-flags to gem5.
  --debug-start TICK  Forward --debug-start to gem5.
  --docker-help       Print Docker install guidance and exit.
  -h, --help          Show this help and exit.

Examples:
  $(basename "$0")
  $(basename "$0") quick --run-tag quick
  $(basename "$0") all --run-tag nightly
  $(basename "$0") checkall --run-tag nightly
  $(basename "$0") checkall
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
    local log_file=""

    if [[ "$MODE" != "checkall" ]]; then
        printf '\n[START] %s %s (tag=%s)\n' "$command" "$workload" "$tag"
    fi

    if [[ "$MODE" == "checkall" && "$command" == "check" ]]; then
        log_file="$(mktemp)"
        bash "$WORKLOAD_RUNNER" "$command" "$workload" "$tag" "${extra_args[@]}" \
            >"$log_file" 2>&1 &
    else
        bash "$WORKLOAD_RUNNER" "$command" "$workload" "$tag" "${extra_args[@]}" &
    fi
    background_pids+=("$!")
    background_labels+=("${command}:${workload}:${tag}")
    background_logs+=("$log_file")
}

monitor_background_runs()
{
    local -a pending_pids=("${background_pids[@]}")
    local -a pending_labels=("${background_labels[@]}")
    local -a pending_logs=("${background_logs[@]}")
    local total_jobs="${#pending_pids[@]}"
    CHECKALL_PASSED=0
    CHECKALL_FAILED=0
    CHECKALL_MISSING=0
    CHECKALL_MISSING_LABELS=()
    CHECKALL_RECORDS=()

    if [[ "$MODE" != "checkall" ]]; then
        printf '\nMonitoring %d background runs...\n' "${#pending_pids[@]}"
    fi

    while ((${#pending_pids[@]} > 0)); do
        local index

        for index in "${!pending_pids[@]}"; do
            local pid="${pending_pids[$index]}"
            local label="${pending_labels[$index]}"
            local log_file="${pending_logs[$index]}"
            local command=""
            local workload=""
            local tag=""

            if kill -0 "$pid" 2>/dev/null; then
                continue
            fi

            IFS=':' read -r command workload tag <<<"$label"

            local rc=0
            local profile_name
            profile_name="$(extract_profile_name "$tag")"
            if wait "$pid"; then
                CHECKALL_PASSED=$((CHECKALL_PASSED + 1))
                if [[ "$MODE" == "checkall" ]]; then
                    CHECKALL_RECORDS+=("$workload|$tag|PASS")
                    printf '%s %s/%s (%d/%d)\n' \
                        "$(status_badge PASS)" "$workload" "$profile_name" \
                        $((CHECKALL_PASSED + CHECKALL_FAILED + CHECKALL_MISSING)) "$total_jobs"
                else
                    printf '[DONE] %s (%d/%d)\n' \
                        "$label" "$CHECKALL_PASSED" "${#background_pids[@]}"
                fi
            else
                rc=$?
                if [[ "$MODE" == "checkall" && "$rc" -eq 2 ]]; then
                    CHECKALL_MISSING=$((CHECKALL_MISSING + 1))
                    CHECKALL_MISSING_LABELS+=("$workload|$tag")
                    CHECKALL_RECORDS+=("$workload|$tag|MISS")
                    printf '%s %s/%s (%d/%d)\n' \
                        "$(status_badge MISS)" "$workload" "$profile_name" \
                        $((CHECKALL_PASSED + CHECKALL_FAILED + CHECKALL_MISSING)) "$total_jobs"
                else
                    CHECKALL_FAILED=$((CHECKALL_FAILED + 1))
                    if [[ "$MODE" == "checkall" ]]; then
                        CHECKALL_RECORDS+=("$workload|$tag|FAIL")
                        printf '%s %s/%s (%d/%d)\n' \
                            "$(status_badge FAIL)" "$workload" "$profile_name" \
                            $((CHECKALL_PASSED + CHECKALL_FAILED + CHECKALL_MISSING)) "$total_jobs"
                    else
                        printf '[FAIL] %s (%d failed)\n' "$label" "$CHECKALL_FAILED" >&2
                    fi
                fi
            fi

            if [[ -n "$log_file" && -f "$log_file" ]]; then
                rm -f -- "$log_file"
            fi

            unset 'pending_pids[index]'
            unset 'pending_labels[index]'
            unset 'pending_logs[index]'
            pending_pids=("${pending_pids[@]}")
            pending_labels=("${pending_labels[@]}")
            pending_logs=("${pending_logs[@]}")
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
    if name.startswith("args") and name != "args0" and str(value).strip()
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

load_base_run_root()
{
    python3 - "$WORKLOAD_CONFIG" <<'PY'
import json
import os
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    cfg = json.load(fh)

root = cfg.get("base_run_root", "tests/testing-results")
print(root)
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

queue_existing_all_mode_checks()
{
    local base_run_root
    local workload
    local profile_name
    local path
    local dir_name
    local tag
    local matched_any
    local -a all_workloads=()
    local -A seen_specs=()

    base_run_root="$(load_base_run_root)"
    if [[ "$base_run_root" != /* ]]; then
        base_run_root="$GEM5_ROOT/$base_run_root"
    fi

    [[ -d "$base_run_root" ]] || die "run root not found: $base_run_root"

    all_workloads=("${DEMO_ALL_WORKLOADS[@]}" "${rodinia_workloads[@]}")

    shopt -s nullglob
    for workload in "${all_workloads[@]}"; do
        for profile_name in "${core_profiles[@]}"; do
            matched_any=0
            for path in "$base_run_root"/"${workload}"-*-"${profile_name}"; do
                [[ -d "$path" ]] || continue
                dir_name="$(basename -- "$path")"
                tag="${dir_name#${workload}-}"
                [[ "$tag" == *-"${profile_name}" ]] || continue
                if [[ -n "${seen_specs["$workload|$tag"]:-}" ]]; then
                    continue
                fi
                seen_specs["$workload|$tag"]=1
                matched_any=1
                run_workload_command_background check "$workload" "$tag"
            done
            if (( ! matched_any )); then
                CHECKALL_EXPECTED_MISSING+=("$workload|$profile_name")
            fi
        done
    done
    shopt -u nullglob

    if ((${#seen_specs[@]} == 0)); then
        die "no matching run directories found under $base_run_root"
    fi
}

render_checkall_report()
{
    local -a ordered_workloads=("${DEMO_ALL_WORKLOADS[@]}" "${rodinia_workloads[@]}")
    local workload
    local record
    local missing
    local record_workload
    local record_tag
    local record_status
    local profile_name
    local workload_total
    local workload_pass
    local workload_fail
    local workload_miss
    local -a pass_items=()
    local -a fail_items=()
    local -a miss_items=()
    local overall_total=0
    local overall_pass=0
    local overall_fail=0
    local overall_miss=0
    local printed_any=0

    printf '\n%s\n' "$(section_title 'Checkall Results')"

    for workload in "${ordered_workloads[@]}"; do
        workload_total=0
        workload_pass=0
        workload_fail=0
        workload_miss=0
        pass_items=()
        fail_items=()
        miss_items=()

        for record in "${CHECKALL_RECORDS[@]}"; do
            IFS='|' read -r record_workload record_tag record_status <<<"$record"
            [[ "$record_workload" == "$workload" ]] || continue
            profile_name="$(extract_profile_name "$record_tag")"
            workload_total=$((workload_total + 1))
            case "$record_status" in
                PASS)
                    workload_pass=$((workload_pass + 1))
                    pass_items+=("$profile_name")
                    ;;
                FAIL)
                    workload_fail=$((workload_fail + 1))
                    fail_items+=("$profile_name")
                    ;;
                MISS)
                    workload_miss=$((workload_miss + 1))
                    miss_items+=("$profile_name")
                    ;;
            esac
        done

        for missing in "${CHECKALL_EXPECTED_MISSING[@]}"; do
            IFS='|' read -r record_workload profile_name <<<"$missing"
            [[ "$record_workload" == "$workload" ]] || continue
            workload_total=$((workload_total + 1))
            workload_miss=$((workload_miss + 1))
            miss_items+=("${profile_name}(no-match)")
        done

        if (( workload_total > 0 )); then
            printed_any=1
            if ((${#pass_items[@]} > 0)); then
                printf '%s %s (%s)\n' \
                    "$(status_badge PASS)" "$workload" "$(join_by_comma "${pass_items[@]}")"
            fi
            if ((${#fail_items[@]} > 0)); then
                printf '%s %s (%s)\n' \
                    "$(status_badge FAIL)" "$workload" "$(join_by_comma "${fail_items[@]}")"
            fi
            if ((${#miss_items[@]} > 0)); then
                printf '%s %s (%s)\n' \
                    "$(status_badge MISS)" "$workload" "$(join_by_comma "${miss_items[@]}")"
            fi
            printf '  %s total=%d pass=%s fail=%s miss=%s\n' \
                "$(summary_label 'summary')" \
                "$workload_total" \
                "$(color_text '1;32' "$workload_pass")" \
                "$(color_text '1;31' "$workload_fail")" \
                "$(color_text '1;33' "$workload_miss")"
            overall_total=$((overall_total + workload_total))
            overall_pass=$((overall_pass + workload_pass))
            overall_fail=$((overall_fail + workload_fail))
            overall_miss=$((overall_miss + workload_miss))
        fi
    done

    if (( ! printed_any )); then
        printf '%s\n' "$(color_text '1;33' 'No matching records found.')"
    fi

    printf '\n%s total=%d pass=%s fail=%s miss=%s\n' \
        "$(section_title 'Overall')" \
        "$overall_total" \
        "$(color_text '1;32' "$overall_pass")" \
        "$(color_text '1;31' "$overall_fail")" \
        "$(color_text '1;33' "$overall_miss")"
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
background_logs=()

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

if [[ -n "$RUN_TAG" ]]; then
    queue_all_mode_checks "$base_tag"
else
    queue_existing_all_mode_checks
fi
monitor_background_runs || true
render_checkall_report

if ((CHECKALL_FAILED > 0 || CHECKALL_MISSING > 0)); then
    die "checkall completed with failures"
fi

printf '\nDemo test completed.\n'
