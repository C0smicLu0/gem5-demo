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
  gem5_workload_runner.sh compile <workload>
  gem5_workload_runner.sh run <workload> [run_tag] [--profile <name> ...]
  gem5_workload_runner.sh analyze <workload> <run_tag>
  gem5_workload_runner.sh check <workload> <run_tag> [low high]
  gem5_workload_runner.sh all <workload> [run_tag] [low high] [--profile <name> ...]

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

# 从 JSON 中读取表达式结果，统一作为脚本配置入口
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

# 检查给定的 workload 名称是否存在于 JSON 的 workloads 对象中
workload_exists() {
  local name="$1"
  python3 - "$CONFIG_FILE" "$name" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1], "r"))
name = sys.argv[2]
sys.exit(0 if name in cfg.get("workloads", {}) else 1)
PY
}

# 解析 profile（支持一层 key 和嵌套路径，如 pressure.mild / cores.args1）
profile_values() {
  local workload="$1"
  local profile="$2"
  python3 - "$CONFIG_FILE" "$workload" "$profile" <<'PY'
import json
import sys

cfg = json.load(open(sys.argv[1], "r"))
workload = sys.argv[2]
profile = sys.argv[3]

def lookup(d, key):
    if not isinstance(d, dict):
        return None
    if key in d:
        return d[key]
    cur = d
    for p in key.split("."):
        if isinstance(cur, dict) and p in cur:
            cur = cur[p]
        else:
            return None
    return cur

g = lookup(cfg.get("config_profiles", {}), profile)
w = lookup(cfg.get("workloads", {}).get(workload, {}).get("config_profiles", {}), profile)
if g is None and w is None:
    sys.exit(1)
print("" if g is None else str(g))
print("" if w is None else str(w))
PY
}

join_trim() {
  # 把多个片段拼接为单行参数串，并去掉多余空白
  echo "$*" | xargs
}

