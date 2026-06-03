#!/usr/bin/env bash

set -euo pipefail

DOCKER_IMAGE="${DOCKER_IMAGE:-ghcr.io/gem5/gcn-gpu:v25-1}"
CONTAINER_NAME="${CONTAINER_NAME:-rodinia-hip-build}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
RODINIA_ROOT="${RODINIA_ROOT:-${SCRIPT_DIR}}"
WORKDIR_IN_DOCKER="${WORKDIR_IN_DOCKER:-/workspace/rodinia_hip}"
GEM5_ROOT_HOST_DEFAULT="$(cd "${RODINIA_ROOT}/.." >/dev/null 2>&1 && pwd)"
GEM5_ROOT_HOST="${GEM5_ROOT_HOST:-${GEM5_ROOT_HOST_DEFAULT}}"
GEM5_ROOT_IN_DOCKER="${GEM5_ROOT_IN_DOCKER:-/workspace/gem5}"

# 默认使用 hip_mod 版本
RODINIA_TREE="${RODINIA_TREE:-hip_mod}"

ARG="${1:-${RODINIA_TREE}}"

resolve_target_rel() {
    local workload="$1"

    case "$workload" in
        rodinia-btree|btree|b+tree)
            echo "${RODINIA_TREE}/b+tree"
            ;;
        rodinia-bfs|bfs)
            echo "${RODINIA_TREE}/bfs"
            ;;
        rodinia-dwt2d|dwt2d)
            echo "${RODINIA_TREE}/dwt2d"
            ;;
        rodinia-gaussian|gaussian)
            echo "${RODINIA_TREE}/gaussian"
            ;;
        rodinia-hotspot|hotspot)
            echo "${RODINIA_TREE}/hotspot"
            ;;
        rodinia-lavaMD|lavaMD)
            echo "${RODINIA_TREE}/lavaMD"
            ;;
        rodinia-nw|nw)
            echo "${RODINIA_TREE}/nw"
            ;;
        rodinia-particlefilter|particlefilter)
            echo "${RODINIA_TREE}/particlefilter"
            ;;
        rodinia-pathfinder|pathfinder)
            echo "${RODINIA_TREE}/pathfinder"
            ;;

        # 仍然兼容直接传路径
        hip|hip_mod|hip/*|hip_mod/*)
            echo "$workload"
            ;;

        *)
            return 1
            ;;
    esac
}

if ! TARGET_REL="$(resolve_target_rel "$ARG")"; then
    echo "error: unsupported workload or target: $ARG" >&2
    echo "usage:" >&2
    echo "  $0 rodinia-nw" >&2
    echo "  $0 rodinia-bfs" >&2
    echo "  $0 rodinia-gaussian" >&2
    echo "  $0 hip_mod" >&2
    echo "  $0 hip_mod/nw" >&2
    exit 1
fi

TARGET_TOP_REL="${TARGET_REL%%/*}"
TARGET_IN_DOCKER="${WORKDIR_IN_DOCKER}/${TARGET_REL}"
BIN_IN_DOCKER="${WORKDIR_IN_DOCKER}/${TARGET_TOP_REL}/bin"
HOST_BIN_OUT="${RODINIA_ROOT}/${TARGET_TOP_REL}/bin"

if ! command -v docker >/dev/null 2>&1; then
    echo "error: docker is not available in PATH" >&2
    exit 1
fi

if [[ ! -d "${RODINIA_ROOT}" ]]; then
    echo "error: RODINIA_ROOT does not exist: ${RODINIA_ROOT}" >&2
    exit 1
fi

if [[ ! -d "${RODINIA_ROOT}/${TARGET_REL}" ]]; then
    echo "error: target directory does not exist: ${RODINIA_ROOT}/${TARGET_REL}" >&2
    exit 1
fi

if [[ ! -d "${GEM5_ROOT_HOST}" ]]; then
    echo "error: GEM5_ROOT_HOST does not exist: ${GEM5_ROOT_HOST}" >&2
    exit 1
fi

if [[ ! -f "${GEM5_ROOT_HOST}/include/gem5/m5ops.h" ]]; then
    echo "warning: GEM5_ROOT_HOST does not look like a gem5 tree: ${GEM5_ROOT_HOST}" >&2
fi

echo "docker image: ${DOCKER_IMAGE}"
echo "container name: ${CONTAINER_NAME}"
echo "rodinia root: ${RODINIA_ROOT}"
echo "workdir in docker: ${WORKDIR_IN_DOCKER}"
echo "gem5 root host: ${GEM5_ROOT_HOST}"
echo "gem5 root in docker: ${GEM5_ROOT_IN_DOCKER}"
echo "input target: ${ARG}"
echo "resolved target: ${TARGET_REL}"
echo "bin output: ${HOST_BIN_OUT}"

INNER_SCRIPT=$(sed -e 's|{{TARGET_IN_DOCKER}}|'"${TARGET_IN_DOCKER}"'|g' \
    -e 's|{{BIN_IN_DOCKER}}|'"${BIN_IN_DOCKER}"'|g' \
    -e 's|{{TARGET_REL_BASENAME}}|'"${TARGET_REL##*/}"'|g' \
    -e 's|{{TARGET_REL}}|'"${TARGET_REL}"'|g' \
    <<'DOCKER_SCRIPT'
