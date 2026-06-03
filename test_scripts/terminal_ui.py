#!/usr/bin/env python3

import os
import re
import shutil
import sys
import unicodedata

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
ENABLE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None

COLORS = {
    "bold": "1",
    "dim": "90",
    "cyan": "36",
    "cyan_bold": "1;36",
    "blue": "1;34",
    "green": "1;32",
    "red": "1;31",
    "yellow": "1;33",
}


def term_width(default=96):
    return max(72, shutil.get_terminal_size((default, 24)).columns)


def color(text, code):
    if not ENABLE_COLOR:
        return str(text)
    return f"\033[{code}m{text}\033[0m"


def style(text, name):
    return color(text, COLORS.get(name, name))


def strip_ansi(text):
    return ANSI_RE.sub("", text)


def char_width(ch):
    if unicodedata.combining(ch):
        return 0
    category = unicodedata.category(ch)
    if category.startswith("C"):
        return 0
    if unicodedata.east_asian_width(ch) in {"F", "W"}:
        return 2
    return 1


def visible_len(text):
    return sum(char_width(ch) for ch in strip_ansi(str(text)))


def status_text(status):
    status = str(status or "UNKNOWN").upper()
    if status == "PASS":
        return style(status, "green")
    if status == "FAIL":
        return style(status, "red")
    return style(status, "yellow")


def badge(status):
    return status_text(status)


def rule(char="-", color_name="cyan"):
    width = term_width()
    print(style(char * width, color_name))


def title(text):
    print()
    rule("=", "cyan")
    print(style(f"  {text}", "cyan_bold"))
    rule("=", "cyan")


def section(text):
    print()
    print(style(text, "cyan_bold"))
    print(style("-" * min(term_width(), 96), "cyan"))


def key_values(items, key_width=None):
    pairs = [(str(k), "" if v is None else str(v)) for k, v in items if v is not None]
    if not pairs:
        return
    key_width = key_width or max(len(k) for k, _ in pairs)
    for key, value in pairs:
        print(f"{style(key.ljust(key_width), 'blue')} : {value}")


def truncate(text, max_width):
    text = str(text)
    if max_width <= 0 or visible_len(text) <= max_width:
        return text
    plain = strip_ansi(text)
    if max_width <= 1:
        return plain[:max_width]
    return plain[: max_width - 1] + "..."


def compress_path(path, max_width=None):
    if not path:
        return ""
    path = str(path)
    max_width = max_width or max(32, term_width() // 2)
    if len(path) <= max_width:
        return path
    home = os.path.expanduser("~")
    if path.startswith(home + os.sep):
        path = "~" + path[len(home):]
    if len(path) <= max_width:
        return path
    parts = path.split(os.sep)
    if len(parts) <= 3:
        return truncate(path, max_width)
    suffix = os.sep.join(parts[-3:])
    prefix = parts[0] or os.sep
    candidate = os.path.join(prefix, "...", suffix)
    return truncate(candidate, max_width)


def _pad(text, width, align="left"):
    text = str(text)
    pad = width - visible_len(text)
    if pad <= 0:
        return text
    if align == "right":
        return " " * pad + text
    return text + " " * pad


def table(headers, rows, aligns=None, max_width=None):
    if aligns is None:
        aligns = ["left"] * len(headers)
    max_width = max_width or term_width()
    raw_rows = [[str(cell) for cell in row] for row in rows]
    widths = [visible_len(h) for h in headers]
    for row in raw_rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], visible_len(cell))

    total_sep = 3 * (len(headers) - 1)
    excess = sum(widths) + total_sep - max_width
    if excess > 0:
        for i in sorted(range(len(widths)), key=lambda n: widths[n], reverse=True):
            if excess <= 0:
                break
            floor = max(8, visible_len(headers[i]))
            take = min(excess, max(0, widths[i] - floor))
            widths[i] -= take
            excess -= take

    def render_row(row):
        cells = []
        for i, cell in enumerate(row):
            align = aligns[i] if i < len(aligns) else "left"
            cells.append(_pad(truncate(cell, widths[i]), widths[i], align))
        return " | ".join(cells)

    print(style(render_row(headers), "bold"))
    print(style("-+-".join("-" * w for w in widths), "dim"))
    for row in raw_rows:
        print(render_row(row))
