#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
CONFIG_FILE="${GEM5_WORKLOAD_CONFIG:-${SCRIPT_DIR}/gem5_workloads.json}"
GEM5_TEST="${GEM5_TEST_SH:-${SCRIPT_DIR}/gem5_test.sh}"

usage() {
  cat <<'EOF'
Usage:
  gem5_workload_runner.sh list
  gem5_workload_runner.sh discover
  gem5_workload_runner.sh run <workload> [run_tag] [extra config args...]
  gem5_workload_runner.sh analyze <workload> <run_tag>
  gem5_workload_runner.sh check <workload> <run_tag> [low high]
  gem5_workload_runner.sh all <workload> [run_tag] [low high] [extra config args...]

Notes:
  - run_tag defaults to current time: YYYYMMDD-HHMMSS
  - run_dir = <base_run_root>/<workload>-<run_tag>
  - analyze reads <run_dir>/lat_run_out/seq_lat_stats_*.txt
  - check prints PASS/FAIL/UNKNOWN for ldst_mean and functional_tests (non-fatal)
  - Edit JSON only; avoid hardcoding args in commands.
EOF
}

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "config not found: $CONFIG_FILE"
  exit 1
fi

get_json() {
  local py_expr="$1"
  python3 - "$CONFIG_FILE" "$py_expr" <<'PY'
import json
import sys

cfg = json.load(open(sys.argv[1], "r"))
expr = sys.argv[2]
val = eval(expr, {}, {"cfg": cfg})
if val is None:
    print("")
elif isinstance(val, (dict, list)):
    print(json.dumps(val))
else:
    print(str(val))
PY
}

workload_exists() {
  local name="$1"
  python3 - "$CONFIG_FILE" "$name" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1], "r"))
name = sys.argv[2]
sys.exit(0 if name in cfg.get("workloads", {}) else 1)
PY
}

list_workloads() {
  python3 - "$CONFIG_FILE" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1], "r"))
keys = sorted(cfg.get("workloads", {}).keys())
isatty = sys.stdout.isatty()

def c(s, code):
    if not isatty:
        return s
    return f"\033[{code}m{s}\033[0m"

groups = {
    "core": [],
    "pannotia": [],
    "rodinia": [],
    "other": [],
}

for k in keys:
    if k in {"square", "sleepMutex", "lfTreeBarrUniq", "hacc", "lulesh"}:
        groups["core"].append(k)
    elif k.startswith("pannotia-"):
        groups["pannotia"].append(k)
    elif k.startswith("rodinia-"):
        groups["rodinia"].append(k)
    else:
        groups["other"].append(k)

print(c("Workloads", "1;36"))
print(c("=" * 72, "36"))
print(f"total: {len(keys)}")

ordered = [("core", "Core"), ("pannotia", "Pannotia"), ("rodinia", "Rodinia"), ("other", "Other")]
for key, title in ordered:
    items = groups[key]
    if not items:
        continue
    print("")
    print(c(f"[{title}] ({len(items)})", "1;34"))
    for i, name in enumerate(items, start=1):
        print(f"  {i:>2}. {name}")
PY
}

discover_workloads() {
  python3 - "$CONFIG_FILE" "$REPO_ROOT" <<'PY'
import json
import os
import pathlib
import sys

cfg = json.load(open(sys.argv[1], "r"))
repo_root = pathlib.Path(sys.argv[2])
resources = repo_root / "tests" / "gem5" / "resources"
configured = set((cfg.get("workloads") or {}).keys())
isatty = sys.stdout.isatty()

def c(s, code):
    if not isatty:
        return s
    return f"\033[{code}m{s}\033[0m"

def status_tag(name):
    return c("[configured]", "1;32") if name in configured else c("[new]", "1;33")

if not resources.exists():
    print(f"resources dir not found: {resources}")
    sys.exit(1)

core = []
pannotia = []
rodinia = []
other = []

# Common offline workloads.
for name in ["square", "sleepMutex", "lfTreeBarrUniq", "hacc", "lulesh"]:
    core.append(name)

# Pannotia bins.
pbin = resources / "gpu-pannotia" / "pannotia-bins"
if pbin.exists():
    for f in sorted(pbin.glob("*.gem5")):
        pannotia.append(f"pannotia-auto:{f.stem}")

# Rodinia binaries.
rbin = resources / "rodinia_hip" / "bin"
if rbin.exists():
    skip = {"run.sh", "filelist.txt", "output.txt", "result.txt"}
    for f in sorted(rbin.iterdir()):
        if not f.is_file():
            continue
        if f.name in skip:
            continue
        if f.suffix in {".txt"}:
            continue
        rodinia.append(f"rodinia-auto:{f.name}")

# Any other top-level resource directories.
known_top = {"gpu-pannotia", "rodinia_hip", "square-gpu-test", "allSyncPrims-1kernel", "hacc-force-tree", "lulesh"}
for d in sorted(resources.iterdir()):
    if not d.is_dir():
        continue
    if d.name in known_top:
        continue
    other.append(f"resource-dir:{d.name}")

print(c("Discovered Heterogeneous Programs", "1;36"))
print(c("=" * 72, "36"))
print(f"resources: {resources}")
print(f"configured workloads in json: {len(configured)}")

def print_group(title, items):
    if not items:
        return
    print("")
    print(c(f"[{title}] ({len(items)})", "1;34"))
    for i, name in enumerate(items, start=1):
        mapped = name
        # Best-effort map for status: auto-discovered names do not always map 1:1.
        probe = name
        if name.startswith("rodinia-auto:"):
            probe = "rodinia-" + name.split(":", 1)[1].replace("+tree.out", "btree").replace("bfs.out", "bfs").replace("needle", "nw").replace("particlefilter_float", "particlefilter")
        elif name.startswith("pannotia-auto:"):
            probe = "pannotia-" + name.split(":", 1)[1]
        print(f"  {i:>2}. {mapped:<36} {status_tag(probe)}")

print_group("Core (known)", core)
print_group("Pannotia (from bins)", pannotia)
print_group("Rodinia (from bin)", rodinia)
print_group("Other Resource Dirs", other)
PY
}

