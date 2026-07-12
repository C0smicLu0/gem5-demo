#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CONFIG_FILE="${GEM5_WORKLOAD_CONFIG:-${SCRIPT_DIR}/gem5_workloads.json}"
SECTION="${1:-value}"

usage() {
  cat <<'USAGE'
Usage:
  ./config_show.sh value
  ./config_show.sh cores
  ./config_show.sh all

Notes:
  - value: common system parameters, cache/timing/memory/network style flags
  - cores: config_profiles.cores contents
  - all: print both sections
USAGE
}

if [[ "$SECTION" == "-h" || "$SECTION" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "config not found: $CONFIG_FILE" >&2
  exit 1
fi

python3 - "$SCRIPT_DIR" "$CONFIG_FILE" "$SECTION" <<'PY'
import json
import shlex
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
import terminal_ui as ui

config_path = Path(sys.argv[2])
section = sys.argv[3]
cfg = json.loads(config_path.read_text())

if section not in {"value", "cores", "all"}:
    print(f"unknown section: {section}", file=sys.stderr)
    print("allowed: value, cores, all", file=sys.stderr)
    raise SystemExit(1)

DEFAULT_CONFIG_ARGS = "--reg-alloc-policy=dynamic --l1d_size=512B --l1i_size=512B --l1d_assoc=2 --l1i_assoc=2 --l2_size=1KiB --l2_assoc=2 --l2-latency=50 --l2-hit-latency=18 --cpu-to-dir-latency=120 --recycle-latency=10 --l3-data-latency=20 --l3-tag-latency=15 --num-tbes=256 --num-subcaches=4 --network=garnet --router-latency=1 --link-latency=1 -n3 -u237"

VALUE_KEYS = [
    "--mem-size",
    "--reg-alloc-policy",
    "--stats-dump-mode",
    "--l1d_size",
    "--l1i_size",
    "--l1d_assoc",
    "--l1i_assoc",
    "--l2_size",
    "--l2_assoc",
    "--l2-latency",
    "--l2-hit-latency",
    "--cpu-to-dir-latency",
    "--recycle-latency",
    "--l3-data-latency",
    "--l3-tag-latency",
    "--num-tbes",
    "--num-subcaches",
    "--network",
    "--router-latency",
    "--link-latency",
    "-n",
    "--num-cpus",
    "-u",
    "--num-compute-units",
]

VALUE_LABELS = {
    "--mem-size": "memory size",
    "--reg-alloc-policy": "register allocation",
    "--stats-dump-mode": "stats dump mode",
    "--l1d_size": "L1D size",
    "--l1i_size": "L1I size",
    "--l1d_assoc": "L1D associativity",
    "--l1i_assoc": "L1I associativity",
    "--l2_size": "L2 size",
    "--l2_assoc": "L2 associativity",
    "--l2-latency": "L2 latency",
    "--l2-hit-latency": "L2 hit latency",
    "--cpu-to-dir-latency": "CPU to dir latency",
    "--recycle-latency": "recycle latency",
    "--l3-data-latency": "L3 data latency",
    "--l3-tag-latency": "L3 tag latency",
    "--num-tbes": "TBEs",
    "--num-subcaches": "subcaches",
    "--network": "network",
    "--router-latency": "router latency",
    "--link-latency": "link latency",
    "-n": "CPU count",
    "--num-cpus": "CPU count",
    "-u": "GPU CU count",
    "--num-compute-units": "GPU CU count",
}


def parse_flags(arg_string):
    try:
        tokens = shlex.split(arg_string or "")
    except ValueError:
        return []
    rows = []
    idx = 0
    while idx < len(tokens):
        token = tokens[idx]
        key = token
        value = ""
        if token.startswith("--") and "=" in token:
            key, value = token.split("=", 1)
        elif token.startswith("-") and not token.startswith("--") and len(token) > 2:
            key, value = token[:2], token[2:]
        elif token.startswith("-") and idx + 1 < len(tokens) and not tokens[idx + 1].startswith("-"):
            value = tokens[idx + 1]
            idx += 1
        rows.append((key, value))
        idx += 1
    return rows


def merge_last_value(flags):
    merged = {}
    for key, value in flags:
        merged[key] = value
    return merged


def show_header(title):
    ui.title(title)
    ui.key_values([
        ("config", ui.compress_path(str(config_path))),
        ("section", section),
    ], key_width=8)


def show_value_section():
    show_header("Config Values")

    global_flags = merge_last_value(parse_flags(cfg.get("config_args", "")))
    default_flags = merge_last_value(parse_flags(DEFAULT_CONFIG_ARGS))
    pressure = cfg.get("config_profiles", {}).get("pressure", {})

    profile_names = [name for name in ["default", "mild", "aggressive"] if name in pressure]
    profile_flags = {name: merge_last_value(parse_flags(pressure[name])) for name in profile_names}

    rows = []
    for key in VALUE_KEYS:
        label = VALUE_LABELS.get(key, key)
        value = global_flags.get(key, "") or default_flags.get(key, "") or "-"
        rows.append([label, key, value])

    ui.table(["name", "flag", "value"], rows)


def show_cores_section():
    show_header("Core Profiles")

    cores = cfg.get("config_profiles", {}).get("cores", {})
    rows = []
    for name in sorted(cores):
        merged = merge_last_value(parse_flags(cores[name]))
        rows.append([
            name,
            merged.get("-n", merged.get("--num-cpus", "-")) or "-",
            merged.get("-u", merged.get("--num-compute-units", "-")) or "-",
            cores[name],
        ])

    ui.section("cores.*")
    if rows:
        ui.table(["profile", "cpus", "gpu_cus", "raw"], rows)
    else:
        print("(none)")

if section in {"value", "all"}:
    show_value_section()
if section in {"cores", "all"}:
    show_cores_section()
PY