extract_num_cpus_from_config_args() {
  local cfg="$1"
  read -r -a arr <<< "$cfg"
  local i tok
  for ((i=0; i<${#arr[@]}; i++)); do
    tok="${arr[$i]}"
    if [[ "$tok" == "-n" || "$tok" == "--num-cpus" ]]; then
      if (( i + 1 < ${#arr[@]} )); then
        echo "${arr[$((i+1))]}"
        return 0
      fi
    elif [[ "$tok" =~ ^-n[0-9]+$ ]]; then
      echo "${tok#-n}"
      return 0
    elif [[ "$tok" == --num-cpus=* ]]; then
      echo "${tok#--num-cpus=}"
      return 0
    fi
  done
  echo ""
}

inject_mt_threads_into_workload_args() {
  local workload_args="$1"
  local num_cpus="$2"
  if [[ -z "$num_cpus" ]]; then
    echo "$workload_args"
    return 0
  fi

  python3 - "$workload_args" "$num_cpus" <<'PY2'
import shlex
import sys

workload_args = sys.argv[1]
num_cpus = sys.argv[2]

if not workload_args.strip():
    print(workload_args)
    sys.exit(0)

tokens = shlex.split(workload_args)

def rewrite_options(opt_str: str) -> str:
    opt_tokens = shlex.split(opt_str)
    out = []
    i = 0
    while i < len(opt_tokens):
        t = opt_tokens[i]
        if t == "--mt-cpu-threads":
            i += 2 if i + 1 < len(opt_tokens) else 1
            continue
        if t.startswith("--mt-cpu-threads="):
            i += 1
            continue
        out.append(t)
        i += 1
    out += ["--mt-cpu-threads", num_cpus]
    return shlex.join(out)

if "--options" in tokens:
    idx = tokens.index("--options")
    if idx + 1 < len(tokens):
        tokens[idx + 1] = rewrite_options(tokens[idx + 1])
    else:
        tokens += ["--mt-cpu-threads", num_cpus]
else:
    tokens += ["--options", shlex.join(["--mt-cpu-threads", num_cpus])]

print(shlex.join(tokens))
PY2
}

option_overridden() {
  # 判断某个 token 是否属于会被覆盖的关键选项（当前只处理 -u/-n 两组）
  local opt="$1"
  local tok="$2"
  case "$opt" in
    u)
      [[ "$tok" == "-u" || "$tok" == --num-compute-units || "$tok" =~ ^-u[0-9]+$ || "$tok" == --num-compute-units=* ]]
      ;;
    n)
      [[ "$tok" == "-n" || "$tok" == --num-cpus || "$tok" =~ ^-n[0-9]+$ || "$tok" == --num-cpus=* ]]
      ;;
    *)
      return 1
      ;;
  esac
}

merge_config_with_overrides() {
  # 按“override 覆盖 base”合并参数串：
  # 当 override 中出现 -u/-n 时，先从 base 删除对应旧值，再追加 override。
  local base="$1"
  local override="$2"
  if [[ -z "$override" ]]; then
    echo "$base"
    return 0
  fi

  read -r -a base_arr <<< "$base"
  read -r -a override_arr <<< "$override"
  local rm_u=0 rm_n=0
  local i

  for ((i=0; i<${#override_arr[@]}; i++)); do
    if option_overridden "u" "${override_arr[$i]}"; then
      rm_u=1
    fi
    if option_overridden "n" "${override_arr[$i]}"; then
      rm_n=1
    fi
  done

  local merged=()
  for ((i=0; i<${#base_arr[@]}; i++)); do
    local tok="${base_arr[$i]}"
    if (( rm_u )) && option_overridden "u" "$tok"; then
      if [[ "$tok" == "-u" || "$tok" == --num-compute-units ]]; then
        ((i++))
      fi
      continue
    fi
    if (( rm_n )) && option_overridden "n" "$tok"; then
      if [[ "$tok" == "-n" || "$tok" == --num-cpus ]]; then
        ((i++))
      fi
      continue
    fi
    merged+=("$tok")
  done
  merged+=("${override_arr[@]}")
  echo "${merged[*]}"
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

build_run_dir() {
  # 统一生成每次运行目录：<base_run_root>/<workload>-<run_tag>
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
  # config_args 采用拼接语义：global + workload + profiles（按输入顺序）
  local workload="$1"
  local run_tag="$2"
  local selected_profiles="${3:-}"
  local run_dir
  run_dir="$(build_run_dir "$workload" "$run_tag")"

  local gem5_opt_args config_args workload_args
  local global_config_args workload_config_args
  local global_profile_args workload_profile_args
  gem5_opt_args="$(get_json "cfg['workloads']['${workload}'].get('gem5_opt_args', cfg.get('gem5_opt_args', ''))")"
  global_config_args="$(get_json "cfg.get('config_args', '')")"
  workload_config_args="$(get_json "cfg['workloads']['${workload}'].get('config_args', '')")"
  global_profile_args=""
  workload_profile_args=""
  config_args="$(join_trim "${global_config_args}" "${workload_config_args}")"
  if [[ -n "$selected_profiles" ]]; then
    read -r -a prof_arr <<< "$selected_profiles"
    local p
    for p in "${prof_arr[@]}"; do
      local vals g_line w_line
      if ! vals="$(profile_values "$workload" "$p")"; then
        echo "unknown profile: $p"
        return 1
      fi
      g_line="$(echo "$vals" | sed -n '1p')"
      w_line="$(echo "$vals" | sed -n '2p')"
      global_profile_args="$(join_trim "${global_profile_args}" "${g_line}")"
      workload_profile_args="$(join_trim "${workload_profile_args}" "${w_line}")"
    done
  fi
  config_args="$(join_trim "${config_args}" "${global_profile_args}" "${workload_profile_args}")"
  workload_args="$(get_json "cfg['workloads']['${workload}'].get('workload_args', '')")"

  local cfg_num_cpus
  cfg_num_cpus="$(extract_num_cpus_from_config_args "$config_args")"
  if [[ "$workload" == rodinia-* && -n "$cfg_num_cpus" ]]; then
    workload_args="$(inject_mt_threads_into_workload_args "$workload_args" "$cfg_num_cpus")"
  fi

  echo "run_dir=${run_dir}"
  if [[ -n "$selected_profiles" ]]; then
    echo "profile=${selected_profiles}"
  fi
  echo "workload_args=${workload_args}"
  if [[ "$workload" == rodinia-* ]]; then
    echo "forwarded_mt_threads=${cfg_num_cpus:-unset} (as --mt-cpu-threads in --options)"
  fi
  "$GEM5_TEST" test \
    --run-dir "$run_dir" \
    --gem5-opt-args "$gem5_opt_args" \
    --config-args "$config_args" \
    --workload-args "$workload_args"
}

run_analyze() {
  # analyze/check 复用同一 run_dir 规则，确保与 run/all 对齐
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

rodinia_compile_target() {
  local workload="$1"
  case "$workload" in
    rodinia-btree) echo "hip_mod/b+tree" ;;
    rodinia-bfs) echo "hip_mod/bfs" ;;
    rodinia-dwt2d) echo "hip_mod/dwt2d" ;;
    rodinia-gaussian) echo "hip_mod/gaussian" ;;
    rodinia-hotspot) echo "hip_mod/hotspot" ;;
    rodinia-lavaMD) echo "hip_mod/lavaMD" ;;
    rodinia-nw) echo "hip_mod/nw" ;;
    rodinia-particlefilter) echo "hip_mod/particlefilter" ;;
    rodinia-pathfinder) echo "hip_mod/pathfinder" ;;
    *) return 1 ;;
  esac
}

run_compile() {
  local workload="$1"
  local compile_sh="${REPO_ROOT}/rodinia_hip/docker_compile.sh"
  if [[ ! -x "$compile_sh" ]]; then
    echo "compile script not found or not executable: $compile_sh"
    return 1
  fi

  local target=""
  if [[ "$workload" == rodinia-* ]]; then
    if ! target="$(rodinia_compile_target "$workload")"; then
      echo "unsupported rodinia workload for compile: $workload"
      return 1
    fi
  else
    echo "compile currently supports rodinia-* workloads only: $workload"
    return 1
  fi

  echo "compile_target=${target}"
  "$compile_sh" "$target"
}

cmd="${1:-}"
case "$cmd" in
  list)
    list_workloads
    ;;
  compile)
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
    run_compile "$workload"
    ;;
  run|analyze|check|all)
    # 统一入口校验：workload 必填且必须在 JSON 中存在
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
      # run: 仅执行测试
      profile_tokens=()
      if (( $# >= 4 )); then
        rem=("${@:4}")
        i=0
        while (( i < ${#rem[@]} )); do
          if [[ "${rem[$i]}" != "--profile" ]]; then
            echo "usage: $0 run <workload> [run_tag] [--profile <name> ...]"
            exit 1
          fi
          i=$((i + 1))
          if (( i >= ${#rem[@]} )); then
            echo "missing value for --profile"
            exit 1
          fi
          profile_tokens+=("${rem[$i]}")
          i=$((i + 1))
        done
      fi
      run_test "$workload" "$run_tag" "${profile_tokens[*]}"
    elif [[ "$cmd" == "analyze" ]]; then
      # analyze: 仅执行离线分析
      run_analyze "$workload" "$run_tag"
    elif [[ "$cmd" == "check" ]]; then
      # check: 仅做阈值检查（可自定义 low/high）
      run_check "$workload" "$run_tag" "${4:-100}" "${5:-150}"
    else
      # all: 顺序执行 run -> analyze -> check
      low="${4:-100}"
      high="${5:-150}"
      profile_tokens=()
      if (( $# >= 6 )); then
        rem=("${@:6}")
        i=0
        while (( i < ${#rem[@]} )); do
          if [[ "${rem[$i]}" != "--profile" ]]; then
            echo "usage: $0 all <workload> [run_tag] [low high] [--profile <name> ...]"
            exit 1
          fi
          i=$((i + 1))
          if (( i >= ${#rem[@]} )); then
            echo "missing value for --profile"
            exit 1
          fi
          profile_tokens+=("${rem[$i]}")
          i=$((i + 1))
        done
      fi
      run_test "$workload" "$run_tag" "${profile_tokens[*]}"
      run_analyze "$workload" "$run_tag"
      run_check "$workload" "$run_tag" "$low" "$high"
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac
