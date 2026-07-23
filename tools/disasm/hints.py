# tools/disasm/hints.py
"""提示文件加载与结构校验。提示文件是纯 Python 模块，约定七个顶层变量。
ENTRIES 两种形式：第三元为 $FFFA-$FFFE 偶数时是向量地址（目标从 ROM 向量表解析）；
其余视为直接 CPU 入口地址（用于跨 bank 已知调用目标），按 bank 窗口校验。"""
import importlib.util
from dataclasses import dataclass

BANK_BASE = {0: 0x8000, 1: 0xC000}   # bank0 可切换窗口 / bank1 固定窗口
BANK_SIZE = 0x4000

@dataclass
class DataRegion:
    bank: int
    start: int
    end: int          # 含端点
    kind: str
    comment: str

@dataclass
class Hints:
    entries: list         # list[tuple[str, int, int]]（名字, bank, CPU 入口地址）
    labels: dict          # dict[(bank, addr), str]
    jump_tables: dict     # dict[(bank, addr), list[int]]
    data_regions: list    # list[DataRegion]
    comments: dict        # dict[(bank, addr), str]
    ram_syms: dict        # dict[addr, str]
    cross_bank: dict      # dict[(bank, addr), (目标bank, 目标addr)]

def _check_addr(bank: int, addr: int, what: str):
    # 先校验 bank 号合法（只有 0/1），否则 BANK_BASE[bank] 会漏出 KeyError，
    # 违反"结构校验失败抛 ValueError"的契约
    if bank not in BANK_BASE:
        raise ValueError(f"{what}: 非法 bank 号 {bank}（合法值 0/1）")
    base = BANK_BASE[bank]
    if not (base <= addr < base + BANK_SIZE):
        raise ValueError(f"{what}: 地址 ${addr:04X} 不在 bank{bank} 窗口 ${base:04X}-${base + BANK_SIZE - 1:04X}")

def _load_module(path: str):
    spec = importlib.util.spec_from_file_location("goonies_hints", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

def load_hints(module_path: str, rom) -> Hints:
    mod = _load_module(module_path)
    get = lambda name: getattr(mod, name, None)
    raw_entries = get("ENTRIES") or []
    labels = dict(get("LABELS") or {})
    jump_tables = {k: list(v) for k, v in (get("JUMP_TABLES") or {}).items()}
    # 显式校验条目为 5 元组；先判类型再取长度，避免非序列元素在 len() 上漏出
    # TypeError（或 DataRegion(*r) 漏出 TypeError），违反"结构校验失败抛 ValueError"契约
    regions = []
    for r in (get("DATA_REGIONS") or []):
        if not isinstance(r, (tuple, list)) or len(r) != 5:
            raise ValueError(f"DATA_REGIONS 条目应为 5 元组 (bank, start, end, kind, comment)，实际: {r!r}")
        regions.append(DataRegion(*r))
    comments = dict(get("COMMENTS") or {})
    ram_syms = dict(get("RAM_SYMS") or {})
    cross_bank = dict(get("CROSS_BANK") or {})

    entries = []
    for name, bank, vec in raw_entries:
        if 0xFFFA <= vec <= 0xFFFE and vec % 2 == 0:
            # 向量入口：第三元是向量地址，目标从 bank1 尾部向量表解析
            off = vec - BANK_BASE[1]
            target = rom.prg_banks[1][off] | (rom.prg_banks[1][off + 1] << 8)
            _check_addr(bank, target, f"入口 {name} 向量目标")
        else:
            # 直接入口：第三元即 CPU 入口地址（跨 bank 调用目标等已知种子）
            # $FFFA-$FFFF 是 bank1 尾部的向量区，落在这里的直接地址视为笔误
            if 0xFFFA <= vec <= 0xFFFF:
                raise ValueError(
                    f"入口 {name}: 直接地址 ${vec:04X} 落在向量区 $FFFA-$FFFF，"
                    "该区间是向量地址，如需向量入口请用向量形式")
            target = vec
            _check_addr(bank, target, f"入口 {name} 直接地址")
        entries.append((name, bank, target))

    for (bank, addr), label in labels.items():
        _check_addr(bank, addr, f"LABELS[{label}]")
    for (bank, addr), targets in jump_tables.items():
        _check_addr(bank, addr, f"JUMP_TABLES[${addr:04X}]")
        for t in targets:
            _check_addr(bank, t, f"JUMP_TABLES[${addr:04X}] 目标")
    for r in regions:
        _check_addr(r.bank, r.start, f"DATA_REGIONS {r.comment} 起始")
        _check_addr(r.bank, r.end, f"DATA_REGIONS {r.comment} 结束")
        if r.end < r.start:
            raise ValueError(f"DATA_REGIONS {r.comment}: 结束地址小于起始地址")
    for (bank, addr) in comments:
        _check_addr(bank, addr, f"COMMENTS[${addr:04X}]")
    for (bank, addr), (tbank, taddr) in cross_bank.items():
        _check_addr(bank, addr, f"CROSS_BANK[${addr:04X}]")
        _check_addr(tbank, taddr, f"CROSS_BANK[${addr:04X}] 目标")
    return Hints(entries=entries, labels=labels, jump_tables=jump_tables,
                 data_regions=regions, comments=comments, ram_syms=ram_syms,
                 cross_bank=cross_bank)
