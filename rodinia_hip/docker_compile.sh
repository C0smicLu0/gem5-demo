#!/usr/bin/env bash

set -euo pipefail

DOCKER_IMAGE="${DOCKER_IMAGE:-ghcr.io/gem5/gcn-gpu:v25-1}"
CONTAINER_NAME="${CONTAINER_NAME:-rodinia-hip-build}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
RODINIA_ROOT="${RODINIA_ROOT:-${SCRIPT_DIR}}"
WORKDIR_IN_DOCKER="${WORKDIR_IN_DOCKER:-/workspace/rodinia_hip}"
TARGET_REL="${1:-hip_mod}"
TARGET_IN_DOCKER="${WORKDIR_IN_DOCKER}/${TARGET_REL}"

SYNC_BIN_DST="${SYNC_BIN_DST:-${SCRIPT_DIR}/../tests/gem5/resources/rodinia_hip/bin_mod}"

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
    echo "usage: $0 [target_rel_path]" >&2
    echo "example: $0 hip_mod" >&2
    echo "example: $0 hip" >&2
    exit 1
fi

echo "docker image: ${DOCKER_IMAGE}"
echo "container name: ${CONTAINER_NAME}"
echo "rodinia root: ${RODINIA_ROOT}"
echo "workdir in docker: ${WORKDIR_IN_DOCKER}"
echo "build target: ${TARGET_REL}"

INNER_SCRIPT=$(sed -e 's|{{TARGET_IN_DOCKER}}|'"${TARGET_IN_DOCKER}"'|g' \
    -e 's|{{TARGET_REL_BASENAME}}|'"${TARGET_REL##*/}"'|g' \
    -e 's|{{TARGET_REL}}|'"${TARGET_REL}"'|g' \
    <<'DOCKER_SCRIPT'
set -u
cd "{{TARGET_IN_DOCKER}}"

echo "[docker] ROCM_PATH=${ROCM_PATH}"
echo "[docker] compiling: {{TARGET_IN_DOCKER}}"

total=0
success=0
failed=0
failed_list=""

BIN_DIR="{{TARGET_IN_DOCKER}}/bin"
rm -rf "${BIN_DIR}"
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
      if [ -e "$out" ]; then
        out="${BIN_DIR}/${workload}__${base}"
      fi
      cp -f "$exe" "$out"
    fi
  done < <(find "$workdir" -maxdepth 3 -type f -perm -111 \
           ! -name '*.sh' ! -name 'run' ! -name '*.py')
}

build_one_dir() {
  local d="$1"
  local label="$2"
  if [ -f "$d/Makefile" ] || [ -f "$d/makefile" ]; then
    total=$((total+1))
    printf "======================================
%s
======================================
" "$label"
    if ( cd "$d" && make ); then
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

# Compile target directory itself if it has a Makefile.
build_one_dir "." "{{TARGET_REL_BASENAME}}" || true

for d in */ ; do
  [ -d "$d" ] || continue
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

echo "$INNER_SCRIPT" | docker run --rm -i \
    --name "${CONTAINER_NAME}" \
    -u "$(id -u):$(id -g)" \
    -v "${RODINIA_ROOT}:${WORKDIR_IN_DOCKER}" \
    -w "${WORKDIR_IN_DOCKER}" \
    -e ROCM_PATH="${ROCM_PATH:-/opt/rocm}" \
    "${DOCKER_IMAGE}" \
    bash -lc "$(cat)"


HOST_BIN_SRC="${RODINIA_ROOT}/${TARGET_REL}/bin"
if [[ -d "${HOST_BIN_SRC}" ]]; then
    mkdir -p "${SYNC_BIN_DST}"
    rm -rf "${SYNC_BIN_DST}"/*
    cp -a "${HOST_BIN_SRC}/." "${SYNC_BIN_DST}/"
    echo "[host] bin synced to: ${SYNC_BIN_DST}"
else
    echo "[host] warning: bin source not found, skip sync: ${HOST_BIN_SRC}" >&2
fi
