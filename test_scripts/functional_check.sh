#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
RESULTS_ROOT="${REPO_ROOT}/tests/testing-results"
SCAN_SUFFIX="args1.7.14"

usage() {
  cat <<'USAGE'
Usage:
  ./functional_check.sh <workload>
  ./functional_check.sh all

Notes:
  - scans gem5-demo/tests/testing-results
  - only directories whose names end with args1 are considered
  - single-workload mode resolves <workload>-*args1
USAGE
}

list_run_dirs() {
  python3 - "$RESULTS_ROOT" "$SCAN_SUFFIX" <<'PY'
import os
import sys

root = sys.argv[1]
suffix = sys.argv[2]

if not os.path.isdir(root):
    raise SystemExit(0)

for entry in sorted(os.listdir(root)):
    path = os.path.join(root, entry)
    if os.path.isdir(path) and entry.endswith(suffix):
        print(entry)
PY
}

list_workloads() {
  python3 - "$RESULTS_ROOT" "$SCAN_SUFFIX" <<'PY'
import os
import sys

root = sys.argv[1]
suffix = sys.argv[2]
seen = []

if not os.path.isdir(root):
    raise SystemExit(0)

for entry in sorted(os.listdir(root)):
    path = os.path.join(root, entry)
    if not (os.path.isdir(path) and entry.endswith(suffix)):
        continue
    if "-" not in entry:
        continue
    workload = entry.rsplit("-", 1)[0]
    if workload not in seen:
        seen.append(workload)

for workload in seen:
    print(workload)
PY
}

resolve_run_dir() {
  local workload="$1"
  python3 - "$RESULTS_ROOT" "$SCAN_SUFFIX" "$workload" <<'PY'
import os
import sys

root = sys.argv[1]
suffix = sys.argv[2]
workload = sys.argv[3]
prefix = f"{workload}-"

matches = []
if os.path.isdir(root):
    for entry in sorted(os.listdir(root)):
        path = os.path.join(root, entry)
        if os.path.isdir(path) and entry.startswith(prefix) and entry.endswith(suffix):
            matches.append(path)

if not matches:
    raise SystemExit(1)

print(matches[-1])
PY
}

run_single_check() {
  local workload="$1"
  local run_dir

  if ! run_dir="$(resolve_run_dir "$workload")"; then
    echo "functional_check input not found for workload: $workload" >&2
    echo "expected directory pattern: ${RESULTS_ROOT}/${workload}-*${SCAN_SUFFIX}" >&2
    echo "available workloads from testing-results:" >&2
    list_workloads >&2
    return 1
  fi

  python3 "${SCRIPT_DIR}/check_report.py" --mode functional --run-dir "$run_dir"
}

run_all_checks() {
  local -a run_dirs=()
  mapfile -t run_dirs < <(list_run_dirs)

  if (( ${#run_dirs[@]} == 0 )); then
    echo "no workloads found under ${RESULTS_ROOT} matching *${SCAN_SUFFIX}" >&2
    return 1
  fi

  python3 - "$SCRIPT_DIR" "$RESULTS_ROOT" "$SCAN_SUFFIX" "${run_dirs[@]}" <<'PY'
import json
import pathlib
import sys

sys.path.insert(0, sys.argv[1])
import terminal_ui as ui

results_root = pathlib.Path(sys.argv[2])
suffix = sys.argv[3]
run_dirs = sys.argv[4:]
function_order = [
    "resource_instantiation",
    "system_initialization",
    "functional_execution",
    "result_validation",
    "exception_check",
]
function_labels = {
    "resource_instantiation": "资源实例化",
    "system_initialization": "系统初始化",
    "functional_execution": "功能执行",
    "result_validation": "结果校验",
    "exception_check": "异常检查",
}

summary_rows = []
overall_bad = False

for run_name in run_dirs:
    run_dir = results_root / run_name
    workload = run_name.rsplit("-", 1)[0] if "-" in run_name else run_name
    analyze_path = run_dir / "analyze.json"
    if not analyze_path.exists():
        summary_rows.append([
            workload,
            ui.status_text("UNKNOWN"),
            ui.status_text("UNKNOWN"),
            ui.status_text("UNKNOWN"),
            ui.status_text("UNKNOWN"),
            ui.status_text("UNKNOWN"),
            ui.status_text("FAIL"),
            "missing analyze.json",
        ])
        overall_bad = True
        continue

    try:
        data = json.loads(analyze_path.read_text())
    except json.JSONDecodeError as exc:
        summary_rows.append([
            workload,
            ui.status_text("UNKNOWN"),
            ui.status_text("UNKNOWN"),
            ui.status_text("UNKNOWN"),
            ui.status_text("UNKNOWN"),
            ui.status_text("UNKNOWN"),
            ui.status_text("FAIL"),
            f"invalid analyze.json: {exc}",
        ])
        overall_bad = True
        continue

    items = ((data.get("functional_tests") or {}).get("items") or {})
    row = [workload]
    fail_notes = []
    counts = {"PASS": 0, "FAIL": 0, "UNKNOWN": 0}

    for key in function_order:
        item = items.get(key) or {}
        status = str(item.get("status", "UNKNOWN")).upper()
        if status not in counts:
            status = "UNKNOWN"
        counts[status] += 1
        if status == "FAIL":
            evidence = item.get("evidence") or []
            note = evidence[0] if evidence else item.get("notes", "") or function_labels[key]
            fail_notes.append(f"{function_labels[key]}: {note}")
        row.append(ui.status_text(status))

    if counts["FAIL"] > 0:
        overall = "FAIL"
        overall_bad = True
    elif counts["UNKNOWN"] > 0:
        overall = "UNKNOWN"
        overall_bad = True
    else:
        overall = "PASS"

    notes = "; ".join(fail_notes[:2]) if fail_notes else f"PASS={counts['PASS']} FAIL={counts['FAIL']} UNKNOWN={counts['UNKNOWN']}"
    row.extend([ui.status_text(overall), notes])
    summary_rows.append(row)

ui.title("Functional Check Summary")
ui.key_values([
    ("results_root", ui.compress_path(str(results_root))),
    ("scan_suffix", suffix),
    ("run_dirs", str(len(run_dirs))),
], key_width=12)
ui.table(
    ["workload", "资源", "初始化", "执行", "结果", "异常", "overall", "notes"],
    summary_rows,
)

raise SystemExit(1 if overall_bad else 0)
PY
}

workload="${1:-}"
if [[ -z "$workload" ]]; then
  usage
  exit 1
fi

if [[ "$workload" == "all" ]]; then
  run_all_checks
  exit $?
fi

run_single_check "$workload"
