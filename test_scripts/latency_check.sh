#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
RESULTS_ROOT="${REPO_ROOT}/tests/testing-results"
VERSION_SUFFIX=".7.14"
export VERSION_SUFFIX

usage() {
  cat <<'USAGE'
Usage:
  ./latency_check.sh <workload>
  ./latency_check.sh all

Notes:
  - scans gem5-demo/tests/testing-results
  - only directories whose names end with args1..args5 are considered
  - latency value is weighted ldst mean from analyze.json
  - <= 150 is green, > 150 is red
USAGE
}

list_run_dirs() {
  python3 - "$RESULTS_ROOT" <<'PY'
import os
import re
import sys

root = sys.argv[1]
suffix = re.escape(os.environ.get("VERSION_SUFFIX", ""))
pattern = re.compile(rf"args[1-5]{suffix}$")

if not os.path.isdir(root):
    raise SystemExit(0)

for entry in sorted(os.listdir(root)):
    path = os.path.join(root, entry)
    if os.path.isdir(path) and pattern.search(entry):
        print(entry)
PY
}

list_workloads() {
  python3 - "$RESULTS_ROOT" <<'PY'
import os
import re
import sys

root = sys.argv[1]
suffix = re.escape(os.environ.get("VERSION_SUFFIX", ""))
pattern = re.compile(rf"^(.*)-(.*args([1-5]){suffix})$")
seen = []

if not os.path.isdir(root):
    raise SystemExit(0)

for entry in sorted(os.listdir(root)):
    path = os.path.join(root, entry)
    if not os.path.isdir(path):
        continue
    match = pattern.match(entry)
    if not match:
        continue
    workload = match.group(1)
    if workload not in seen:
        seen.append(workload)

for workload in seen:
    print(workload)
PY
}

resolve_run_dirs() {
  local workload="$1"
  python3 - "$RESULTS_ROOT" "$workload" <<'PY'
import os
import re
import sys

root = sys.argv[1]
workload = sys.argv[2]
suffix = re.escape(os.environ.get("VERSION_SUFFIX", ""))
pattern = re.compile(rf"^(.*)-(.*args([1-5]){suffix})$")
rows = []

if os.path.isdir(root):
    for entry in sorted(os.listdir(root)):
        path = os.path.join(root, entry)
        if not os.path.isdir(path):
            continue
        match = pattern.match(entry)
        if not match:
            continue
        if match.group(1) == workload:
            rows.append(entry)

for row in rows:
    print(row)
PY
}

run_table() {
  local scope="$1"
  shift

  python3 - "$SCRIPT_DIR" "$RESULTS_ROOT" "$scope" "$@" <<'PY'
import re
import os
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, sys.argv[1])
import check_report
import terminal_ui as ui

results_root = Path(sys.argv[2])
scope = sys.argv[3]
run_names = sys.argv[4:]
suffix = re.escape(os.environ.get("VERSION_SUFFIX", ""))
pattern = re.compile(rf"^(.*)-(.*?(args([1-5])){suffix})$")
arg_order = ["args1", "args2", "args3", "args4", "args5"]

by_workload = defaultdict(dict)
overall_bad = False

for run_name in run_names:
    match = pattern.match(run_name)
    if not match:
        continue
    workload = match.group(1)
    arg_key = f"args{match.group(4)}"
    run_dir = results_root / run_name
    data, analyze_path, rc = check_report.load_json(run_dir)

    if rc != 0 or data is None:
        by_workload[workload][arg_key] = ui.style("missing", "yellow")
        overall_bad = True
        continue

    mean, samples = check_report.weighted_ldst_metric(data)
    if mean is None:
        by_workload[workload][arg_key] = ui.style("missing", "yellow")
        overall_bad = True
    else:
        color = "green" if mean <= check_report.THRESHOLD else "red"
        by_workload[workload][arg_key] = ui.style(f"{mean:.6f}", color)
        if mean > check_report.THRESHOLD:
            overall_bad = True

rows = []
for workload in sorted(by_workload):
    row = [workload]
    for arg_key in arg_order:
        row.append(by_workload[workload].get(arg_key, ui.style("-", "dim")))
    rows.append(row)

ui.title("Latency Check Summary")
ui.key_values([
    ("results_root", ui.compress_path(str(results_root))),
    ("scope", scope),
    ("workloads", str(len(rows))),
    ("threshold", f"<= {check_report.THRESHOLD:.3f}"),
], key_width=12)
ui.table(["workload", *arg_order], rows)

raise SystemExit(1 if overall_bad else 0)
PY
}

target="${1:-}"
if [[ -z "$target" ]]; then
  usage
  exit 1
fi

if [[ "$target" == "all" ]]; then
  mapfile -t run_dirs < <(list_run_dirs)
  if (( ${#run_dirs[@]} == 0 )); then
    echo "no workloads found under ${RESULTS_ROOT} matching *args[1-5]" >&2
    exit 1
  fi
  run_table all "${run_dirs[@]}"
  exit $?
fi

mapfile -t run_dirs < <(resolve_run_dirs "$target")
if (( ${#run_dirs[@]} == 0 )); then
  echo "latency_check input not found for workload: $target" >&2
  echo "expected directory pattern: ${RESULTS_ROOT}/${target}-*args[1-5]" >&2
  echo "available workloads from testing-results:" >&2
  list_workloads >&2
  exit 1
fi

run_table "$target" "${run_dirs[@]}"
