# The Goonies (RC809) 全 ROM 反汇编

[English](README_en.md) | 中文

《七宝奇谋》（The Goonies，Konami 1986，日版编号 RC809）红白机 ROM 的**完整反汇编工程**：一套可复现的 6502 反汇编工具链（纯 Python 标准库，零依赖），加上由它生成的、全 32KB PRG ROM **逐字节分类、逐条注释**的反汇编产物。

这不是一次性的手工导出——工具链从 iNES 头解析、递归下降分析、跳转表标注到 asm 渲染全自动，逆向知识全部沉淀在一个可执行的"提示文件"里，一条命令即可完整再生成全部产物。

## 特性

**反汇编工具链（`tools/disasm/`）**

- 递归下降分析引擎：从 Reset/NMI/IRQ 入口跟踪指令流，自动区分代码与数据，配合提示文件声明间接跳转/跳转表，最终全 ROM UNKNOWN 清零
- 151 个合法 6502 opcode 的完整指令表，逐条 decode→encode 重编码与原字节比对（无损验证内置于管道，不一致即拒绝输出）
- 提示文件（`tools/disasm/hints/goonies.py`）即知识库：入口、语义标签、跳转表、数据区、注释、RAM 符号，全部带中文证据注释；加载器与边界校验器防止知识腐烂（地址越界、标签不落指令边界、控制流目标落入数据区、入口落在数据区内 → 直接报错）
- 跨 bank 调用自动标注（`JSR $CE57  -> Bank1:ResetScroll`）；支持**跨界指令**（本作 `$BFFE` 的 JSR 第三字节落在另一 bank）
- ca65 兼容的输出语法：指令为活动文本，地址与原始字节在行尾注释（本机未装 cc65，外部重汇编验证留作可选扩展）
- 覆盖率报告：每 bank CODE/DATA/UNKNOWN 统计、UNKNOWN 区间清单、分析警告

**反汇编产物（`asm/`）**

- 双 bank 共 32KB **每字节分类完毕**（CODE/DATA，UNKNOWN = 0）
- 170 个语义标签（产物中另含 1212 个 `Lxxxx` 自动标签）、74 个跟踪入口、134 个数据区（含类型与中文注释）、118 个 RAM 符号、12 张内联跳转表全标（分发例程 `DispatchJump` 单一间接跳转，86 个去重目标）
- 命名贴近反汇编语境（`ObjMainLoop`、`FlushPpuBuf`、`StageLoad`…），为后续 C 语言复刻直接服务

产物样例：

```asm
MainLoop:
    ; 主循环 = RNG 搅拌空转环：帧工作全在 NMI，本环只负责搅随机数
    LDA $0D                         ; 8079: A5 0D
    ORA FrameCnt                    ; 807B: 05 1E  ...
    ...
    JSR $CE57                       ; 8334: 20 57 CE   -> Bank1:ResetScroll
```

## 主要逆向发现

- **向量入口在 bank0**：NMI=$808F / Reset=$8011 / IRQ=$8114 全部落在 $8000-$BFFF 窗口，即 bank0 是 mapper 87 的上电默认 bank（目标字节已核：NMI=现场保存序列、Reset=CLD/SEI 初始化、IRQ=RTI 桩）
- **mapper 87 极简使用**：全 ROM 对 `$6000` 的写仅 2 处（NMI 双写 + WaitSprite0 恢复），**PRG bank 从不切换**（只切 CHR）；影子寄存器 `$1E` 值仅 0/2 二态
- **跨界指令**：`$BFFE` 的 `JSR $8713` 第三字节物理落在 bank1 `$C000`，工具链为此支持跨界解码（详见 `docs/re/re_notes.md` §5.5）
- **NMI 驱动帧模型**：主循环是 RNG 搅拌空转环，全部帧工作在 NMI 十一步流程里；`FrameCnt` 只在"重活帧"递增，等于逻辑帧号
- **物体系统**：物体槽 37 字段布局全表（类型/X/Y/状态/计时器/碰撞盒…）、三态 FindFreeObj、生成/消失/变身条件
- **关卡数据四级格式**：布局页链 → 页描述符（12 字节）→ quad 记录 → metatile 流（含 `$CE1F` 填充表在 `$39→$41` 处的非恒等细节，47 处真实数据依赖）
- **调色板无独立表**：内嵌在 PPU 串流中（4 处 `$3F00` 段，锚点见 `docs/re/re_notes.md` §8.6）

