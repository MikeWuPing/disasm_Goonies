# tools/disasm/cpu6502.py
"""6502 指令表与双向编解码。只收录 151 个合法 opcode；非法 opcode 由 decode 返回 None。"""
from dataclasses import dataclass

IMP, ACC, IMM = "imp", "acc", "imm"
ZP, ZPX, ZPY = "zp", "zpx", "zpy"
ABS, ABX, ABY, IND = "abs", "abx", "aby", "ind"
IZX, IZY, REL = "izx", "izy", "rel"

MODE_LEN = {IMP: 1, ACC: 1, IMM: 2, ZP: 2, ZPX: 2, ZPY: 2, IZX: 2, IZY: 2, REL: 2,
            ABS: 3, ABX: 3, ABY: 3, IND: 3}

# opcode: (助记符, 寻址模式) —— 共 151 项
OPCODES = {
    0x00: ("BRK", IMP), 0x01: ("ORA", IZX), 0x05: ("ORA", ZP), 0x06: ("ASL", ZP),
    0x08: ("PHP", IMP), 0x09: ("ORA", IMM), 0x0A: ("ASL", ACC), 0x0D: ("ORA", ABS), 0x0E: ("ASL", ABS),
    0x10: ("BPL", REL), 0x11: ("ORA", IZY), 0x15: ("ORA", ZPX), 0x16: ("ASL", ZPX),
    0x18: ("CLC", IMP), 0x19: ("ORA", ABY), 0x1D: ("ORA", ABX), 0x1E: ("ASL", ABX),
    0x20: ("JSR", ABS), 0x21: ("AND", IZX), 0x24: ("BIT", ZP), 0x25: ("AND", ZP),
    0x26: ("ROL", ZP), 0x28: ("PLP", IMP), 0x29: ("AND", IMM), 0x2A: ("ROL", ACC),
    0x2C: ("BIT", ABS), 0x2D: ("AND", ABS), 0x2E: ("ROL", ABS),
    0x30: ("BMI", REL), 0x31: ("AND", IZY), 0x35: ("AND", ZPX), 0x36: ("ROL", ZPX),
    0x38: ("SEC", IMP), 0x39: ("AND", ABY), 0x3D: ("AND", ABX), 0x3E: ("ROL", ABX),
    0x40: ("RTI", IMP), 0x41: ("EOR", IZX), 0x45: ("EOR", ZP), 0x46: ("LSR", ZP),
    0x48: ("PHA", IMP), 0x49: ("EOR", IMM), 0x4A: ("LSR", ACC), 0x4C: ("JMP", ABS),
    0x4D: ("EOR", ABS), 0x4E: ("LSR", ABS),
    0x50: ("BVC", REL), 0x51: ("EOR", IZY), 0x55: ("EOR", ZPX), 0x56: ("LSR", ZPX),
    0x58: ("CLI", IMP), 0x59: ("EOR", ABY), 0x5D: ("EOR", ABX), 0x5E: ("LSR", ABX),
    0x60: ("RTS", IMP), 0x61: ("ADC", IZX), 0x65: ("ADC", ZP), 0x66: ("ROR", ZP),
    0x68: ("PLA", IMP), 0x69: ("ADC", IMM), 0x6A: ("ROR", ACC), 0x6C: ("JMP", IND),
    0x6D: ("ADC", ABS), 0x6E: ("ROR", ABS),
    0x70: ("BVS", REL), 0x71: ("ADC", IZY), 0x75: ("ADC", ZPX), 0x76: ("ROR", ZPX),
    0x78: ("SEI", IMP), 0x79: ("ADC", ABY), 0x7D: ("ADC", ABX), 0x7E: ("ROR", ABX),
    0x81: ("STA", IZX), 0x84: ("STY", ZP), 0x85: ("STA", ZP), 0x86: ("STX", ZP),
    0x88: ("DEY", IMP), 0x8A: ("TXA", IMP), 0x8C: ("STY", ABS), 0x8D: ("STA", ABS), 0x8E: ("STX", ABS),
    0x90: ("BCC", REL), 0x91: ("STA", IZY), 0x94: ("STY", ZPX), 0x95: ("STA", ZPX),
    0x96: ("STX", ZPY), 0x98: ("TYA", IMP), 0x99: ("STA", ABY), 0x9A: ("TXS", IMP), 0x9D: ("STA", ABX),
    0xA0: ("LDY", IMM), 0xA1: ("LDA", IZX), 0xA2: ("LDX", IMM), 0xA4: ("LDY", ZP),
    0xA5: ("LDA", ZP), 0xA6: ("LDX", ZP), 0xA8: ("TAY", IMP), 0xA9: ("LDA", IMM),
    0xAA: ("TAX", IMP), 0xAC: ("LDY", ABS), 0xAD: ("LDA", ABS), 0xAE: ("LDX", ABS),
    0xB0: ("BCS", REL), 0xB1: ("LDA", IZY), 0xB4: ("LDY", ZPX), 0xB5: ("LDA", ZPX),
    0xB6: ("LDX", ZPY), 0xB8: ("CLV", IMP), 0xB9: ("LDA", ABY), 0xBA: ("TSX", IMP),
    0xBC: ("LDY", ABX), 0xBD: ("LDA", ABX), 0xBE: ("LDX", ABY),
    0xC0: ("CPY", IMM), 0xC1: ("CMP", IZX), 0xC4: ("CPY", ZP), 0xC5: ("CMP", ZP),
    0xC6: ("DEC", ZP), 0xC8: ("INY", IMP), 0xC9: ("CMP", IMM), 0xCA: ("DEX", IMP),
    0xCC: ("CPY", ABS), 0xCD: ("CMP", ABS), 0xCE: ("DEC", ABS),
    0xD0: ("BNE", REL), 0xD1: ("CMP", IZY), 0xD5: ("CMP", ZPX), 0xD6: ("DEC", ZPX),
    0xD8: ("CLD", IMP), 0xD9: ("CMP", ABY), 0xDD: ("CMP", ABX), 0xDE: ("DEC", ABX),
    0xE0: ("CPX", IMM), 0xE1: ("SBC", IZX), 0xE4: ("CPX", ZP), 0xE5: ("SBC", ZP),
    0xE6: ("INC", ZP), 0xE8: ("INX", IMP), 0xE9: ("SBC", IMM), 0xEA: ("NOP", IMP),
    0xEC: ("CPX", ABS), 0xED: ("SBC", ABS), 0xEE: ("INC", ABS),
    0xF0: ("BEQ", REL), 0xF1: ("SBC", IZY), 0xF5: ("SBC", ZPX), 0xF6: ("INC", ZPX),
    0xF8: ("SED", IMP), 0xF9: ("SBC", ABY), 0xFD: ("SBC", ABX), 0xFE: ("INC", ABX),
}

