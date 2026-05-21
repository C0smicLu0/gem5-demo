#!/usr/bin/env python3

import argparse
import configparser
from collections import defaultdict
import glob
import io
import json
import os
import re
import sys
from contextlib import redirect_stdout
from datetime import datetime

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
ENABLE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None


def color(text, code):
    if not ENABLE_COLOR:
        return text
    return f"\033[{code}m{text}\033[0m"


def strip_ansi(text):
    return ANSI_RE.sub("", text)


def section_header(title):
    line = "═" * 72
    print("\n" + color(line, "36"))
    print(color(f"  {title}", "1;36"))
    print(color(line, "36"))


def status_text(status):
    if status == "PASS":
        return color(status, "1;32")
    if status == "FAIL":
        return color(status, "1;31")
    return color(status, "1;33")


def fmt_int(v):
    return f"{int(v):,}"


def read_text_file(path):
    with open(path, "r", errors="ignore") as f:
        return f.read()


class LatRunOutAnalyzer:
    def __init__(self, run_dir):
        self.run_dir = run_dir
        self.lat_dir = os.path.join(run_dir, "lat_run_out")
        self.files = []
        self.types = defaultdict(lambda: {
            "samples": 0,
            "sum": 0.0,
            "min": None,
            "max": None,
            "over_100": 0,
            "over_500": 0,
            "over_1000": 0,
            "over_5000": 0,
        })
        self.total = {
            "samples": 0,
            "sum": 0.0,
            "min": None,
            "max": None,
            "over_100": 0,
            "over_500": 0,
            "over_1000": 0,
            "over_5000": 0,
        }

    def _last_block_lines(self, text):
        chunks = [c.strip() for c in text.split("----") if c.strip()]
        if not chunks:
            return []
        return chunks[-1].splitlines()

    def _parse_type_line(self, line):
        item = {}
        for tok in line.strip().split():
            if "=" not in tok:
                continue
            k, v = tok.split("=", 1)
            item[k] = v
        if "type" not in item or "accesses" not in item or "total_latency" not in item:
            return None
        return item

    def process(self):
        self.files = sorted(glob.glob(os.path.join(self.lat_dir, "seq_lat_stats_*.txt")))
        if not self.files:
            return False
        for path in self.files:
            text = read_text_file(path)
            for line in self._last_block_lines(text):
                if not line.strip().startswith("type="):
                    continue
                item = self._parse_type_line(line)
                if not item:
                    continue
                typ = item["type"]
                accesses = int(float(item.get("accesses", 0)))
                tot = float(item.get("total_latency", 0))
                tmin = float(item.get("min_latency", 0))
                tmax = float(item.get("max_latency", 0))
                st = self.types[typ]
                st["samples"] += accesses
                st["sum"] += tot
                st["over_100"] += int(float(item.get("over_100", 0)))
                st["over_500"] += int(float(item.get("over_500", 0)))
                st["over_1000"] += int(float(item.get("over_1000", 0)))
                st["over_5000"] += int(float(item.get("over_5000", 0)))
                st["min"] = tmin if st["min"] is None else min(st["min"], tmin)
                st["max"] = tmax if st["max"] is None else max(st["max"], tmax)

        for st in self.types.values():
            self.total["samples"] += st["samples"]
            self.total["sum"] += st["sum"]
            self.total["over_100"] += st["over_100"]
            self.total["over_500"] += st["over_500"]
            self.total["over_1000"] += st["over_1000"]
            self.total["over_5000"] += st["over_5000"]
            if st["min"] is not None:
                self.total["min"] = st["min"] if self.total["min"] is None else min(self.total["min"], st["min"])
            if st["max"] is not None:
                self.total["max"] = st["max"] if self.total["max"] is None else max(self.total["max"], st["max"])

        return self.total["samples"] > 0

    def _metrics(self, st):
        if st["samples"] <= 0:
            return {}
        return {
            "samples": int(st["samples"]),
            "min": int(st["min"]) if st["min"] is not None else None,
            "max": int(st["max"]) if st["max"] is not None else None,
            "mean": st["sum"] / st["samples"],
            "over_100": int(st["over_100"]),
            "over_500": int(st["over_500"]),
            "over_1000": int(st["over_1000"]),
            "over_5000": int(st["over_5000"]),
        }

    def build_summary_data(self):
        data = {"total": self._metrics(self.total), "types": {}}
        for typ in sorted(self.types.keys()):
            data["types"][typ] = self._metrics(self.types[typ])

        ld = self.types.get("LD", {"samples": 0, "sum": 0.0, "min": None, "max": None, "over_100": 0, "over_500": 0, "over_1000": 0, "over_5000": 0})
        st = self.types.get("ST", {"samples": 0, "sum": 0.0, "min": None, "max": None, "over_100": 0, "over_500": 0, "over_1000": 0, "over_5000": 0})
        ldst = {
            "samples": ld["samples"] + st["samples"],
            "sum": ld["sum"] + st["sum"],
            "min": min([x for x in [ld["min"], st["min"]] if x is not None], default=None),
            "max": max([x for x in [ld["max"], st["max"]] if x is not None], default=None),
            "over_100": ld["over_100"] + st["over_100"],
            "over_500": ld["over_500"] + st["over_500"],
            "over_1000": ld["over_1000"] + st["over_1000"],
            "over_5000": ld["over_5000"] + st["over_5000"],
        }
        data["ldst"] = self._metrics(ldst)
        data["meta"] = {"lat_run_out_files": self.files}
        return data

    def print_summary(self):
        section_header("Latency Aggregate (lat_run_out)")
        print(color("source files", "1;34") + f": {len(self.files)}")
        total = self._metrics(self.total)
        if not total:
            print(color("无有效聚合数据", "1;33"))
            return
        print(color("total samples", "1;34") + f": {total['samples']:,}")
        print(color("mean/min/max", "1;34") +
              f": {total['mean']:.2f} / {total['min']} / {total['max']}")
        print(color("slow buckets", "1;34") +
              f": >100={total['over_100']:,}  >500={total['over_500']:,}  "
              f">1000={total['over_1000']:,}  >5000={total['over_5000']:,}")
        print(color("-" * 72, "90"))
        print(color(f"{'type':<14}{'samples':>14}{'mean':>12}{'min':>10}{'max':>10}", "1"))
        print(color("-" * 72, "90"))
        for typ in sorted(self.types.keys()):
            m = self._metrics(self.types[typ])
            print(f"{typ:<14}{fmt_int(m['samples']):>14}{m['mean']:>12.2f}{m['min']:>10}{m['max']:>10}")


