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

Build gem5 and the GPU demo workloads:

```bash
bash demo_build.sh
```

Useful variants:

```bash
bash demo_build.sh --gem5-only
bash demo_build.sh --gpu-only --gpu-in-container
```

`--gpu-in-container` is for the case where you are already inside a suitable
GPU build environment and do not want the GPU workload scripts to launch Docker
again.

## Test

Run the default quick demo:

```bash
bash demo_test.sh
```

This is equivalent to running `square` once with profile `cores.args1`.

Run all configured `cores.args*` profiles in parallel:

```bash
bash demo_test.sh all
```

Optional examples:

```bash
bash demo_test.sh quick --run-tag smoke
bash demo_test.sh all --run-tag nightly
```
