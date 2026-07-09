#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CONFIG_FILE="${GEM5_WORKLOAD_CONFIG:-${SCRIPT_DIR}/gem5_workloads.json}"
TARGET="${1:-all}"

usage() {
  cat <<'USAGE'
Usage:
  ./config_show.sh
  ./config_show.sh all
  ./config_show.sh <workload>

Notes:
  - reads test_scripts/gem5_workloads.json by default
  - shows global experiment config, config profiles, and workload definitions
USAGE
}

if [[ "$TARGET" == "-h" || "$TARGET" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "config not found: $CONFIG_FILE" >&2
  exit 1
fi

python3 - "$SCRIPT_DIR" "$CONFIG_FILE" "$TARGET" <<'PY'
import json
import sys
from pathlib import Path

# 读取配置文件路径
config_path = Path(sys.argv[2])
cfg = json.loads(config_path.read_text())

# 提取 pressure 配置集，如果不存在则返回空字典
pressure_profiles = cfg.get("config_profiles", {}).get("pressure", {})

# 只获取 "default" 配置集的原始字符串值
default_value = pressure_profiles.get("default", "(empty)")

# 直接打印原始值
print(default_value)
PY
