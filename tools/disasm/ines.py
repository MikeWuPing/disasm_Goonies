# tools/disasm/ines.py
"""iNES 头解析与 bank 数据暴露。"""
from dataclasses import dataclass

PRG_BANK_SIZE = 16384   # 16KB
CHR_BANK_SIZE = 8192    # 8KB

@dataclass
class NesRom:
    prg_banks: list      # list[bytes]，每个 16KB
    chr_banks: list      # list[bytes]，每个 8KB
    mapper: int
    mirroring: str       # "vertical" | "horizontal"

def load_rom(path: str) -> NesRom:
    with open(path, "rb") as f:
        data = f.read()
    if len(data) < 16 or data[0:4] != b"NES\x1a":
        raise ValueError(f"{path}: 不是合法 iNES 文件（坏魔数或文件过短）")
    n_prg, n_chr = data[4], data[5]
    flags6, flags7 = data[6], data[7]
    mapper = (flags6 >> 4) | (flags7 & 0xF0)
    mirroring = "vertical" if (flags6 & 0x01) else "horizontal"
    need = 16 + n_prg * PRG_BANK_SIZE + n_chr * CHR_BANK_SIZE
    if len(data) < need:
        raise ValueError(f"{path}: 文件大小 {len(data)} 不足头部声明的 {need}")
    prg = [data[16 + i * PRG_BANK_SIZE: 16 + (i + 1) * PRG_BANK_SIZE] for i in range(n_prg)]
    chr_ = [data[16 + n_prg * PRG_BANK_SIZE + i * CHR_BANK_SIZE:
                 16 + n_prg * PRG_BANK_SIZE + (i + 1) * CHR_BANK_SIZE] for i in range(n_chr)]
    return NesRom(prg_banks=prg, chr_banks=chr_, mapper=mapper, mirroring=mirroring)
