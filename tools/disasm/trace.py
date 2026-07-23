# tools/disasm/trace.py
"""递归下降分析：从入口跟踪指令流，产出每字节 CODE/DATA/UNKNOWN 状态。"""
from dataclasses import dataclass, field
from cpu6502 import decode
from hints import BANK_BASE, BANK_SIZE

CODE, DATA, UNKNOWN = "code", "data", "unknown"

@dataclass
class BankResult:
    bank: int
    base_addr: int
    states: list = field(default_factory=list)      # list[str]，长度 BANK_SIZE
    instrs: dict = field(default_factory=dict)      # cpu_addr -> Instruction
    xrefs: dict = field(default_factory=dict)       # 目标 -> [来源...]
    labels: dict = field(default_factory=dict)      # cpu_addr -> 名称
    warnings: list = field(default_factory=list)
    buf: bytes = b""                                # 本 bank 原始字节（render 数据行用）

def trace_bank(rom, bank: int, hints) -> BankResult:
    base = BANK_BASE[bank]
    buf = rom.prg_banks[bank]
    res = BankResult(bank=bank, base_addr=base,
                     states=[UNKNOWN] * BANK_SIZE)
    res.buf = buf
    # CPU 视角 $C000 之后仍有存储：bank0 尾部指令可能跨边界（实证：$BFFE JSR $8713
    # 的第三字节在 bank1 $C000）。解码用拼接缓冲；states/instrs 仍只记本 bank 窗口。
    decode_buf = buf + (rom.prg_banks[1][:0x10] if bank == 0 else b"")

    for r in hints.data_regions:
        if r.bank == bank:
            for a in range(r.start, r.end + 1):
                res.states[a - base] = DATA

    for (bank_, addr), name in hints.labels.items():
        if bank_ == bank:
            res.labels[addr] = name

    queue = []
    for name, ebank, addr in hints.entries:
        if ebank == bank:
            res.labels[addr] = name
            queue.append(addr)

    def add_xref(target, source):
        res.xrefs.setdefault(target, []).append(source)

    def enqueue(addr):
        if addr not in queue:
            queue.append(addr)

    while queue:
        addr = queue.pop(0)
        while True:
            off = addr - base
            if not (0 <= off < BANK_SIZE):
                break
            if res.states[off] != UNKNOWN:
                break  # 已处理（CODE 或 DATA）
            ins = decode(decode_buf, off, base)
            if ins is None:
                res.warnings.append(f"bank{bank} ${addr:04X}: 非法 opcode ${buf[off]:02X}，路径终止")
                break
            # 标 CODE 并记录（跨边界指令只标落在本 bank 窗口内的字节）
            for i in range(ins.length):
                if off + i < BANK_SIZE:
                    res.states[off + i] = CODE
            res.instrs[addr] = ins
            if ins.branch_target is not None:
                add_xref(ins.branch_target, addr)
                if base <= ins.branch_target < base + BANK_SIZE:
                    enqueue(ins.branch_target)
                else:
                    res.warnings.append(f"bank{bank} ${addr:04X}: 分支目标 ${ins.branch_target:04X} 在窗口外")
            if ins.abs_target is not None:
                add_xref(ins.abs_target, addr)
                if base <= ins.abs_target < base + BANK_SIZE:
                    enqueue(ins.abs_target)
                else:
                    res.warnings.append(f"bank{bank} ${addr:04X}: 跳转目标 ${ins.abs_target:04X} 在窗口外")
            if ins.is_indirect:
                targets = hints.jump_tables.get((bank, addr))
                if targets:
                    for t in targets:
                        add_xref(t, addr)
                        enqueue(t)
                else:
                    res.warnings.append(f"bank{bank} ${addr:04X}: JMP(ind) 缺少跳转表提示")
            if ins.is_end:
                break
            addr += ins.length

    # 自动标签：被引用但无名的代码地址
    for target in sorted(res.xrefs):
        if target in res.instrs and target not in res.labels:
            res.labels[target] = f"L{target:04X}"
    return res

def validate_hint_boundaries(hints, result: BankResult) -> list:
    """LABELS/JUMP_TABLES 起止必须落在指令边界或数据区上；
    ENTRIES 入口不得落在 DATA_REGION 内（$BF68 事件曾因漏检此规则而静默错挂）；
    控制流目标（分支/JSR/JMP/JMP(ind)）不得落在 DATA_REGION 内——命中即说明
    数据区错盖真实代码，或跟踪把数据误当代码、分支目标被吞。"""
    errors = []
    bank, base = result.bank, result.base_addr
    code_addrs = set(result.instrs)

    def in_data(addr):
        return result.states[addr - base] == DATA if base <= addr < base + BANK_SIZE else False

    for (b, addr), name in hints.labels.items():
        if b == bank and addr not in code_addrs and not in_data(addr):
            errors.append(f"LABELS[{name}] ${addr:04X} 不在指令边界或数据区上")
    for (b, addr) in hints.jump_tables:
        if b == bank and addr not in code_addrs:
            errors.append(f"JUMP_TABLES[${addr:04X}] 不是已确认代码")
    # 入口若落在数据区内，说明 hints 错挂（入口是代码种子，与 DATA 声明互斥）
    for name, ebank, addr in hints.entries:
        if ebank != bank:
            continue
        for r in hints.data_regions:
            if r.bank == bank and r.start <= addr <= r.end:
                errors.append(f"ENTRIES[{name}] ${addr:04X} 落在数据区 {r.comment}"
                              f"（${r.start:04X}-${r.end:04X}）内")
                break
    # 控制流目标落区校验：trace 先预标 DATA、跟踪遇 DATA 即停，被数据区吞掉的
    # 目标永远不会变成 CODE（故查 states 无意义），只能靠 xref 目标反查区域检出
    for r in hints.data_regions:
        if r.bank != bank:
            continue
        for target, srcs in result.xrefs.items():
            if r.start <= target <= r.end:
                src_text = ",".join(f"${s:04X}" for s in srcs)
                errors.append(f"控制流目标 ${target:04X} 落在数据区 {r.comment}"
                              f"（${r.start:04X}-${r.end:04X}）内（来源 {src_text}）")
    return errors
