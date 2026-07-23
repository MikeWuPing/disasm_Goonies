# 《七宝奇谋》(RC809) 逆向笔记

本文记录阶段 A 反汇编过程中确认的结构事实，每条注明代码证据（bank/地址）。
地址约定：CPU 地址；bank0 = $8000-$BFFF 可切换窗口（prg_banks[0]），bank1 = $C000-$FFFF 固定窗口（prg_banks[1]）。

## 1. 主循环时序模型（C 复刻"NMI 每帧驱动一次"的直接依据）

### 1.1 总体结论

原版把**全部帧工作放在 NMI 中断里完成**；主程序复位后进入一个不做任何帧同步的空转环。
C 复刻的正确模型是：

```
Reset 初始化
for (;;) {
    等待帧边界（vblank）;      // 对应硬件 NMI 触发
    NmiBody();                // 一次 NMI = 渲染尾活 + 声音 + 输入 + 游戏逻辑一帧
}
```

主循环体（MainLoop）在 C 侧**不需要移植**——它只是 ROM 时代的 RNG 搅拌器（见 1.2），
游戏逻辑的"每帧一步"由 NmiBody 尾部的 FrameDispatch 完成。

### 1.2 主循环是 RNG 搅拌空转环，不做帧等待

证据（bank0 $8070-$807C，MainLoop）：

```
L8070: LDA $0D          ; RNG 状态
       ORA FrameCnt     ; $09，NMI 里每帧递增
       AND #$0F
       TAY
       LDA $807F,Y      ; 16 字节状态转移表（DATA_REGION $807F-$808E）
       STA $0D
       JMP L8070
```

循环体内没有 vblank 等待、没有标志轮询；它唯一的效果是把 FrameCnt 的低 4 位持续搅入 $0D。
帧节拍完全由 PPU 的 NMI 硬件中断驱动（InitHardware $8128 置 PpuCtrlShadow=$88，位7开 NMI）。

### 1.3 NMI 帧处理全流程（bank0 $808F Nmi）

按源码顺序（每条已核实）：

1. PHP/PHA/TXA/PHA/TYA/PHA 保存现场；LDA PPU_STATUS 清地址锁存（$8095）。
2. `LDY NmiBusy; BNE` —— **掉帧防重入**（$8098）：若上次 NMI 的重活尚未做完
   （NmiBusy=1），跳过步骤 3/6/9，只走最小路径。
3. NmiBusy==0 时：PpuOff 关显示 → OAM_ADDR=0 → OAM_DMA 页 $0200（OamBuf 整体推送）
   → FlushPpuBuf（$865B，消费 PpuBuf 命令流写 VRAM）。
4. RenderDelay($0C) 非零则递减且 PPU_MASK 写 0（开渲染延迟，防建屏撕裂）；
   到 0 后写 PpuMaskShadow($0F)。（$80AA-$80BA）
5. GameMode!=0 时把 PPU_CTRL 的 nametable X 选择位清 0（顶部 HUD 栏固定在 nametable 0）。（$80BD）
6. `MAPPER87=2` 连写两次（$80CA/$80CD，切 CHR bank 2）→ JSR ResetScroll（bank1 $CE57，
   $2005 双写 0：HUD 区滚动归零）。NmiBusy==0 时 DrawSprites（$8963，精灵阴影页布局）。
7. JSR WaitSprite0（bank1 $CE63）：SceneId($1F) 位7=1 且 RenderDelay=0 时，
   先等 PPU_STATUS 位6（sprite-0 命中）清、再等置 —— 即等电子束扫过 HUD/游戏区界线；
   命中后 JSR ApplyScroll（bank0 $8400：$2005 双写 ScrollX($18)/ScrollY($19)），
   实现**顶栏固定 + 游戏区滚动**的屏幕分割；例程末尾 `MAPPER87=MapperShadow($1E)` 恢复 bank。
8. PPU_CTRL=PpuCtrlShadow；GameMode!=0 时按 $46 位7 与 $80(StageId) 位0 重算 nametable 选择位。（$80DD-$80F5）
9. JSR SoundUpdate（bank1 $F201）：声音驱动每帧步进一次。
10. NmiBusy==0 时：NmiBusy=1 → ReadJoypad($837D) → **FrameDispatch($8158)** →
    FinishOam($8A69，剩余 OAM 槽填 $F4) → NmiBusy=0。（$80FB-$810C）
11. 恢复现场后落到 $8114 RTI —— **IRQ 向量直指该 RTI**（NES 无 IRQ 源，Irq 是共享桩）。

### 1.4 帧计数器与掉帧语义

- FrameCnt($09)/FrameCntHi($17) 在 FrameDispatch 开头 INC/BNE/INC（$8158），
  每个"重活帧"恰好 +1；轻活帧（掉帧）不递增——**FrameCnt 是逻辑帧号，不是 vblank 号**。
- NmiBusy 的生命周期：在同一次 NMI 内 0→1→0（$80FF 置位、$810C 清零）。
  它只在"上一次 NMI 的逻辑段被下一次 vblank 打断"（处理超时=掉帧）时才为 1，
  此时新 NMI 走轻路径：不推 OAM、不刷 VRAM、不跑逻辑，仅保住声音与现场。
- C 复刻用单线程顺序执行即可，但建议保留 NmiBody 内部的段落顺序与
  "逻辑帧号只在重活帧递增"的语义。

### 1.5 游戏逻辑分发（FrameDispatch，bank0 $8158）

```
INC FrameCnt / (回绕) INC FrameCntHi
GameMode($00) < 3 → JSR HandleStartSelect($83B3)   ; 标题区每帧查 Start/Select 边沿
LDA GameMode → JSR DispatchJump($859A) 走 $816C 表  ; 8 个模式处理器，每帧一次
```

GameMode 分发表（DATA_REGION $816C-$817B，8 项）当前解读：
0=上电建屏($817C) 1=计时等待($81A9) 2=标题建屏序列($81B1) 3=PRESS START 闪烁($81F5)
4=开局过渡($822D) 5=游戏主循环($825E，SceneId 低 4 位再分子状态) 6=续关/结束画面($82A0)
7=标题/演示序列($832F→bank1 TitleSeq $EFB8)。
模式计时：ModeTimer($42)/$43 组成 16 位帧计时；ModeTimerSet256($83EB) 置 $0100，
ModeTimerTick($836D) 每帧 Timer16Sub($85FF) 减 1，归零返 A=0（Timer16Add $85F5 为对称加例程）。

### 1.6 PpuBuf：每帧一批的 VRAM 写命令流

- 缓冲 PpuBuf($0600)，写指针 PpuBufIdx($11)。帧内任意时刻生产者追加命令，
  NMI 步骤 3 的 FlushPpuBuf($865B) 一次性消费并清零指针。
- 命令格式（FlushPpuBuf 消费端）：首字节 0=结束 / 2=垂直写（PPU_CTRL 位2），
  随后 PPU 地址双字节，数据写到 $FF 为止。
- 生产端例程族（bank0 除注明外）：PpuBufPut($870A 基础追加)、
  PpuBufPutFF/01/00($8700/$8704/$8708)、PpuBufPutAtX($870C)/PpuBufSetIdx($8710)/
  PpuBufCloseAtX($8713)、PpuBufPutStr($86AD，$872D 字符串指针表)、
  PpuBufPutNum($845C，6 位 BCD)、PpuBufPutAddr($BFA4，命令 1+地址)、
  PpuBufPutAddrV($BFBB，命令 2 垂直写)、PpuBufPutTiles($BFB5)+PpuBufTileStream($BFC0，
  tile 流：$30=重复下一字节 N 次、$FF=结束)、DrawHudItem(bank1 $EC07，HUD 道具 4 tile+$05F2 BCD)。

### 1.7 手柄帧模型

ReadJoypad($837D) 在 NMI 逻辑段每帧一次：$4016 strobe 后 8 位移位；
每位用 `LSR+ORA $27+LSR` 合并 D0/D1 两数据线（抗 DPCM 采样抖动）；
JoyBits($24)=P1|P2 合并、JoyBits2($25)=P2 原始；帧尾
JoyPressed($05)=新按下边沿（EOR JoyHeld AND JoyBits），JoyHeld($07)=上帧值。
HandleStartSelect($83B3)：JoyPressed AND #$30（Start|Select 边沿）分支，GameMode 0-2 每帧调用。

## 2. ROM 布局地图（A12 末状态，全 ROM UNKNOWN 清零）

### bank1（固定窗口 $C000-$FFFF）

- $C000-$CB8F：敌人 AI/物体例程群（DispatchJump $BF10 表 44 项目标去重 21 个 + LC013 等）；
  例程间夹本地参数表（已按"数据读+代码夹逼"证据标 DATA：$C23E/$C344/$C48C/$C5C0/$C67F/$C776/$C8FE/$C9C1 组）。
- $CB90 BgmByStage：按 $A3 查 $CBAC 声音 ID 表（$CBAD-$CBB5，9 字节）播放关卡 BGM。
- $CBB6 ScrollStep：ScrollX 步进与列计数（$81）。
- $CC6E LCC6E：滚动渲染（按 StageId 取关卡流，PpuBuf 填 tile 行）。
- $CE57 ResetScroll / $CE63 WaitSprite0（sprite-0 分割）。
- $CED6 ObjProxScan：每帧物体邻近扫描（FrameCnt&3 相位轮转，参数表 $D096/$D09E/$D0C0/$D0E9，
  键位掩码表 $D083-$D095 已标 DATA）。
- $D083-$D095：场景交互按键掩码表（A11 标 DATA；项 0 的 $D082=0 字节与 BRK 指令重合）。
- $D0C0-$EC06：关卡数据大区（A12 全段判读完毕，分段与格式见 §8，asm 内已有
  SpawnPageTab/LayoutPageTab/PageDescTab/MetaTileStreams 等锚点标签）。
- $EC07 DrawHudItem + $EC84-$ECAF HUD 道具 tile 表（每项 4 tile）。
- $ECB0/$ECB4 LoadScreen0/2：RLE 建屏（流格式 $34/$35/$36/$39，数据 $ED34-$EFB7 已机械解析验证）。
- $EFB8 TitleSeq：标题/演示序列 5 阶段状态机（DispatchJump $EFBE 表）。
- $F08E SoundCmd / $F201 SoundUpdate：Konami 声音驱动；通道组基址表 $F177（$B0/$C1/$D2/$E3），
  音序指针表 $F4CF-$F55C（71 项，项 0 哑元），音序数据 $F55D-$FFF9，$FFFA-$FFFF 向量。

### bank0（可切换窗口 $8000-$BFFF，上电/常态映射 prg_banks[0]）

- $8000-$808E：产品串（$8000-'RC809 1,0 860107'）/Reset/签名/MainLoop；$808F-$8157：NMI 全流程 + Irq 桩 + PpuOff/InitHardware/Sprite0Arm。
- $8158-$845B：FrameDispatch + 8 模式处理器 + SetGameMode/ReadJoypad/HandleStartSelect/GameStart/StageInit。
- $845C-$8764：PpuBuf 例程族 + DispatchJump($859A) + 清场/声音初始化 + FlushPpuBuf + 字符串表。
- $8765-$8955：字符串文本流（tile 编码，首条 'THE GOONIES'；A10 已标 DATA）。
- $8956-$8A80：ClearLoadScreen0/精灵绘制族（DrawSprites/DrawMetasprite/FinishOam）。
- $8A81-$925B：metasprite 数据（A10 已标：指针表 $8A81-$8B80 128 项、$8B81-$8B86 3 项，流 $8B87-$925B）。
- $925C-$BFFF：游戏主体逻辑（物体系统/玩家/敌人/关卡推进），DispatchJump 11 张内联表已全部分标；
  $BFFE 跨界 JSR（见 5.5）。**A11 后 bank0 UNKNOWN 清零**：原 39 个未知小区间全部判明——
  36 个标 DATA（物体系统参数表群，见 §7 与 hints DATA_REGIONS）、$A4A7 两个孤儿 stub 补代码、
  $8632/$9E54 两段无引用死数据标 dead_data。

## 3. DispatchJump 内联表全图（12 张，A9 全标）

通用分发器 DispatchJump($859A)：JSR 后紧跟字指针表，弹返回地址作表基址，A*2 索引 JMP($20)。
常见惯例：表后内联延续代码本身也是表项之一（首项或末项）。

| 调用点 | 表地址 | 项数 | 索引 | 用途判读 |
|---|---|---|---|---|
| bank0 $8169 | $816C | 8 | GameMode | 游戏模式分发 |
| bank0 $9307 | $930A | 7 | $50,X | 物体状态（含内联延续 $9318） |
| bank0 $9BC3 | $9BC6 | 19 | $50,X | 玩家/物体大状态 |
| bank0 $9E96 | $9E99 | 6 | $50,X | 物体子状态（配 $9EA5 数据表） |
| bank0 $9ECD | $9ED0 | 4 | $50,X | 物体子状态 |
| bank0 $9F01 | $9F04 | 6 | $50,X | 物体子状态（末项重复首项） |
| bank0 $A001 | $A004 | 6 | $50,X | 物体子状态（同构） |
| bank0 $A90B | $A90E | 13 | A($4A) | 事件/脚本 |
| bank0 $ADB6 | $ADB9 | 30 | $60,X | 敌人/物体状态族 |
| bank0 $B4F4 | $B4F7 | 9 | A | 道具/HUD 事件 |
| bank0 $BF0D | $BF10 | 44 | A | 敌人 AI（目标全在 bank1，去重 21） |
| bank1 $EFBB | $EFBE | 5 | TitlePhase($0110) | 标题/演示序列 |

注意 $BF10 表项数曾误判 45：bank1 多处 JSR $BF68 实证 $BF68 是代码（ObjPpuAddr）而非表项，
表实为 44 项（$BF10-$BF67）。教训：内联延续代码与表项重叠时，以跨 bank 调用实证为准。

## 4. 杂项事实

- 热启动签名：$07F8-$07FF == $F8..$FF 时跳过重初始化（Reset $8041 校验）。
- 声音通道组零页基址：$B0/$C1/$D2/$E3（$F177 表），SoundCmd 以命令>>6&3 选组。
- sprite-0 标记精灵：OamBuf[0] 写入原型 $27/$FD/$21/$B8（$8154 表），
  WaitSprite0 轮询 PPU_STATUS 位6。

## 5. Mapper 87 切换机制实证（A10）

### 5.1 写寄存器点位：全 ROM 仅 2 处，无独立封装例程

对两 bank 全部 `STA/STX/STY abs` 落 $6000-$7FFF 的指令做机器穷举（含 UNKNOWN 区），
再逐条对照 trace 状态排除操作数字节误匹配（如 `JSR $F08E` 的 $8E/$F0 与下一字节拼出
`STX $68F0` 之类）后，真实写点仅 2 处：

| 位置 | 代码 | 语义 |
|---|---|---|
| bank0 $80CA/$80CD（NMI 内） | `LDA #$02; STA $6000; STA $6000` | 每帧 vblank 强制写 2（双写=防御性写法） |
| bank1 $CE90（WaitSprite0 末尾） | `LDA MapperShadow; STA $6000` | sprite-0 命中后以影子值恢复 |

原始字节扫描在 bank1 $D0C0-$EC06 关卡数据区还有多个 $8D/$8E/$8C 命中，
均为数据字节误匹配（该区域无任何代码引用，A12 将整体标 DATA）。
结论：**没有 mapper 写封装例程**——写操作内联于 NMI 与 WaitSprite0，
配合影子寄存器 $1E 构成全游戏的 bank 切换协议。

### 5.2 影子寄存器 MapperShadow($1E) 协议

全部读写点（机器扫描零页 $1E 的全部寻址模式，排除数据区误配）：

- 写（值 2）：bank0 $818B（L817C 模式 0 建屏）、$8327（L832F 模式 7）；
  bank1 $ECB6（LoadScreen2）、$EFCD（LEFC8）、$F061（LF05C 路径）。
- 写（值 0）：bank0 $8433（StageInit 清场）。
- 写（条件）：bank1 $CB7B（StageScreenSetup：$A3<2 时写 2，否则写 0）。
- 读：仅 bank1 $CE8E（WaitSprite0 末尾恢复，即上表唯一读者）。

协议要点：想换 CHR bank 的代码**只写影子**；物理写 $6000 只发生在帧内两个硬件时刻——
vblank（NMI 强制写 2，顶栏 HUD 区渲染用）与 sprite-0 命中（WaitSprite0 恢复影子，
游戏区渲染用）。即**每帧 CHR bank 在 HUD/游戏区分界线处恰好切换一次**，
与 1.3 节步骤 6/7 的屏幕分割机制互锁。

### 5.3 寄存器位定义推导（以代码证据为准，不照搬 wiki）

- 写入值仅观察到 $00/$02 → 只有**位 1** 被使用，位 0 全程为 0；值为二态信号。
- 本 ROM 为 2×8KB CHR + 2×16KB PRG。已跟踪的全部跨窗口 JSR/JMP（双向百余处，
  现由 emit 自动标注 `-> BankN:名`）均以 "$8000-$BFFF=prg_banks[0]、$C000-$FFFF=
  prg_banks[1] 固定映射"为前提且自洽，**从未观察到 PRG bank 切换动作**——
  本 ROM 不使用 PRG 切换（与 mapper 87 "32KB PRG 固定、仅切 CHR"的常规描述一致）。
- 值→CHR bank 译码：写 2 的场合（NMI 顶栏、标题/游戏屏）对应游戏主图元集；
  写 0 的场合（StageInit 清场、$A3≥2 的 StageScreenSetup）对应建屏过渡。
  按 mapper 87 通行的 "D0/D1 位交换" 译码，$02→CHR bank 1、$00→CHR bank 0，
  与 2 个 8KB CHR bank 的规模自洽。该译码属推测级；代码硬证据只到"值 0/2 二态切换"。

### 5.4 切换发生的场景清单

1. 每帧 vblank：NMI $80CA/$80CD 写 2（顶栏 HUD 图元集）。
2. 每帧 sprite-0 命中：WaitSprite0 $CE90 恢复 MapperShadow（游戏区图元集）。
3. 建屏路径写影子（下一帧 sprite-0 后生效）：LoadScreen2 $ECB6=2、LEFC8 $EFCD=2、
   $F061=2、L817C $818B=2、L832F $8327=2、StageInit $8433=0、
   StageScreenSetup $CB7B=($A3<2?2:0)。

### 5.5 跨 bank 代码流两例（A10 新实证，trace/emit 已支持）

- **跨界指令**：bank0 尾 $BFFE `JSR $8713` 的第三字节（$87）物理位于 bank1 $C000；
  RTS 后 CPU 直接流入 bank1 $C001（TileStreamAdv8：`$35/$36 += 8` 后 `JMP $BFEA`），
  tile 流写入行推进在 bank 边界两侧接力。bank1 $C000 因此是"半个指令字节"，
  物理归属 bank1、逻辑归属 bank0 指令；A12 起在 hints 中以 kind=seam 的 DATA_REGION
  标注（不再是 UNKNOWN），asm 中渲染为裸 `.byte $87` 承接 TileStreamAdv8。
- **跨界分支**：bank0 $BFF8 `BEQ $C00F`（相对位移 +$15 越窗）跳进 bank1 LC00F
  （`JSR $8713; RTS` = tile 流 $FE 终止封口），随后 RTS 返回 bank0。

## 6. bank0 主体逻辑命名进展（A10）

以下为 A10 新增语义名（证据均见 hints/goonies.py COMMENTS）：

- 声音提交：SoundCmdC0($861C)/SoundCmd80($8622) —— 表 $862E-$8631（$40/$80/$C0/$00）逐项送 SoundCmd。
- 字符串族扩展：PpuBufPutStrRaw($86B6 无命令头重入)、PpuBufPutFFAtX($8714)、
  PpuBufPutStrChain($8718 串6+串A+串X+串$1B)、RenderDelay5NmiOn($8136，InitHardware 尾部共用出口，
  LoadScreen0 尾 JMP 回此)。
- 建屏/清场：ClearLoadScreen0($8956)、ClearOamRange($8A6D)、HideOamSlots1to6($B384)、
  ScanObjWindow($BAF4，滚动窗 ±$3C 扫 16 物体记录)。
- 游戏循环：PauseCheck($99DC，Start 翻转 $1A 暂停，送声 $31)、ObjLoopNext($9B55，$48 迭代尾)、
  DispatchObjAi($BDD5，相位门控+PpuBuf 余量后经 $BF10 表分发)、ObjTypeRemap($BEF8)、
  AnimSpriteStep($A7FB，动画 16 位累加夹阈值写精灵号)、SetSpriteByFlag($9504)、
  ObjPosAddDelta($A515)、ObjWalkByDir($9534，A11 由 ObjFlag03Dispatch 改名)、LoadStageTimer($9A16，A11 由 LoadA3Ptr 改名)、
  InitObjRing($B5DF，按 $A3 的槽环模式初始化)、Word16ShlX($BCE4)。
- 孤儿例程（无引用但解码干净且尾转已跟踪代码，保持 L 名）：L8A65/L9510/L951E/LA137/
  LA228/LA2D5/LA2DE/LA4E0/LA588。
- 数据区新标（A10）：产品串 $8000-$8010（'RC809 1,0 860107'+$D7）、文本流 $8765-$8955、
  metasprite 指针表 $8A81-$8B80/$8B81-$8B86（仅 3 项有效）与流 $8B87-$925B、
  $9A29 字表（LoadStageTimer）、$A3C1 X 位移增量表、$A43D 位表、$A541 坐标增量表、
  $A83A 动画参数指针表+$A874 参数流、$B560 三并列表、$B610/$B618 InitObjRing 双表。
  判界方法：跟踪代码数据读基址 + 指针目标机械扫描（区间全封闭）+ 无代码流引用 + 两侧代码夹逼。

## 7. 精灵/物体系统（A11，C 复刻的直接依据）

### 7.1 OAM 体系与槽位布局

OamBuf($0200-$02FF) 是精灵阴影页。NMI 步骤 3（重活帧）整体 DMA 推送（OAM_DMA 页号 2）；
帧内 DrawSprites 把各物体翻译成硬件精灵写入本页，NMI 逻辑段末尾 FinishOam 把剩余槽隐藏。
64 个硬件槽的固定分工（证据逐条见 hints COMMENTS）：

| 槽 | 字节范围 | 用途 | 证据 |
|---|---|---|---|
| 0 | $0200-$0203 | sprite-0 命中标记（HUD/游戏区分割） | Sprite0Arm $8148 抄 $8154 原型 |
| 1-6 | $0204-$021B | 飘分弹出（tile $74）与拳攻击对静态物的命中检测 | FloatScoreShow $B3F2、FloatScoreDrift $B3A2、AttackHitScan $AD64 |
| 7-10 | $021C-$022B | 静态记录物（门/道具图标，帧相位闪帧） | StaticOamAlloc $C15B 步 4 扫 $F4 |
| 11-15 | $022C-$023F | 同上扫描上界内（$AD64 循环到 X<$40） | AttackHitScan $AD62-$AD84 |
| 16-63 | $0240-$02FF | metasprite 区：OamIdx($12) 从 $40 起，回绕也回 $40 | ResetOamIdx $8A7C、DrawMetasprite $8A37 |

绘制顺序（DrawSprites $8963）：槽 $0F → $01（玩家）→ $0E（被救伙伴）→
$02-$0D 按 SpriteRot($15) 轮转起点 → 槽 $00。轮转起点每帧 +1（$02..$0D 循环），
NES 每扫描线 8 精灵限制下让中优先级物体轮流闪烁而非固定消失。
ClearOamRange($8A6D)：OamBuf[X..A) 步 4 填 $F4；FinishOam($8A69) 是其 A=0（填到页尾）形态；
ClearOam($85B4) 整页填 $F4；HideOamSlots1to6($B384) 专藏飘分槽。

metasprite 流格式（DrawMetasprite $8995 消费，数据 $8B87-$925B）：
首字节=片数（0=空），随后每片 3-4 字节：[Y 偏移标志][tile][attr?][X 偏移]。
Y 偏移字节位 0=1 时沿用上一片的 attr（省一字节），其余位是有符号 Y 偏移×2
（ROR 算术右移还原，支持负值）；attr 会再 ORA 槽修饰 ObjAttr($0420,X)（受击闪白/调色）。
$80=嵌套调用（下两字节为新指针，单层），$81=返回。OamIdx 写满一页回绕到 $40。
绘制剪枝：ObjXPage($0410,X)≠0（物体在邻页）或 ObjSprite($70,X)==0 直接跳过；
精灵号 $54-$58（玩家系）X 窗收窄为 [$0C,$F4)，其余 [$08,$F8)。

### 7.2 物体槽布局（16 槽 × 并行数组，槽号即 X 索引）

全字段为"基址+槽号"的并行字节数组（ClearObject $A2E7 的清单为最权威字段表）：