set -u

cd "{{TARGET_IN_DOCKER}}"

echo "[docker] ROCM_PATH=${ROCM_PATH}"
echo "[docker] GEM5_ROOT=${GEM5_ROOT:-}"
echo "[docker] compiling: {{TARGET_IN_DOCKER}}"

total=0
success=0
failed=0
failed_list=""

BIN_DIR="{{BIN_IN_DOCKER}}"
mkdir -p "${BIN_DIR}"

collect_bins() {
  local workdir="$1"
  local workload="$2"

  while IFS= read -r exe; do
    [ -n "$exe" ] || continue

    if file -b "$exe" | grep -q "ELF"; then
      local base out
      base="$(basename "$exe")"
      out="${BIN_DIR}/${base}"
      cp -f "$exe" "$out"
      echo "[collect] ${workload}: ${exe} -> ${out}"
    fi
  done < <(find "$workdir" -maxdepth 3 -type f -perm -111 \
           ! -name '*.sh' ! -name 'run' ! -name '*.py')
}

build_one_dir() {
  local d="$1"
  local label="$2"

  if [ -f "$d/Makefile" ] || [ -f "$d/makefile" ]; then
    total=$((total+1))

    printf "======================================\n%s\n======================================\n" "$label"

    if ( cd "$d" && { make clean || true; } && make ); then
      success=$((success+1))
      collect_bins "$d" "$label"
      echo "[build] $label : SUCCESS"
    else
      failed=$((failed+1))
      failed_list="${failed_list} $label"
      echo "[build] $label : FAILED"
    fi

    return 0
  fi

  return 1
}

# 编译目标目录本身
build_one_dir "." "{{TARGET_REL_BASENAME}}" || true

# 兼容目标目录下还有子目录 Makefile 的情况
for d in */ ; do
  [ -d "$d" ] || continue
  [ "$d" = "bin/" ] && continue
  build_one_dir "$d" "${d%/}" || true
done

bin_count=$(find "${BIN_DIR}" -maxdepth 1 -type f | wc -l)

if [ "$total" -gt 0 ]; then
  success_pct=$((100 * success / total))
else
  success_pct=0
fi

echo
echo "==================== Build Summary ===================="
echo "Target: {{TARGET_REL}}"
echo "Total workloads:   $total"
echo "Successful:        $success"
echo "Failed:            $failed"
echo "Success rate:      ${success_pct}%"
echo "Binaries staged:   $bin_count"
echo "Bin directory:     ${BIN_DIR}"
if [ "$failed" -gt 0 ]; then
  echo "Failed workloads:  $failed_list"
fi
echo "======================================================="

if [ "$failed" -gt 0 ]; then
  exit 1
fi
DOCKER_SCRIPT
)

printf '%s\n' "$INNER_SCRIPT" | docker run --rm -i \
    --name "${CONTAINER_NAME}" \
    -u "$(id -u):$(id -g)" \
    -v "${RODINIA_ROOT}:${WORKDIR_IN_DOCKER}" \
    -v "${GEM5_ROOT_HOST}:${GEM5_ROOT_IN_DOCKER}:ro" \
    -w "${WORKDIR_IN_DOCKER}" \
    -e ROCM_PATH="${ROCM_PATH:-/opt/rocm}" \
    -e GEM5_ROOT="${GEM5_ROOT_IN_DOCKER}" \
    "${DOCKER_IMAGE}" \
    bash -s

echo "[host] build finished"
echo "[host] binaries are in: ${HOST_BIN_OUT}"
