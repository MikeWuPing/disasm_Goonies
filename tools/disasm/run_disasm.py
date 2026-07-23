# tools/disasm/run_disasm.py
"""反汇编管道入口：python tools/disasm/run_disasm.py"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ines import load_rom
from hints import load_hints
from trace import trace_bank, validate_hint_boundaries
from cpu6502 import reencode
from emit import render_bank, render_inc
from report import coverage_report

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))

def main(argv) -> int:
    rom = load_rom(os.path.join(REPO, "refer", "org.nes"))
    hints = load_hints(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                    "hints", "goonies.py"), rom)
    results = {b: trace_bank(rom, b, hints) for b in (0, 1)}

    errors = []
    for b, res in results.items():
        errors.extend(validate_hint_boundaries(hints, res))
    if errors:
        for e in errors:
            print(f"提示文件错误: {e}", file=sys.stderr)
        return 2

    bad = 0
    for res in results.values():
        for addr, ins in res.instrs.items():
            if reencode(ins) != ins.raw:
                print(f"重编码不一致: bank{res.bank} ${addr:04X}", file=sys.stderr)
                bad += 1
    if bad:
        return 3

    outdir = os.path.join(REPO, "asm")
    os.makedirs(outdir, exist_ok=True)
    # 全局符号表：两 bank 标签合并（窗口互不重叠），供 emit 标注跨 bank 调用目标
    global_syms = {}
    for b, res in results.items():
        for addr, name in res.labels.items():
            global_syms[addr] = (b, name)
    for b, res in results.items():
        with open(os.path.join(outdir, f"goonies_bank{b}.asm"), "w", encoding="utf-8") as f:
            f.write(render_bank(res, hints, global_syms))
    with open(os.path.join(outdir, "goonies.inc"), "w", encoding="utf-8") as f:
        f.write(render_inc(hints))
    text, ok = coverage_report(results)
    with open(os.path.join(outdir, "coverage.txt"), "w", encoding="utf-8") as f:
        f.write(text)
    sys.stdout.write(text)
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