| 偏移 | 符号 | 用途 |
|---|---|---|
| $50,X | ObjState | 槽状态机索引（各类型处理器的 DispatchJump 索引） |
| $60,X | ObjType | 类型：0=玩家、1=伙伴、2-6=敌人、7=弹弓弹、8=炸弹、$0D-$11=弹丸、$12=碎片、$17=可顶替型、$19/$1A=拾取物、$1C=闪烁物、≥$21=飘分/爆风；0 亦=空槽 |
| $70,X | ObjSprite | 精灵号（metasprite 表索引），0=不绘制 |
| $0100,X | ObjContactBits | 接触方向位（PlayerContactScan 写；==3 被夹碎） |
| $0120,X | ObjProbeB | 地形探测结果 B（ObjPhysicsStep Y=$11） |
| $0130,X | ObjFireCd | 开火冷却（ObjFireCheck，$A29E[$1B&7] 重装） |
| $0140,X | ObjAirFlag | 滞空标志（JumpInit 置位，落地清） |
| $0150,X | ProxRec1 | 邻近记录 1（ObjProxScan 写，$FF=无） |
| $0160,X | ProxRec2 | 邻近记录 2（同上） |
| $0170,X | ObjClimbCd | 攀爬冷却（挂起置 $0B） |
| $0400,X | ObjTimer2 | 计时器 2（LA109） |
| $0410,X | ObjXPage | X 第 9 位（跨页位）；非零跳过绘制 |
| $0420,X | ObjAttr | 精灵属性修饰（ORA 入 attr；位0=玩家无敌闪烁（PlayerBlinkTick $9DE2 EOR #1）、位1=类型$1C 物体周期闪（ObjMainLoop L9B63 EOR #2）） |
| $0430,X | ObjTimer | 通用计时（ObjExpireTick 归零变身） |
| $0440,X | ObjAnimFrac | 动画累加小数（16 位定点低字节） |
| $0450,X | ObjAnimAcc | 动画累加整数（位7=往返方向；高位=帧号） |
| $0460,X | ObjY | Y 屏像素（$F4=藏，≥$E8 非玩家回收） |
| $0470,X | ObjX | X 屏像素低 8 位 |
| $0480,X | ObjYFrac | Y 小数（ObjMoveYAdd/Sub） |
| $0490,X | ObjXFrac | X 小数（ObjMoveXAdd/Sub） |
| $04A0,X | ObjMoveDir | 移动方向 1=右/2=左（选朝向帧） |
| $04B0,X | ObjFloorBand | 地面带号 0-8（FloorBandScan，$A2BF 阈值表） |
| $04C0,X | ObjSpeedX | X 速索引（$A647 定点速度表；部分处理器直接作符号像素速） |
| $04D0,X | ObjSpeedY | Y 速索引（同上） |
| $04E0,X | ObjVelYFrac | Y 速度小数（ObjGravity 16 位） |
| $04F0,X | ObjVelY | Y 速度整数（负=升；$FE-$FF 终端速度窗） |
| $0500,X | ObjActFlags | 位6=开火请求、位7=疑似待考证 |
| $0510,X | ObjDirFlags | 位0-1=移动方向、位2-3=攀爬方向、位2 兼=跌落受伤 |
| $0520,X | ObjProbeA | 地形探测结果 A（非零=可站立） |
| $0530,X | ObjRecLink | 记录链接（生成置 $FF；门环配对校验） |
| $0540,X | ObjPhase | 阶段计数（处理器内小状态） |
| $0550,X | ObjVariant | 变体号（服装/方位/行走档） |
| $0560,X | ObjParent | 父子槽互链（弹丸↔母体） |
| $0570,X | ObjBoxProf | 碰撞盒档案号（HitBoxBuild 索引） |
| $0580,X | ObjGrav | 重力（JumpInit 按 $A795 表装载） |
| $0590,X | ObjFrameCnt | 槽帧计数（ObjStateDispatch 每帧 INC） |
| $05A0,X | ObjAtkProbe | 攻击点地形结果（0=有效攻击点） |
| $05B0,X | ObjShieldT | 保护计时（受击豁免） |
| $05C0,X | ObjBandBak | 起跳时地面带备份（跌落落差判定） |

槽位分工（生成例程夹逼证据）：槽 0=伴随/特殊（ObjMainLoop 每帧先查）；
槽 1=玩家（L988E 出生、ClearAllObjects 先清槽 1）；槽 2-6=敌人（FindFreeObjLo $AB64）；
槽 7=弹弓弹（LB0A9）、槽 8=炸弹（LB003/LB04D）；槽 9-$0B=敌人生成（FindFreeObjEx $AB7C，
可顶类型 $17）；槽 $0B-$0D=敌人弹丸（FindFreeObjHi $AB5A）；槽 $0E=被救伙伴
（SpawnRescued $A9C2，绝对地址 $046E/$047E 实证）；槽 $0F=关卡出口/特殊
（L97DF/L937B，绝对地址 $046F/$054F 实证）。ObjMainLoop($9B06) 只驱动 $0D-$00 共 14 槽
（LDX #$0D 起）；槽 $0E/$0F 由专用序列自驱。

类型与状态的关系：ObjStateDispatch($9BB6) 以 ObjType 经 $9BC6 表（19 项）选类型处理器；
处理器内部再以 ObjState($50,X) 经各自 DispatchJump 表（$930A/$9E99/$9ED0/$9F04/$A004）分子状态；
ObjPhase($0540,X) 是子状态内的线性阶段（如 ObjExpireTick 的 0 初始化→1 闪烁→2 变身）。

### 7.3 生成记录环与滚动生成流

关卡物体不直接进槽，先入"生成记录环"SpawnRing($0700-$075F，16 条×6 字节)：

| 偏移 | 用途 |
|---|---|
| +0 ($0700) | X 格位&$F8（页内 8px 对齐） |
| +1 ($0701) | 页号（StageId 页） |
| +2 ($0702) | 生成 id \| 位7（位7=在滚动宽窗内；ObjProxScan 只处理位7=0，ScanObjWindow 按 ScrollX±$3C 维护） |
| +3 ($0703) | Y 参数（SpawnRecordLoad 经 $BCA8 分桶+$BCC9 表译出） |
| +4 ($0704) | 屏 X（$FF=窗外不可用；ScanObjWindow 计算） |
| +5 ($0705) | 状态/占用（ObjProxScan 高半字节类档、StaticOamAlloc 占用标记） |