class CacheMissRateAnalyzer:
    CACHE_HINTS = ("cache", "l1", "l2", "l3", "ruby", "tcp", "tcc", "sqc", "cu", "cpu")

    def __init__(self, stats_file):
        self.stats_file = stats_file
        self.direct_miss_rates = {}
        self.demand_miss_rates = {}
        self.generic_derived_miss_rates = {}

    @staticmethod
    def _to_percent(v):
        return v * 100.0

    def _last_dump_text(self, text):
        blocks = re.split(r"^---------- Begin Simulation Statistics(?: : .*?)? ----------$", text, flags=re.MULTILINE)
        if len(blocks) < 2:
            return ""
        return blocks[-1].split("---------- End Simulation Statistics   ----------", 1)[0]

    def _is_cache_stat(self, name):
        low = name.lower()
        return any(h in low for h in self.CACHE_HINTS)

    def process(self):
        if not os.path.exists(self.stats_file):
            return False
        text = read_text_file(self.stats_file)
        dump = self._last_dump_text(text)
        if not dump:
            return False

        values = {}
        for line in dump.splitlines():
            fields = line.split()
            if len(fields) < 2:
                continue
            name, raw = fields[0], fields[1]
            if not self._is_cache_stat(name):
                continue
            try:
                values[name] = float(raw)
            except ValueError:
                continue

        for name, val in values.items():
            lname = name.lower()
            if "miss_rate" in lname or "missrate" in lname:
                self.direct_miss_rates[name] = self._to_percent(val)

        for miss_name, miss_val in values.items():
            low = miss_name.lower()
            if "m_demand_misses" not in low:
                continue
            acc_name = miss_name.replace("m_demand_misses", "m_demand_accesses")
            if acc_name not in values:
                continue
            accesses = values[acc_name]
            if accesses <= 0:
                continue
            self.demand_miss_rates[f"{miss_name} / {acc_name}"] = self._to_percent(miss_val / accesses)

        for miss_name, miss_val in values.items():
            low = miss_name.lower()
            if "miss_rate" in low or "missrate" in low or "m_demand_misses" in low or "misses" not in low:
                continue
            acc_name = miss_name.replace("misses", "accesses")
            if acc_name not in values:
                acc_name = miss_name.replace("Misses", "Accesses")
            if acc_name not in values:
                continue
            accesses = values[acc_name]
            if accesses <= 0:
                continue
            self.generic_derived_miss_rates[f"{miss_name} / {acc_name}"] = self._to_percent(miss_val / accesses)

        return bool(self.demand_miss_rates or self.generic_derived_miss_rates or self.direct_miss_rates)

    def print_summary(self):
        section_header("Cache Miss Rate (last stats dump)")
        if not self.direct_miss_rates and not self.demand_miss_rates and not self.generic_derived_miss_rates:
            print(color("无可用 miss rate 数据", "1;33"))
            return
        if self.demand_miss_rates:
            print(color("优先统计（m_demand_misses / m_demand_accesses）", "1;34"))
            for name in sorted(self.demand_miss_rates):
                print(f"  • {name:<60} {self.demand_miss_rates[name]:>8.4f}%")
        else:
            print(color("优先统计（m_demand_misses / m_demand_accesses）: 无", "33"))

        if self.generic_derived_miss_rates:
            print(color("兜底统计（misses/accesses）", "1;34"))
            for name in sorted(self.generic_derived_miss_rates):
                print(f"  • {name:<60} {self.generic_derived_miss_rates[name]:>8.4f}%")
        else:
            print(color("兜底统计（misses/accesses）: 无", "33"))

        if self.direct_miss_rates:
            print(color("参考（stats 原生 miss_rate）", "1;34"))
            for name in sorted(self.direct_miss_rates):
                print(f"  • {name:<60} {self.direct_miss_rates[name]:>8.4f}%")
        else:
            print(color("参考（stats 原生 miss_rate）: 无", "33"))

    def build_summary_data(self):
        return {
            "demand_derived": self.demand_miss_rates,
            "generic_derived": self.generic_derived_miss_rates,
            "direct": self.direct_miss_rates,
        }


