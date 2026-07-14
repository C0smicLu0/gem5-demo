#!/usr/bin/env python3

import argparse
import pathlib
import re
import sys
import time

CPU_RE = re.compile(r"^(system\.cpu(\d+)\.numCycles)\s+(\S+)")
CU_RE = re.compile(r"^(system\.cpu\d+\.CUs(\d+)\.vALUInsts)\s+(\S+)")


RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"

FG_RED = "\033[38;5;196m"
FG_GREEN = "\033[38;5;42m"
FG_YELLOW = "\033[38;5;220m"
FG_CYAN = "\033[38;5;45m"
FG_WHITE = "\033[38;5;15m"
FG_GRAY = "\033[38;5;245m"
FG_BLUE = "\033[38;5;75m"


def color(text, *styles):
    return "".join(styles) + str(text) + RESET


def plain_len(text):
    return len(re.sub(r"\x1b\[[0-9;]*m", "", text))


def pad_colored(text, width):
    padding = max(0, width - plain_len(text))
    return text + (" " * padding)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Realtime scanner for gem5 stats.txt"
    )

    parser.add_argument(
        "run_dir",
        help="Directory containing stats.txt"
    )

    parser.add_argument(
        "-i",
        "--input",
        default="stats.txt",
        help="Input stats filename (default: stats.txt)"
    )

    parser.add_argument(
        "--refresh",
        type=float,
        default=0.05,
        help="Screen refresh interval in seconds (default: 0.05)"
    )

    parser.add_argument(
        "--delay",
        type=float,
        default=0.02,
        help="Pause time in seconds (default: 0)"
    )

    parser.add_argument(
        "--delay-lines",
        type=int,
        default=1000,
        help="Pause every N lines (default: 1000)"
    )

    return parser.parse_args()


def separator(width=72):
    return color("─" * width, FG_GRAY)


def progress_bar(progress, width=32):
    progress = max(0.0, min(progress, 1.0))
    filled = int(progress * width)
    bar = color("#" * filled, FG_GRAY)
    rest = color("-" * (width - filled), FG_GRAY)
    return f"[{bar}{rest}]"


def status_ratio(valid, total):
    if total == 0:
        return color("0.0%", FG_GRAY)
    return color(f"{valid / total * 100:5.1f}%", FG_GREEN, BOLD)


def render_stat_block(title, total, valid, invalid):
    lines = [
        color(title, BOLD, FG_WHITE),
        f"  {pad_colored(color('Total', FG_GRAY), 16)} {color(total, FG_WHITE, BOLD)}",
        f"  {pad_colored(color('Valid', FG_GRAY), 16)} {color(valid, FG_GREEN, BOLD)}",
        f"  {pad_colored(color('Invalid', FG_GRAY), 16)} {color(invalid, FG_RED, BOLD)}",
        f"  {pad_colored(color('Valid Ratio', FG_GRAY), 16)} {status_ratio(valid, total)}",
    ]
    return "\n".join(lines)


def render_last_line(title, content):
    label = color(title, FG_BLUE, BOLD)
    if not content:
        content = color("(none)", FG_GRAY)
    return f"{label}\n  {content}"


def refresh(progress,
            cpu_total,
            cpu_valid,
            cpu_invalid,
            cu_total,
            cu_valid,
            cu_invalid,
            last_cpu,
            last_cu):

    print("\033[2J\033[H", end="")

    print(separator())
    print(color("gem5 stats scanner", BOLD, FG_WHITE))
    print(separator())

    print(
        f"{pad_colored(color('Progress', FG_GRAY), 12)} "
        f"{progress_bar(progress)}  "
        f"{color(f'{progress * 100:6.2f}%', FG_GRAY, BOLD)}"
    )
    print()

    print(render_stat_block("CPU", cpu_total, cpu_valid, cpu_invalid))
    print(separator())
    print()
    print(render_stat_block("Compute Units", cu_total, cu_valid, cu_invalid))
    print(separator())
    print()
    print(render_last_line("Last CPU hit", last_cpu))
    print(separator())
    print()
    print(render_last_line("Last CU hit", last_cu))
    print(separator())

    sys.stdout.flush()


