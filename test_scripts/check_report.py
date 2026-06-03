#!/usr/bin/env python3

import argparse
import json
import math
import pathlib
import sys

import terminal_ui as ui

THRESHOLD = 150.0

FUNCTION_LABELS = {
    "resource_instantiation": "资源实例化",
    "system_initialization": "系统初始化",
    "functional_execution": "功能执行",
    "result_validation": "结果校验",
    "exception_check": "异常检查",
}
FUNCTION_ORDER = [
    "resource_instantiation",
    "system_initialization",
    "functional_execution",
    "result_validation",
    "exception_check",
]


def load_json(run_dir):
    path = pathlib.Path(run_dir) / "analyze.json"
    if not path.exists():
        print(ui.style("check input not found", "red") + f": {path}", file=sys.stderr)
        return None, path, 2
    try:
        return json.loads(path.read_text()), path, 0
    except json.JSONDecodeError as exc:
        print(ui.style("invalid analyze.json", "red") + f": {path}: {exc}", file=sys.stderr)
        return None, path, 1


def metric_mean(data, key):
    value = (data.get(key) or {}).get("mean")
    if value is None:
        return None
    try:
        value = float(value)
    except (TypeError, ValueError):
        return None
    if math.isnan(value):
        return None
    return value


def metric_samples(data, key):
    value = (data.get(key) or {}).get("samples")
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def weighted_ldst_metric(data):
    mean = metric_mean(data, "ldst")
    samples = metric_samples(data, "ldst")
    if mean is not None:
        return mean, samples

    cpu_mean = metric_mean(data, "cpu_ldst")
    gpu_mean = metric_mean(data, "gpu_ldst")
    cpu_samples = metric_samples(data, "cpu_ldst")
    gpu_samples = metric_samples(data, "gpu_ldst")
    total_samples = 0
    weighted_sum = 0.0
    if cpu_mean is not None and cpu_samples > 0:
        total_samples += cpu_samples
        weighted_sum += cpu_mean * cpu_samples
    if gpu_mean is not None and gpu_samples > 0:
        total_samples += gpu_samples
        weighted_sum += gpu_mean * gpu_samples
    if total_samples <= 0:
        return None, 0
    return weighted_sum / total_samples, total_samples


def latency_rows(data):
    rows = []
    missing = []
    over = []
    for label, key in (
        ("cpu_ldst_mean", "cpu_ldst"),
        ("gpu_ldst_mean", "gpu_ldst"),
    ):
        mean = metric_mean(data, key)
        samples = metric_samples(data, key)
        if mean is None:
            mean_text = "missing"
        else:
            mean_text = f"{mean:.6f}"
        rows.append([
            ui.style(label, "blue"),
            f"{samples:,}",
            mean_text,
            "-",
            "",
            ui.status_text("INFO"),
        ])

    mean, samples = weighted_ldst_metric(data)
    label = "ldst_mean(weighted)"
    if mean is None:
        status = "UNKNOWN"
        delta = ""
        mean_text = "missing"
        missing.append(label)
    else:
        delta_value = mean - THRESHOLD
        status = "PASS" if mean <= THRESHOLD else "FAIL"
        delta = f"{delta_value:+.6f}"
        mean_text = f"{mean:.6f}"
        if status == "FAIL":
            over.append(f"{label}={mean:.6f} > {THRESHOLD:.3f}")
    rows.append([
        ui.style(label, "blue"),
        f"{samples:,}",
        mean_text,
        f"<= {THRESHOLD:.3f}",
        delta,
        ui.status_text(status),
    ])
    return rows, missing, over


