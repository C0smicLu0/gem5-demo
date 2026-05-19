# Pannotia CPU+GPU Full Managed Build And Run Commands

This directory is a git-trackable copy of the modified Pannotia source tree.
It is self-contained for the active Pannotia tests: BC, color MAX, color
MAXMIN, and MIS.

Run all commands from the gem5 repository root:

```bash
export GEM5_ROOT="$PWD"
export PANNOTIA_SRC="$GEM5_ROOT/tests/gem5/gpu/pannotia_modified_src/pannotia"
```

## Build

Use the GCN GPU Docker image from the host/WSL environment where Docker works:

```bash
docker run --rm \
  -v "$GEM5_ROOT":"$GEM5_ROOT" \
  -w "$PANNOTIA_SRC/bc" \
  ghcr.io/gem5/gcn-gpu:v25-1 \
  bash -lc "make -f Makefile.gem5-fusion clean && make -f Makefile.gem5-fusion GEM5_ROOT=$GEM5_ROOT"

docker run --rm \
  -v "$GEM5_ROOT":"$GEM5_ROOT" \
  -w "$PANNOTIA_SRC/color" \
  ghcr.io/gem5/gcn-gpu:v25-1 \
  bash -lc "make -f Makefile.gem5-fusion clean && make -f Makefile.gem5-fusion GEM5_ROOT=$GEM5_ROOT VARIANT=MAX && make -f Makefile.gem5-fusion GEM5_ROOT=$GEM5_ROOT VARIANT=MAXMIN"

docker run --rm \
  -v "$GEM5_ROOT":"$GEM5_ROOT" \
  -w "$PANNOTIA_SRC/mis" \
  ghcr.io/gem5/gcn-gpu:v25-1 \
  bash -lc "make -f Makefile.gem5-fusion clean && make -f Makefile.gem5-fusion GEM5_ROOT=$GEM5_ROOT"
```

Equivalent commands from inside an already-running `ghcr.io/gem5/gcn-gpu:v25-1`
container:

```bash
cd "$PANNOTIA_SRC/bc"
make -f Makefile.gem5-fusion clean
make -f Makefile.gem5-fusion GEM5_ROOT="$GEM5_ROOT"

cd "$PANNOTIA_SRC/color"
make -f Makefile.gem5-fusion clean
make -f Makefile.gem5-fusion GEM5_ROOT="$GEM5_ROOT" VARIANT=MAX
make -f Makefile.gem5-fusion GEM5_ROOT="$GEM5_ROOT" VARIANT=MAXMIN

cd "$PANNOTIA_SRC/mis"
make -f Makefile.gem5-fusion clean
make -f Makefile.gem5-fusion GEM5_ROOT="$GEM5_ROOT"
```

## Replace Test Binaries

```bash
mkdir -p "$GEM5_ROOT/tests/gem5/resources/gpu-pannotia/pannotia-bins"

cp "$PANNOTIA_SRC/bc/bin/bc.gem5" \
  "$GEM5_ROOT/tests/gem5/resources/gpu-pannotia/pannotia-bins/bc.gem5"

cp "$PANNOTIA_SRC/color/bin/color_max.gem5" \
  "$GEM5_ROOT/tests/gem5/resources/gpu-pannotia/pannotia-bins/color_max.gem5"

cp "$PANNOTIA_SRC/color/bin/color_maxmin.gem5" \
  "$GEM5_ROOT/tests/gem5/resources/gpu-pannotia/pannotia-bins/color_maxmin.gem5"

cp "$PANNOTIA_SRC/mis/bin/mis_hip.gem5" \
  "$GEM5_ROOT/tests/gem5/resources/gpu-pannotia/pannotia-bins/mis_hip.gem5"
```

## Run Manually

```bash
cd "$GEM5_ROOT"

build/VEGA_X86/gem5.opt configs/example/apu_se.py \
  -n8 --mem-size=8GB \
  -c tests/gem5/resources/gpu-pannotia/pannotia-bins/bc.gem5 \
  --options "tests/gem5/resources/gpu-pannotia/pannotia-datasets/1k_128k.gr --gpu-cus 16" \
  > bc_cpu_gpu.log 2>&1

build/VEGA_X86/gem5.opt configs/example/apu_se.py \
  -n8 --mem-size=8GB \
  -c tests/gem5/resources/gpu-pannotia/pannotia-bins/color_max.gem5 \
  --options "tests/gem5/resources/gpu-pannotia/pannotia-datasets/1k_128k.gr 0 --gpu-cus 16" \
  > color_max_cpu_gpu.log 2>&1

build/VEGA_X86/gem5.opt configs/example/apu_se.py \
  -n8 --mem-size=8GB \
  -c tests/gem5/resources/gpu-pannotia/pannotia-bins/color_maxmin.gem5 \
  --options "tests/gem5/resources/gpu-pannotia/pannotia-datasets/1k_128k.gr 0 --gpu-cus 16" \
  > color_maxmin_cpu_gpu.log 2>&1

build/VEGA_X86/gem5.opt configs/example/apu_se.py \
  -n8 --mem-size=8GiB \
  -c tests/gem5/resources/gpu-pannotia/pannotia-bins/mis_hip.gem5 \
  --options "tests/gem5/resources/gpu-pannotia/pannotia-datasets/1k_128k.gr 0 --gpu-cus 16" \
  > mis_cpu_gpu.log 2>&1
```

Add `--debug-log` inside `--options` when stage-level workload logs are needed.

Examples:

```bash
--options "tests/gem5/resources/gpu-pannotia/pannotia-datasets/1k_128k.gr --gpu-cus 16 --debug-log"
--options "tests/gem5/resources/gpu-pannotia/pannotia-datasets/1k_128k.gr 0 --gpu-cus 16 --debug-log"
```
