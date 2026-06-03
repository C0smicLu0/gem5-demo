#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
ORIG_PWD="$PWD"
cd "${REPO_ROOT}"

set -e

DEFAULT_GEM5_OPT_ARGS="-re"
DEFAULT_CONFIG_ARGS="--reg-alloc-policy=dynamic --l1d_size=512B --l1i_size=512B --l1d_assoc=2 --l1i_assoc=2 --l2_size=1KiB --l2_assoc=2 --l2-latency=50 --l2-hit-latency=18 --cpu-to-dir-latency=120 --recycle-latency=10 --l3-data-latency=20 --l3-tag-latency=15 --num-tbes=256 --num-subcaches=4 --network=garnet --router-latency=1 --link-latency=1 -n3 -u237"
DEFAULT_WORKLOAD_ARGS="--download-resource square-gpu-test --download-resource-version 1.0.0 --download-dir /gem5/tests/gem5/resources -c /gem5/tests/gem5/resources/square-gpu-test-1.0.0"

split_shell_words() {
  local input="$1"
  local -n out_ref="$2"
  out_ref=()

  mapfile -d '' -t out_ref < <(
    python3 - "$input" <<'PY'
import shlex
import sys

for token in shlex.split(sys.argv[1]):
    sys.stdout.buffer.write(token.encode("utf-8"))
    sys.stdout.buffer.write(b"\0")
PY
  )
}

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
  local -a gem5_opt_args_arr=()
  local -a config_args_arr=()
  local -a workload_args_arr=()
  local -a full_cmd=()

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

  split_shell_words "$gem5_opt_extra" gem5_opt_args_arr
  split_shell_words "$config_args" config_args_arr
  split_shell_words "$workload_args" workload_args_arr

  full_cmd=(
    docker
    run
    "${docker_run_args[@]}"
    -u "$(id -u):$(id -g)"
    -v "${REPO_ROOT}:/gem5"
    -w /gem5
    ghcr.io/gem5/gcn-gpu:v25-1
    "${gem5_opt_bin}"
    -d "${run_dir_in_container}"
    "${gem5_opt_args_arr[@]}"
    "${config_py}"
    "${config_args_arr[@]}"
    "${workload_args_arr[@]}"
  )

  {
    echo "#!/bin/bash"
    echo "set -e"
    printf '%q ' "${full_cmd[@]}"
    echo
  } > "${run_dir}/run_cmd.sh"
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

run_latency_check() {
  local run_dir="$1"
  if [ -z "$run_dir" ]; then
    echo "usage: $0 latency_check <run_dir>"
    return 1
  fi
  run_dir="$(resolve_path "$run_dir")"
  python3 "${SCRIPT_DIR}/check_report.py" --mode latency --run-dir "${run_dir}"
}
run_functional_check() {
  local run_dir="$1"
  if [ -z "$run_dir" ]; then
    echo "usage: $0 functional_check <run_dir>"
    return 1
  fi
  run_dir="$(resolve_path "$run_dir")"
  python3 "${SCRIPT_DIR}/check_report.py" --mode functional --run-dir "${run_dir}"
}
run_check() {
  local run_dir="$1"
  if [ -z "$run_dir" ]; then
    echo "usage: $0 check <run_dir>"
    return 1
  fi
  run_dir="$(resolve_path "$run_dir")"
  python3 "${SCRIPT_DIR}/check_report.py" --mode check --run-dir "${run_dir}"
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
  functional_check)
    run_functional_check "${2:-}"
    ;;
  latency_check)
    run_latency_check "${2:-}"
    ;;
  check)
    run_check "${2:-}"
    ;;
  *)
    echo "usage: $0 {list|test|analyze|functional_check|latency_check|check} ..."
    exit 1
    ;;
esac