build_run_dir() {
  local workload="$1"
  local run_tag="$2"
  local root
  root="$(get_json "cfg.get('base_run_root')")"
  if [[ "$root" != /* ]]; then
    root="${REPO_ROOT}/${root}"
  fi
  echo "${root}/${workload}-${run_tag}"
}

run_test() {
  local workload="$1"
  local run_tag="$2"
  local extra_config_args="${3:-}"
  local run_dir
  run_dir="$(build_run_dir "$workload" "$run_tag")"

  local gem5_opt_args config_args workload_args
  local global_config_args workload_config_args
  gem5_opt_args="$(get_json "cfg['workloads']['${workload}'].get('gem5_opt_args', cfg.get('gem5_opt_args', ''))")"
  global_config_args="$(get_json "cfg.get('config_args', '')")"
  workload_config_args="$(get_json "cfg['workloads']['${workload}'].get('config_args', '')")"
  config_args="$(echo "${global_config_args} ${workload_config_args}" | xargs)"
  workload_args="$(get_json "cfg['workloads']['${workload}'].get('workload_args', '')")"
  if [[ -n "$extra_config_args" ]]; then
    # Override semantics for short options like "-u 8" / "-n 4":
    # remove existing -u/-n from JSON config_args, then append user args.
    read -r -a base_arr <<< "$config_args"
    read -r -a extra_arr <<< "$extra_config_args"

    local rm_u=0 rm_n=0
    local i
    for ((i=0; i<${#extra_arr[@]}; i++)); do
      case "${extra_arr[$i]}" in
        -u|--num-compute-units) rm_u=1 ;;
        -n|--num-cpus) rm_n=1 ;;
      esac
    done

    local merged=()
    for ((i=0; i<${#base_arr[@]}; i++)); do
      local tok="${base_arr[$i]}"
      if (( rm_u )) && [[ "$tok" =~ ^-u[0-9]+$ ]]; then
        continue
      fi
      if (( rm_n )) && [[ "$tok" =~ ^-n[0-9]+$ ]]; then
        continue
      fi
      if (( rm_u )) && [[ "$tok" == "-u" || "$tok" == "--num-compute-units" ]]; then
        ((i++))
        continue
      fi
      if (( rm_n )) && [[ "$tok" == "-n" || "$tok" == "--num-cpus" ]]; then
        ((i++))
        continue
      fi
      merged+=("$tok")
    done
    merged+=("${extra_arr[@]}")
    config_args="${merged[*]}"
  fi

  echo "run_dir=${run_dir}"
  "$GEM5_TEST" test \
    --run-dir "$run_dir" \
    --gem5-opt-args "$gem5_opt_args" \
    --config-args "$config_args" \
    --workload-args "$workload_args"
}

run_analyze() {
  local workload="$1"
  local run_tag="$2"
  local run_dir
  run_dir="$(build_run_dir "$workload" "$run_tag")"
  "$GEM5_TEST" analyze "$run_dir"
}

run_check() {
  local workload="$1"
  local run_tag="$2"
  local low="${3:-100}"
  local high="${4:-150}"
  local run_dir
  run_dir="$(build_run_dir "$workload" "$run_tag")"
  "$GEM5_TEST" check "$run_dir" "$low" "$high"
}

cmd="${1:-}"
case "$cmd" in
  list)
    list_workloads
    ;;
  discover)
    discover_workloads
    ;;
  run|analyze|check|all)
    workload="${2:-}"
    if [[ -z "$workload" ]]; then
      usage
      exit 1
    fi
    if ! workload_exists "$workload"; then
      echo "unknown workload: $workload"
      echo "available:"
      list_workloads
      exit 1
    fi
    run_tag="${3:-$(date +%Y%m%d-%H%M%S)}"
    if [[ "$cmd" == "run" ]]; then
      extra_config_args="${*:4}"
      run_test "$workload" "$run_tag" "$extra_config_args"
    elif [[ "$cmd" == "analyze" ]]; then
      run_analyze "$workload" "$run_tag"
    elif [[ "$cmd" == "check" ]]; then
      run_check "$workload" "$run_tag" "${4:-100}" "${5:-150}"
    else
      low="${4:-100}"
      high="${5:-150}"
      extra_config_args="${*:6}"
      run_test "$workload" "$run_tag" "$extra_config_args"
      run_analyze "$workload" "$run_tag"
      run_check "$workload" "$run_tag" "$low" "$high"
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac
