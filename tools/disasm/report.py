# tools/disasm/report.py
"""覆盖率报告：每 bank 的 CODE/DATA/UNKNOWN 统计与 UNKNOWN 区间清单。"""
from trace import CODE, DATA, UNKNOWN

def _unknown_ranges(result) -> list:
    ranges = []
    start = None
    for i, s in enumerate(result.states):
        if s == UNKNOWN and start is None:
            start = i
        elif s != UNKNOWN and start is not None:
            ranges.append((result.base_addr + start, result.base_addr + i - 1))
            start = None
    if start is not None:
        ranges.append((result.base_addr + start, result.base_addr + len(result.states) - 1))
    return ranges

def coverage_report(results: dict) -> tuple:
    lines = []
    all_ok = True
    for bank in sorted(results):
        res = results[bank]
        n = len(res.states)
        c = sum(1 for s in res.states if s == CODE)
        d = sum(1 for s in res.states if s == DATA)
        u = n - c - d
        ok = (u == 0)
        all_ok = all_ok and ok
        lines.append(f"bank{bank}: CODE {c} ({c / n:.1%})  DATA {d} ({d / n:.1%})  "
                     f"UNKNOWN {u} ({u / n:.1%})  {'OK' if ok else 'INCOMPLETE'}")
        for s, e in _unknown_ranges(res):
            lines.append(f"  UNKNOWN 区间: ${s:04X}-${e:04X} ({e - s + 1} 字节)")
        for w in res.warnings:
            lines.append(f"  警告: {w}")
    return "\n".join(lines) + "\n", all_ok