生成流（bank1 关卡数据，2 字节/条：字节 0=X 格位|子索引、字节 1=id，$FF=桶 0 直取）
由 SpawnStreamPtr($BBFB) 按页定位（$D229+$D161[页]*16）；
SpawnRingFill($BADA)/SpawnRingInit($BC15) 建关整填 16 条，
SpawnStreamAdv($BA7B) 每帧随滚动推进（$88/$89 vs $8A/$8B 窗边界检测），
SpawnRecordLoad($BC2C) 单条载入；$0702 id 分桶表 $BCA8-$BCBD（11 对区间夹逼）。
每帧 DispatchObjAi($BDD5) 双相（$8E&1 正/倒扫）把屏内记录按 ObjTypeRemap
分派给 bank1 $BF10 表 44 项 AI（FrameCnt&2 在 id $43 处分担负载，PpuBufIdx<$28 余量门控）。

门另有 8 条门环（DoorRing $07C0-$07C7 状态 0/2/3、DoorSlotLk $07D0、
DoorTimer $07D8、DoorAnim $07E8；索引=记录 id&7），
InitObjRing($B5DF) 按 $B618[区域] 定环大小、$B610 模式填充；
DoorProxSpawn($B868) 按 $B98F 门位表临近生成门物体，DoorOpenScan($B429) 驱动开门动画，
DoorCloseCheck($B49B) 复位；$033A=挂起门记录。

### 7.4 运动/地形/碰撞三件套

定点运动：速度表 $A647-$A664（15 对整数/小数，0.015-5.0 px/f），
ObjMoveXAdd/Sub($A5B0/$A5F0) 与 ObjMoveYAdd/Sub($A570/$A58F) 加减 16 位定点
（小数 $0490/$0480，整数 $0470/$0460），X 向跨 256 边界翻 ObjXPage 位0，
跨页且屏位入 $40-$C0 时 ClearObject（卷出回收）。
地形：TerrainMap($0340-$03FF，双页各 $60) 8px 一位；TerrainBitTest($A3ED)
把（屏 X+ScrollX，屏 Y）合成世界点查位；ObjPosAddDelta($A515)+LA3ED=探针位移版，
ObjStepY/ObjPhysicsStep 把两个探点结果存 ObjProbeA/B 作站立/穿透判据。
伪 3D 纵深：FloorBandScan($A2A6) 按 $A2BF 阈值把 Y 划为 9 条地面带（$A2C8 为带面 Y），
同带才能互动（ObjFireCheck/PlayerContactScan/LA13C 均比对 $04B0,X vs $04B1=玩家带）。
跳跃：TryClimbOrJump($A665)→JumpInit($A6CD，$A795 表 7 种跳型)→ObjGravity($A6E5)
（终端速度、落地贴带、跌落 ≥4 带玩家受伤）。

碰撞盒：HitBoxBuild($A37A) 按档案号*4 查 $A3C1 四元组建盒（$28-$2B/$2C-$2F 两盒位），
HitBoxTest($A31D) 双轴 AABB；AttackHitScan($AC89) 每帧四轮（拳/踢/弹弓/炸弹）
AttackBoxRun($ACE5)：$AC3F 指针选可击类型表（$AC47-$AC88 四张），
命中转 HitReact($ADAF)——攻击 0 按类型 $ADB9 表 30 项反应，$AE34 音效表，
PlayerDamage($AE43) 按 $AE6C 表扣血并置 $05F6=$50 无敌（PlayerBlinkTick 闪烁）。
变身链：ObjExpireTick($9C4F) 计时尽 → TransformObj($9C90) 按 kind 查
$9CF6-$9D2D 四表（新类型/精灵/计时/分值档）——敌人死亡变拾取物/爆风/飘分的统一出口。

### 7.5 死亡/重生与 HUD 联动