_BRANCHES = {"BPL", "BMI", "BVC", "BVS", "BCC", "BCS", "BNE", "BEQ"}
_ENDS = {"RTS", "RTI", "BRK"}

@dataclass
class Instruction:
    addr: int            # CPU 地址
    opcode: int
    mnemonic: str
    mode: str
    operand: int
    length: int
    raw: bytes
    is_branch: bool
    is_call: bool
    is_jump: bool
    is_indirect: bool
    is_end: bool
    branch_target: int | None
    abs_target: int | None

def decode(buf: bytes, offset: int, base_addr: int) -> Instruction | None:
    """解码 buf[offset] 处指令；base_addr 为 buf[0] 对应的 CPU 地址。非法 opcode 返回 None。"""
    op = buf[offset]
    if op not in OPCODES:
        return None
    mnemonic, mode = OPCODES[op]
    length = MODE_LEN[mode]
    raw = bytes(buf[offset:offset + length])
    if len(raw) < length:
        return None  # bank 尾部截断
    operand = 0
    if length == 2:
        operand = raw[1]
    elif length == 3:
        operand = raw[1] | (raw[2] << 8)
    addr = base_addr + offset
    is_branch = mnemonic in _BRANCHES
    is_call = mnemonic == "JSR"
    is_jump = mnemonic == "JMP"
    is_indirect = is_jump and mode == IND
    is_end = mnemonic in _ENDS or is_jump
    branch_target = abs_target = None
    if is_branch:
        disp = operand - 256 if operand >= 128 else operand
        branch_target = addr + 2 + disp
    elif (is_call or is_jump) and mode == ABS:
        abs_target = operand
    return Instruction(addr=addr, opcode=op, mnemonic=mnemonic, mode=mode, operand=operand,
                       length=length, raw=raw, is_branch=is_branch, is_call=is_call,
                       is_jump=is_jump, is_indirect=is_indirect, is_end=is_end,
                       branch_target=branch_target, abs_target=abs_target)

_MNEMONIC_MODE_TO_OPCODE = {(mn, mode): op for op, (mn, mode) in OPCODES.items()}

def encode(mnemonic: str, mode: str, operand: int = 0) -> bytes:
    """(助记符, 模式, 操作数) → 原始字节。operand 为跳转/分支指令编码前的原始操作数字节值。"""
    op = _MNEMONIC_MODE_TO_OPCODE.get((mnemonic, mode))
    if op is None:
        raise ValueError(f"无法编码: {mnemonic} {mode}")
    n = MODE_LEN[mode]
    if n == 1:
        return bytes([op])
    if n == 2:
        return bytes([op, operand & 0xFF])
    return bytes([op, operand & 0xFF, (operand >> 8) & 0xFF])

def reencode(ins: Instruction) -> bytes:
    """把解码出的 Instruction 重新编码为原始字节（用于无损验证）。"""
    if ins.mode == REL:
        disp = ins.branch_target - (ins.addr + 2)
        return encode(ins.mnemonic, ins.mode, disp & 0xFF)
    return encode(ins.mnemonic, ins.mode, ins.operand)
