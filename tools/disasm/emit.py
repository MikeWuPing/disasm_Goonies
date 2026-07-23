# tools/disasm/emit.py
"""BankResult → ca65 可汇编 asm 文本 / goonies.inc。指令活动文本，地址与原始字节入行尾注释。
跨 bank 调用标注：render_bank 接受可选 global_syms（两 bank 标签合并表 addr→(bank,名)），
操作数/分支目标落在另一 bank 窗口且有名时，行尾注释追加 "-> BankN:名"；
hints.cross_bank[(bank,指令地址)]=(目标bank,目标addr) 为显式覆盖，优先于自动解析。"""
import cpu6502 as cpu
from trace import CODE, DATA

def _fmt_raw(raw: bytes) -> str:
    return " ".join(f"{b:02X}" for b in raw)

def _operand_text(ins: cpu.Instruction, result, ram_syms: dict) -> str:
    """按寻址模式渲染操作数；优先代码标签与 RAM 符号。"""
    op = ins.operand
    def sym(a):
        if a in result.labels:
            return result.labels[a]
        if a in ram_syms:
            return ram_syms[a]
        return f"${a:04X}" if a > 0xFF else f"${a:02X}"
    m = ins.mode
    if m == cpu.ACC:
        return "A"
    if m == cpu.IMP:
        return ""
    if m == cpu.IMM:
        return f"#${op:02X}"
    if m == cpu.REL:
        return sym(ins.branch_target)
    if m == cpu.ZP:  return sym(op)
    if m == cpu.ZPX: return f"{sym(op)},X"
    if m == cpu.ZPY: return f"{sym(op)},Y"
    if m == cpu.ABS: return sym(op)
    if m == cpu.ABX: return f"{sym(op)},X"
    if m == cpu.ABY: return f"{sym(op)},Y"
    if m == cpu.IND: return f"({sym(op)})"
    if m == cpu.IZX: return f"(${op:02X},X)"
    if m == cpu.IZY: return f"(${op:02X}),Y"
    raise ValueError(f"未知寻址模式 {m}")

def _byte_line(chunk: list, start: int) -> str:
    hexs = ",".join(f"${b:02X}" for b in chunk)
    raw = " ".join(f"{b:02X}" for b in chunk)
    return f"    .byte {hexs:<40}; {start:04X}: {raw}"

def _cross_bank_note(ins, result, hints, global_syms) -> str:
    """跨 bank 目标注释。显式 CROSS_BANK 优先；否则按操作数/分支目标自动解析。
    仅当目标在另一 bank 窗口（≥$8000 且不在本 bank 窗口）且全局符号表有名时标注。"""
    explicit = hints.cross_bank.get((result.bank, ins.addr)) if hints else None
    if explicit is not None:
        tbank, taddr = explicit
        name = global_syms.get(taddr, (None, None))[1] if global_syms else None
        return f"  -> Bank{tbank}:{name or f'${taddr:04X}'}"
    if not global_syms:
        return ""
    if ins.mode == cpu.REL:
        tgt = ins.branch_target
    elif ins.mode in (cpu.ABS, cpu.ABX, cpu.ABY):
        tgt = ins.operand
    else:  # IND 的操作数是指针地址而非跳转目标，其余模式无绝对地址
        return ""
    if tgt is None or tgt < 0x8000:
        return ""
    base = result.base_addr
    if base <= tgt < base + len(result.states):
        return ""  # 本 bank 窗口内
    hit = global_syms.get(tgt)
    if not hit:
        return ""
    return f"  -> Bank{hit[0]}:{hit[1]}"

def render_bank(result, hints, global_syms=None) -> str:
    ram_syms = hints.ram_syms
    base = result.base_addr
    lines = [
        f"; === Goonies RC809 — Bank {result.bank} (base ${base:04X}) ===",
        "; 本文件由 tools/disasm 自动生成，请勿手工编辑",
        '.include "goonies.inc"',
        "",
    ]
    comments = {a: c for (b, a), c in hints.comments.items() if b == result.bank}
    addr = base
    end = base + len(result.states)
    while addr < end:
        off = addr - base
        state = result.states[off]
        if addr in result.labels:
            lines.append(f"{result.labels[addr]}:")
        # 注释独立于标签门控：无标签地址的注释单独成行，紧贴其指令/数据行之前
        if addr in comments:
            lines.append(f"    ; {comments[addr]}")
        if state == CODE:
            ins = result.instrs[addr]
            operand = _operand_text(ins, result, ram_syms)
            stmt = f"{ins.mnemonic} {operand}".rstrip()
            xref = ""
            srcs = result.xrefs.get(addr)
            if srcs and addr not in result.labels:
                xref = "  xref: " + ",".join(f"${s:04X}" for s in srcs)
            xb = _cross_bank_note(ins, result, hints, global_syms)
            lines.append(f"    {stmt:<28}; {addr:04X}: {_fmt_raw(ins.raw)}{xref}{xb}")
            addr += ins.length
        elif state == DATA:
            chunk = []
            start = addr
            entry = addr  # 入口字节豁免：标签/注释刚输出过的入口字节照常消费
            while addr < end and result.states[addr - base] == DATA and \
                    (addr == entry or (addr not in result.labels and addr not in comments)):
                chunk.append(result.buf[addr - base])
                addr += 1
                if len(chunk) == 8:
                    lines.append(_byte_line(chunk, start))
                    start = addr
                    chunk = []
            if chunk:
                lines.append(_byte_line(chunk, start))
        else:  # UNKNOWN
            lines.append(f"    .byte ${result.buf[off]:02X}    ; {addr:04X}: ?? UNKNOWN")
            addr += 1
    lines.append("")
    return "\n".join(lines)

def render_inc(hints) -> str:
    lines = ["; goonies.inc — 自动生成：RAM 与寄存器符号", ""]
    for addr, name in sorted(hints.ram_syms.items()):
        lines.append(f"{name} = ${addr:02X}" if addr <= 0xFF else f"{name} = ${addr:04X}")
    lines.append("")
    return "\n".join(lines)
