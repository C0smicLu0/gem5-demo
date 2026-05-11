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

# Build

Use the provided build script:
```bashs
./demo_build.sh
```

This script builds the required gem5 binary for the demo.

# Test

Use the provided test script:
```bash
./demo_test.sh
```
This script runs the demo test cases and verifies that the modified cache coherence protocol can execute correctly.