class FunctionalTestAnalyzer:
    STATUS_PASS = "PASS"
    STATUS_FAIL = "FAIL"
    STATUS_UNKNOWN = "UNKNOWN"

    CRITICAL_PATTERNS = ["panic", "fatal", "assert", "deadlock", "segmentation fault", "timeout", "no space left on device"]
    INIT_FAIL_PATTERNS = ["gpu init fail", "address space error", "memory alloc fail"]
    EXEC_HINT_PATTERNS = ["begin simulation", "exiting @ tick", "exiting because", "sim_seconds", "final_tick"]
    RESULT_FAIL_PATTERNS = ["verification failed", "mismatch", "incorrect", "wrong answer", "error:"]
    RESULT_PASS_PATTERNS = ["pass", "passed", "success", "verification ok"]
    CONFIG_OBJECT_HINTS = ["cpu", "gpu", "cu", "cache", "directory", "memory"]

    def __init__(self, run_dir):
        self.run_dir = run_dir
        self.files = {
            "simerr": os.path.join(run_dir, "simerr.txt"),
            "simout": os.path.join(run_dir, "simout.txt"),
            "stats": os.path.join(run_dir, "stats.txt"),
            "config_ini": os.path.join(run_dir, "config.ini"),
            "config_json": os.path.join(run_dir, "config.json"),
        }
        self.read_files = []
        self.items = {}

    def _read_if_exists(self, key):
        path = self.files[key]
        if not os.path.exists(path):
            return ""
        self.read_files.append(path)
        return read_text_file(path)

    def _combined_text(self, keys):
        return "\n".join(self._read_if_exists(key) for key in keys)

    @staticmethod
    def _mk_result(status, evidence, notes):
        return {"status": status, "evidence": evidence[:8], "notes": notes}

    @staticmethod
    def _find_pattern_evidence(text, patterns, source_name):
        evidence = []
        if not text:
            return evidence
        for idx, line in enumerate(text.splitlines(), start=1):
            low = line.lower()
            for pat in patterns:
                if pat in low:
                    evidence.append(f"{source_name}:{idx}: {line.strip()[:180]}")
                    break
            if len(evidence) >= 8:
                break
        return evidence

    def _analyze_resource_instantiation(self):
        ini_exists = os.path.exists(self.files["config_ini"])
        json_exists = os.path.exists(self.files["config_json"])
        if not ini_exists and not json_exists:
            return self._mk_result(self.STATUS_UNKNOWN, [], "缺少 config.ini/config.json，无法离线确认资源实例化")

        found = set()
        evidence = []
        if ini_exists:
            cfg = configparser.ConfigParser()
            try:
                cfg.read(self.files["config_ini"])
                self.read_files.append(self.files["config_ini"])
                for sec in cfg.sections():
                    sec_low = sec.lower()
                    for hint in self.CONFIG_OBJECT_HINTS:
                        if hint in sec_low:
                            found.add(hint)
                            if len(evidence) < 6:
                                evidence.append(f"config.ini: section [{sec}]")
            except configparser.Error as exc:
                evidence.append(f"config.ini parse error: {exc}")

        if json_exists:
            try:
                self.read_files.append(self.files["config_json"])
                with open(self.files["config_json"], "r", errors="ignore") as f:
                    cfgj = json.load(f)
                as_text = json.dumps(cfgj).lower()
                for hint in self.CONFIG_OBJECT_HINTS:
                    if hint in as_text:
                        found.add(hint)
                        if len(evidence) < 6:
                            evidence.append(f"config.json: found token '{hint}'")
            except (json.JSONDecodeError, OSError) as exc:
                evidence.append(f"config.json parse error: {exc}")

        if "cpu" not in found and "gpu" not in found:
            return self._mk_result(self.STATUS_FAIL, evidence, "未发现关键 CPU/GPU 资源迹象")
        if found:
            return self._mk_result(self.STATUS_PASS, evidence, f"检测到资源对象迹象: {sorted(found)}")
        return self._mk_result(self.STATUS_UNKNOWN, evidence, "配置存在但缺少可识别资源对象证据")

    def _analyze_system_init(self):
        all_text = self._combined_text(["simout", "simerr"])
        fail_ev = self._find_pattern_evidence(all_text, self.INIT_FAIL_PATTERNS, "simout/simerr")
        if fail_ev:
            return self._mk_result(self.STATUS_FAIL, fail_ev, "检测到初始化失败关键词")
        exec_ev = self._find_pattern_evidence(all_text, self.EXEC_HINT_PATTERNS, "simout/simerr")
        if exec_ev:
            return self._mk_result(self.STATUS_PASS, exec_ev, "检测到进入执行阶段迹象")
        return self._mk_result(self.STATUS_UNKNOWN, [], "缺少初始化成功或失败的明确证据")

    def _analyze_function_execution(self):
        all_text = self._combined_text(["simout", "simerr"])
        crash_ev = self._find_pattern_evidence(all_text, self.CRITICAL_PATTERNS + ["aborted", "killed", "traceback"], "simout/simerr")
        if crash_ev:
            return self._mk_result(self.STATUS_FAIL, crash_ev, "检测到中断/崩溃迹象")
        ok_ev = self._find_pattern_evidence(all_text, ["exiting because", "exiting @ tick"], "simout/simerr")
        if ok_ev:
            return self._mk_result(self.STATUS_PASS, ok_ev, "检测到正常退出迹象")
        return self._mk_result(self.STATUS_UNKNOWN, [], "未发现明确退出状态")

    def _analyze_result_validation(self):
        all_text = self._combined_text(["simout", "simerr"])
        fail_ev = self._find_pattern_evidence(all_text, self.RESULT_FAIL_PATTERNS, "simout/simerr")
        if fail_ev:
            return self._mk_result(self.STATUS_FAIL, fail_ev, "检测到 correctness/error 失败信号")
        pass_ev = self._find_pattern_evidence(all_text, self.RESULT_PASS_PATTERNS, "simout/simerr")
        if pass_ev:
            return self._mk_result(self.STATUS_PASS, pass_ev, "检测到 correctness/返回状态成功信号")
        return self._mk_result(self.STATUS_UNKNOWN, [], "无统一 correctness 文本，保持 UNKNOWN")

    def _analyze_exception_check(self):
        all_text = self._combined_text(["simout", "simerr", "stats"])
        hit_ev = self._find_pattern_evidence(all_text, self.CRITICAL_PATTERNS, "simout/simerr/stats")
        if hit_ev:
            return self._mk_result(self.STATUS_FAIL, hit_ev, "命中严重异常关键字")
        return self._mk_result(self.STATUS_PASS, [], "未命中严重异常关键字")

    def process(self):
        self.items = {
            "resource_instantiation": self._analyze_resource_instantiation(),
            "system_initialization": self._analyze_system_init(),
            "functional_execution": self._analyze_function_execution(),
            "result_validation": self._analyze_result_validation(),
            "exception_check": self._analyze_exception_check(),
        }
        return self.items

    def build_summary_data(self):
        counts = {"pass": 0, "fail": 0, "unknown": 0}
        for item in self.items.values():
            s = item["status"]
            if s == self.STATUS_PASS:
                counts["pass"] += 1
            elif s == self.STATUS_FAIL:
                counts["fail"] += 1
            else:
                counts["unknown"] += 1
        return {
            "summary": counts,
            "items": self.items,
            "meta": {"source_files": sorted(set(self.read_files)), "policy": "evidence_aware"},
        }

    def print_summary(self):
        section_header("Functional Tests (offline evidence)")
        labels = {
            "resource_instantiation": "资源实例化",
            "system_initialization": "系统初始化",
            "functional_execution": "功能执行",
            "result_validation": "结果校验",
            "exception_check": "异常检查",
        }
        for key in ["resource_instantiation", "system_initialization", "functional_execution", "result_validation", "exception_check"]:
            item = self.items.get(key, {})
            status = item.get("status", self.STATUS_UNKNOWN)
            print(f"• {labels[key]:<12} {status_text(status)}")
            print(color("  notes", "1;34") + f": {item.get('notes', '')}")
            ev = item.get("evidence", [])
            if ev:
                for e in ev[:3]:
                    print(color("  evidence", "90") + f": {e}")
            else:
                print(color("  evidence", "90") + ": (none)")


