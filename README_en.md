# The Goonies (RC809) — Full ROM Disassembly

English | [中文](README.md)

A **complete disassembly project** for The Goonies (Konami, 1986, Japanese release RC809) on the NES: a reproducible 6502 disassembler toolchain (pure Python standard library, zero dependencies) plus the fully classified, fully annotated disassembly it generates — every single byte of the 32KB PRG ROM accounted for.

This is not a one-off manual export. The toolchain does everything from iNES header parsing and recursive-descent analysis to jump-table annotation and asm rendering. All reverse-engineering knowledge lives in an executable "hints file," so the entire output regenerates with a single command.

## Features

**Disassembler toolchain (`tools/disasm/`)**

- Recursive-descent analysis engine: traces instruction flow from the Reset/NMI/IRQ entries, automatically separating code from data. With hint-file declarations for indirect jumps and jump tables, the UNKNOWN byte count reaches zero across the whole ROM.
- Complete table of the 151 legal 6502 opcodes, with per-instruction decode→encode re-encoding verified byte-for-byte against the original (losslessness is enforced in the pipeline; any mismatch aborts the run).
- The hints file (`tools/disasm/hints/goonies.py`) *is* the knowledge base: entries, semantic labels, jump tables, data regions, comments, and RAM symbols — all with evidence notes. Load-time and boundary validators keep the knowledge from rotting (out-of-window addresses, labels not on instruction boundaries, control-flow targets landing inside data regions, entries inside data regions → hard errors).
- Automatic cross-bank call annotation (`JSR $CE57  -> Bank1:ResetScroll`) and support for a **bank-straddling instruction** (this game's `JSR` at `$BFFE` has its third byte physically inside the other bank).
- ca65-compatible output syntax: instructions as live text, addresses and raw bytes in trailing comments (cc65 is not installed locally; external re-assembly verification is an optional extension).
- Coverage report: per-bank CODE/DATA/UNKNOWN statistics, UNKNOWN range listing, and analysis warnings.

**Disassembly output (`asm/`)**

- All 32KB across both banks **classified byte-by-byte** (CODE/DATA, UNKNOWN = 0).
- 170 semantic labels (plus 1,212 automatic `Lxxxx` labels in the output), 74 trace entries, 134 data regions (typed, with comments), 118 RAM symbols, 12 inline jump tables fully mapped (a single indirect-jump dispatcher `DispatchJump`, 86 deduplicated targets).
- Naming stays close to the disassembly context (`ObjMainLoop`, `FlushPpuBuf`, `StageLoad`…), ready to serve a follow-up faithful C reimplementation.

Sample output:

```asm
MainLoop:
    ; main loop = RNG-stirring idle ring: all frame work happens in NMI
    LDA $0D                         ; 8079: A5 0D
    ORA FrameCnt                    ; 807B: 05 1E  ...
    ...
    JSR $CE57                       ; 8334: 20 57 CE   -> Bank1:ResetScroll
```

## Key Reverse-Engineering Findings

- **Vectors live in bank0**: NMI=$808F / Reset=$8011 / IRQ=$8114 all point into the $8000-$BFFF window — bank0 is mapper 87's power-on default bank (entry bytes verified: NMI = register-save sequence, Reset = CLD/SEI init, IRQ = RTI stub).
- **Minimal mapper 87 usage**: only two `$6000` writes exist in the entire ROM (an NMI double-write and a WaitSprite0 restore); the **PRG bank is never switched** (CHR bank only); the shadow register `$1E` takes just two values (0/2).
- **Bank-straddling instruction**: the `JSR $8713` at `$BFFE` has its third byte physically at `$C000` in bank1; the toolchain supports cross-boundary decoding for it (see `docs/re/re_notes.md` §5.5).
- **NMI-driven frame model**: the main loop is an RNG-stirring idle ring; all per-frame work happens inside an 11-step NMI sequence. `FrameCnt` increments only on "busy frames," making it the logical frame number.
- **Object system**: a fully mapped 37-field object-slot layout (type/X/Y/state/timers/hitboxes…), the three-state FindFreeObj allocator, and spawn/despawn/transform conditions.
- **Four-level level-data format**: layout page chain → 12-byte page descriptors → quad records → metatile streams (including the non-identity `$39→$41` entry of the `$CE1F` fill table, which 47 real data sites depend on).
- **No standalone palette table**: palettes are embedded in PPU string streams (four `$3F00` segments; anchors in `docs/re/re_notes.md` §8.6).

Full details (NMI timing model, mapper 87 evidence, object-slot field table, level-data format) are in **[docs/re/re_notes.md](docs/re/re_notes.md)** — currently in Chinese, with precise address-level citations throughout.

## Repository Layout

```
asm/                     Disassembly output (auto-generated, do not edit, fully reproducible)
  goonies_bank0.asm      Switchable bank ($8000-$BFFF)
  goonies_bank1.asm      Fixed bank ($C000-$FFFF, contains the vectors)
  goonies.inc            RAM and hardware register symbols
  coverage.txt           Coverage report and warnings
tools/disasm/            Disassembler toolchain (Python 3.10+, stdlib only)
  run_disasm.py          Pipeline entry: analyze → render → report → verify
  ines.py                iNES header parsing
  cpu6502.py             Opcode table and bidirectional encode/decode
  hints.py               Hints-file loading and structural validation
  trace.py               Recursive-descent engine and boundary validation
  emit.py                asm / inc rendering
  report.py              Coverage report
  hints/goonies.py       ★ The reverse-engineering knowledge base
  tests/                 44 unit/integration tests (unittest)
docs/re/re_notes.md      Reverse-engineering notes (companion document)
```

## Quick Start

Requires Python 3.10+. No third-party dependencies.

```bash
# 1. Drop in your own ROM (see version fingerprint below)
mkdir -p refer && cp /path/to/org.nes refer/org.nes

# 2. Regenerate asm/ in one shot (analyze + render + report + verify)
python tools/disasm/run_disasm.py

# 3. Run the tests (44: opcode round-trips, recursive descent, rendering,
#    hints validation, real-ROM integration)
python -m unittest discover -s tools/disasm/tests -t . -v
```

Pipeline exit codes: `0` = all good (UNKNOWN cleared); `1` = incomplete coverage; `2` = hints-file error (knowledge rot, reported with bank and address); `3` = re-encode mismatch.

### ROM Version Fingerprint

This project targets the Japanese RC809 release (1986-01-07), iNES format:

| Item | Value |
|---|---|
| File size | 49,168 bytes (16-byte header + 2×16KB PRG + 2×8KB CHR) |
| Mapper | 87, vertical mirroring |
| MD5 | `460d3e6805496c35d630f538d01e68e4` |
| SHA-1 | `78e80a5bdf23feb5f287fda15a9bffa4431fc7ba` |

The ROM's product string `RC809 1,0 860107` is visible at the top of `asm/goonies_bank0.asm`. Other regional versions are untested. **The ROM file is not included in this repository** — please supply your own.

## Copyright & Legal

- The Goonies, including its code and artwork, is the **intellectual property of Konami** (© Konami 1986).
- The `asm/` directory is a disassembly of the original PRG ROM and **remains Konami's copyright**. It is published here for study, research, and interoperability purposes. This repository contains no ROM file, no CHR graphics data, and no playable game assets.
- This project is not affiliated with, endorsed by, or sponsored by Konami. If you are a rights holder with concerns, please open an issue and we will respond promptly.
- The **original tooling and documentation under `tools/` and `docs/`** are licensed under the [MIT License](LICENSE) (this license does not apply to the `asm/` disassembly output).

## Project Context

This repository is the first milestone of a larger effort: a faithful reimplementation of The Goonies in C, running as a UEFI Shell application (GOP graphics, verified under QEMU/OVMF) — with game logic translated line-by-line from this disassembly rather than rewritten from memory. Later milestones (ROM asset extractor, UEFI project skeleton, game-core port, fidelity verification) will be published in this same repository.
