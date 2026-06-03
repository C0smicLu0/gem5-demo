# gem5 Cache Coherence Fusion Demo

This project is based on gem5 and demonstrates an extension to cache coherence protocols with **state fusion** and **granularity-adaptive fusion**.

The goal of this demo is to provide a reproducible build and test workflow for evaluating the proposed coherence protocol optimization in gem5.

## Overview

Modern cache coherence protocols may introduce significant state-management overhead, especially when handling complex sharing patterns and fine-grained memory accesses. This demo explores two optimization ideas:

- **State Fusion**  
  Combines compatible coherence states to reduce protocol complexity and improve state transition efficiency.

- **Granularity-Adaptive Fusion**  
  Dynamically adjusts the fusion granularity according to access behavior, allowing the protocol to adapt to different memory sharing patterns.

The implementation is integrated into gem5 and can be built and tested using the provided scripts.

## Docker

`demo_build.sh` and `demo_test.sh` use Docker.

When `demo_build.sh` runs on a native Linux host and `docker` is missing, it
will try to install Docker automatically and then continue the build. Under
WSL, the script does not auto-install Docker and instead points you to Docker
Desktop for Windows.

If Docker is not installed yet, print the official install guidance with:

```bash
bash download_docker.sh
```

You can also use the built-in help entry:

```bash
bash demo_build.sh --docker-help
bash demo_test.sh --docker-help
```

With this workspace under WSL, Docker Desktop for Windows with the WSL 2
backend is usually the simplest setup.

## Build

Build gem5 and the demo workloads:

```bash
bash demo_build.sh [--gem5-only] [--workload-only] \
  [--workloads-in-container] [--image IMAGE] \
  [--jobs N] [--pannotia BENCH]...
```

Common examples:

```bash
bash demo_build.sh --gem5-only
bash demo_build.sh --workload-only --workloads-in-container
```

`--workloads-in-container` is for the case where you are already inside a suitable
build environment and do not want the workload build scripts to launch Docker
again.

## Test

Run the default quick demo:

```bash
bash demo_test.sh [quick] [--run-tag TAG] [--debug-flags CSV] \
  [--debug-start TICK]
```

This is equivalent to running `square` once with profile `cores.args1`.

Run the full demo suite:

```bash
bash demo_test.sh all [--run-tag TAG] [--debug-flags CSV] \
  [--debug-start TICK]
```

Check an existing full-suite batch, or scan all matching results:

```bash
bash demo_test.sh checkall [--run-tag TAG]
```

`demo_test.sh` does two different things depending on the mode:

- `quick` runs `square` once with profile `cores.args1`.
- `all` runs the demo workloads in parallel.
- `checkall` runs `check` across the same workload/profile matrix and prints
  compact real-time progress plus a per-workload summary.

The `all` mode currently includes:

- Mixed CPU-GPU demo workloads across every configured `cores.args*` profile
  except `args0`: `square`, `hacc`, `pannotia-bc-1k-128k`,
  `pannotia-color-max-1k-128k`, and `pannotia-color-maxmin-1k-128k`
- All configured `rodinia-*` workloads from `test_scripts/gem5_workloads.json`

`checkall` behavior:

- With `--run-tag TAG`, it checks the batch produced by
  `bash demo_test.sh all --run-tag TAG`.
- Without `--run-tag`, it scans `tests/testing-results` and checks every
  matching workload/profile result directory.
- It prints one compact real-time status line per finished configuration:
  `workload/argsX`.
- Final output is grouped by workload, for example
  `[PASS] square (args1, args2)` and `[MISS] square (args3(no-match))`.
- Each workload also gets a colored `summary total=... pass=... fail=... miss=...`
  line, followed by an overall total.

Common examples:

```bash
bash demo_test.sh quick --run-tag quick
bash demo_test.sh all --run-tag nightly
bash demo_test.sh checkall --run-tag nightly
bash demo_test.sh checkall
bash demo_test.sh all --debug-flags ProtocolTrace
```

`--run-tag` is used as the base name of each run directory under
`tests/testing-results`.

## Single Workloads And Analysis

If you want to compile, run, or analyze a single benchmark in more detail, use
the scripts under `test_scripts/`.

- `test_scripts/gem5_workload_runner.sh`
  Workload-oriented entry point. Use this when you want to work with a named
  benchmark from `gem5_workloads.json`.
- `test_scripts/gem5_test.sh`
  Lower-level runner. Use this when you already know the exact `run_dir`,
  `config_args`, or `workload_args` you want to pass.
- `test_scripts/analyze_log.py`
  Parses `lat_run_out/{seq,coal}_lat_stats_*.txt` and writes
  `analyze.md` / `analyze.json`.
- `test_scripts/build_gem5_vega_x86.sh`
  Builds `build/VEGA_X86/gem5.opt` inside Docker.
- `test_scripts/gem5_workloads.json`
  Defines workload names, config profiles such as `cores.args*`, and default
  command-line arguments.

Common `gem5_workload_runner.sh` flows:

```bash
bash test_scripts/gem5_workload_runner.sh compile all
bash test_scripts/gem5_workload_runner.sh list
bash test_scripts/gem5_workload_runner.sh compile square
bash test_scripts/gem5_workload_runner.sh run square [run_tag] [--profile PROFILE]...
bash test_scripts/gem5_workload_runner.sh run hacc [run_tag] [--profile PROFILE] [--debug-flags CSV]
bash test_scripts/gem5_workload_runner.sh run pannotia-bc-1k-128k [run_tag] [--profile PROFILE]...
bash test_scripts/gem5_workload_runner.sh run rodinia-bfs [run_tag] [--profile PROFILE]...
bash test_scripts/gem5_workload_runner.sh analyze square <run_tag>
bash test_scripts/gem5_workload_runner.sh check square <run_tag>
bash test_scripts/gem5_workload_runner.sh all square [run_tag] [--profile PROFILE]...
```

Common `gem5_test.sh` flows:

```bash
bash test_scripts/gem5_test.sh test --run-dir <run_dir> [--gem5-opt-bin BIN] \
  [--config-py FILE] [--gem5-opt-args "..."] [--config-args "..."] \
  [--workload-args "..."]
bash test_scripts/gem5_test.sh analyze <run_dir>
bash test_scripts/gem5_test.sh check <run_dir> [LOW] [HIGH]
```

For more detail on the helper scripts and configuration layout, see
`test_scripts/README.md`.