def main():
    parser = argparse.ArgumentParser(description="gem5 lat_run_out 聚合分析工具")
    parser.add_argument("--run-dir", required=True, help="run目录，读取 lat_run_out/seq_lat_stats_*.txt")
    parser.add_argument("--output-md", help="分析markdown输出路径")
    parser.add_argument("--output-json", help="分析json输出路径")
    args = parser.parse_args()

    run_dir = args.run_dir
    stats_file = os.path.join(run_dir, "stats.txt")
    output_md = args.output_md or os.path.join(run_dir, "analyze.md")
    output_json = args.output_json or os.path.join(run_dir, "analyze.json")

    analyzer = LatRunOutAnalyzer(run_dir)
    miss_analyzer = CacheMissRateAnalyzer(stats_file)
    func_analyzer = FunctionalTestAnalyzer(run_dir)

    captured = io.StringIO()
    with redirect_stdout(captured):
        ok = analyzer.process()
        if ok:
            analyzer.print_summary()
            miss_analyzer.process()
            miss_analyzer.print_summary()
            func_analyzer.process()
            func_analyzer.print_summary()
        else:
            print("\n" + color("解析失败：lat_run_out 下无可用 seq_lat_stats_*.txt", "1;31"))

    analysis_text = captured.getvalue()
    print(analysis_text, end="")

    if not ok:
        with open(output_md, "w") as f:
            f.write(strip_ansi(analysis_text))
        sys.exit(1)

    summary = analyzer.build_summary_data()
    summary["meta"] = {
        "run_dir": run_dir,
        "lat_run_out_dir": os.path.join(run_dir, "lat_run_out"),
        "generated_at": datetime.now().isoformat(),
    }
    summary["cache_miss_rates"] = miss_analyzer.build_summary_data()
    summary["functional_tests"] = func_analyzer.build_summary_data()

    with open(output_md, "w") as f:
        f.write(strip_ansi(analysis_text))
    with open(output_json, "w") as f:
        json.dump(summary, f, indent=2)

    print(f"\nWrote: {output_md}")
    print(f"Wrote: {output_json}")


if __name__ == "__main__":
    main()
