# test_scripts

本目录包含用于构建、运行和分析 `gem5-demo` GPU 工作负载的辅助脚本。

## 文件说明

- `build_gem5_vega_x86.sh`：在 Docker 中构建 `build/VEGA_X86/gem5.opt`。
- `enter_docker.sh`：打开一个交互式 Docker 终端，仓库挂载到 `/gem5`。
- `gem5_test.sh`：底层执行器，提供 `list | test | analyze | check` 子命令。
- `gem5_workload_runner.sh`：面向工作负载的封装脚本，提供 `list | run | analyze | check | all`。
- `gem5_workloads.json`：工作负载及其参数的配置文件。
- `analyze_log.py`：解析 `lat_run_out/seq_lat_stats_*.txt` 并生成汇总报告。

## 路径行为

脚本具备可移植性，不硬编码用户名：

- 仓库根目录通过脚本所在位置自动检测。
- `gem5_workload_runner.sh` 的默认值：
  - 配置文件：`test_scripts/gem5_workloads.json`
  - 测试脚本：`test_scripts/gem5_test.sh`
- `gem5_workloads.json` 中使用：
  - `"base_run_root": "tests/testing-results"`
  - 相对路径会基于仓库根目录解析。

## 测试流程

1. `gem5_workload_runner.sh` 读取 `gem5_workloads.json`，确定 `run_dir`。
2. `run/all` 会调用 `gem5_test.sh test` 生成并执行容器化的 gem5 命令。
3. `analyze/all` 会调用 `gem5_test.sh analyze`，后者再调用 `analyze_log.py`。
4. `check/all` 会调用 `gem5_test.sh check`，根据 `ldst.mean` 阈值和功能测试状态进行判断。

## 配置参数的优先级

对于 `run/all` 命令，`config_args` 按以下顺序合并（后出现的会覆盖 `-u/-n` 等参数）：

1. JSON 中的全局 `config_args`
2. JSON 中工作负载级别的 `config_args`
3. `--profile <name>` 对应的参数（全局或工作负载级别的 profile）

说明：
- 不再支持在 `run/all` 命令后直接追加额外 config 参数。
- 若检测到此类额外参数，脚本会报错并退出。

你也可以通过环境变量覆盖默认值：

- `GEM5_WORKLOAD_CONFIG`
- `GEM5_TEST_SH`
- `GEM5_ROOT`（用于 `enter_docker.sh` 和构建脚本）
- `DOCKER_IMAGE`

## 快速开始

在仓库根目录（`gem5-demo`）下执行：

```bash
chmod +x test_scripts/*.sh
```

构建：

```bash
test_scripts/build_gem5_vega_x86.sh
```

列出所有工作负载：

```bash
test_scripts/gem5_workload_runner.sh list
```

运行单个工作负载：

```bash
test_scripts/gem5_workload_runner.sh run square
```

运行 + 分析 + 检查：

```bash
test_scripts/gem5_workload_runner.sh all square
```

直接使用 `gem5_test.sh` 的手动流程：

```bash
test_scripts/gem5_test.sh test --run-dir tests/testing-results/manual-run
test_scripts/gem5_test.sh analyze tests/testing-results/manual-run
test_scripts/gem5_test.sh check tests/testing-results/manual-run 100 150
```

## 输出
每个运行目录通常包含：

`simout`、`stats.txt` 及其他 `gem5` 输出文件

`lat_run_out/seq_lat_stats_*.txt`（由 `Sequencer` 延迟回调生成）

`analyze.md`、`analyze.json`（由 `analyze_log.py` 生成）