def functional_rows(data):
    items = ((data.get("functional_tests") or {}).get("items") or {})
    rows = []
    missing = []
    failed = []
    if not items:
        missing.append("functional_tests.items")
    for key in FUNCTION_ORDER:
        item = items.get(key) or {}
        status = str(item.get("status", "UNKNOWN")).upper()
        notes = item.get("notes", "")
        evidence = item.get("evidence") or []
        first_evidence = evidence[0] if evidence else "(none)"
        if key not in items:
            missing.append(f"functional_tests.items.{key}")
        if status == "FAIL":
            failed.append(f"{FUNCTION_LABELS.get(key, key)}: {first_evidence}")
        rows.append([
            FUNCTION_LABELS.get(key, key),
            ui.status_text(status),
            notes,
        ])
    return rows, missing, failed


def functional_counts(data):
    counts = {"PASS": 0, "FAIL": 0, "UNKNOWN": 0}
    items = ((data.get("functional_tests") or {}).get("items") or {})
    for key in FUNCTION_ORDER:
        status = str((items.get(key) or {}).get("status", "UNKNOWN")).upper()
        if status not in counts:
            status = "UNKNOWN"
        counts[status] += 1
    return counts


def overall_status(function_missing, function_failed, latency_missing, latency_over):
    if function_failed or latency_over:
        return "FAIL"
    if function_missing or latency_missing:
        return "UNKNOWN"
    return "PASS"


def render_diagnostics(function_missing, function_failed, latency_missing, latency_over):
    problems = []
    if function_missing:
        problems.append(("missing fields", ", ".join(function_missing[:8])))
    if latency_missing:
        problems.append(("missing metrics", ", ".join(latency_missing)))
    if latency_over:
        problems.append(("over threshold", "; ".join(latency_over)))
    if function_failed:
        problems.append(("failed evidence", " | ".join(function_failed[:3])))
    if not problems:
        return
    ui.section("Diagnostics")
    ui.key_values(problems, key_width=15)


def render_functional(data, title="Functional Check"):
    rows, missing, failed = functional_rows(data)
    ui.title(title)
    if missing and missing == ["functional_tests.items"]:
        print(ui.style("functional_tests items missing", "yellow"))
        return missing, failed
    ui.table(["test", "status", "notes"], rows)
    return missing, failed


def render_latency(data, title="Latency Check"):
    rows, missing, over = latency_rows(data)
    ui.title(title)
    ui.table(["metric", "samples", "mean", "threshold", "delta", "status"], rows,
             aligns=["left", "right", "right", "right", "right", "left"])
    return missing, over


def render_full(data, run_dir, analyze_path):
    function_rows_data, function_missing, function_failed = functional_rows(data)
    latency_rows_data, latency_missing, latency_over = latency_rows(data)
    counts = functional_counts(data)
    status = overall_status(function_missing, function_failed, latency_missing, latency_over)

    ui.title("gem5 Check Report")
    ui.key_values([
        ("run_dir", ui.compress_path(run_dir)),
        ("analyze_json", ui.compress_path(analyze_path)),
        ("functional", f"PASS={counts['PASS']} FAIL={counts['FAIL']} UNKNOWN={counts['UNKNOWN']}"),
        ("latency_threshold", f"<= {THRESHOLD:.3f}"),
        ("overall", ui.status_text(status)),
    ], key_width=17)

    ui.section("Functional Tests")
    ui.table(["test", "status", "notes"], function_rows_data)

    ui.section("Latency Metrics")
    ui.table(["metric", "samples", "mean", "threshold", "delta", "status"], latency_rows_data,
             aligns=["left", "right", "right", "right", "right", "left"])

    render_diagnostics(function_missing, function_failed, latency_missing, latency_over)

    return status


def main():
    parser = argparse.ArgumentParser(description="Render gem5 analyze.json checks")
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--mode", choices=["check", "functional", "latency"], default="check")
    args = parser.parse_args()

    data, analyze_path, rc = load_json(args.run_dir)
    if rc != 0:
        return rc

    if args.mode == "functional":
        function_missing, function_failed = render_functional(data)
        status = overall_status(function_missing, function_failed, [], [])
    elif args.mode == "latency":
        latency_missing, latency_over = render_latency(data)
        status = overall_status([], [], latency_missing, latency_over)
    else:
        status = render_full(data, args.run_dir, analyze_path)
    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