全部细节（NMI 时序模型、mapper 87 实证、物体槽字段表、关卡数据格式）见 **[docs/re/re_notes.md](docs/re/re_notes.md)**。

## 仓库结构

```
asm/                     反汇编产物（自动生成，禁止手编，可全量复现）
  goonies_bank0.asm      可切换 bank（$8000-$BFFF）
  goonies_bank1.asm      固定 bank（$C000-$FFFF，含向量表）
  goonies.inc            RAM 与寄存器符号表
  coverage.txt           覆盖率报告与警告
tools/disasm/            反汇编工具链（Python 3.10+，纯标准库）
  run_disasm.py          管道入口：分析 → 渲染 → 报告 → 验证
  ines.py                iNES 头解析
  cpu6502.py             指令表与双向编解码
  hints.py               提示文件加载与结构校验
  trace.py               递归下降引擎与边界校验
  emit.py                asm / inc 渲染
  report.py              覆盖率报告
  hints/goonies.py       ★ 逆向知识库（所有语义命名与数据区声明）
  tests/                 44 项单元/集成测试（unittest）
docs/re/re_notes.md      逆向笔记（本项目配套文档）
```

## 快速开始

需要 Python 3.10+，无第三方依赖。

```bash
# 1. 放入你自己的 ROM（见下一节版本标识）
mkdir -p refer && cp /path/to/org.nes refer/org.nes

# 2. 一条命令全量再生成 asm/（分析 + 渲染 + 报告 + 验证）
python tools/disasm/run_disasm.py

# 3. 跑测试（44 项：指令表往返、递归下降、渲染、提示校验、真实 ROM 集成）
python -m unittest discover -s tools/disasm/tests -t . -v
```

管道返回码：`0`=全通过（UNKNOWN 清零）；`1`=覆盖不全；`2`=提示文件错误（知识腐烂，报错带 bank 和地址）；`3`=重编码不一致。

### ROM 版本标识

本工程针对日版 RC809（1986-01-07），iNES 格式：

| 项 | 值 |
|---|---|
| 文件大小 | 49168 字节（16 字节头 + 2×16KB PRG + 2×8KB CHR） |
| Mapper | 87，垂直镜像 |
| MD5 | `460d3e6805496c35d630f538d01e68e4` |
| SHA-1 | `78e80a5bdf23feb5f287fda15a9bffa4431fc7ba` |

ROM 头部产品串 `RC809 1,0 860107` 可在 `asm/goonies_bank0.asm` 开头直接看到。其他版本（美版/欧版）未经适配。**ROM 文件不在本仓库中**，请自备。

## 版权与法律声明

- 《The Goonies》游戏及其代码、美术均为 **Konami 知识产权**（© Konami 1986）。
- `asm/` 目录是原作 PRG ROM 的反汇编，**其版权仍归 Konami 所有**；本仓库以学习、研究与互操作目的公开，不包含 ROM 文件、CHR 图形数据或任何可直接运行的游戏素材。
- 本项目与 Konami 无任何关联，亦非官方认可作品。若权利方有任何疑虑，请开 issue 联系，我们将及时处理。
- **`tools/` 与 `docs/` 中的原创工具链与文档**以 [MIT License](LICENSE) 授权（该授权不适用于 `asm/` 反汇编产物）。

## 项目背景

本仓库是一个更大工程的第一阶段产物：目标是在 UEFI Shell 环境下（GOP 图形、QEMU/OVMF 验证）用 C 语言原味复刻《七宝奇谋》——逻辑不凭印象重写，全部对照本反汇编翻译。后续阶段（ROM 资源提取器、UEFI 工程骨架、游戏核心复刻、保真验证）将在同一仓库陆续公开。
