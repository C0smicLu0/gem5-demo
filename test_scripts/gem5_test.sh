#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
ORIG_PWD="$PWD"
cd "${REPO_ROOT}"

set -e

DEFAULT_GEM5_OPT_ARGS="-re"
DEFAULT_CONFIG_ARGS="--reg-alloc-policy=dynamic --l1d_size=512B --l1i_size=512B --l1d_assoc=2 --l1i_assoc=2 --l2_size=1KiB --l2_assoc=2 --l2-latency=50 --l2-hit-latency=18 --cpu-to-dir-latency=120 --recycle-latency=10 --l3-data-latency=20 --l3-tag-latency=15 --num-tbes=256 --num-subcaches=4 --network=garnet --router-latency=1 --link-latency=1 -n3 -u237"
DEFAULT_WORKLOAD_ARGS="--download-resource square-gpu-test --download-resource-version 1.0.0 --download-dir /gem5/tests/gem5/resources -c /gem5/tests/gem5/resources/square-gpu-test-1.0.0"

resolve_path() {
  local input="$1"
  if [ -z "$input" ]; then
    echo ""
    return 0
  fi
  if [[ "$input" = /* ]]; then
    echo "$input"
  else
    echo "${ORIG_PWD}/${input}"
  fi
}

extract_run_dir() {
  local run_dir=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --run-dir) run_dir="$2"; shift 2 ;;
      --gem5-opt-bin|--config-py|--gem5-opt-args|--config-args|--workload-args) shift 2 ;;
      *) echo "unknown arg: $1"; return 1 ;;
    esac
  done
  if [ -z "$run_dir" ]; then
    echo "usage: $0 test --run-dir <abs_run_dir> [--gem5-opt-bin ...] [--config-py ...] [--gem5-opt-args \"...\"] [--config-args \"...\"] [--workload-args \"...\"]"
    return 1
  fi
  resolve_path "$run_dir"
}

build_run_cmd() {
  local run_dir=""
  local gem5_opt_bin="/gem5/build/VEGA_X86/gem5.opt"
  local config_py="/gem5/configs/example/apu_se.py"
  local gem5_opt_extra="$DEFAULT_GEM5_OPT_ARGS"
  local config_args="$DEFAULT_CONFIG_ARGS"
  local workload_args="$DEFAULT_WORKLOAD_ARGS"

  while [ $# -gt 0 ]; do
    case "$1" in
      --run-dir) run_dir="$2"; shift 2 ;;
      --gem5-opt-bin) gem5_opt_bin="$2"; shift 2 ;;
      --config-py) config_py="$2"; shift 2 ;;
      --gem5-opt-args) gem5_opt_extra="$2"; shift 2 ;;
      --config-args) config_args="$2"; shift 2 ;;
      --workload-args) workload_args="$2"; shift 2 ;;
      *) echo "unknown arg: $1"; return 1 ;;
    esac
  done

  if [ -z "$run_dir" ]; then
    echo "usage: $0 test --run-dir <abs_run_dir> [--gem5-opt-bin ...] [--config-py ...] [--gem5-opt-args \"...\"] [--config-args \"...\"] [--workload-args \"...\"]"
    return 1
  fi
  run_dir="$(resolve_path "$run_dir")"

  mkdir -p "$run_dir"

  local run_dir_in_container="${run_dir/$REPO_ROOT/\/gem5}"
  if [ "$run_dir_in_container" = "$run_dir" ]; then
    echo "run_dir must be under ${REPO_ROOT} so it maps to /gem5 in container"
    return 1
  fi

  local full_cmd="docker run ${docker_run_args[*]} -u $(id -u):$(id -g) -v ${REPO_ROOT}:/gem5 -w /gem5 ghcr.io/gem5/gcn-gpu:v25-1 ${gem5_opt_bin} -d ${run_dir_in_container} ${gem5_opt_extra} ${config_py} ${config_args} ${workload_args}"
  cat > "${run_dir}/run_cmd.sh" <<EOF
#!/bin/bash
set -e
${full_cmd}
EOF
  chmod +x "${run_dir}/run_cmd.sh"
}

run_test() {
  build_run_cmd "$@"
  local run_dir=""
  run_dir="$(extract_run_dir "$@")"
  set +e
  bash "${run_dir}/run_cmd.sh"
  local run_rc=$?
  set -e
  if [ $run_rc -ne 0 ]; then
    echo "test failed with exit code ${run_rc}"
    return $run_rc
  fi
}

run_analyze() {
  local run_dir="$1"
  if [ -z "$run_dir" ]; then
    echo "usage: $0 analyze <run_dir>"
    return 1
  fi
  run_dir="$(resolve_path "$run_dir")"
  if ! ls "${run_dir}/lat_run_out"/seq_lat_stats_*.txt >/dev/null 2>&1 && ! ls "${run_dir}/lat_run_out"/coal_lat_stats_*.txt >/dev/null 2>&1; then
    echo "analyze input not found: ${run_dir}/lat_run_out/{seq,coal}_lat_stats_*.txt"
    echo "hint: run with updated Sequencer/GPUCoalescer that writes lat_run_out first."
    return 1
  fi
  python3 "${SCRIPT_DIR}/analyze_log.py" \
    --run-dir "${run_dir}" \
    --output-md "${run_dir}/analyze.md" \
    --output-json "${run_dir}/analyze.json"
}

run_check() {
  local run_dir="$1"
  local check_low="${2:-100}"
  local check_high="${3:-150}"
  if [ -z "$run_dir" ]; then
    echo "usage: $0 check <run_dir> [low] [high]"
    return 1
  fi
  run_dir="$(resolve_path "$run_dir")"
  python3 - "${run_dir}/analyze.json" "${check_low}" "${check_high}" <<'PY'
import json
import math
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
low = float(sys.argv[2])
high = float(sys.argv[3])
data = json.loads(path.read_text())
cpu_ldst = data.get("cpu_ldst") or {}
gpu_ldst = data.get("gpu_ldst") or {}
ldst = data.get("ldst") or {}
cpu_mean = cpu_ldst.get("mean")
gpu_mean = gpu_ldst.get("mean")
ldst_mean = ldst.get("mean")

if ldst_mean is None:
    cpu_samples = cpu_ldst.get("samples") or 0
    gpu_samples = gpu_ldst.get("samples") or 0
    total_samples = cpu_samples + gpu_samples
    if total_samples > 0 and cpu_mean is not None and gpu_mean is not None:
        ldst_mean = (cpu_mean * cpu_samples + gpu_mean * gpu_samples) / total_samples
    elif total_samples > 0 and cpu_mean is not None and gpu_samples == 0:
        ldst_mean = cpu_mean
    elif total_samples > 0 and gpu_mean is not None and cpu_samples == 0:
        ldst_mean = gpu_mean

isatty = sys.stdout.isatty()
def c(s, code):
    if not isatty:
        return s
    return f"\033[{code}m{s}\033[0m"

def status_color(status):
    if status == "PASS":
        return c(status, "1;32")
    if status == "FAIL":
        return c(status, "1;31")
    return c(status, "1;33")

print(c("Check Summary", "1;36"))
print(c("=" * 72, "36"))
for metric_name, mean in (("cpu_ldst_mean", cpu_mean), ("gpu_ldst_mean", gpu_mean), ("ldst_mean", ldst_mean)):
    print(c(metric_name, "1;34"))
    if mean is None or (isinstance(mean, float) and math.isnan(mean)):
        print(f"  status: {status_color('UNKNOWN')}")
        print(f"  notes : {metric_name} is missing")
    else:
        in_range = (low <= mean <= high)
        status = "PASS" if in_range else "FAIL"
        print(f"  status: {status_color(status)}")
        print(f"  notes : value={mean:.6f}, range=[{low:.3f}, {high:.3f}]")

ft = data.get("functional_tests")
if ft:
    items = ft.get("items", {})
    if items:
        print("")
        print(c("functional_tests", "1;34"))
        for name in sorted(items.keys()):
            status = str(items[name].get("status", "UNKNOWN"))
            print(f"  {name:<28} {status_color(status)}")
PY
}

docker_run_args=("--rm")
if [ -t 0 ] && [ -t 1 ]; then
  docker_run_args+=("-it")
else
  docker_run_args+=("-i")
fi

case "${1:-}" in
  list)
    docker run "${docker_run_args[@]}" \
      -u $(id -u):$(id -g) \
      -v "$PWD:/gem5" \
      -w /gem5/tests \
      ghcr.io/gem5/gcn-gpu:v25-1 \
      ./main.py list --tests \
        --isa VEGA_X86 \
        --variant opt \
        --host gcn_gpu \
        gem5/gpu
    ;;
  test)
    shift
    run_test "$@"
    ;;
  analyze)
    run_analyze "${2:-}"
    ;;
  check)
    run_check "${2:-}" "${3:-}" "${4:-}"
    ;;
  *)
    echo "usage: $0 {list|test|analyze|check} ..."
    exit 1
    ;;
esac