DeathSequence($9ACE)：$05DD==3 且 $B2==0 送声 $16 递减；PlayerBlinkTick($9DD4)
无敌期闪烁（$0421 EOR#1/4 帧）；DeathSeqFlag($05F1) 置位后 ObjMainLoop 只放行
类型 ≥$27（爆风/飘分继续演）。HP：PlayerHp($A0，上限 $17)/PlayerHpShown($A1)
逐帧靠拢并画血格（$BEF2 tile 表，nametable $2086 起）；
HpDelta($9F) 带符号增量（伤害=位7 负值）。关卡倒计时 StageTimer($90/$91 BCD 秒）
由 LoadStageTimer($9A16) 按区域装初值（$9A29 表），StageTimerTick($9A3D) 60 帧减 1 秒，
$90==$50 告警，归零 $51=1 + "TIME UP"。

### 7.6 A11 命名的物体系统例程速查

生成/回收：FindFreeObjLo($AB64 槽 2-6)/FindFreeObjHi($AB5A 槽 $0B-$0D)/
FindFreeObjEx($AB7C 槽 9-$0B)、SpawnObjAtSlot($AB38)、InitObjByKind($AAD8/Y 变体 $AAD1，
$ABD6-$AC3E 错位共享表群）、ClearObject($A2E7)/ClearObjectList($A309)。
动画：AnimSpriteStep($A7FB 单程夹取)/AnimSpritePingpong($A7A3 往返)/
AnimPingpongByDir($9529)/AnimIdleByDir($94E7)/AnimByType1/2($9E61/$9E73)、
SetSpriteByFlag($9504 朝向选帧)。
运动：ObjWalkByDir($9534)、ObjMoveXAdd/Sub 及 IfDir 门控版、ObjMoveYAdd/Sub、
ScrollWorldObj($A60F 滚动联动全槽平移)、FacePlayer($A20F)、ObjFireCheck($A22A)、
ObjThrowProj/2($B211/$B280)+ProjPosInit($B2F1)+SpawnDebris($9E07)+DebrisUpdate($9DEB)。
场景：ObjMainLoop($9B06)/ObjStateDispatch($9BB6)、AttackHitScan($AC89)、
PlayerInteract($B622)/PlayerContactScan($B753)、SpawnRescued($A9C2)/DoorContent($A909)、
FloatScoreShow/Drift($B3E9/$B399)、AddScore($84D0)。
bank1 配套：ObjProxScan($CED6)、RecProxCheck($C060)/RecAttrAddr($C01D)/
StaticOamAlloc($C15B)/Ptr16Add($C013)。

### 7.7 演示模式与死数据

L995C/L9962 = 演示输入注入：$8D 游标读 $99A4-$99DB 按键流
（偶偏移=键位、奇偏移=持续帧数，时长 $FF 结束转 L999F 切模式）——
即标题后 attract mode 的"自动游玩"。$8632-$865A（41 字节）与 $9E54-$9E60（13 字节）
为无引用死数据（前者高熵疑似遗留随机表，后者形如废弃小例程+表），已标 dead_data。

## 8. 关卡数据格式（A12，阶段 B 提取器的直接依据）

本节判读 bank1 $D0C0-$EC06 关卡数据大区。所有边界均经"消费代码反推格式 + 机械扫描
验证封闭"双重确认（页偏移最大值、quad 索引最大值、流模拟覆盖等均精确吻合，无填充猜测）。
asm 锚点标签：ProxClassIdxTab/ProxBoxTab/SpawnPageTab/SpawnBasePtr/SpawnStreamData/
LayoutPageTab/ScrollLockRtTab/ScrollLockLtTab/AltQuadRangeTab/StageAreaMapTab/
StageNameStrTab/QuadBaseDef/QuadRecDef/QuadBaseAlt/QuadRecAlt/PageDescPtr/PageDescTab/
MetaAttrTab/MetaStreamPtrPtr/MetaStreamPtrTab/MetaTileStreams。

### 8.1 分段总表（$D0C0-$EC06，全段连续无空洞）

| 区间 | 锚点 | 类型 | 内容 |
|---|---|---|---|
| $D0C0-$D0E8 | ProxClassIdxTab | 索引表 41B | ObjProxScan 类档→距离框记录号*4 |
| $D0E9-$D160 | ProxBoxTab | 记录 30×4B | ObjProxScan 距离框（+0 X 全宽/+1 Y 下距/+2 X 偏移/+3 Y 偏移） |
| $D161-$D228 | SpawnPageTab | 页表 200B | 生成流页偏移（单位 16B=8 条记录，0=空页） |
| $D229-$D22A | SpawnBasePtr | 指针 | 生成流基址（=$D22B） |
| $D22B-$D6BA | SpawnStreamData | 生成流 | 2 字节/条生成记录（见 8.4） |
| $D6BB-$D782 | LayoutPageTab | 页表 200B | 布局页→页描述符号（单位 12B，$24=空页） |
| $D783-$D79D | ScrollLockRtTab | 列表 26+FF | 右滚锁定页（LCE41 消费，关右端点） |
| $D79E-$D7B8 | ScrollLockLtTab | 列表 26+FF | 左滚锁定页（LCC13 消费，关左端点） |
| $D7B9-$D7CB | AltQuadRangeTab | 区间 9 对+FF | 命中页改用 alt quad 基址（周目版面差分） |
| $D7CC-$D80A | StageAreaMapTab | 映射表 | 页→区域（范围对+$FE 分隔+$FF 终止，10 区域） |
| $D80B-$D81E | StageNameStrTab | 字节表 20B | 关名字符串号（10 区域×2 周目） |
| $D81F-$D820 | QuadBaseDef | 指针 | 默认 quad 基址（=$D821） |
| $D821-$DB60 | QuadRecDef | quad 记录 | 4B/条（2×2 metatile），默认页用 197 索引≤$CF |
| $DB61-$DB62 | QuadBaseAlt | 指针 | alt quad 基址（=$DB63） |
| $DB63-$DDF2 | QuadRecAlt | quad 记录 | 同构，alt 页用 161 索引≤$A3 |
| $DDF3-$DDF4 | PageDescPtr | 指针 | 页描述符基址（=$DDF5） |
| $DDF5-$E0B8 | PageDescTab | 描述符 59×12B | 每字节=8×8 tile 块的 quad 记录号 |
| $E0B9-$E1AC | MetaAttrTab | 属性表 244B | quad 字节→nametable 属性字节（用到 ≤$CF） |
| $E1AD-$E1AE | MetaStreamPtrPtr | 指针 | 流指针表基址（=$E1AF） |
| $E1AF-$E396 | MetaStreamPtrTab | 指针表 244 项 | quad 字节→metatile 流（全落 $E397-$EBF8） |
| $E397-$EC06 | MetaTileStreams | tile 流 | 4×4 tile metatile 流（见 8.3，模拟覆盖无空洞） |

### 8.2 布局链（StageLoad/LCC6E 建屏与滚屏渲染）

一级索引是"页"：StageId($80) 即页号，$81 是页内列计数（0-$20，每页 32 列=256px）；
StageLoad 与 ScrollStep 维护"$32 = StageId + ($81≥$10)"作有效页。渲染链（LCC6E 实证）：

```
LayoutPageTab[$32] (页描述符号 d，$24=空页)
  → PageDescTab[d*12 .. d*12+11] (12 个 quad 记录号：4 列带 × 3 行组)
      行组由 $4D 选择（LCC6E 每次调用渲 8 行带，StageLoad 调 3 次建满 24 行）
      列带由 $CE3D 阈值（08/10/18/20）把列号 $30 映到带内半侧 $3E∈{0,1}
  → quad 记录 4 字节 @ QuadBaseDef+号*4（$32 页命中 AltQuadRangeTab 区间时改用 QuadBaseAlt）
      $3E=0 取字节 0/2（左 4 列），$3E=1 取字节 1/3（右 4 列）——每字节=一个 4×4 metatile
  → quad 字节 q 双索引：
      MetaAttrTab[q]      → 属性字节（写 $23C0/$27C0 属性表，LCC6E $CD47）
      MetaStreamPtrTab[q] → metatile 流地址（写 nametable $2000/$2400 区，LCC6E $CD61）
```

地形位图同步生成：流消费时每写一个 tile，按值更新 TerrainMap($0340)——
tile<$14 清位、≥$14 置位（$9D 为位图偏移、$9E 为位掩码，8px 一位双页各 $60）。

验证事实：LayoutPageTab 最大值 $3A → 描述符 59 条×12B 恰止 $E0B8（接 MetaAttrTab）；
默认/alt quad 实际索引上限 $CF/$A3 → 记录区恰止 $DB60/$DDF2（各接下一指针）。

### 8.3 metatile tile 流格式（MetaTileStreams，LCC6E $CDA3 循环消费）

每流填 4×4=16 个 tile 槽（4 列×4 行，无显式长度，槽满即止）：

- 字节 <$30 或 ≥$3A：字面 tile，占 1 槽；
- $30-$39：本行剩余槽全部填充（低半字节查 $CE1F 表取值：$30-$37→0-7，$38 被拦截为跳指针命令不查表，$39→$41；该表在下标 8/9 处非恒等，$CE1F=00 01..07 00 41 …）；
  填充命令在本行最后一列才被消耗（同一字节可连填多列）；
- $38 lo hi：流指针跳转（换流续读），用于共享公共后缀——与 RLE 屏流同手法。

机械模拟：244 个表项流按上规则消费，触及字节精确覆盖 $E397-$EC06 无空洞、无越界。
tile<$14 / ≥$14 兼作地形位（见 8.2），即 tile 号本身编码碰撞属性。

### 8.4 生成流格式（SpawnStreamData，SpawnRecordLoad $BC2C 消费）

2 字节/条：字节 0 = X 格位（&$F8，页内 8px 对齐）| 子索引（低 3 位）；字节 1 = 生成 id，
$FF = 空位（直取桶 0）。16 字节=8 条为一块，SpawnPageTab[页] 给块号，
SpawnBasePtr($D22B)+块号*16 定位（SpawnStreamPtr $BBFB）。
SpawnRingFill/SpawnRingInit 建关整填 16 条入 SpawnRing($0700-$075F)，
SpawnStreamAdv 随滚动推进换块；id 经 $BCA8 分桶+$BCC9 表译 Y 参数（§7.3）。
验证事实：SpawnPageTab 非零 72 页、最大块号 $48 → 流数据恰止 $D6BA（接 LayoutPageTab）。
生成 id 值域参照 ObjProxScan/DispatchObjAi：$18-$2F 门类、$30-$36 危险物、$39-$3B Boss 门、
$3C-$42 攀爬物、$43+ 敌人（经 ObjTypeRemap 压缩进 $BF10 AI 表）。

### 8.5 区域/周目结构与杂项表

- StageAreaMapTab($D7CC)：页号→区域 0-9。格式=2 字节范围对 [lo,hi) 顺序夹逼，
  $FE=换区（区域计数+1），$FF=表终。区域 0 无范围对（首对 00 00 永不命中=兜底），
  区域 1=页 $6A-$6C，区域 9=页 $61-$63；页号含 +$64 的周目 2 镜像（如 $0D+$64=$71）。
- StageNameStrTab($D80B)：Y=区域*2+（StageId≥$64 周目 2）取 PpuBufPutStr 串号
  （$0E/$13/$0F/$11/$14/$10/$12），StageScreenSetup 经 PpuBufPutStrChain 写屏顶关名。
- ScrollLockRtTab/LtTab($D783/$D79E)：ScrollX==0 且方向匹配时按 StageId 全等扫描，
  命中即停滚（$1C=0）——每关左右端点页清单，两表互补拼出各关可滚区间。
- AltQuadRangeTab($D7B9)：9 个页区间（页 $0C-$18/$55-$63/$6A-$74/$B9-$C2 等）命中时
  LCC6E 改用 QuadRecAlt——同一页描述符在两套 quad 记录上解释出不同版面（周目差分）。
- ObjProxScan 配套（$D09E-$D160，A11 起已标，A12 复核）：$D09E 类型参数对 17 项
  （$33=基础距离兼 X 半宽基数与 Y 上距；$34 装入无读者=死读保留位）；
  ProxClassIdxTab 值=记录号*4（≤$74，代码路径上界 $28=41 项恰满）；
  ProxBoxTab 记录 0 内容为 FF FF FF FF（退化值，匹配窗被推飞=不匹配）。

### 8.6 调色板位置（阶段 B 注意：不是独立表）

全 ROM 无独立调色板表；调色板以 PPU 地址 $3F00 段**内嵌于 PpuBufPutStr 字符串流**
（bank0 文本流区 $8765-$8955，A10 已标 text_stream）。4 处 $3F00 段：

- 串 6（$87CC）：空 $3F00 记录（3F 00 FF，无负载无文本；'KONAMI 1986'/'PUSH START' 文本在串 2 $87CF 的 $2269/$22A9 段，PpuBufPutStrChain 首串仍是串 6）；
- 串 0（$887A）：标题/界面用调色板组；
- 串 $1B（$889D）：链尾串——游戏内调色板（0F 07 00 10 / 0F 16 22 30 / 0F 07 17 27 / 0F 02 00 10 …）；
- 串 5（$892B）：另一组（02 13 04 26 / 02 2C 0F 20 / 02 20 10 0F / 02 20 37 27 …）。

提取器（阶段 B）按串指针表 $872D 索引各串，按 PpuBufPutStr 串格式解析文本流，切出其中 $3F00 段作为调色板数据；
4 处 $3F00 段偏移：$87CC/$887A/$889D/$892B（注意 $87CC 是空记录）。
metasprite 数据在 bank0 $8A81-$925B（A10 已标：指针表 128+3 项、流格式见 §7.1）。

### 8.7 A11 遗留零星语义收尾结论

- $07F3 vs $07F0（实证）：Score($07F3-$07F5)=当前分 3 字节 BCD 低位在前，
  HiScore($07F0-$07F2)=HI 分同构。AddScore 累加当前分后 L853A 高位到低位比较，
  当前分>HI 则抄入 HI；加分进位溢出时两区同夹 $99×3（L8509 写 $07F0-$07F2）。
  PpuBufPutNum 项 2 显当前分（$20B9）、项 4 显 HI（$222E）。冷启动清 $07F0-$07FF 并
  置 $07F2=1（HI 初值末位 1），热启动签名 $07F8-$07FF 命中则两区保留。$07F6/$07F7 无引用。
  RAM_SYMS 已增 Score/HiScore 符号。
- $0500 位7（实证）：ObjActFlags 双人格——玩家槽 1 为 JoyPressed 整字节直拷
  （$9418 写入），位7=A 键边沿（$9485 消费=跳跃）、位6=B 键（$B02F 弹弓/$B052 炸弹）；
  敌人槽位6=开火请求（ObjFireCheck 置位，投射例程消费），位7 由 LA18B 在 ObjDirFlags≠0
  时置位但全 ROM 无读者——写而不用的残留位（推测为调试/废弃标志）。
- $8632/$9E54 dead_data（A12 精确复核，维持原判）：全 PRG 指令操作数与 DATA 字对
  双重扫描零外部引用。$8632 区唯一字面命中在 bank1 $F641（音序数据内 $8640 巧合字节对）；
  $9E54 区=ADC $9E58,Y;RTS+(02 01 00)×3，操作数自指区内（死代码自带死数据）。