def main():

    args = parse_args()

    run_dir = pathlib.Path(args.run_dir)
    stats_path = run_dir / args.input

    if not stats_path.is_file():
        print(color(f"Stats file not found: {stats_path}", FG_RED, BOLD), file=sys.stderr)
        return 1

    total_size = stats_path.stat().st_size

    line_count = 0

    cpu_total = 0
    cpu_valid = 0
    cpu_invalid = 0

    cu_total = 0
    cu_valid = 0
    cu_invalid = 0

    cpu_ids = set()
    cu_ids = set()

    last_cpu = ""
    last_cu = ""

    last_refresh = 0

    with stats_path.open(
        "r",
        encoding="utf-8",
        errors="replace"
    ) as handle:

        while True:

            line = handle.readline()

            if not line:
                break

            line_count += 1

            line = line.rstrip("\n")

            cpu_match = CPU_RE.match(line)

            if cpu_match:

                cpu_total += 1

                value = float(cpu_match.group(3))

                if value != 0:
                    cpu_valid += 1
                else:
                    cpu_invalid += 1

                cpu_ids.add(int(cpu_match.group(2)))
                last_cpu = line

            else:

                cu_match = CU_RE.match(line)

                if cu_match:

                    cu_total += 1

                    value = float(cu_match.group(3))

                    if value != 0:
                        cu_valid += 1
                    else:
                        cu_invalid += 1

                    cu_ids.add(int(cu_match.group(2)))
                    last_cu = line

            now = time.time()

            if now - last_refresh >= args.refresh:

                progress = handle.tell() / total_size if total_size else 1.0

                refresh(
                    progress,
                    cpu_total,
                    cpu_valid,
                    cpu_invalid,
                    cu_total,
                    cu_valid,
                    cu_invalid,
                    last_cpu,
                    last_cu,
                )

                last_refresh = now

            if (
                args.delay > 0
                and line_count % args.delay_lines == 0
            ):
                time.sleep(args.delay)

    refresh(
        1.0,
        cpu_total,
        cpu_valid,
        cpu_invalid,
        cu_total,
        cu_valid,
        cu_invalid,
        last_cpu,
        last_cu,
    )

    print()
    print(color("Scan completed.", FG_GREEN, BOLD))
    print()
    print(separator(40))
    print(color("Summary", FG_WHITE, BOLD))
    print(separator(40))
    print(f"  {pad_colored(color('Unique CPUs', FG_GRAY), 16)} {color(len(cpu_ids), FG_WHITE, BOLD)}")
    print(f"  {pad_colored(color('CPU Valid', FG_GRAY), 16)} {color(cpu_valid, FG_GREEN, BOLD)}")
    print(f"  {pad_colored(color('CPU Invalid', FG_GRAY), 16)} {color(cpu_invalid, FG_RED, BOLD)}")
    print(f"  {pad_colored(color('CPU Valid Ratio', FG_GRAY), 16)} {status_ratio(cpu_valid, cpu_total)}")
    print()
    print(f"  {pad_colored(color('Unique CUs', FG_GRAY), 16)} {color(len(cu_ids), FG_WHITE, BOLD)}")
    print(f"  {pad_colored(color('CU Valid', FG_GRAY), 16)} {color(cu_valid, FG_GREEN, BOLD)}")
    print(f"  {pad_colored(color('CU Invalid', FG_GRAY), 16)} {color(cu_invalid, FG_RED, BOLD)}")
    print(f"  {pad_colored(color('CU Valid Ratio', FG_GRAY), 16)} {status_ratio(cu_valid, cu_total)}")
    print(separator(40))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
