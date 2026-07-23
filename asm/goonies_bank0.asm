; === Goonies RC809 — Bank 0 (base $8000) ===
; 本文件由 tools/disasm 自动生成，请勿手工编辑
.include "goonies.inc"

    .byte $52,$43,$38,$30,$39,$20,$31,$2C         ; 8000: 52 43 38 30 39 20 31 2C
    .byte $30,$20,$38,$36,$30,$31,$30,$37         ; 8008: 30 20 38 36 30 31 30 37
    .byte $D7                                     ; 8010: D7
Reset:
    ; 上电复位：等两个 vblank→PpuOff→清 RAM $0000-$07EF→验热启动签名→InitHardware→主循环 L8070
    CLD                         ; 8011: D8
    SEI                         ; 8012: 78
    LDA #$00                    ; 8013: A9 00
    STA SceneId                 ; 8015: 85 1F
L8017:
    LDA PPU_STATUS              ; 8017: AD 02 20
    BPL L8017                   ; 801A: 10 FB
L801C:
    LDA PPU_STATUS              ; 801C: AD 02 20
    BPL L801C                   ; 801F: 10 FB
    JSR PpuOff                  ; 8021: 20 15 81
    LDX #$FF                    ; 8024: A2 FF
    TXS                         ; 8026: 9A
    INX                         ; 8027: E8
    LDA #$07                    ; 8028: A9 07
    STA $21                     ; 802A: 85 21
    TXA                         ; 802C: 8A
    STA TmpPtr                  ; 802D: 85 20
    LDY #$EF                    ; 802F: A0 EF
    STA SpawnRing               ; 8031: 8D 00 07
    STA GameMode                ; 8034: 85 00
L8036:
    STA ($20),Y                 ; 8036: 91 20
    DEY                         ; 8038: 88
    BNE L8036                   ; 8039: D0 FB
    DEC $21                     ; 803B: C6 21
    BPL L8036                   ; 803D: 10 F7
    LDX #$F8                    ; 803F: A2 F8
L8041:
    ; 热启动签名校验：$07F8+i == $F8+i（i=0..7）则跳过重建
    TXA                         ; 8041: 8A
    CMP SpawnRing,X             ; 8042: DD 00 07
    BNE L804C                   ; 8045: D0 05
    INX                         ; 8047: E8
    BNE L8041                   ; 8048: D0 F7
    BEQ L8063                   ; 804A: F0 17
L804C:
    ; 签名不符：清 $07F0-$07FF、$07F2=1、重写 $07F8-$07FF 签名
    TYA                         ; 804C: 98
    LDY #$F0                    ; 804D: A0 F0
L804F:
    STA SpawnRing,Y             ; 804F: 99 00 07
    INY                         ; 8052: C8
    BNE L804F                   ; 8053: D0 FA
    LDA #$01                    ; 8055: A9 01
    STA $07F2                   ; 8057: 8D F2 07
    LDX #$F8                    ; 805A: A2 F8
L805C:
    TXA                         ; 805C: 8A
    STA SpawnRing,X             ; 805D: 9D 00 07
    INX                         ; 8060: E8
    BNE L805C                   ; 8061: D0 F9
L8063:
    JSR InitHardware            ; 8063: 20 28 81
    JSR InitSound               ; 8066: 20 14 86
    LDA #$02                    ; 8069: A9 02
    STA SpriteRot               ; 806B: 85 15
    JSR ResetOamIdx             ; 806D: 20 7C 8A
MainLoop:
    ; 主循环空转：按 ($0D|FrameCnt)&$0F 查 $807F 状态表；实际工作全在 NMI 内
    LDA $0D                     ; 8070: A5 0D
    ORA FrameCnt                ; 8072: 05 09
    AND #$0F                    ; 8074: 29 0F
    TAY                         ; 8076: A8
    LDA $807F,Y                 ; 8077: B9 7F 80
    STA $0D                     ; 807A: 85 0D
    JMP MainLoop                ; 807C: 4C 70 80
    .byte $33,$BB,$3F,$80,$2E,$A9,$61,$87         ; 807F: 33 BB 3F 80 2E A9 61 87
    .byte $AD,$C3,$B2,$C8,$7C,$25,$48,$7A         ; 8087: AD C3 B2 C8 7C 25 48 7A
Nmi:
    ; 帧节拍主体：OAM DMA($0200)→FlushPpuBuf→切 CHR 调 bank1→SoundUpdate→ReadJoypad/FrameDispatch；NmiBusy 防重入
    PHP                         ; 808F: 08
    PHA                         ; 8090: 48
    TXA                         ; 8091: 8A
    PHA                         ; 8092: 48
    TYA                         ; 8093: 98
    PHA                         ; 8094: 48
    LDA PPU_STATUS              ; 8095: AD 02 20
    LDY NmiBusy                 ; 8098: A4 04
    BNE L80AA                   ; 809A: D0 0E
    JSR PpuOff                  ; 809C: 20 15 81
    STA OAM_ADDR                ; 809F: 8D 03 20
    LDY #$02                    ; 80A2: A0 02
    STY OAM_DMA                 ; 80A4: 8C 14 40
    JSR FlushPpuBuf             ; 80A7: 20 5B 86
L80AA:
    LDA PpuMaskShadow           ; 80AA: A5 0F
    LDX RenderDelay             ; 80AC: A6 0C
    BEQ L80BA                   ; 80AE: F0 0A
    LDX NmiBusy                 ; 80B0: A6 04
    BNE L80B8                   ; 80B2: D0 04
    DEC RenderDelay             ; 80B4: C6 0C
    BEQ L80BA                   ; 80B6: F0 02
L80B8:
    LDA #$00                    ; 80B8: A9 00
L80BA:
    STA PPU_MASK                ; 80BA: 8D 01 20
    LDA GameMode                ; 80BD: A5 00
    BEQ L80C8                   ; 80BF: F0 07
    LDA PpuCtrlShadow           ; 80C1: A5 0E
    AND #$FE                    ; 80C3: 29 FE
    STA PPU_CTRL                ; 80C5: 8D 00 20
L80C8:
    ; Mapper87 写 $6000 两次（值 2=CHR bank）后 JSR bank1 ResetScroll
    LDA #$02                    ; 80C8: A9 02
    STA MAPPER87                ; 80CA: 8D 00 60
    STA MAPPER87                ; 80CD: 8D 00 60
    JSR $CE57                   ; 80D0: 20 57 CE  -> Bank1:ResetScroll
    LDA NmiBusy                 ; 80D3: A5 04
    BNE L80DA                   ; 80D5: D0 03
    JSR DrawSprites             ; 80D7: 20 63 89
L80DA:
    JSR $CE63                   ; 80DA: 20 63 CE  -> Bank1:WaitSprite0
    LDA PpuCtrlShadow           ; 80DD: A5 0E
    STA PPU_CTRL                ; 80DF: 8D 00 20
    LDA GameMode                ; 80E2: A5 00
    BEQ L80F8                   ; 80E4: F0 12
    LDA StageId                 ; 80E6: A5 80
    LSR A                       ; 80E8: 4A
    LDA PpuCtrlShadow           ; 80E9: A5 0E
    AND #$FE                    ; 80EB: 29 FE
    LDX $46                     ; 80ED: A6 46
    BMI L80F3                   ; 80EF: 30 02
    ADC #$00                    ; 80F1: 69 00
L80F3:
    STA PpuCtrlShadow           ; 80F3: 85 0E
    STA PPU_CTRL                ; 80F5: 8D 00 20
L80F8:
    JSR $F201                   ; 80F8: 20 01 F2  -> Bank1:SoundUpdate
    LDA NmiBusy                 ; 80FB: A5 04
    BNE L810E                   ; 80FD: D0 0F
    INC NmiBusy                 ; 80FF: E6 04
    JSR ReadJoypad              ; 8101: 20 7D 83
    JSR FrameDispatch           ; 8104: 20 58 81
    JSR FinishOam               ; 8107: 20 69 8A
    LDA #$00                    ; 810A: A9 00
    STA NmiBusy                 ; 810C: 85 04
L810E:
    PLA                         ; 810E: 68
    TAY                         ; 810F: A8
    PLA                         ; 8110: 68
    TAX                         ; 8111: AA
    PLA                         ; 8112: 68
    PLP                         ; 8113: 28
Irq:
    ; IRQ 桩：仅 RTI（NES 无 IRQ 源）；与 NMI 寄存器恢复尾共用地址，向量直指此处
    RTI                         ; 8114: 40
PpuOff:
    ; A=0 写 PPU_CTRL/PPU_MASK 关显示；Reset/NMI/LoadScreen 共用
    LDA #$00                    ; 8115: A9 00
    STA PPU_CTRL                ; 8117: 8D 00 20
    STA PPU_MASK                ; 811A: 8D 01 20
    RTS                         ; 811D: 60
L811E:
    LDA PpuCtrlShadow           ; 811E: A5 0E
    STA PPU_CTRL                ; 8120: 8D 00 20
    LDA #$1E                    ; 8123: A9 1E
    STA PpuMaskShadow           ; 8125: 85 0F
    RTS                         ; 8127: 60
InitHardware:
    ; $4015=$1F 开 APU 通道、$4017=$C0；PpuCtrlShadow=$88 开 NMI；PpuMaskShadow=$1E、RenderDelay=5
    LDA #$1F                    ; 8128: A9 1F
    STA APU_STATUS              ; 812A: 8D 15 40
    LDA #$C0                    ; 812D: A9 C0
    STA JOY2                    ; 812F: 8D 17 40
    LDA #$1E                    ; 8132: A9 1E
    STA PpuMaskShadow           ; 8134: 85 0F
RenderDelay5NmiOn:
    LDA #$05                    ; 8136: A9 05
    STA RenderDelay             ; 8138: 85 0C
    LDA #$88                    ; 813A: A9 88
    STA PpuCtrlShadow           ; 813C: 85 0E
    STA PPU_CTRL                ; 813E: 8D 00 20
    RTS                         ; 8141: 60
Sprite0Arm:
    ; sprite-0 武装：SceneId=$80（位7=分割使能），$8154 原型 4 字节抄入 OamBuf[0..3] 作命中标记
    LDA #$80                    ; 8142: A9 80
    STA SceneId                 ; 8144: 85 1F
L8146:
    LDX #$00                    ; 8146: A2 00
L8148:
    LDA $8154,X                 ; 8148: BD 54 81
    STA OamBuf,X                ; 814B: 9D 00 02
    INX                         ; 814E: E8
    CPX #$04                    ; 814F: E0 04
    BNE L8148                   ; 8151: D0 F5
    RTS                         ; 8153: 60
    .byte $27,$FD,$21,$B8                         ; 8154: 27 FD 21 B8
FrameDispatch:
    ; FrameCnt/FrameCntHi 递增；GameMode<3 先 HandleStartSelect；再按 GameMode 经 DispatchJump 分发表 $816C
    INC FrameCnt                ; 8158: E6 09
    BNE L815E                   ; 815A: D0 02
    INC FrameCntHi              ; 815C: E6 17
L815E:
    LDA GameMode                ; 815E: A5 00
    CMP #$03                    ; 8160: C9 03
    BCS L8167                   ; 8162: B0 03
    JSR HandleStartSelect       ; 8164: 20 B3 83
L8167:
    LDA GameMode                ; 8167: A5 00
    JSR DispatchJump            ; 8169: 20 9A 85
    .byte $7C,$81,$A9,$81,$B1,$81,$F5,$81         ; 816C: 7C 81 A9 81 B1 81 F5 81
    .byte $2D,$82,$5E,$82,$A0,$82,$2F,$83         ; 8174: 2D 82 5E 82 A0 82 2F 83
L817C:
    LDA SubMode                 ; 817C: A5 01
    BNE L8196                   ; 817E: D0 16
    JSR L925C                   ; 8180: 20 5C 92
    LDA #$00                    ; 8183: A9 00
    STA ScrollX                 ; 8185: 85 18
    STA StageId                 ; 8187: 85 80
    LDA #$02                    ; 8189: A9 02
    STA MapperShadow            ; 818B: 85 1E
    LDA PpuCtrlShadow           ; 818D: A5 0E
    ORA #$01                    ; 818F: 09 01
    STA PpuCtrlShadow           ; 8191: 85 0E
    INC SubMode                 ; 8193: E6 01
L8195:
    RTS                         ; 8195: 60
L8196:
    INC ScrollX                 ; 8196: E6 18
    BNE L8195                   ; 8198: D0 FB
    LDA PpuCtrlShadow           ; 819A: A5 0E
    AND #$FE                    ; 819C: 29 FE
    STA PpuCtrlShadow           ; 819E: 85 0E
    JSR L8210                   ; 81A0: 20 10 82
    JSR ModeTimerSet256         ; 81A3: 20 EB 83
    JMP L824E                   ; 81A6: 4C 4E 82
L81A9:
    JSR ModeTimerTick           ; 81A9: 20 6D 83
    BNE L8195                   ; 81AC: D0 E7
    JMP L824A                   ; 81AE: 4C 4A 82
L81B1:
    LDX SubMode                 ; 81B1: A6 01
    BEQ L81E1                   ; 81B3: F0 2C
    DEX                         ; 81B5: CA
    BEQ L81CC                   ; 81B6: F0 14
    DEX                         ; 81B8: CA
    BEQ L81C7                   ; 81B9: F0 0C
    JSR L995C                   ; 81BB: 20 5C 99
    LDA $0A                     ; 81BE: A5 0A
    BEQ L8195                   ; 81C0: F0 D3
    LDA #$00                    ; 81C2: A9 00
    JMP SetGameMode             ; 81C4: 4C 5C 83
L81C7:
    INC SubMode                 ; 81C7: E6 01
    JMP L988E                   ; 81C9: 4C 8E 98
L81CC:
    JSR ModeTimerTick           ; 81CC: 20 6D 83
    BNE L8195                   ; 81CF: D0 C4
    INC SubMode                 ; 81D1: E6 01
    INC $03                     ; 81D3: E6 03
    JSR L841B                   ; 81D5: 20 1B 84
    JSR ModeTimerSet256         ; 81D8: 20 EB 83
    JSR L9938                   ; 81DB: 20 38 99
    JMP Sprite0Arm              ; 81DE: 4C 42 81
L81E1:
    JSR ModeTimerSet256         ; 81E1: 20 EB 83
    JSR ClearLoadScreen0        ; 81E4: 20 56 89
    INC SubMode                 ; 81E7: E6 01
    LDX #$0F                    ; 81E9: A2 0F
    LDA #$19                    ; 81EB: A9 19
    JSR PpuBufPutStrChain       ; 81ED: 20 18 87
    LDA #$01                    ; 81F0: A9 01
    JMP PpuBufPutStr            ; 81F2: 4C AD 86
L81F5:
    LDX SubMode                 ; 81F5: A6 01
    BEQ L8226                   ; 81F7: F0 2D
    DEX                         ; 81F9: CA
    BEQ L8206                   ; 81FA: F0 0A
    JSR L840E                   ; 81FC: 20 0E 84
    LDA #$01                    ; 81FF: A9 01
    STA $07C9                   ; 8201: 8D C9 07
    BNE L824E                   ; 8204: D0 48
L8206:
    DEC ModeTimer               ; 8206: C6 42
    BEQ L8219                   ; 8208: F0 0F
    LDA ModeTimer               ; 820A: A5 42
    AND #$08                    ; 820C: 29 08
    BNE L8214                   ; 820E: D0 04
L8210:
    LDA #$03                    ; 8210: A9 03
    BNE L8216                   ; 8212: D0 02
L8214:
    LDA #$83                    ; 8214: A9 83
L8216:
    JMP PpuBufPutStr            ; 8216: 4C AD 86
L8219:
    LDX #$0F                    ; 8219: A2 0F
    LDA #$19                    ; 821B: A9 19
    JSR PpuBufPutStrChain       ; 821D: 20 18 87
    LDA #$05                    ; 8220: A9 05
    STA RenderDelay             ; 8222: 85 0C
    BNE L8257                   ; 8224: D0 31
L8226:
    LDY #$1C                    ; 8226: A0 1C
    JSR SoundCmdC0              ; 8228: 20 1C 86
    BCS L825B                   ; 822B: B0 2E
L822D:
    LDA SubMode                 ; 822D: A5 01
    BEQ L8237                   ; 822F: F0 06
    JSR Sprite0Arm              ; 8231: 20 42 81
    JMP L824E                   ; 8234: 4C 4E 82
L8237:
    LDA #$FF                    ; 8237: A9 FF
    STA DoorPendRec             ; 8239: 8D 3A 03
    LDA #$00                    ; 823C: A9 00
    STA HpDelta                 ; 823E: 85 9F
    JSR L9938                   ; 8240: 20 38 99
    LDA #$00                    ; 8243: A9 00
    STA $07C9                   ; 8245: 8D C9 07
    BEQ L825B                   ; 8248: F0 11
L824A:
    LDA #$54                    ; 824A: A9 54
    STA ModeTimer               ; 824C: 85 42
L824E:
    INC GameMode                ; 824E: E6 00
L8250:
    LDA #$00                    ; 8250: A9 00
    STA $0A                     ; 8252: 85 0A
    STA SubMode                 ; 8254: 85 01
    RTS                         ; 8256: 60
L8257:
    LDA #$50                    ; 8257: A9 50
    STA ModeTimer               ; 8259: 85 42
L825B:
    INC SubMode                 ; 825B: E6 01
    RTS                         ; 825D: 60
L825E:
    LDA SceneId                 ; 825E: A5 1F
    AND #$0F                    ; 8260: 29 0F
    TAY                         ; 8262: A8
    BEQ L829D                   ; 8263: F0 38
    DEY                         ; 8265: 88
    BEQ L8289                   ; 8266: F0 21
    DEY                         ; 8268: 88
    BEQ L8282                   ; 8269: F0 17
    DEY                         ; 826B: 88
    BEQ L8271                   ; 826C: F0 03
    JMP L9A6B                   ; 826E: 4C 6B 9A
L8271:
    LDA $05D5                   ; 8271: AD D5 05
    BEQ L827A                   ; 8274: F0 04
    DEC $05D5                   ; 8276: CE D5 05
    RTS                         ; 8279: 60
L827A:
    LDA #$23                    ; 827A: A9 23
    JSR $F08E                   ; 827C: 20 8E F0  -> Bank1:SoundCmd
    INC SceneId                 ; 827F: E6 1F
    RTS                         ; 8281: 60
L8282:
    LDA $B2                     ; 8282: A5 B2
    BNE L829C                   ; 8284: D0 16
    JMP L824A                   ; 8286: 4C 4A 82
L8289:
    LDA $0335                   ; 8289: AD 35 03
    BEQ L8293                   ; 828C: F0 05
    LDA #$07                    ; 828E: A9 07
    JMP SetGameMode             ; 8290: 4C 5C 83
L8293:
    JSR L986A                   ; 8293: 20 6A 98
    LDA $0A                     ; 8296: A5 0A
    BEQ L829C                   ; 8298: F0 02
    INC SceneId                 ; 829A: E6 1F
L829C:
    RTS                         ; 829C: 60
L829D:
    JMP L988E                   ; 829D: 4C 8E 98
L82A0:
    LDA #$00                    ; 82A0: A9 00
    STA SceneId                 ; 82A2: 85 1F
    STA $05FF                   ; 82A4: 8D FF 05
    LDX SubMode                 ; 82A7: A6 01
    BEQ L8300                   ; 82A9: F0 55
    JSR ModeTimerTick           ; 82AB: 20 6D 83
    BNE L82BC                   ; 82AE: D0 0C
    LDX #$04                    ; 82B0: A2 04
    LDA #$00                    ; 82B2: A9 00
    JSR ClearOamRange           ; 82B4: 20 6D 8A
    LDA #$00                    ; 82B7: A9 00
    JMP SetGameMode             ; 82B9: 4C 5C 83
L82BC:
    LDA JoyHeld                 ; 82BC: A5 07
    TAY                         ; 82BE: A8
    AND #$10                    ; 82BF: 29 10
    BNE L82CC                   ; 82C1: D0 09
    TYA                         ; 82C3: 98
    AND #$20                    ; 82C4: 29 20
    BEQ L829C                   ; 82C6: F0 D4
    LDA #$00                    ; 82C8: A9 00
    BEQ L82F6                   ; 82CA: F0 2A
L82CC:
    TYA                         ; 82CC: 98
    AND #$88                    ; 82CD: 29 88
    CMP #$88                    ; 82CF: C9 88
    BNE L82ED                   ; 82D1: D0 1A
    LDA #$00                    ; 82D3: A9 00
    STA Score                   ; 82D5: 8D F3 07
    STA $07F4                   ; 82D8: 8D F4 07
    STA $07F5                   ; 82DB: 8D F5 07
    LDA #$02                    ; 82DE: A9 02
    STA $46                     ; 82E0: 85 46
    LDA #$05                    ; 82E2: A9 05
    STA $47                     ; 82E4: 85 47
    JSR L844C                   ; 82E6: 20 4C 84
    LDA #$04                    ; 82E9: A9 04
    BNE L82F6                   ; 82EB: D0 09
L82ED:
    JSR L925C                   ; 82ED: 20 5C 92
    LDA #$00                    ; 82F0: A9 00
    STA $43                     ; 82F2: 85 43
    LDA #$03                    ; 82F4: A9 03
L82F6:
    STA $37                     ; 82F6: 85 37
    JSR InitSound               ; 82F8: 20 14 86
    LDA $37                     ; 82FB: A5 37
    JMP SetGameMode             ; 82FD: 4C 5C 83
L8300:
    JSR ClearLoadScreen0        ; 8300: 20 56 89
    DEC $46                     ; 8303: C6 46
    BMI L830E                   ; 8305: 30 07
    JSR L844C                   ; 8307: 20 4C 84
    LDA #$04                    ; 830A: A9 04
    BNE SetGameMode             ; 830C: D0 4E
L830E:
    LDY #$0D                    ; 830E: A0 0D
    JSR L860B                   ; 8310: 20 0B 86
    LDX #$0F                    ; 8313: A2 0F
    LDA #$19                    ; 8315: A9 19
    JSR PpuBufPutStrChain       ; 8317: 20 18 87
    LDA #$0D                    ; 831A: A9 0D
    JSR PpuBufPutStr            ; 831C: 20 AD 86
    LDA #$00                    ; 831F: A9 00
    STA ScrollX                 ; 8321: 85 18
    STA $03                     ; 8323: 85 03
    LDA #$02                    ; 8325: A9 02
    STA MapperShadow            ; 8327: 85 1E
    JSR ModeTimerSet256         ; 8329: 20 EB 83
    JMP L825B                   ; 832C: 4C 5B 82
L832F:
    LDA #$00                    ; 832F: A9 00
    STA DeathSeqFlag            ; 8331: 8D F1 05
    JMP $EFB8                   ; 8334: 4C B8 EF  -> Bank1:TitleSeq
GameStart:
    ; 开局初始化：$A3==9 时 INC $92；StageInit、INC $1D、清 HUD/计分状态（$05D6/$A5/$49/$05F2/$05F3/$05D8/$A6/$81），A=4 落入 SetGameMode
    LDA StageArea               ; 8337: A5 A3
    CMP #$09                    ; 8339: C9 09
    BNE L833F                   ; 833B: D0 02
    INC $92                     ; 833D: E6 92
L833F:
    JSR StageInit               ; 833F: 20 29 84
    INC PowerLevel              ; 8342: E6 1D
    LDA #$00                    ; 8344: A9 00
    STA $05D6                   ; 8346: 8D D6 05
    STA $A5                     ; 8349: 85 A5
    STA EquipBits               ; 834B: 85 49
    STA SlingAmmo               ; 834D: 8D F2 05
    STA BombAmmo                ; 8350: 8D F3 05
    STA $05D8                   ; 8353: 8D D8 05
    STA $A6                     ; 8356: 85 A6
    STA $81                     ; 8358: 85 81
    LDA #$04                    ; 835A: A9 04
SetGameMode:
    ; A→GameMode、ModeTimer=$50，尾转 L8250 清 $0A/SubMode；标题/菜单等多处以不同 A 调用
    STA GameMode                ; 835C: 85 00
    LDA #$50                    ; 835E: A9 50
    STA ModeTimer               ; 8360: 85 42
    JMP L8250                   ; 8362: 4C 50 82
L8365:
    LDX #$4B                    ; 8365: A2 4B
    BNE L836F                   ; 8367: D0 06
    LDX #$44                    ; 8369: A2 44
    BNE L836F                   ; 836B: D0 02
ModeTimerTick:
    ; 16 位模式计时步进：$42/$43==0 返 A=0，否则 Timer16Sub 减 1 返 A=1；各模式处理器每帧调用
    LDX #$42                    ; 836D: A2 42
L836F:
    LDA GameMode,X              ; 836F: B5 00
    ORA SubMode,X               ; 8371: 15 01
    BEQ L837C                   ; 8373: F0 07
    LDA #$01                    ; 8375: A9 01
    JSR Timer16Sub              ; 8377: 20 FF 85
    LDA #$01                    ; 837A: A9 01
L837C:
    RTS                         ; 837C: 60
ReadJoypad:
    ; 标准手柄读取：strobe $4016 后 8 位移位，LSR+ORA 合并两数据位；JoyBits=P1|P2 合并、JoyPressed=新按下、JoyHeld=上帧
    LDX #$01                    ; 837D: A2 01
    STX JOY1                    ; 837F: 8E 16 40
    DEX                         ; 8382: CA
    STX JOY1                    ; 8383: 8E 16 40
    LDY #$08                    ; 8386: A0 08
L8388:
    LDA JOY1                    ; 8388: AD 16 40
    STA $27                     ; 838B: 85 27
    LSR A                       ; 838D: 4A
    ORA $27                     ; 838E: 05 27
    LSR A                       ; 8390: 4A
    ROL JoyBits                 ; 8391: 26 24
    LDA JOY2                    ; 8393: AD 17 40
    STA $27                     ; 8396: 85 27
    LSR A                       ; 8398: 4A
    ORA $27                     ; 8399: 05 27
    LSR A                       ; 839B: 4A
    ROL JoyBits2                ; 839C: 26 25
    DEY                         ; 839E: 88
    BNE L8388                   ; 839F: D0 E7
    LDA #$FF                    ; 83A1: A9 FF
    AND JoyBits                 ; 83A3: 25 24
    ORA JoyBits2                ; 83A5: 05 25
    STA JoyBits                 ; 83A7: 85 24
    TAY                         ; 83A9: A8
    EOR JoyHeld                 ; 83AA: 45 07
    AND JoyBits                 ; 83AC: 25 24
    STA JoyPressed              ; 83AE: 85 05
    STY JoyHeld                 ; 83B0: 84 07
    RTS                         ; 83B2: 60
HandleStartSelect:
    ; JoyPressed AND #$30（Start|Select 边沿）分支；GameMode 0-2 时每帧调用
    LDA JoyPressed              ; 83B3: A5 05
    AND #$30                    ; 83B5: 29 30
    BEQ L83CE                   ; 83B7: F0 15
    JSR ModeTimerSet256         ; 83B9: 20 EB 83
    LDX GameMode                ; 83BC: A6 00
    DEX                         ; 83BE: CA
    BNE L83CF                   ; 83BF: D0 0E
    AND #$20                    ; 83C1: 29 20
    BNE L83CE                   ; 83C3: D0 09
    LDA #$00                    ; 83C5: A9 00
    STA $03                     ; 83C7: 85 03
    LDA #$03                    ; 83C9: A9 03
    JSR SetGameMode             ; 83CB: 20 5C 83
L83CE:
    RTS                         ; 83CE: 60
L83CF:
    LDA #$00                    ; 83CF: A9 00
    STA ScrollX                 ; 83D1: 85 18
    STA StageId                 ; 83D3: 85 80
    STA PpuBufIdx               ; 83D5: 85 11
    STA SubMode                 ; 83D7: 85 01
    LDA #$01                    ; 83D9: A9 01
    STA GameMode                ; 83DB: 85 00
    LDA #$1E                    ; 83DD: A9 1E
    STA PpuMaskShadow           ; 83DF: 85 0F
    LDA #$88                    ; 83E1: A9 88
    STA PpuCtrlShadow           ; 83E3: 85 0E
    JSR L925C                   ; 83E5: 20 5C 92
    JSR L8210                   ; 83E8: 20 10 82
ModeTimerSet256:
    ; 置 16 位模式计时=$0100（ModeTimer=0、$43=1，即 256 帧）
    LDX #$00                    ; 83EB: A2 00
    STX ModeTimer               ; 83ED: 86 42
    INX                         ; 83EF: E8
    STX $43                     ; 83F0: 86 43
    RTS                         ; 83F2: 60
L83F3:
    LDA PPU_STATUS              ; 83F3: AD 02 20
    LDA #$20                    ; 83F6: A9 20
    STA PPU_ADDR                ; 83F8: 8D 06 20
    LDA #$00                    ; 83FB: A9 00
    STA PPU_ADDR                ; 83FD: 8D 06 20
ApplyScroll:
    ; sprite-0 命中后的帧中滚动应用：虚读 PPU_STATUS 后 $2005 双写 ScrollX($18)/ScrollY($19)
    LDX PPU_STATUS              ; 8400: AE 02 20
    LDX ScrollX                 ; 8403: A6 18
    STX PPU_SCROLL              ; 8405: 8E 05 20
    LDX ScrollY                 ; 8408: A6 19
    STX PPU_SCROLL              ; 840A: 8E 05 20
    RTS                         ; 840D: 60
L840E:
    LDA #$00                    ; 840E: A9 00
    STA Score                   ; 8410: 8D F3 07
    STA $07F4                   ; 8413: 8D F4 07
    STA $07F5                   ; 8416: 8D F5 07
    STA $92                     ; 8419: 85 92
L841B:
    JSR L85CA                   ; 841B: 20 CA 85
    JSR L85D6                   ; 841E: 20 D6 85
    LDA #$02                    ; 8421: A9 02
    STA $46                     ; 8423: 85 46
    LDA #$05                    ; 8425: A9 05
    STA $47                     ; 8427: 85 47
StageInit:
    ; 关卡初始化：清 SceneId/MapperShadow/$A3/$05DF/$0335，$A0=$A1=$17 后 ClearObjectList，$80(StageId)=$6A、$9A=1，尾转 LBAF4
    LDA #$00                    ; 8429: A9 00
    STA SceneId                 ; 842B: 85 1F
    STA KeyCount                ; 842D: 8D DF 05
    STA $0335                   ; 8430: 8D 35 03
    STA MapperShadow            ; 8433: 85 1E
    STA StageArea               ; 8435: 85 A3
    JSR L844C                   ; 8437: 20 4C 84
    LDA #$6A                    ; 843A: A9 6A
    STA StageId                 ; 843C: 85 80
    LDA #$69                    ; 843E: A9 69
    LDX #$00                    ; 8440: A2 00
    JSR SpawnRingInit           ; 8442: 20 15 BC
    LDA #$01                    ; 8445: A9 01
    STA $9A                     ; 8447: 85 9A
    JMP ScanObjWindow           ; 8449: 4C F4 BA
L844C:
    LDA #$17                    ; 844C: A9 17
    STA PlayerHp                ; 844E: 85 A0
    STA PlayerHpShown           ; 8450: 85 A1
    JMP ClearObjectList         ; 8452: 4C 09 A3
L8455:
    RTS                         ; 8455: 60
L8456:
    LDX PpuBufIdx               ; 8456: A6 11
    CPX #$40                    ; 8458: E0 40
    BCS L8455                   ; 845A: B0 F9
PpuBufPutNum:
    ; 6 位 BCD 转 ASCII 入 PpuBuf：LSR×4/AND #$0F 取半字节、ORA #$30、$27 抑制前导零
    STA TmpPtr                  ; 845C: 85 20
    AND #$7F                    ; 845E: 29 7F
    TAY                         ; 8460: A8
    LDX #$05                    ; 8461: A2 05
    LDA #$00                    ; 8463: A9 00
    STA $27                     ; 8465: 85 27
L8467:
    LDA $84BB,Y                 ; 8467: B9 BB 84
    STA TmpPtr,X                ; 846A: 95 20
    DEY                         ; 846C: 88
    DEX                         ; 846D: CA
    BNE L8467                   ; 846E: D0 F7
    LDA #$01                    ; 8470: A9 01
    JSR PpuBufPut               ; 8472: 20 0A 87
    LDA JoyBits2                ; 8475: A5 25
    JSR PpuBufPut               ; 8477: 20 0A 87
    LDA JoyBits                 ; 847A: A5 24
    JSR PpuBufPut               ; 847C: 20 0A 87
L847F:
    LDY $21                     ; 847F: A4 21
    LDA ($22),Y                 ; 8481: B1 22
    LSR A                       ; 8483: 4A
    LSR A                       ; 8484: 4A
    LSR A                       ; 8485: 4A
    LSR A                       ; 8486: 4A
    STA $26                     ; 8487: 85 26
    BNE L848F                   ; 8489: D0 04
    LDA $27                     ; 848B: A5 27
    BEQ L8495                   ; 848D: F0 06
L848F:
    LDA $26                     ; 848F: A5 26
    INC $27                     ; 8491: E6 27
    ORA #$30                    ; 8493: 09 30
L8495:
    JSR PpuBufPut               ; 8495: 20 0A 87
    LDA ($22),Y                 ; 8498: B1 22
    AND #$0F                    ; 849A: 29 0F
    STA $26                     ; 849C: 85 26
    BNE L84AC                   ; 849E: D0 0C
    LDA $27                     ; 84A0: A5 27
    BNE L84AC                   ; 84A2: D0 08
    LDA $21                     ; 84A4: A5 21
    BEQ L84AC                   ; 84A6: F0 04
    LDA #$00                    ; 84A8: A9 00
    BEQ L84B2                   ; 84AA: F0 06
L84AC:
    INC $27                     ; 84AC: E6 27
    LDA $26                     ; 84AE: A5 26
    ORA #$30                    ; 84B0: 09 30
L84B2:
    JSR PpuBufPut               ; 84B2: 20 0A 87
    DEC $21                     ; 84B5: C6 21
    BPL L847F                   ; 84B7: 10 C6
    JMP PpuBufPutFF             ; 84B9: 4C 00 87
    .byte $01,$90,$00,$9B,$20,$02,$F3,$07         ; 84BC: 01 90 00 9B 20 02 F3 07
    .byte $B9,$20,$00,$46,$00,$7D,$20,$02         ; 84C4: B9 20 00 46 00 7D 20 02
    .byte $F0,$07,$2E,$22                         ; 84CC: F0 07 2E 22
AddScore:
    ; A*2 查 $8583 分值字表（BCD）加 ($24)=Score($07F3，低字节在前) 三位 BCD；进位溢出夹写 HiScore($07F0)-$07F2=$99；尾 L853A 比较当前分与 HI，超出则抄入 HI；L9CB7/$9A75/$9DA7 调用
    ASL A                       ; 84D0: 0A
    STA $22                     ; 84D1: 85 22
    STX $3E                     ; 84D3: 86 3E
    STY $3F                     ; 84D5: 84 3F
    LDY $22                     ; 84D7: A4 22
    LDA $8583,Y                 ; 84D9: B9 83 85
    STA $22                     ; 84DC: 85 22
    LDA $8584,Y                 ; 84DE: B9 84 85
    STA $23                     ; 84E1: 85 23
    LDA #$00                    ; 84E3: A9 00
L84E5:
    STA $21                     ; 84E5: 85 21
    LDA #$F3                    ; 84E7: A9 F3
    STA JoyBits                 ; 84E9: 85 24
    LDA #$07                    ; 84EB: A9 07
    STA JoyBits2                ; 84ED: 85 25
    LDA $03                     ; 84EF: A5 03
    BNE L850F                   ; 84F1: D0 1C
    LDY #$00                    ; 84F3: A0 00
    LDX #$03                    ; 84F5: A2 03
    CLC                         ; 84F7: 18
L84F8:
    LDA ($24),Y                 ; 84F8: B1 24
    JSR L8559                   ; 84FA: 20 59 85
    STA ($24),Y                 ; 84FD: 91 24
    INY                         ; 84FF: C8
    DEX                         ; 8500: CA
    BNE L84F8                   ; 8501: D0 F5
    BCC L8514                   ; 8503: 90 0F
    LDX #$02                    ; 8505: A2 02
    LDA #$99                    ; 8507: A9 99
L8509:
    STA HiScore,X               ; 8509: 9D F0 07
    DEX                         ; 850C: CA
    BPL L8509                   ; 850D: 10 FA
L850F:
    LDX $3E                     ; 850F: A6 3E
    LDY $3F                     ; 8511: A4 3F
    RTS                         ; 8513: 60
L8514:
    LDY #$02                    ; 8514: A0 02
    LDA ($24),Y                 ; 8516: B1 24
    CMP $47                     ; 8518: C5 47
    BCC L853A                   ; 851A: 90 1E
    LDX #$0A                    ; 851C: A2 0A
    LDA $47                     ; 851E: A5 47
    CLC                         ; 8520: 18
    JSR L8555                   ; 8521: 20 55 85
    BCC L8528                   ; 8524: 90 02
    LDA #$FF                    ; 8526: A9 FF
L8528:
    STA $47                     ; 8528: 85 47
    LDA $46                     ; 852A: A5 46
    CMP #$79                    ; 852C: C9 79
    BCS L853A                   ; 852E: B0 0A
    INC $46                     ; 8530: E6 46
    JSR InitSound               ; 8532: 20 14 86
    LDY #$29                    ; 8535: A0 29
    JSR SoundCmd80              ; 8537: 20 22 86
L853A:
    LDY #$02                    ; 853A: A0 02
L853C:
    LDA HiScore,Y               ; 853C: B9 F0 07
    CMP ($24),Y                 ; 853F: D1 24
    BCC L8548                   ; 8541: 90 05
    BNE L8552                   ; 8543: D0 0D
    DEY                         ; 8545: 88
    BPL L853C                   ; 8546: 10 F4
L8548:
    LDY #$02                    ; 8548: A0 02
L854A:
    LDA ($24),Y                 ; 854A: B1 24
    STA HiScore,Y               ; 854C: 99 F0 07
    DEY                         ; 854F: 88
    BPL L854A                   ; 8550: 10 F8
L8552:
    JMP L850F                   ; 8552: 4C 0F 85
L8555:
    STX TmpPtr                  ; 8555: 86 20
    LDX #$00                    ; 8557: A2 00
L8559:
    STA $27                     ; 8559: 85 27
    AND #$F0                    ; 855B: 29 F0
    STA $26                     ; 855D: 85 26
    EOR $27                     ; 855F: 45 27
    STA $27                     ; 8561: 85 27
    LDA TmpPtr,X                ; 8563: B5 20
    AND #$0F                    ; 8565: 29 0F
    ADC $27                     ; 8567: 65 27
    CMP #$0A                    ; 8569: C9 0A
    BCC L856F                   ; 856B: 90 02
    ADC #$05                    ; 856D: 69 05
L856F:
    ADC $26                     ; 856F: 65 26
    STA $26                     ; 8571: 85 26
    LDA TmpPtr,X                ; 8573: B5 20
    AND #$F0                    ; 8575: 29 F0
    ADC $26                     ; 8577: 65 26
    BCS L857F                   ; 8579: B0 04
    CMP #$A0                    ; 857B: C9 A0
    BCC L8582                   ; 857D: 90 03
L857F:
    SBC #$A0                    ; 857F: E9 A0
    SEC                         ; 8581: 38
L8582:
    RTS                         ; 8582: 60
    .byte $01,$00,$02,$00,$05,$00,$10,$00         ; 8583: 01 00 02 00 05 00 10 00
    .byte $50,$00,$80,$00,$00,$10                 ; 858B: 50 00 80 00 00 10
RenderDelaySet9:
    ; RenderDelay=9 变体：LDA #$09 后 BNE → $8597 STA RenderDelay（跳过 $8595 的 LDA #$11 变体），A 恒为 $09；bank1 $CA14 JSR 实证
    LDA #$09                    ; 8591: A9 09
    BNE L8597                   ; 8593: D0 02
RenderDelaySet17:
    ; RenderDelay=$11 后置 RenderDelay 并 RTS；开渲染延迟帧数由 NMI $80AC 递减消费
    LDA #$11                    ; 8595: A9 11
L8597:
    STA RenderDelay             ; 8597: 85 0C
    RTS                         ; 8599: 60
DispatchJump:
    ; 内联跳转表分发器：弹返回地址作表基址，A*2 索引取目标 JMP($20)；全 ROM 12 处调用
    STX $3E                     ; 859A: 86 3E
    ASL A                       ; 859C: 0A
    TAY                         ; 859D: A8
    INY                         ; 859E: C8
    PLA                         ; 859F: 68
    STA TmpPtr                  ; 85A0: 85 20
    PLA                         ; 85A2: 68
    STA $21                     ; 85A3: 85 21
    LDA ($20),Y                 ; 85A5: B1 20
    TAX                         ; 85A7: AA
    INY                         ; 85A8: C8
    LDA ($20),Y                 ; 85A9: B1 20
    STA $21                     ; 85AB: 85 21
    STX TmpPtr                  ; 85AD: 86 20
    LDX $3E                     ; 85AF: A6 3E
    JMP (TmpPtr)                ; 85B1: 6C 20 00
ClearOam:
    ; 全精灵隐藏：步长 4 向 OamBuf 各槽 Y 写 $F4
    LDA #$F4                    ; 85B4: A9 F4
    LDX #$00                    ; 85B6: A2 00
L85B8:
    STA OamBuf,X                ; 85B8: 9D 00 02
    INX                         ; 85BB: E8
    INX                         ; 85BC: E8
    INX                         ; 85BD: E8
    INX                         ; 85BE: E8
    BNE L85B8                   ; 85BF: D0 F7
    RTS                         ; 85C1: 60
ClearAllObjects:
    ; 先 ClearObject 槽 1（玩家），再 JMP ClearObjectList 清其余槽
    LDX #$01                    ; 85C2: A2 01
    JSR ClearObject             ; 85C4: 20 E7 A2
    JMP ClearObjectList         ; 85C7: 4C 09 A3
L85CA:
    LDA #$00                    ; 85CA: A9 00
    LDX #$18                    ; 85CC: A2 18
L85CE:
    STA GameMode,X              ; 85CE: 95 00
    INX                         ; 85D0: E8
    CPX #$B0                    ; 85D1: E0 B0
    BNE L85CE                   ; 85D3: D0 F9
    RTS                         ; 85D5: 60
L85D6:
    LDA #$05                    ; 85D6: A9 05
    STA $21                     ; 85D8: 85 21
    LDA #$00                    ; 85DA: A9 00
    STA TmpPtr                  ; 85DC: 85 20
    TAY                         ; 85DE: A8
L85DF:
    STA ($20),Y                 ; 85DF: 91 20
    INY                         ; 85E1: C8
    BNE L85DF                   ; 85E2: D0 FB
    DEC $21                     ; 85E4: C6 21
    LDX $21                     ; 85E6: A6 21
    CPX #$04                    ; 85E8: E0 04
    BCS L85DF                   ; 85EA: B0 F3
    LDY #$4F                    ; 85EC: A0 4F
L85EE:
    STA ObjContactBits,Y        ; 85EE: 99 00 01
    DEY                         ; 85F1: 88
    BPL L85EE                   ; 85F2: 10 FA
    RTS                         ; 85F4: 60
Timer16Add:
    ; X 处 16 位计时加 A：CLC; ADC $00,X; BCC; INC $01,X；与 Timer16Sub 对称
    CLC                         ; 85F5: 18
    ADC GameMode,X              ; 85F6: 75 00
    STA GameMode,X              ; 85F8: 95 00
    BCC L85FE                   ; 85FA: 90 02
    INC SubMode,X               ; 85FC: F6 01
L85FE:
    RTS                         ; 85FE: 60
Timer16Sub:
    ; X 处 16 位计时减 A：EOR #$FF; SEC; ADC $00,X; BCS; DEC $01,X
    EOR #$FF                    ; 85FF: 49 FF
    SEC                         ; 8601: 38
    ADC GameMode,X              ; 8602: 75 00
    STA GameMode,X              ; 8604: 95 00
    BCS L860A                   ; 8606: B0 02
    DEC SubMode,X               ; 8608: D6 01
L860A:
    RTS                         ; 860A: 60
L860B:
    STY TmpPtr                  ; 860B: 84 20
    JSR InitSound               ; 860D: 20 14 86
    LDY TmpPtr                  ; 8610: A4 20
    BNE SoundCmdC0              ; 8612: D0 08
InitSound:
    ; 取 $862E 表 4 字节（$00,$C0,$80,$40）依次送 bank1 SoundCmd；Reset 初始化调用
    LDY #$00                    ; 8614: A0 00
    LDA $8631,Y                 ; 8616: B9 31 86
    JSR $F08E                   ; 8619: 20 8E F0  -> Bank1:SoundCmd
SoundCmdC0:
    ; 声音命令 $C0 提交：LDA $8630 后 JSR SoundCmd；BgmByStage 提交播放经此（bank1 $CBA5 JSR 等 2 处）
    LDA $8630,Y                 ; 861C: B9 30 86
    JSR $F08E                   ; 861F: 20 8E F0  -> Bank1:SoundCmd
SoundCmd80:
    ; 声音命令 $80 提交：LDA $862F 后 JSR SoundCmd（bank1 $CBAA JSR 等 2 处）
    LDA $862F,Y                 ; 8622: B9 2F 86
    JSR $F08E                   ; 8625: 20 8E F0  -> Bank1:SoundCmd
    LDA $862E,Y                 ; 8628: B9 2E 86
    JMP $F08E                   ; 862B: 4C 8E F0  -> Bank1:SoundCmd
    .byte $40,$80,$C0,$00,$15,$D6,$27,$68         ; 862E: 40 80 C0 00 15 D6 27 68
    .byte $A9,$6C,$AD,$6E,$AF,$3D,$7E,$BF         ; 8636: A9 6C AD 6E AF 3D 7E BF
    .byte $3A,$7B,$BC,$3B,$7A,$BD,$70,$B1         ; 863E: 3A 7B BC 3B 7A BD 70 B1
    .byte $6A,$AB,$25,$66,$29,$4F,$8F,$32         ; 8646: 6A AB 25 66 29 4F 8F 32
    .byte $73,$B4,$A4,$00,$35,$76,$37,$78         ; 864E: 73 B4 A4 00 35 76 37 78
    .byte $B9,$21,$62,$1B,$5C                     ; 8656: B9 21 62 1B 5C
FlushPpuBuf:
    ; NMI 中消费 PpuBuf 命令流：命令字（0=结束/2=垂直写）→PPU 地址→数据至 $FF；末尾清缓冲与 PpuBufIdx
    JSR PpuBufPut00             ; 865B: 20 08 87
    LDA PPU_STATUS              ; 865E: AD 02 20
    LDY #$00                    ; 8661: A0 00
L8663:
    LDX PpuBuf,Y                ; 8663: BE 00 06
    BEQ L86A2                   ; 8666: F0 3A
    CPX #$02                    ; 8668: E0 02
    BNE L8670                   ; 866A: D0 04
    LDA #$04                    ; 866C: A9 04
    BNE L8672                   ; 866E: D0 02
L8670:
    LDA #$00                    ; 8670: A9 00
L8672:
    STA PPU_CTRL                ; 8672: 8D 00 20
    INY                         ; 8675: C8
    LDA PPU_STATUS              ; 8676: AD 02 20
    LDA PpuBuf,Y                ; 8679: B9 00 06
    STA PPU_ADDR                ; 867C: 8D 06 20
    INY                         ; 867F: C8
    LDA PpuBuf,Y                ; 8680: B9 00 06
    STA PPU_ADDR                ; 8683: 8D 06 20
    INY                         ; 8686: C8
L8687:
    LDA PpuBuf,Y                ; 8687: B9 00 06
    CMP #$FF                    ; 868A: C9 FF
    BEQ L8695                   ; 868C: F0 07
L868E:
    STA PPU_DATA                ; 868E: 8D 07 20
    INY                         ; 8691: C8
    JMP L8687                   ; 8692: 4C 87 86
L8695:
    INY                         ; 8695: C8
    LDA PpuBuf,Y                ; 8696: B9 00 06
    CMP #$03                    ; 8699: C9 03
    BCC L8663                   ; 869B: 90 C6
    DEY                         ; 869D: 88
    LDA #$FF                    ; 869E: A9 FF
    BNE L868E                   ; 86A0: D0 EC
L86A2:
    LDA #$00                    ; 86A2: A9 00
    STA PpuBuf                  ; 86A4: 8D 00 06
    STA PpuBufIdx               ; 86A7: 85 11
    STA PPU_CTRL                ; 86A9: 8D 00 20
    RTS                         ; 86AC: 60
PpuBufPutStr:
    ; A*2 索引 $872D 字符串指针表，流式抄入 PpuBuf；$FE/$FD 为控制码
    PHA                         ; 86AD: 48
    LDA #$02                    ; 86AE: A9 02
    STA $23                     ; 86B0: 85 23
    JSR PpuBufPut01             ; 86B2: 20 04 87
    PLA                         ; 86B5: 68
PpuBufPutStrRaw:
    ; PpuBufPutStr 的 +9 重入点：不做 $23=2/$01 命令头，A*2 查 $872D 直接拷贝；PpuBufPutStrChain 两次 JSR
    LDY #$00                    ; 86B6: A0 00
    STA $22                     ; 86B8: 85 22
    ASL A                       ; 86BA: 0A
    TAX                         ; 86BB: AA
    LDA $872D,X                 ; 86BC: BD 2D 87
    STA TmpPtr                  ; 86BF: 85 20
    LDA $872E,X                 ; 86C1: BD 2E 87
    STA $21                     ; 86C4: 85 21
    LDX PpuBufIdx               ; 86C6: A6 11
L86C8:
    LDA ($20),Y                 ; 86C8: B1 20
    INY                         ; 86CA: C8
    CMP #$FF                    ; 86CB: C9 FF
    BEQ PpuBufSetIdx            ; 86CD: F0 41
    CMP #$FE                    ; 86CF: C9 FE
    BEQ L86EC                   ; 86D1: F0 19
    CMP #$FD                    ; 86D3: C9 FD
    BEQ L86F0                   ; 86D5: F0 19
    STA PpuBuf,X                ; 86D7: 9D 00 06
    LDA $22                     ; 86DA: A5 22
    BPL L86E9                   ; 86DC: 10 0B
    LDA $23                     ; 86DE: A5 23
    BNE L86E7                   ; 86E0: D0 05
    STA PpuBuf,X                ; 86E2: 9D 00 06
    BEQ L86E9                   ; 86E5: F0 02
L86E7:
    DEC $23                     ; 86E7: C6 23
L86E9:
    INX                         ; 86E9: E8
    BNE L86C8                   ; 86EA: D0 DC
L86EC:
    LDA #$FF                    ; 86EC: A9 FF
    BNE PpuBufPutAtX            ; 86EE: D0 1C
L86F0:
    LDA #$FF                    ; 86F0: A9 FF
    JSR PpuBufPutAtX            ; 86F2: 20 0C 87
    LDA #$02                    ; 86F5: A9 02
    STA $23                     ; 86F7: 85 23
    LDA #$01                    ; 86F9: A9 01
    JSR PpuBufPutAtX            ; 86FB: 20 0C 87
    BNE L86C8                   ; 86FE: D0 C8
PpuBufPutFF:
    ; PpuBuf 追加 $FF（命令流终止符），BNE 落入 PpuBufPut
    LDA #$FF                    ; 8700: A9 FF
    BNE PpuBufPut               ; 8702: D0 06
PpuBufPut01:
    ; PpuBuf 追加 $01，BNE 落入 PpuBufPut
    LDA #$01                    ; 8704: A9 01
    BNE PpuBufPut               ; 8706: D0 02
PpuBufPut00:
    ; PpuBuf 追加 $00，落入 PpuBufPut
    LDA #$00                    ; 8708: A9 00
PpuBufPut:
    ; A 追加到 PpuBuf[PpuBufIdx] 并递增；L8700/L8704/L8708 分别追加 $FF/$01/$00
    LDX PpuBufIdx               ; 870A: A6 11
PpuBufPutAtX:
    ; 以 X 为下标写 PpuBuf 并 INX（直写变体；L8713 经此封口）
    STA PpuBuf,X                ; 870C: 9D 00 06
    INX                         ; 870F: E8
PpuBufSetIdx:
    ; X 回写 PpuBufIdx 后 RTS
    STX PpuBufIdx               ; 8710: 86 11
    RTS                         ; 8712: 60
PpuBufCloseAtX:
    ; INX 后 A=$FF 转 PpuBufPutAtX：在 X 后一位写终止符
    INX                         ; 8713: E8
PpuBufPutFFAtX:
    ; LDA #$FF 后 BNE PpuBufPutAtX：X 处写 $FF、INX、提交 PpuBufIdx；bank1 $EC68 JSR
    LDA #$FF                    ; 8714: A9 FF
    BNE PpuBufPutAtX            ; 8716: D0 F4
PpuBufPutStrChain:
    ; PHA/TXA/PHA 后：串 6（带命令头）→ PLA 串 A（Raw）→ PLA 串 X（Raw）→ 串 $1B（Raw 尾转）；bank1 $CB8C/$F059 调用
    PHA                         ; 8718: 48
    TXA                         ; 8719: 8A
    PHA                         ; 871A: 48
    LDA #$06                    ; 871B: A9 06
    JSR PpuBufPutStr            ; 871D: 20 AD 86
    PLA                         ; 8720: 68
    JSR PpuBufPutStrRaw         ; 8721: 20 B6 86
    PLA                         ; 8724: 68
    JSR PpuBufPutStrRaw         ; 8725: 20 B6 86
    LDA #$1B                    ; 8728: A9 1B
    JMP PpuBufPutStr            ; 872A: 4C AD 86
    .byte $7A,$88,$65,$87,$CF,$87,$E4,$87         ; 872D: 7A 88 65 87 CF 87 E4 87
    .byte $F5,$87,$2B,$89,$CC,$87,$77,$88         ; 8735: F5 87 2B 89 CC 87 77 88
    .byte $65,$88,$00,$88,$29,$88,$29,$88         ; 873D: 65 88 00 88 29 88 29 88
    .byte $29,$88,$59,$88,$A3,$88,$B4,$88         ; 8745: 29 88 59 88 A3 88 B4 88
    .byte $C5,$88,$D6,$88,$E7,$88,$F8,$88         ; 874D: C5 88 D6 88 E7 88 F8 88
    .byte $09,$89,$E3,$87,$71,$88,$74,$88         ; 8755: 09 89 E3 87 71 88 74 88
    .byte $1A,$89,$1A,$89,$1A,$89,$9D,$88         ; 875D: 1A 89 1A 89 1A 89 9D 88
    .byte $21,$43,$54,$48,$45,$00,$47,$4F         ; 8765: 21 43 54 48 45 00 47 4F
    .byte $4F,$4E,$49,$45,$53,$F1,$00,$49         ; 876D: 4F 4E 49 45 53 F1 00 49
    .byte $53,$00,$41,$00,$54,$52,$41,$44         ; 8775: 53 00 41 00 54 52 41 44
    .byte $45,$4D,$41,$52,$4B,$FD,$21,$A3         ; 877D: 45 4D 41 52 4B FD 21 A3
    .byte $4F,$46,$00,$57,$41,$52,$4E,$45         ; 8785: 4F 46 00 57 41 52 4E 45
    .byte $52,$00,$42,$52,$4F,$53,$CF,$00         ; 878D: 52 00 42 52 4F 53 CF 00
    .byte $49,$4E,$43,$CF,$FD,$22,$84,$F2         ; 8795: 49 4E 43 CF FD 22 84 F2
    .byte $00,$31,$39,$38,$35,$00,$57,$41         ; 879D: 00 31 39 38 35 00 57 41
    .byte $52,$4E,$45,$52,$00,$42,$52,$4F         ; 87A5: 52 4E 45 52 00 42 52 4F
    .byte $53,$CF,$00,$49,$4E,$43,$CF,$FD         ; 87AD: 53 CF 00 49 4E 43 CF FD
    .byte $22,$C4,$41,$4C,$4C,$00,$52,$49         ; 87B5: 22 C4 41 4C 4C 00 52 49
    .byte $47,$48,$54,$53,$00,$52,$45,$53         ; 87BD: 47 48 54 53 00 52 45 53
    .byte $45,$52,$56,$45,$44,$CF,$FE,$3F         ; 87C5: 45 52 56 45 44 CF FE 3F
    .byte $00,$FF,$22,$69,$F3,$00,$4B,$4F         ; 87CD: 00 FF 22 69 F3 00 4B 4F
    .byte $4E,$41,$4D,$49,$00,$31,$39,$38         ; 87D5: 4E 41 4D 49 00 31 39 38
    .byte $36,$FD,$22,$2B,$48,$49,$FE,$22         ; 87DD: 36 FD 22 2B 48 49 FE 22
    .byte $A9,$50,$55,$53,$48,$00,$53,$54         ; 87E5: A9 50 55 53 48 00 53 54
    .byte $41,$52,$54,$00,$4B,$45,$59,$FE         ; 87ED: 41 52 54 00 4B 45 59 FE
    .byte $23,$C0,$55,$55,$55,$55,$55,$55         ; 87F5: 23 C0 55 55 55 55 55 55
    .byte $55,$55,$FE,$21,$8D,$54,$48,$45         ; 87FD: 55 55 FE 21 8D 54 48 45
    .byte $00,$45,$4E,$44,$FD,$21,$CA,$43         ; 8805: 00 45 4E 44 FD 21 CA 43
    .byte $4F,$4E,$47,$52,$41,$54,$55,$4C         ; 880D: 4F 4E 47 52 41 54 55 4C
    .byte $41,$54,$49,$4F,$4E,$FD,$22,$2B         ; 8815: 41 54 49 4F 4E FD 22 2B
    .byte $50,$4F,$49,$4E,$54,$00,$35,$30         ; 881D: 50 4F 49 4E 54 00 35 30
    .byte $30,$30,$30,$FE,$20,$93,$54,$49         ; 8825: 30 30 30 FE 20 93 54 49
    .byte $4D,$45,$52,$5B,$00,$00,$00,$00         ; 882D: 4D 45 52 5B 00 00 00 00
    .byte $00,$00,$FD,$20,$81,$4C,$49,$46         ; 8835: 00 00 FD 20 81 4C 49 46
    .byte $45,$5B,$AC,$AC,$AC,$AC,$AC,$AC         ; 883D: 45 5B AC AC AC AC AC AC
    .byte $FD,$20,$B3,$53,$43,$4F,$52,$45         ; 8845: FD 20 B3 53 43 4F 52 45
    .byte $5B,$00,$00,$00,$00,$00,$00,$FD         ; 884D: 5B 00 00 00 00 00 00 FD
    .byte $20,$7C,$A3,$FE,$21,$8B,$47,$41         ; 8855: 20 7C A3 FE 21 8B 47 41
    .byte $4D,$45,$00,$4F,$56,$45,$52,$FE         ; 885D: 4D 45 00 4F 56 45 52 FE
    .byte $20,$6B,$54,$49,$4D,$45,$00,$4F         ; 8865: 20 6B 54 49 4D 45 00 4F
    .byte $56,$45,$52,$FE,$20,$8E,$FF,$20         ; 886D: 56 45 52 FE 20 8E FF 20
    .byte $A2,$FF,$20,$AA,$FF,$3F,$00,$27         ; 8875: A2 FF 20 AA FF 3F 00 27
    .byte $05,$27,$05,$27,$27,$0F,$0F,$27         ; 887D: 05 27 05 27 27 0F 0F 27
    .byte $27,$20,$20,$27,$00,$00,$00,$27         ; 8885: 27 20 20 27 00 00 00 27
    .byte $36,$12,$26,$27,$36,$16,$12,$27         ; 888D: 36 12 26 27 36 16 12 27
    .byte $36,$12,$20,$27,$17,$27,$0F,$FD         ; 8895: 36 12 20 27 17 27 0F FD
    .byte $3F,$00,$FD,$00,$00,$FE,$0F,$07         ; 889D: 3F 00 FD 00 00 FE 0F 07
    .byte $00,$10,$0F,$16,$22,$30,$0F,$07         ; 88A5: 00 10 0F 16 22 30 0F 07
    .byte $17,$27,$0F,$02,$00,$10,$FF,$0F         ; 88AD: 17 27 0F 02 00 10 FF 0F
    .byte $07,$17,$36,$0F,$16,$22,$30,$0F         ; 88B5: 07 17 36 0F 16 22 30 0F
    .byte $0F,$0F,$0F,$0F,$00,$0C,$30,$FF         ; 88BD: 0F 0F 0F 0F 00 0C 30 FF
    .byte $0F,$07,$17,$36,$0F,$16,$22,$30         ; 88C5: 0F 07 17 36 0F 16 22 30
    .byte $0F,$00,$10,$30,$0F,$0F,$0F,$0F         ; 88CD: 0F 00 10 30 0F 0F 0F 0F
    .byte $FF,$0F,$07,$17,$36,$0F,$16,$22         ; 88D5: FF 0F 07 17 36 0F 16 22
    .byte $30,$0F,$07,$2A,$36,$0F,$07,$22         ; 88DD: 30 0F 07 2A 36 0F 07 22
    .byte $30,$FF,$0F,$01,$21,$3C,$0F,$16         ; 88E5: 30 FF 0F 01 21 3C 0F 16
    .byte $22,$30,$0F,$00,$10,$30,$0F,$0F         ; 88ED: 22 30 0F 00 10 30 0F 0F
    .byte $0F,$0F,$FF,$0F,$01,$11,$31,$0F         ; 88F5: 0F 0F FF 0F 01 11 31 0F
    .byte $16,$22,$30,$0F,$0F,$0F,$0F,$0F         ; 88FD: 16 22 30 0F 0F 0F 0F 0F
    .byte $00,$19,$30,$FF,$0F,$07,$17,$38         ; 8905: 00 19 30 FF 0F 07 17 38
    .byte $0F,$16,$22,$30,$0F,$07,$2A,$38         ; 890D: 0F 16 22 30 0F 07 2A 38
    .byte $0F,$17,$22,$30,$FF,$0F,$36,$21         ; 8915: 0F 17 22 30 FF 0F 36 21
    .byte $16,$0F,$20,$00,$27,$0F,$36,$12         ; 891D: 16 0F 20 00 27 0F 36 12
    .byte $20,$0F,$27,$17,$0F,$FE,$3F,$00         ; 8925: 20 0F 27 17 0F FE 3F 00
    .byte $02,$13,$04,$26,$02,$2C,$0F,$20         ; 892D: 02 13 04 26 02 2C 0F 20
    .byte $02,$20,$10,$0F,$02,$20,$37,$27         ; 8935: 02 20 10 0F 02 20 37 27
    .byte $02,$00,$00,$00,$02,$00,$00,$00         ; 893D: 02 00 00 00 02 00 00 00
    .byte $02,$00,$00,$00,$02,$07,$17,$30         ; 8945: 02 00 00 00 02 07 17 30
    .byte $FE,$01,$02,$04,$08,$10,$20,$40         ; 894D: FE 01 02 04 08 10 20 40
    .byte $80                                     ; 8955: 80
ClearLoadScreen0:
    ; SceneId=0 → ClearAllObjects($85C2) → ClearOam($85B4) → JMP LoadScreen0($ECB0)；bank1 LEFC8/$F04F JSR
    LDA #$00                    ; 8956: A9 00
    STA SceneId                 ; 8958: 85 1F
    JSR ClearAllObjects         ; 895A: 20 C2 85
    JSR ClearOam                ; 895D: 20 B4 85
    JMP $ECB0                   ; 8960: 4C B0 EC  -> Bank1:LoadScreen0
DrawSprites:
    ; 遍历物体槽画精灵：槽序 $0F→$01→$0E→轮转 $02-$0D（SpriteRot 起点防闪烁）→$00，逐槽 DrawMetasprite
    LDX #$0F                    ; 8963: A2 0F
    JSR DrawMetasprite          ; 8965: 20 95 89
    LDX #$01                    ; 8968: A2 01
    JSR DrawMetasprite          ; 896A: 20 95 89
    LDX #$0E                    ; 896D: A2 0E
    JSR DrawMetasprite          ; 896F: 20 95 89
    LDX SpriteRot               ; 8972: A6 15
L8974:
    JSR DrawMetasprite          ; 8974: 20 95 89
    LDX $3E                     ; 8977: A6 3E
    INX                         ; 8979: E8
    CPX #$0E                    ; 897A: E0 0E
    BCC L8980                   ; 897C: 90 02
    LDX #$02                    ; 897E: A2 02
L8980:
    CPX SpriteRot               ; 8980: E4 15
    BNE L8974                   ; 8982: D0 F0
    LDX SpriteRot               ; 8984: A6 15
    INX                         ; 8986: E8
    CPX #$0E                    ; 8987: E0 0E
    BCC L898D                   ; 8989: 90 02
    LDX #$02                    ; 898B: A2 02
L898D:
    STX SpriteRot               ; 898D: 86 15
    LDX #$00                    ; 898F: A2 00
    JSR DrawMetasprite          ; 8991: 20 95 89
L8994:
    RTS                         ; 8994: 60
DrawMetasprite:
    ; $0410,X≠0（跨页）或 $70,X==0 跳过；$54-$58 号精灵 X 窗 [$0C,$F4) 其余 [$08,$F8)；精灵号 ASL 选 $8A81/$8B81 指针表，metasprite 流写 OamBuf 四元组(Y/tile/attr/X)；首字节=片数，片首字节位0=沿用上一 attr、其余位=有符号 Y 偏移×2；$80/$81=嵌套调用/返回
    STX $3E                     ; 8995: 86 3E
    LDA ObjXPage,X              ; 8997: BD 10 04
    BNE L8994                   ; 899A: D0 F8
    LDA ObjSprite,X             ; 899C: B5 70
    BEQ L8994                   ; 899E: F0 F4
    CMP #$54                    ; 89A0: C9 54
    BCC L89B4                   ; 89A2: 90 10
    CMP #$59                    ; 89A4: C9 59
    BCS L89B4                   ; 89A6: B0 0C
    LDA ObjX,X                  ; 89A8: BD 70 04
    CMP #$0C                    ; 89AB: C9 0C
    BCC L8994                   ; 89AD: 90 E5
    CMP #$F4                    ; 89AF: C9 F4
    BCC L89BF                   ; 89B1: 90 0C
    RTS                         ; 89B3: 60
L89B4:
    LDA ObjX,X                  ; 89B4: BD 70 04
    CMP #$08                    ; 89B7: C9 08
    BCC L8994                   ; 89B9: 90 D9
    CMP #$F8                    ; 89BB: C9 F8
    BCS L8994                   ; 89BD: B0 D5
L89BF:
    STA $31                     ; 89BF: 85 31
    LDA ObjY,X                  ; 89C1: BD 60 04
    STA $30                     ; 89C4: 85 30
    LDA ObjSprite,X             ; 89C6: B5 70
    JMP L89CB                   ; 89C8: 4C CB 89
L89CB:
    ASL A                       ; 89CB: 0A
    TAY                         ; 89CC: A8
    BCC L89DA                   ; 89CD: 90 0B
    LDA $8B81,Y                 ; 89CF: B9 81 8B
    STA $33                     ; 89D2: 85 33
    LDA $8B82,Y                 ; 89D4: B9 82 8B
    JMP L89E2                   ; 89D7: 4C E2 89
L89DA:
    LDA $8A81,Y                 ; 89DA: B9 81 8A
    STA $33                     ; 89DD: 85 33
    LDA $8A82,Y                 ; 89DF: B9 82 8A
L89E2:
    STA $34                     ; 89E2: 85 34
    LDY #$00                    ; 89E4: A0 00
    LDA ($33),Y                 ; 89E6: B1 33
    STA $32                     ; 89E8: 85 32
    BEQ L8994                   ; 89EA: F0 A8
    INY                         ; 89EC: C8
    LDX OamIdx                  ; 89ED: A6 12
L89EF:
    LDA ($33),Y                 ; 89EF: B1 33
    STA $37                     ; 89F1: 85 37
    INY                         ; 89F3: C8
    CMP #$80                    ; 89F4: C9 80
    BEQ L8A40                   ; 89F6: F0 48
    CMP #$81                    ; 89F8: C9 81
    BEQ L8A58                   ; 89FA: F0 5C
    CLC                         ; 89FC: 18
    LDA $37                     ; 89FD: A5 37
    BPL L8A02                   ; 89FF: 10 01
    SEC                         ; 8A01: 38
L8A02:
    ROR A                       ; 8A02: 6A
    CLC                         ; 8A03: 18
    ADC $30                     ; 8A04: 65 30
    STA OamBuf,X                ; 8A06: 9D 00 02
    INX                         ; 8A09: E8
    LDA ($33),Y                 ; 8A0A: B1 33
    INY                         ; 8A0C: C8
    STA OamBuf,X                ; 8A0D: 9D 00 02
    INX                         ; 8A10: E8
    LDA $37                     ; 8A11: A5 37
    LSR A                       ; 8A13: 4A
    BCC L8A1B                   ; 8A14: 90 05
    LDA $14                     ; 8A16: A5 14
    JMP L8A20                   ; 8A18: 4C 20 8A
L8A1B:
    LDA ($33),Y                 ; 8A1B: B1 33
    INY                         ; 8A1D: C8
    STA $14                     ; 8A1E: 85 14
L8A20:
    STX OamIdx                  ; 8A20: 86 12
    LDX $3E                     ; 8A22: A6 3E
    ORA ObjAttr,X               ; 8A24: 1D 20 04
    LDX OamIdx                  ; 8A27: A6 12
    STA OamBuf,X                ; 8A29: 9D 00 02
    INX                         ; 8A2C: E8
    LDA ($33),Y                 ; 8A2D: B1 33
    CLC                         ; 8A2F: 18
    ADC $31                     ; 8A30: 65 31
    STA OamBuf,X                ; 8A32: 9D 00 02
    INY                         ; 8A35: C8
    INX                         ; 8A36: E8
    BEQ ResetOamIdx             ; 8A37: F0 43
L8A39:
    DEC $32                     ; 8A39: C6 32
    BNE L89EF                   ; 8A3B: D0 B2
    STX OamIdx                  ; 8A3D: 86 12
    RTS                         ; 8A3F: 60
L8A40:
    LDA $33                     ; 8A40: A5 33
    STA $35                     ; 8A42: 85 35
    LDA $34                     ; 8A44: A5 34
    STA $36                     ; 8A46: 85 36
    LDA ($35),Y                 ; 8A48: B1 35
    STA $33                     ; 8A4A: 85 33
    INY                         ; 8A4C: C8
    LDA ($35),Y                 ; 8A4D: B1 35
    STA $34                     ; 8A4F: 85 34
    INY                         ; 8A51: C8
    STY $3F                     ; 8A52: 84 3F
    LDY #$00                    ; 8A54: A0 00
    BEQ L89EF                   ; 8A56: F0 97
L8A58:
    LDA $35                     ; 8A58: A5 35
    STA $33                     ; 8A5A: 85 33
    LDA $36                     ; 8A5C: A5 36
    STA $34                     ; 8A5E: 85 34
    LDY $3F                     ; 8A60: A4 3F
    JMP L8A39                   ; 8A62: 4C 39 8A
L8A65:
    LDA #$00                    ; 8A65: A9 00
    BEQ L8A6B                   ; 8A67: F0 02
FinishOam:
    ; 剩余 OAM 槽（OamIdx 到页尾回绕）Y 填 $F4，落入 ResetOamIdx
    LDA #$00                    ; 8A69: A9 00
L8A6B:
    LDX OamIdx                  ; 8A6B: A6 12
ClearOamRange:
    ; STA $30（终点）后 OamBuf[X..$30) 步 4 填 $F4，X 回写前 RTS；bank1 $CA5D JSR（A=终点偏移）
    STA $30                     ; 8A6D: 85 30
    LDA #$F4                    ; 8A6F: A9 F4
L8A71:
    STA OamBuf,X                ; 8A71: 9D 00 02
    INX                         ; 8A74: E8
    INX                         ; 8A75: E8
    INX                         ; 8A76: E8
    INX                         ; 8A77: E8
    CPX $30                     ; 8A78: E4 30
    BNE L8A71                   ; 8A7A: D0 F5
ResetOamIdx:
    ; OamIdx=$40：metasprite 写入从槽 16 开始
    LDX #$40                    ; 8A7C: A2 40
    STX OamIdx                  ; 8A7E: 86 12
    RTS                         ; 8A80: 60
    .byte $87,$8B,$88,$8B,$99,$8B,$A4,$8B         ; 8A81: 87 8B 88 8B 99 8B A4 8B
    .byte $B5,$8B,$C6,$8B,$D1,$8B,$E2,$8B         ; 8A89: B5 8B C6 8B D1 8B E2 8B
    .byte $F4,$8B,$06,$8C,$17,$8C,$29,$8C         ; 8A91: F4 8B 06 8C 17 8C 29 8C
    .byte $3A,$8C,$4B,$8C,$59,$8C,$6C,$8E         ; 8A99: 3A 8C 4B 8C 59 8C 6C 8E
    .byte $71,$8E,$67,$8C,$79,$8C,$8B,$8C         ; 8AA1: 71 8E 67 8C 79 8C 8B 8C
    .byte $9A,$8C,$AF,$8C,$B7,$8C,$32,$91         ; 8AA9: 9A 8C AF 8C B7 8C 32 91
    .byte $22,$91,$2A,$91,$49,$91,$00,$91         ; 8AB1: 22 91 2A 91 49 91 00 91
    .byte $11,$91,$C7,$91,$D3,$91,$DF,$91         ; 8AB9: 11 91 C7 91 D3 91 DF 91
    .byte $EB,$91,$63,$91,$BF,$8C,$D0,$8C         ; 8AC1: EB 91 63 91 BF 8C D0 8C
    .byte $DE,$8C,$EF,$8C,$00,$8D,$0E,$8D         ; 8AC9: DE 8C EF 8C 00 8D 0E 8D
    .byte $1F,$8D,$31,$8D,$43,$8D,$57,$8D         ; 8AD1: 1F 8D 31 8D 43 8D 57 8D
    .byte $6B,$8D,$81,$8D,$97,$8D,$A9,$8D         ; 8AD9: 6B 8D 81 8D 97 8D A9 8D
    .byte $B9,$8D,$CE,$8D,$D7,$8D,$E6,$8D         ; 8AE1: B9 8D CE 8D D7 8D E6 8D
    .byte $EE,$8D,$FC,$8D,$04,$8E,$12,$8E         ; 8AE9: EE 8D FC 8D 04 8E 12 8E
    .byte $20,$8E,$2E,$8E,$33,$8E,$38,$8E         ; 8AF1: 20 8E 2E 8E 33 8E 38 8E
    .byte $3D,$8E,$42,$8E,$4D,$8E,$58,$8E         ; 8AF9: 3D 8E 42 8E 4D 8E 58 8E
    .byte $5D,$8E,$62,$8E,$67,$8E,$DA,$90         ; 8B01: 5D 8E 62 8E 67 8E DA 90
    .byte $76,$8E,$7F,$8E,$88,$8E,$96,$8E         ; 8B09: 76 8E 7F 8E 88 8E 96 8E
    .byte $A4,$8E,$B2,$8E,$C0,$8E,$CE,$8E         ; 8B11: A4 8E B2 8E C0 8E CE 8E
    .byte $DC,$8E,$EA,$8E,$F8,$8E,$07,$8F         ; 8B19: DC 8E EA 8E F8 8E 07 8F
    .byte $16,$8F,$2A,$8F,$3E,$8F,$4C,$8F         ; 8B21: 16 8F 2A 8F 3E 8F 4C 8F
    .byte $5A,$8F,$71,$8F,$7C,$8F,$93,$8F         ; 8B29: 5A 8F 71 8F 7C 8F 93 8F
    .byte $AD,$8F,$BE,$8F,$C3,$8F,$C8,$8F         ; 8B31: AD 8F BE 8F C3 8F C8 8F
    .byte $D0,$8F,$72,$91,$D8,$8F,$E1,$8F         ; 8B39: D0 8F 72 91 D8 8F E1 8F
    .byte $EA,$8F,$F3,$8F,$01,$90,$0D,$90         ; 8B41: EA 8F F3 8F 01 90 0D 90
    .byte $19,$90,$2D,$90,$35,$90,$40,$90         ; 8B49: 19 90 2D 90 35 90 40 90
    .byte $80,$91,$4B,$90,$5F,$90,$6D,$90         ; 8B51: 80 91 4B 90 5F 90 6D 90
    .byte $72,$90,$95,$91,$81,$90,$FA,$91         ; 8B59: 72 90 95 91 81 90 FA 91
    .byte $D2,$90,$B9,$91,$B0,$90,$B5,$90         ; 8B61: D2 90 B9 91 B0 90 B5 90
    .byte $BA,$90,$C2,$90,$CA,$90,$E2,$90         ; 8B69: BA 90 C2 90 CA 90 E2 90
    .byte $F1,$90,$2D,$92,$3B,$92,$49,$92         ; 8B71: F1 90 2D 92 3B 92 49 92
    .byte $6D,$90,$87,$8B,$6D,$90,$87,$8B         ; 8B79: 6D 90 87 8B 6D 90 87 8B
    .byte $6D,$90,$5F,$90,$57,$92,$00,$05         ; 8B81: 6D 90 5F 90 57 92 00 05
    .byte $D8,$10,$40,$FD,$E9,$11,$01,$E9         ; 8B89: D8 10 40 FD E9 11 01 E9
    .byte $12,$F9,$F9,$13,$01,$F9,$14,$F9         ; 8B91: 12 F9 F9 13 01 F9 14 F9
    .byte $03,$D6,$10,$40,$FD,$E7,$15,$FD         ; 8B99: 03 D6 10 40 FD E7 15 FD
    .byte $F7,$16,$FD,$05,$D8,$10,$40,$FD         ; 8BA1: F7 16 FD 05 D8 10 40 FD
    .byte $E9,$17,$01,$E9,$18,$F9,$F9,$19         ; 8BA9: E9 17 01 E9 18 F9 F9 19
    .byte $01,$F9,$0F,$F9,$05,$D8,$10,$00         ; 8BB1: 01 F9 0F F9 05 D8 10 00
    .byte $FC,$E9,$11,$F8,$E9,$12,$00,$F9         ; 8BB9: FC E9 11 F8 E9 12 00 F9
    .byte $13,$F8,$F9,$14,$00,$03,$D6,$10         ; 8BC1: 13 F8 F9 14 00 03 D6 10
    .byte $00,$FC,$E7,$15,$FC,$F7,$16,$FC         ; 8BC9: 00 FC E7 15 FC F7 16 FC
    .byte $05,$D8,$10,$00,$FC,$E9,$17,$F8         ; 8BD1: 05 D8 10 00 FC E9 17 F8
    .byte $E9,$18,$00,$F9,$19,$F8,$F9,$0F         ; 8BD9: E9 18 00 F9 19 F8 F9 0F
    .byte $00,$05,$D6,$10,$40,$FD,$F7,$20         ; 8BE1: 00 05 D6 10 40 FD F7 20
    .byte $01,$E7,$1E,$01,$F6,$20,$00,$F9         ; 8BE9: 01 E7 1E 01 F6 20 00 F9
    .byte $E7,$1E,$F9,$05,$D6,$10,$00,$FD         ; 8BF1: E7 1E F9 05 D6 10 00 FD
    .byte $E7,$1E,$F9,$F7,$20,$F9,$E6,$1E         ; 8BF9: E7 1E F9 F7 20 F9 E6 1E
    .byte $40,$01,$F7,$20,$01,$05,$D4,$2D         ; 8C01: 40 01 F7 20 01 05 D4 2D
    .byte $00,$FD,$E5,$6A,$F9,$E3,$6B,$01         ; 8C09: 00 FD E5 6A F9 E3 6B 01
    .byte $F5,$6C,$F9,$F3,$6D,$01,$05,$D4         ; 8C11: F5 6C F9 F3 6D 01 05 D4
    .byte $2D,$00,$FD,$E2,$6B,$40,$F8,$E5         ; 8C19: 2D 00 FD E2 6B 40 F8 E5
    .byte $6A,$00,$F3,$6D,$F8,$F5,$6C,$00         ; 8C21: 6A 00 F3 6D F8 F5 6C 00
    .byte $05,$D6,$10,$40,$FA,$DB,$26,$02         ; 8C29: 05 D6 10 40 FA DB 26 02
    .byte $E5,$28,$F6,$E7,$27,$FE,$F5,$29         ; 8C31: E5 28 F6 E7 27 FE F5 29
    .byte $FA,$05,$D6,$10,$00,$FF,$DB,$26         ; 8C39: FA 05 D6 10 00 FF DB 26
    .byte $F7,$E7,$27,$FB,$E5,$28,$03,$F5         ; 8C41: F7 E7 27 FB E5 28 03 F5
    .byte $29,$FF,$04,$E2,$2A,$40,$F8,$F3         ; 8C49: 29 FF 04 E2 2A 40 F8 F3
    .byte $2B,$00,$F3,$2C,$F8,$E7,$10,$FF         ; 8C51: 2B 00 F3 2C F8 E7 10 FF
    .byte $04,$E2,$2A,$00,$01,$F3,$2B,$F9         ; 8C59: 04 E2 2A 00 01 F3 2B F9
    .byte $F3,$2C,$01,$E7,$10,$FA,$05,$D6         ; 8C61: F3 2C 01 E7 10 FA 05 D6
    .byte $10,$40,$FD,$E7,$24,$FB,$E3,$23         ; 8C69: 10 40 FD E7 24 FB E3 23
    .byte $03,$F3,$25,$01,$F6,$20,$00,$F9         ; 8C71: 03 F3 25 01 F6 20 00 F9
    .byte $05,$D6,$10,$00,$FD,$E3,$23,$F7         ; 8C79: 05 D6 10 00 FD E3 23 F7
    .byte $E7,$24,$FF,$F3,$25,$F9,$F6,$20         ; 8C81: E7 24 FF F3 25 F9 F6 20
    .byte $40,$01,$04,$F6,$2E,$40,$00,$F6         ; 8C89: 40 01 04 F6 2E 40 00 F6
    .byte $2E,$00,$F9,$07,$2F,$FD,$EB,$2D         ; 8C91: 2E 00 F9 07 2F FD EB 2D
    .byte $FD,$06,$D2,$1F,$00,$F9,$F3,$67         ; 8C99: FD 06 D2 1F 00 F9 F3 67
    .byte $F9,$E3,$66,$F9,$E2,$66,$40,$01         ; 8CA1: F9 E3 66 F9 E2 66 40 01
    .byte $D3,$1F,$01,$F3,$67,$01,$02,$F2         ; 8CA9: D3 1F 01 F3 67 01 02 F2
    .byte $68,$00,$F9,$F3,$69,$01,$02,$F2         ; 8CB1: 68 00 F9 F3 69 01 02 F2
    .byte $69,$40,$F9,$F3,$68,$01,$05,$D4         ; 8CB9: 69 40 F9 F3 68 01 05 D4
    .byte $30,$42,$FE,$E3,$32,$F8,$E3,$31         ; 8CC1: 30 42 FE E3 32 F8 E3 31
    .byte $00,$F3,$34,$F8,$F3,$33,$00,$04         ; 8CC9: 00 F3 34 F8 F3 33 00 04
    .byte $D2,$30,$42,$FE,$E3,$36,$FA,$E3         ; 8CD1: D2 30 42 FE E3 36 FA E3
    .byte $35,$02,$F3,$37,$FC,$05,$D4,$30         ; 8CD9: 35 02 F3 37 FC 05 D4 30
    .byte $42,$FE,$E3,$39,$F8,$E3,$38,$00         ; 8CE1: 42 FE E3 39 F8 E3 38 00
    .byte $F3,$3B,$F8,$F3,$3A,$00,$05,$D4         ; 8CE9: F3 3B F8 F3 3A 00 05 D4
    .byte $30,$02,$FB,$E3,$31,$F9,$E3,$32         ; 8CF1: 30 02 FB E3 31 F9 E3 32
    .byte $01,$F3,$33,$F9,$F3,$34,$01,$04         ; 8CF9: 01 F3 33 F9 F3 34 01 04
    .byte $D2,$30,$02,$FB,$E3,$35,$F7,$E3         ; 8D01: D2 30 02 FB E3 35 F7 E3
    .byte $36,$FF,$F3,$37,$FD,$05,$D4,$30         ; 8D09: 36 FF F3 37 FD 05 D4 30
    .byte $02,$FB,$E3,$38,$F9,$E3,$39,$01         ; 8D11: 02 FB E3 38 F9 E3 39 01
    .byte $F3,$3A,$F9,$F3,$3B,$01,$05,$D2         ; 8D19: F3 3A F9 F3 3B 01 05 D2
    .byte $30,$42,$FD,$E3,$36,$F9,$E3,$3C         ; 8D21: 30 42 FD E3 36 F9 E3 3C
    .byte $01,$F3,$3E,$00,$F2,$3E,$02,$F9         ; 8D29: 01 F3 3E 00 F2 3E 02 F9
    .byte $05,$D2,$30,$02,$FC,$E3,$3C,$F8         ; 8D31: 05 D2 30 02 FC E3 3C F8
    .byte $E3,$36,$00,$F3,$3E,$F9,$F2,$3E         ; 8D39: E3 36 00 F3 3E F9 F2 3E
    .byte $42,$00,$06,$D2,$3D,$02,$F9,$D3         ; 8D41: 42 00 06 D2 3D 02 F9 D3
    .byte $3F,$01,$E3,$40,$F9,$E3,$41,$01         ; 8D49: 3F 01 E3 40 F9 E3 41 01
    .byte $F3,$43,$F9,$F3,$44,$01,$06,$D2         ; 8D51: F3 43 F9 F3 44 01 06 D2
    .byte $3F,$42,$F9,$D3,$3D,$01,$E3,$41         ; 8D59: 3F 42 F9 D3 3D 01 E3 41
    .byte $F9,$E3,$40,$01,$F3,$44,$F9,$F3         ; 8D61: F9 E3 40 01 F3 44 F9 F3
    .byte $43,$01,$06,$D2,$30,$42,$FD,$E3         ; 8D69: 43 01 06 D2 30 42 FD E3
    .byte $36,$F9,$E3,$47,$01,$F3,$48,$00         ; 8D71: 36 F9 E3 47 01 F3 48 00
    .byte $F2,$3E,$02,$F9,$DA,$49,$40,$09         ; 8D79: F2 3E 02 F9 DA 49 40 09
    .byte $06,$D2,$30,$02,$FC,$E3,$47,$F8         ; 8D81: 06 D2 30 02 FC E3 47 F8
    .byte $E3,$36,$00,$F3,$48,$F9,$DA,$49         ; 8D89: E3 36 00 F3 48 F9 DA 49
    .byte $00,$F0,$F2,$3E,$42,$00,$05,$D2         ; 8D91: 00 F0 F2 3E 42 00 05 D2
    .byte $4A,$02,$FD,$E3,$4B,$F9,$F3,$48         ; 8D99: 4A 02 FD E3 4B F9 F3 48
    .byte $F9,$E2,$4B,$42,$01,$F3,$48,$01         ; 8DA1: F9 E2 4B 42 01 F3 48 01
    .byte $04,$E4,$42,$02,$FD,$F4,$45,$02         ; 8DA9: 04 E4 42 02 FD F4 45 02
    .byte $F9,$05,$46,$FD,$F4,$45,$42,$01         ; 8DB1: F9 05 46 FD F4 45 42 01
    .byte $06,$D2,$4C,$02,$F8,$E3,$4D,$F8         ; 8DB9: 06 D2 4C 02 F8 E3 4D F8
    .byte $E3,$4E,$00,$F3,$4F,$F9,$D2,$4C         ; 8DC1: E3 4E 00 F3 4F F9 D2 4C
    .byte $42,$00,$F3,$4F,$00,$02,$F2,$50         ; 8DC9: 42 00 F3 4F 00 02 F2 50
    .byte $02,$F9,$F2,$50,$42,$01,$04,$E2         ; 8DD1: 02 F9 F2 50 42 01 04 E2
    .byte $51,$02,$F9,$F3,$52,$F9,$E2,$51         ; 8DD9: 51 02 F9 F3 52 F9 E2 51
    .byte $42,$01,$F3,$52,$01,$04,$D8,$A0         ; 8DE1: 42 01 F3 52 01 04 D8 A0
    .byte $41,$00,$80,$43,$8E,$04,$D6,$A0         ; 8DE9: 41 00 80 43 8E 04 D6 A0
    .byte $41,$00,$E3,$A2,$FA,$E7,$A4,$00         ; 8DF1: 41 00 E3 A2 FA E7 A4 00
    .byte $F3,$A5,$FA,$04,$D8,$A0,$01,$F9         ; 8DF9: F3 A5 FA 04 D8 A0 01 F9
    .byte $80,$4E,$8E,$04,$D6,$A0,$01,$F9         ; 8E01: 80 4E 8E 04 D6 A0 01 F9
    .byte $E7,$A4,$F9,$E3,$A2,$FF,$F3,$A5         ; 8E09: E7 A4 F9 E3 A2 FF F3 A5
    .byte $FF,$04,$D6,$A6,$41,$F9,$D9,$A0         ; 8E11: FF 04 D6 A6 41 F9 D9 A0
    .byte $FF,$E7,$A7,$FA,$F5,$A3,$F8,$04         ; 8E19: FF E7 A7 FA F5 A3 F8 04
    .byte $D8,$A0,$01,$FA,$D7,$A6,$00,$E7         ; 8E21: D8 A0 01 FA D7 A6 00 E7
    .byte $A7,$FF,$F5,$A3,$01,$01,$F8,$A8         ; 8E29: A7 FF F5 A3 01 01 F8 A8
    .byte $01,$FC,$01,$F8,$A9,$01,$FC,$01         ; 8E31: 01 FC 01 F8 A9 01 FC 01
    .byte $F8,$AA,$01,$FC,$01,$F8,$A9,$41         ; 8E39: F8 AA 01 FC 01 F8 A9 41
    .byte $FC,$03,$E4,$A2,$41,$FA,$E9,$A1         ; 8E41: FC 03 E4 A2 41 FA E9 A1
    .byte $00,$F5,$A3,$F9,$03,$E8,$A1,$01         ; 8E49: 00 F5 A3 F9 03 E8 A1 01
    .byte $F9,$E5,$A2,$FF,$F5,$A3,$00,$01         ; 8E51: F9 E5 A2 FF F5 A3 00 01
    .byte $F2,$A0,$41,$FC,$01,$F2,$AB,$41         ; 8E59: F2 A0 41 FC 01 F2 AB 41
    .byte $FC,$01,$F2,$A0,$01,$FC,$01,$F2         ; 8E61: FC 01 F2 A0 01 FC 01 F2
    .byte $AB,$01,$FC,$01,$F2,$64,$01,$FC         ; 8E69: AB 01 FC 01 F2 64 01 FC
    .byte $01,$F2,$84,$01,$FC,$02,$F2,$63         ; 8E71: 01 F2 84 01 FC 02 F2 63
    .byte $00,$F9,$F2,$63,$40,$01,$02,$F2         ; 8E79: 00 F9 F2 63 40 01 02 F2
    .byte $62,$00,$F9,$F2,$62,$40,$01,$04         ; 8E81: 62 00 F9 F2 62 40 01 04
    .byte $E2,$54,$40,$F8,$E3,$53,$00,$F3         ; 8E89: E2 54 40 F8 E3 53 00 F3
    .byte $56,$F8,$F3,$55,$00,$04,$E2,$57         ; 8E91: 56 F8 F3 55 00 04 E2 57
    .byte $40,$F9,$E3,$53,$01,$F3,$59,$F9         ; 8E99: 40 F9 E3 53 01 F3 59 F9
    .byte $F3,$58,$01,$04,$E2,$53,$00,$F9         ; 8EA1: F3 58 01 04 E2 53 00 F9
    .byte $E3,$54,$01,$F3,$55,$F9,$F3,$56         ; 8EA9: E3 54 01 F3 55 F9 F3 56
    .byte $01,$04,$E2,$53,$00,$F8,$E3,$57         ; 8EB1: 01 04 E2 53 00 F8 E3 57
    .byte $00,$F3,$58,$F8,$F3,$59,$00,$04         ; 8EB9: 00 F3 58 F8 F3 59 00 04
    .byte $E2,$5B,$43,$F8,$E3,$5A,$00,$F3         ; 8EC1: E2 5B 43 F8 E3 5A 00 F3
    .byte $5D,$F8,$F3,$5C,$00,$04,$E2,$5F         ; 8EC9: 5D F8 F3 5C 00 04 E2 5F
    .byte $43,$F8,$E3,$5E,$00,$F3,$61,$F8         ; 8ED1: 43 F8 E3 5E 00 F3 61 F8
    .byte $F3,$60,$00,$04,$E2,$5A,$03,$F9         ; 8ED9: F3 60 00 04 E2 5A 03 F9
    .byte $E3,$5B,$01,$F3,$5C,$F9,$F3,$5D         ; 8EE1: E3 5B 01 F3 5C F9 F3 5D
    .byte $01,$04,$E2,$5E,$03,$F9,$E3,$5F         ; 8EE9: 01 04 E2 5E 03 F9 E3 5F
    .byte $01,$F3,$60,$F9,$F3,$61,$01,$04         ; 8EF1: 01 F3 60 F9 F3 61 01 04
    .byte $E2,$B0,$00,$F8,$F3,$B1,$F8,$E2         ; 8EF9: E2 B0 00 F8 F3 B1 F8 E2
    .byte $B0,$40,$00,$F3,$B1,$00,$04,$E2         ; 8F01: B0 40 00 F3 B1 00 04 E2
    .byte $B2,$00,$F8,$F3,$B3,$F8,$E2,$B2         ; 8F09: B2 00 F8 F3 B3 F8 E2 B2
    .byte $40,$00,$F3,$B3,$00,$06,$D8,$F7         ; 8F11: 40 00 F3 B3 00 06 D8 F7
    .byte $01,$F9,$D9,$F8,$01,$E9,$F9,$F9         ; 8F19: 01 F9 D9 F8 01 E9 F9 F9
    .byte $E9,$FA,$01,$F9,$FB,$F9,$F9,$FC         ; 8F21: E9 FA 01 F9 FB F9 F9 FC
    .byte $01,$06,$D8,$F8,$41,$F8,$D9,$F7         ; 8F29: 01 06 D8 F8 41 F8 D9 F7
    .byte $00,$E9,$FA,$F8,$E9,$F9,$00,$F9         ; 8F31: 00 E9 FA F8 E9 F9 00 F9
    .byte $FC,$F8,$F9,$FB,$00,$04,$E0,$AD         ; 8F39: FC F8 F9 FB 00 04 E0 AD
    .byte $40,$F8,$E1,$AC,$00,$F1,$AF,$F8         ; 8F41: 40 F8 E1 AC 00 F1 AF F8
    .byte $F1,$AE,$00,$04,$E0,$AC,$00,$F8         ; 8F49: F1 AE 00 04 E0 AC 00 F8
    .byte $E1,$AD,$00,$F1,$AE,$F8,$F1,$AF         ; 8F51: E1 AD 00 F1 AE F8 F1 AF
    .byte $00,$07,$B8,$7A,$02,$F4,$D9,$7A         ; 8F59: 00 07 B8 7A 02 F4 D9 7A
    .byte $F4,$C9,$7B,$FC,$E1,$7C,$F8,$E1         ; 8F61: F4 C9 7B FC E1 7C F8 E1
    .byte $7D,$00,$F1,$7E,$F8,$F1,$7F,$00         ; 8F69: 7D 00 F1 7E F8 F1 7F 00
    .byte $08,$B8,$7A,$02,$F4,$C9,$7A,$04         ; 8F71: 08 B8 7A 02 F4 C9 7A 04
    .byte $80,$5F,$8F,$07,$B8,$7B,$02,$F4         ; 8F79: 80 5F 8F 07 B8 7B 02 F4
    .byte $C9,$7B,$04,$D1,$7C,$F0,$D1,$7D         ; 8F81: C9 7B 04 D1 7C F0 D1 7D
    .byte $F8,$E1,$7E,$F0,$E1,$7F,$F8,$E9         ; 8F89: F8 E1 7E F0 E1 7F F8 E9
    .byte $7B,$FC,$08,$C0,$7C,$02,$00,$C1         ; 8F91: 7B FC 08 C0 7C 02 00 C1
    .byte $7D,$08,$D1,$7E,$00,$D1,$7F,$08         ; 8F99: 7D 08 D1 7E 00 D1 7F 08
    .byte $C9,$7A,$FC,$D9,$7B,$F4,$D9,$7A         ; 8FA1: C9 7A FC D9 7B F4 D9 7A
    .byte $04,$E9,$7A,$FC,$05,$C0,$7C,$02         ; 8FA9: 04 E9 7A FC 05 C0 7C 02
    .byte $F8,$C1,$7D,$00,$D1,$7E,$F8,$D1         ; 8FB1: F8 C1 7D 00 D1 7E F8 D1
    .byte $7F,$00,$D9,$7B,$04,$01,$F8,$72         ; 8FB9: 7F 00 D9 7B 04 01 F8 72
    .byte $00,$FC,$01,$F4,$73,$01,$FC,$02         ; 8FC1: 00 FC 01 F4 73 01 FC 02
    .byte $E2,$6E,$00,$FA,$F3,$6F,$00,$02         ; 8FC9: E2 6E 00 FA F3 6F 00 02
    .byte $E2,$70,$01,$FC,$F3,$71,$FC,$02         ; 8FD1: E2 70 01 FC F3 71 FC 02
    .byte $E2,$88,$01,$FC,$F2,$86,$00,$FC         ; 8FD9: E2 88 01 FC F2 86 00 FC
    .byte $02,$E2,$89,$01,$FC,$F2,$86,$00         ; 8FE1: 02 E2 89 01 FC F2 86 00
    .byte $FC,$02,$E2,$87,$01,$FC,$F2,$86         ; 8FE9: FC 02 E2 87 01 FC F2 86
    .byte $00,$FC,$04,$E2,$8C,$01,$F9,$E3         ; 8FF1: 00 FC 04 E2 8C 01 F9 E3
    .byte $8D,$01,$F3,$9C,$F9,$F3,$9D,$01         ; 8FF9: 8D 01 F3 9C F9 F3 9D 01
    .byte $06,$D2,$DE,$63,$00,$D2,$DE,$23         ; 9001: 06 D2 DE 63 00 D2 DE 23
    .byte $F8,$80,$21,$90,$06,$D2,$DF,$63         ; 9009: F8 80 21 90 06 D2 DF 63
    .byte $00,$D2,$DF,$23,$F8,$80,$21,$90         ; 9011: 00 D2 DF 23 F8 80 21 90
    .byte $06,$D2,$FE,$23,$F8,$D3,$FE,$00         ; 9019: 06 D2 FE 23 F8 D3 FE 00
    .byte $E3,$FE,$F8,$E3,$FE,$00,$F3,$FE         ; 9021: E3 FE F8 E3 FE 00 F3 FE
    .byte $F8,$F3,$FE,$00,$02,$E4,$77,$01         ; 9029: F8 F3 FE 00 02 E4 77 01
    .byte $FA,$F3,$78,$01,$03,$E2,$85,$00         ; 9031: FA F3 78 01 03 E2 85 00
    .byte $FC,$F3,$94,$F8,$F3,$95,$00,$03         ; 9039: FC F3 94 F8 F3 95 00 03
    .byte $E2,$85,$01,$FC,$F3,$94,$F8,$F3         ; 9041: E2 85 01 FC F3 94 F8 F3
    .byte $95,$00,$06,$D2,$80,$01,$F9,$E3         ; 9049: 95 00 06 D2 80 01 F9 E3
    .byte $82,$F9,$F3,$90,$F9,$D3,$81,$01         ; 9051: 82 F9 F3 90 F9 D3 81 01
    .byte $E3,$83,$01,$F3,$91,$01,$04,$E2         ; 9059: E3 83 01 F3 91 01 04 E2
    .byte $80,$01,$F9,$F3,$90,$F9,$E3,$81         ; 9061: 80 01 F9 F3 90 F9 E3 81
    .byte $01,$F3,$91,$01,$01,$EE,$84,$01         ; 9069: 01 F3 91 01 01 EE 84 01
    .byte $FC,$04,$E2,$92,$01,$F9,$F3,$93         ; 9071: FC 04 E2 92 01 F9 F3 93
    .byte $F9,$E2,$92,$41,$01,$F3,$93,$01         ; 9079: F9 E2 92 41 01 F3 93 01
    .byte $0F,$00,$C0,$03,$08,$01,$C1,$10         ; 9081: 0F 00 C0 03 08 01 C1 10
    .byte $01,$C2,$18,$11,$C3,$00,$11,$C4         ; 9089: 01 C2 18 11 C3 00 11 C4
    .byte $08,$11,$C5,$10,$11,$C6,$18,$21         ; 9091: 08 11 C5 10 11 C6 18 21
    .byte $C7,$00,$21,$C8,$08,$21,$C9,$10         ; 9099: C7 00 21 C8 08 21 C9 10
    .byte $21,$CA,$18,$31,$CB,$00,$31,$CC         ; 90A1: 21 CA 18 31 CB 00 31 CC
    .byte $08,$31,$CD,$10,$31,$CE,$18,$01         ; 90A9: 08 31 CD 10 31 CE 18 01
    .byte $F2,$75,$01,$FD,$01,$F2,$65,$00         ; 90B1: F2 75 01 FD 01 F2 65 00
    .byte $FD,$02,$E8,$96,$01,$F6,$E9,$99         ; 90B9: FD 02 E8 96 01 F6 E9 99
    .byte $FE,$02,$E8,$97,$01,$F6,$E9,$99         ; 90C1: FE 02 E8 97 01 F6 E9 99
    .byte $FE,$02,$E8,$98,$01,$F6,$E9,$99         ; 90C9: FE 02 E8 98 01 F6 E9 99
    .byte $FE,$02,$E8,$9A,$01,$F6,$E9,$99         ; 90D1: FE 02 E8 9A 01 F6 E9 99
    .byte $FE,$02,$E8,$9B,$01,$F6,$E9,$99         ; 90D9: FE 02 E8 9B 01 F6 E9 99
    .byte $FE,$04,$D6,$BC,$40,$FC,$E7,$BD         ; 90E1: FE 04 D6 BC 40 FC E7 BD
    .byte $FC,$E6,$BE,$42,$FC,$F7,$BF,$FC         ; 90E9: FC E6 BE 42 FC F7 BF FC
    .byte $04,$D6,$BC,$00,$FD,$E7,$BD,$FD         ; 90F1: 04 D6 BC 00 FD E7 BD FD
    .byte $E6,$BE,$02,$FD,$F7,$BF,$FD,$05         ; 90F9: E6 BE 02 FD F7 BF FD 05
    .byte $DE,$10,$40,$FD,$ED,$1B,$F7,$EF         ; 9101: DE 10 40 FD ED 1B F7 EF
    .byte $1A,$FF,$FD,$1D,$F7,$FF,$1C,$FF         ; 9109: 1A FF FD 1D F7 FF 1C FF
    .byte $05,$DE,$10,$00,$FC,$EF,$1A,$FA         ; 9111: 05 DE 10 00 FC EF 1A FA
    .byte $ED,$1B,$02,$FF,$1C,$FA,$FD,$1D         ; 9119: ED 1B 02 FF 1C FA FD 1D
    .byte $02,$02,$E8,$8A,$01,$F6,$E9,$99         ; 9121: 02 02 E8 8A 01 F6 E9 99
    .byte $FE,$02,$E8,$8B,$01,$F6,$E9,$99         ; 9129: FE 02 E8 8B 01 F6 E9 99
    .byte $FE,$06,$E2,$D8,$03,$F8,$E2,$D8         ; 9131: FE 06 E2 D8 03 F8 E2 D8
    .byte $43,$00,$E2,$D9,$00,$F8,$F3,$DA         ; 9139: 43 00 E2 D9 00 F8 F3 DA
    .byte $F8,$E2,$D9,$40,$00,$F3,$DA,$00         ; 9141: F8 E2 D9 40 00 F3 DA 00
    .byte $07,$F2,$E0,$00,$F8,$E3,$E1,$F8         ; 9149: 07 F2 E0 00 F8 E3 E1 F8
    .byte $E2,$E1,$40,$00,$E2,$E2,$43,$00         ; 9151: E2 E1 40 00 E2 E2 43 00
    .byte $F3,$E3,$00,$E2,$E2,$03,$F8,$F3         ; 9159: F3 E3 00 E2 E2 03 F8 F3
    .byte $E3,$F8,$04,$E2,$EE,$40,$F8,$E3         ; 9161: E3 F8 04 E2 EE 40 F8 E3
    .byte $EF,$00,$F2,$EE,$C0,$F8,$F3,$EF         ; 9169: EF 00 F2 EE C0 F8 F3 EF
    .byte $00,$04,$E2,$BB,$40,$00,$E3,$DC         ; 9171: 00 04 E2 BB 40 00 E3 DC
    .byte $F8,$F3,$DB,$00,$F3,$DD,$F8,$06         ; 9179: F8 F3 DB 00 F3 DD F8 06
    .byte $E2,$B5,$02,$F8,$E3,$B6,$00,$F3         ; 9181: E2 B5 02 F8 E3 B6 00 F3
    .byte $B7,$F8,$F3,$B8,$00,$EC,$B9,$03         ; 9189: B7 F8 F3 B8 00 EC B9 03
    .byte $F8,$ED,$BA,$00,$04,$E2,$E8,$01         ; 9191: F8 ED BA 00 04 E2 E8 01
    .byte $F8,$F3,$E9,$F8,$E2,$E8,$41,$00         ; 9199: F8 F3 E9 F8 E2 E8 41 00
    .byte $F3,$E9,$00,$05,$E2,$FA,$02,$F8         ; 91A1: F3 E9 00 05 E2 FA 02 F8
    .byte $E2,$FA,$42,$00,$E2,$FB,$00,$FC         ; 91A9: E2 FA 42 00 E2 FB 00 FC
    .byte $F2,$FC,$01,$F8,$F2,$FC,$41,$00         ; 91B1: F2 FC 01 F8 F2 FC 41 00
    .byte $04,$E8,$E4,$02,$F6,$F9,$E5,$F6         ; 91B9: 04 E8 E4 02 F6 F9 E5 F6
    .byte $F1,$E6,$FE,$F1,$E7,$06,$03,$E2         ; 91C1: F1 E6 FE F1 E7 06 03 E2
    .byte $01,$00,$FC,$F3,$02,$F9,$F2,$02         ; 91C9: 01 00 FC F3 02 F9 F2 02
    .byte $40,$00,$03,$E2,$01,$40,$FD,$F3         ; 91D1: 40 00 03 E2 01 40 FD F3
    .byte $02,$00,$F2,$02,$00,$F9,$03,$E2         ; 91D9: 02 00 F2 02 00 F9 03 E2
    .byte $03,$00,$FC,$F3,$02,$F9,$F2,$02         ; 91E1: 03 00 FC F3 02 F9 F2 02
    .byte $40,$00,$04,$E2,$04,$00,$F9,$F3         ; 91E9: 40 00 04 E2 04 00 F9 F3
    .byte $05,$F9,$E2,$04,$40,$00,$F3,$05         ; 91F1: 05 F9 E2 04 40 00 F3 05
    .byte $00,$07,$E0,$06,$01,$E4,$E1,$07         ; 91F9: 00 07 E0 06 01 E4 E1 07
    .byte $EC,$E1,$08,$F4,$E1,$09,$FC,$E1         ; 9201: EC E1 08 F4 E1 09 FC E1
    .byte $0A,$04,$E1,$0B,$0C,$E1,$0C,$14         ; 9209: 0A 04 E1 0B 0C E1 0C 14
    .byte $05,$03,$05,$03,$06,$06,$06,$02         ; 9211: 05 03 05 03 06 06 06 02
    .byte $04,$01,$EA,$F2,$00,$FD,$04,$E2         ; 9219: 04 01 EA F2 00 FD 04 E2
    .byte $F3,$00,$F9,$E3,$F4,$01,$F3,$F5         ; 9221: F3 00 F9 E3 F4 01 F3 F5
    .byte $F9,$F3,$F6,$01,$04,$E2,$D2,$00         ; 9229: F9 F3 F6 01 04 E2 D2 00
    .byte $F9,$E3,$D3,$01,$F3,$D4,$F9,$F3         ; 9231: F9 E3 D3 01 F3 D4 F9 F3
    .byte $D5,$01,$04,$E2,$D6,$01,$F9,$E3         ; 9239: D5 01 04 E2 D6 01 F9 E3
    .byte $D7,$01,$F3,$F0,$F9,$F3,$F1,$01         ; 9241: D7 01 F3 F0 F9 F3 F1 01
    .byte $04,$E2,$8E,$02,$F9,$E3,$8F,$01         ; 9249: 04 E2 8E 02 F9 E3 8F 01
    .byte $F3,$9E,$F9,$F3,$9F,$01,$01,$F2         ; 9251: F3 9E F9 F3 9F 01 01 F2
    .byte $76,$00,$FD                             ; 9259: 76 00 FD
L925C:
    JSR ClearLoadScreen0        ; 925C: 20 56 89
    JSR $ECB4                   ; 925F: 20 B4 EC  -> Bank1:LoadScreen2
    LDA #$00                    ; 9262: A9 00
    JSR PpuBufPutStr            ; 9264: 20 AD 86
    LDA #$14                    ; 9267: A9 14
    JSR PpuBufPutNum            ; 9269: 20 5C 84
    LDA #$02                    ; 926C: A9 02
    JMP PpuBufPutStr            ; 926E: 4C AD 86
L9271:
    LDA $9A                     ; 9271: A5 9A
    ORA RenderDelay             ; 9273: 05 0C
    BEQ L927C                   ; 9275: F0 05
    LDA #$01                    ; 9277: A9 01
    STA $16                     ; 9279: 85 16
    RTS                         ; 927B: 60
L927C:
    JSR DeathSequence           ; 927C: 20 CE 9A
    JSR DoorCloseCheck          ; 927F: 20 9B B4
    JSR DoorOpenScan            ; 9282: 20 29 B4
    JSR AttackHitScan           ; 9285: 20 89 AC
    LDA FrameCnt                ; 9288: A5 09
    LSR A                       ; 928A: 4A
    BCC L9293                   ; 928B: 90 06
    JSR LB376                   ; 928D: 20 76 B3
    JMP L92AF                   ; 9290: 4C AF 92
L9293:
    LDX StageArea               ; 9293: A6 A3
    DEX                         ; 9295: CA
    LDA $92B4,X                 ; 9296: BD B4 92
    TAY                         ; 9299: A8
    LDA SlingAmmo               ; 929A: AD F2 05
    BEQ L92A0                   ; 929D: F0 01
    INY                         ; 929F: C8
L92A0:
    LDA EquipBits               ; 92A0: A5 49
    AND #$20                    ; 92A2: 29 20
    BEQ L92A7                   ; 92A4: F0 01
    INY                         ; 92A6: C8
L92A7:
    TYA                         ; 92A7: 98
    CLC                         ; 92A8: 18
    ADC PowerLevel              ; 92A9: 65 1D
    AND #$07                    ; 92AB: 29 07
    STA DifficultyGear          ; 92AD: 85 1B
L92AF:
    LDA #$00                    ; 92AF: A9 00
    STA $16                     ; 92B1: 85 16
    RTS                         ; 92B3: 60
    .byte $00,$01,$01,$02,$02,$03,$03,$04         ; 92B4: 00 01 01 02 02 03 03 04
    .byte $04                                     ; 92BC: 04
L92BD:
    LDA $05D0                   ; 92BD: AD D0 05
    CMP #$03                    ; 92C0: C9 03
    BNE L92C9                   ; 92C2: D0 05
    LDY #$07                    ; 92C4: A0 07
    JMP SetSpriteByFlag         ; 92C6: 4C 04 95
L92C9:
    JSR L9821                   ; 92C9: 20 21 98
    LDX ObjLoopSlot             ; 92CC: A6 48
    JSR FloorBandScan           ; 92CE: 20 A6 A2
    LDA #$10                    ; 92D1: A9 10
    STA ObjSpeedX,X             ; 92D3: 9D C0 04
    LDA #$00                    ; 92D6: A9 00
    STA ObjXPage,X              ; 92D8: 9D 10 04
    LDA #$03                    ; 92DB: A9 03
    LDY ObjSprite,X             ; 92DD: B4 70
    CPY #$13                    ; 92DF: C0 13
    BNE L92E5                   ; 92E1: D0 02
    LDA #$04                    ; 92E3: A9 04
L92E5:
    STA ObjBoxProf,X            ; 92E5: 9D 70 05
    LDA ObjState,X              ; 92E8: B5 50
    CMP #$06                    ; 92EA: C9 06
    BEQ L9305                   ; 92EC: F0 17
    JSR L9405                   ; 92EE: 20 05 94
    LDA $05D1                   ; 92F1: AD D1 05
    BNE L92FE                   ; 92F4: D0 08
    JSR PlayerContactScan       ; 92F6: 20 53 B7
    LDX ObjLoopSlot             ; 92F9: A6 48
    JSR LB003                   ; 92FB: 20 03 B0
L92FE:
    LDX ObjLoopSlot             ; 92FE: A6 48
    JSR PlayerInteract          ; 9300: 20 22 B6
    LDX ObjLoopSlot             ; 9303: A6 48
L9305:
    LDA ObjState,X              ; 9305: B5 50
    JSR DispatchJump            ; 9307: 20 9A 85
    .byte $6C,$94,$2E,$9D,$6D,$95,$BC,$93         ; 930A: 6C 94 2E 9D 6D 95 BC 93
    .byte $83,$95,$4E,$95,$18,$93                 ; 9312: 83 95 4E 95 18 93
L9318:
    LDA #$08                    ; 9318: A9 08
    STA ObjSpeedX,X             ; 931A: 9D C0 04
    LDY ObjPhase,X              ; 931D: BC 40 05
    BEQ L937B                   ; 9320: F0 59
    DEY                         ; 9322: 88
    BEQ L9350                   ; 9323: F0 2B
    DEC ObjTimer,X              ; 9325: DE 30 04
    BNE L936D                   ; 9328: D0 43
    LDA $05DA                   ; 932A: AD DA 05
    STA ObjX,X                  ; 932D: 9D 70 04
    JSR LB85B                   ; 9330: 20 5B B8
    JSR ClearObjectList         ; 9333: 20 09 A3
    LDA #$00                    ; 9336: A9 00
    STA $0541                   ; 9338: 8D 41 05
    STA $51                     ; 933B: 85 51
    LDA StageArea               ; 933D: A5 A3
    CMP #$08                    ; 933F: C9 08
    BNE L934D                   ; 9341: D0 0A
    LDA $05D6                   ; 9343: AD D6 05
    CMP #$05                    ; 9346: C9 05
    BCS L934D                   ; 9348: B0 03
    JMP GameStart               ; 934A: 4C 37 83
L934D:
    JMP $CA30                   ; 934D: 4C 30 CA  -> Bank1:LCA30
L9350:
    LDY #$00                    ; 9350: A0 00
    JSR AnimPingpongByDir       ; 9352: 20 29 95
    JSR ObjWalkByDir            ; 9355: 20 34 95
    LDA ObjX,X                  ; 9358: BD 70 04
    CMP $05D9                   ; 935B: CD D9 05
    BEQ L936E                   ; 935E: F0 0E
    CMP $05DC                   ; 9360: CD DC 05
    BNE L93BC                   ; 9363: D0 57
    INC ObjPhase,X              ; 9365: FE 40 05
    LDA #$30                    ; 9368: A9 30
    STA ObjTimer,X              ; 936A: 9D 30 04
L936D:
    RTS                         ; 936D: 60
L936E:
    LDA #$00                    ; 936E: A9 00
    STA $05D9                   ; 9370: 8D D9 05
    JSR InitSound               ; 9373: 20 14 86
    LDY #$1A                    ; 9376: A0 1A
    JMP SoundCmd80              ; 9378: 4C 22 86
L937B:
    JSR ClearObjectList         ; 937B: 20 09 A3
    LDX ObjLoopSlot             ; 937E: A6 48
    LDA #$31                    ; 9380: A9 31
    STA $6F                     ; 9382: 85 6F
    LDA #$64                    ; 9384: A9 64
    STA $7F                     ; 9386: 85 7F
    LDA #$00                    ; 9388: A9 00
    STA $041F                   ; 938A: 8D 1F 04
    STA $054F                   ; 938D: 8D 4F 05
    LDA $05DB                   ; 9390: AD DB 05
    STA $046F                   ; 9393: 8D 6F 04
    LDY #$03                    ; 9396: A0 03
    LDA $05DA                   ; 9398: AD DA 05
    CMP ObjX,X                  ; 939B: DD 70 04
    BCC L93A2                   ; 939E: 90 02
    LDY #$00                    ; 93A0: A0 00
L93A2:
    CLC                         ; 93A2: 18
    ADC $93BD,Y                 ; 93A3: 79 BD 93
    STA $05D9                   ; 93A6: 8D D9 05
    CLC                         ; 93A9: 18
    ADC $93BE,Y                 ; 93AA: 79 BE 93
    STA $05DC                   ; 93AD: 8D DC 05
    STA $047F                   ; 93B0: 8D 7F 04
    LDA $93BF,Y                 ; 93B3: B9 BF 93
    STA ObjDirFlags,X           ; 93B6: 9D 10 05
    INC ObjPhase,X              ; 93B9: FE 40 05
L93BC:
    RTS                         ; 93BC: 60
    .byte $06,$0A,$01,$FA,$F6,$02                 ; 93BD: 06 0A 01 FA F6 02
L93C3:
    LDA $05D2                   ; 93C3: AD D2 05
    BEQ L93CC                   ; 93C6: F0 04
    DEC $05D2                   ; 93C8: CE D2 05
    RTS                         ; 93CB: 60
L93CC:
    LDA #$08                    ; 93CC: A9 08
    LDY StageArea               ; 93CE: A4 A3
    CPY #$07                    ; 93D0: C0 07
    BEQ L93D6                   ; 93D2: F0 02
    LDA #$04                    ; 93D4: A9 04
L93D6:
    ORA ObjMoveDir,X            ; 93D6: 1D A0 04
    STA ObjDirFlags,X           ; 93D9: 9D 10 05
    LDA #$08                    ; 93DC: A9 08
    STA ObjSpeedX,X             ; 93DE: 9D C0 04
    LDA $05D4                   ; 93E1: AD D4 05
    BNE L93EE                   ; 93E4: D0 08
    LDA $05D3                   ; 93E6: AD D3 05
    BEQ L93EF                   ; 93E9: F0 04
    DEC $05D3                   ; 93EB: CE D3 05
L93EE:
    RTS                         ; 93EE: 60
L93EF:
    INC $05D4                   ; 93EF: EE D4 05
    LDA #$83                    ; 93F2: A9 83
    STA SceneId                 ; 93F4: 85 1F
    JSR L9502                   ; 93F6: 20 02 95
    LDA #$40                    ; 93F9: A9 40
    STA $05D5                   ; 93FB: 8D D5 05
    LDA #$0A                    ; 93FE: A9 0A
    STA HpDelta                 ; 9400: 85 9F
    PLA                         ; 9402: 68
    PLA                         ; 9403: 68
    RTS                         ; 9404: 60
L9405:
    LDA $05D1                   ; 9405: AD D1 05
    BNE L93C3                   ; 9408: D0 B9
    LDA JoyHeld                 ; 940A: A5 07
    AND #$03                    ; 940C: 29 03
    EOR #$03                    ; 940E: 49 03
    BNE L9416                   ; 9410: D0 04
    LDA #$02                    ; 9412: A9 02
    STA JoyHeld                 ; 9414: 85 07
L9416:
    LDA JoyPressed              ; 9416: A5 05
    STA ObjActFlags,X           ; 9418: 9D 00 05
    LDA ObjState,X              ; 941B: B5 50
    BEQ L9439                   ; 941D: F0 1A
    CMP #$04                    ; 941F: C9 04
    BEQ L9450                   ; 9421: F0 2D
    LDA $05FD                   ; 9423: AD FD 05
    BNE L942F                   ; 9426: D0 07
    LDA ObjDirFlags,X           ; 9428: BD 10 05
    AND #$03                    ; 942B: 29 03
    BNE L946B                   ; 942D: D0 3C
L942F:
    LDA #$08                    ; 942F: A9 08
    STA ObjSpeedX,X             ; 9431: 9D C0 04
    STA $05FD                   ; 9434: 8D FD 05
    BNE L945D                   ; 9437: D0 24
L9439:
    LDA #$00                    ; 9439: A9 00
    STA $05FD                   ; 943B: 8D FD 05
    LDA $05FC                   ; 943E: AD FC 05
    BEQ L945D                   ; 9441: F0 1A
    DEC $05FC                   ; 9443: CE FC 05
    BNE L946B                   ; 9446: D0 23
    LDA ObjDirFlags,X           ; 9448: BD 10 05
    AND #$FB                    ; 944B: 29 FB
    JMP L945D                   ; 944D: 4C 5D 94
L9450:
    LDA ObjDirFlags,X           ; 9450: BD 10 05
    AND #$0C                    ; 9453: 29 0C
    BEQ L945D                   ; 9455: F0 06
    LDA ObjSprite,X             ; 9457: B5 70
    CMP #$13                    ; 9459: C9 13
    BEQ L946B                   ; 945B: F0 0E
L945D:
    LDA JoyHeld                 ; 945D: A5 07
    STA ObjDirFlags,X           ; 945F: 9D 10 05
    AND #$03                    ; 9462: 29 03
    BEQ L946B                   ; 9464: F0 05
    LDA #$00                    ; 9466: A9 00
    STA $05D7                   ; 9468: 8D D7 05
L946B:
    RTS                         ; 946B: 60
L946C:
    LDA $0547                   ; 946C: AD 47 05
    ORA AttackFlag              ; 946F: 0D F4 05
    BNE L946B                   ; 9472: D0 F7
L9474:
    LDA ObjProbeA,X             ; 9474: BD 20 05
    ORA ObjProbeB,X             ; 9477: 1D 20 01
    BNE L9485                   ; 947A: D0 09
    LDA #$00                    ; 947C: A9 00
    STA ObjDirFlags,X           ; 947E: 9D 10 05
    LDA #$02                    ; 9481: A9 02
    BNE L9493                   ; 9483: D0 0E
L9485:
    LDA ObjActFlags,X           ; 9485: BD 00 05
    AND #$80                    ; 9488: 29 80
    BEQ L9496                   ; 948A: F0 0A
    JSR LA4B7                   ; 948C: 20 B7 A4
    BNE L9496                   ; 948F: D0 05
    LDA #$05                    ; 9491: A9 05
L9493:
    JMP LA301                   ; 9493: 4C 01 A3
L9496:
    LDA ObjDirFlags,X           ; 9496: BD 10 05
    AND #$08                    ; 9499: 29 08
    BEQ L94A9                   ; 949B: F0 0C
    LDA #$80                    ; 949D: A9 80
    JSR L95FB                   ; 949F: 20 FB 95
    LDA ObjState,X              ; 94A2: B5 50
    CMP #$04                    ; 94A4: C9 04
    BNE L94D7                   ; 94A6: D0 2F
L94A8:
    RTS                         ; 94A8: 60
L94A9:
    LDA ObjDirFlags,X           ; 94A9: BD 10 05
    AND #$04                    ; 94AC: 29 04
    BEQ L94D7                   ; 94AE: F0 27
    CPX #$01                    ; 94B0: E0 01
    BNE L94B9                   ; 94B2: D0 05
    LDA $05FC                   ; 94B4: AD FC 05
    BNE L94C4                   ; 94B7: D0 0B
L94B9:
    LDA #$40                    ; 94B9: A9 40
    JSR L95FB                   ; 94BB: 20 FB 95
    LDA ObjState,X              ; 94BE: B5 50
    CMP #$04                    ; 94C0: C9 04
    BEQ L94A8                   ; 94C2: F0 E4
L94C4:
    CPX #$01                    ; 94C4: E0 01
    BNE L94D7                   ; 94C6: D0 0F
    LDA $05D1                   ; 94C8: AD D1 05
    BNE L94D7                   ; 94CB: D0 0A
    LDA #$04                    ; 94CD: A9 04
    STA ObjBoxProf,X            ; 94CF: 9D 70 05
    LDY #$0D                    ; 94D2: A0 0D
    JMP SetSpriteByFlag         ; 94D4: 4C 04 95
L94D7:
    JSR L972C                   ; 94D7: 20 2C 97
    BCC L94DF                   ; 94DA: 90 03
    JMP AnimByType1             ; 94DC: 4C 61 9E
L94DF:
    JSR L975C                   ; 94DF: 20 5C 97
    BCC AnimIdleByDir           ; 94E2: 90 03
    JMP AnimByType2             ; 94E4: 4C 73 9E
AnimIdleByDir:
    ; 非玩家且类型≠5 时 Y=8 转 AnimSpriteStep；玩家（X=1）按 $05D7 取 Y=$11/7 转 SetSpriteByFlag；L967D 调用
    CPX #$01                    ; 94E7: E0 01
    BEQ L94F6                   ; 94E9: F0 0B
    LDA ObjType,X               ; 94EB: B5 60
    CMP #$05                    ; 94ED: C9 05
    BEQ L950F                   ; 94EF: F0 1E
    LDY #$08                    ; 94F1: A0 08
    JMP AnimSpriteStep          ; 94F3: 4C FB A7
L94F6:
    LDA $05D7                   ; 94F6: AD D7 05
    BEQ L9502                   ; 94F9: F0 07
    LDY #$11                    ; 94FB: A0 11
    DEC $05D7                   ; 94FD: CE D7 05
    BNE SetSpriteByFlag         ; 9500: D0 02
L9502:
    LDY #$07                    ; 9502: A0 07
SetSpriteByFlag:
    ; $04A0,X 位0=0 则 INY；TYA→$70,X（精灵号槽）；调用者以 Y 传候选精灵号
    LDA ObjMoveDir,X            ; 9504: BD A0 04
    AND #$01                    ; 9507: 29 01
    BNE L950C                   ; 9509: D0 01
    INY                         ; 950B: C8
L950C:
    TYA                         ; 950C: 98
    STA ObjSprite,X             ; 950D: 95 70
L950F:
    RTS                         ; 950F: 60
L9510:
    LDA ObjMoveDir,Y            ; 9510: B9 A0 04
    AND #$01                    ; 9513: 29 01
    BNE L9519                   ; 9515: D0 02
    INX                         ; 9517: E8
    INX                         ; 9518: E8
L9519:
    TXA                         ; 9519: 8A
    STA ObjSprite,Y             ; 951A: 99 70 00
    RTS                         ; 951D: 60
L951E:
    LDA ObjMoveDir,X            ; 951E: BD A0 04
    AND #$01                    ; 9521: 29 01
    BNE L9526                   ; 9523: D0 01
    INY                         ; 9525: C8
L9526:
    JMP AnimSpriteStep          ; 9526: 4C FB A7
AnimPingpongByDir:
    ; $04A0,X 位0=0 时 INY（朝向左用奇帧）后 JMP AnimSpritePingpong；L9352/$9F20/LA03E 等调用
    LDA ObjMoveDir,X            ; 9529: BD A0 04
    AND #$01                    ; 952C: 29 01
    BNE L9531                   ; 952E: D0 01
    INY                         ; 9530: C8
L9531:
    JMP AnimSpritePingpong      ; 9531: 4C A3 A7
ObjWalkByDir:
    ; $0510,X AND #3==0 直接 RTS；位0=0 JMP ObjMoveXSub（左行），位0=1 JMP ObjMoveXAdd（右行）
    LDA ObjDirFlags,X           ; 9534: BD 10 05
    AND #$03                    ; 9537: 29 03
    BNE L953C                   ; 9539: D0 01
    RTS                         ; 953B: 60
L953C:
    AND #$01                    ; 953C: 29 01
    BNE L9543                   ; 953E: D0 03
    JMP ObjMoveXSub             ; 9540: 4C F0 A5
L9543:
    JMP ObjMoveXAdd             ; 9543: 4C B0 A5
L9546:
    INC ObjSpeedX,X             ; 9546: FE C0 04
    INC ObjSpeedX,X             ; 9549: FE C0 04
    BNE L955C                   ; 954C: D0 0E
L954E:
    LDA AttackFlag              ; 954E: AD F4 05
    ORA $0547                   ; 9551: 0D 47 05
    ORA $05D7                   ; 9554: 0D D7 05
    ORA $05D1                   ; 9557: 0D D1 05
    BNE L955F                   ; 955A: D0 03
L955C:
    JSR L9573                   ; 955C: 20 73 95
L955F:
    JSR LA69C                   ; 955F: 20 9C A6
L9562:
    JSR PlayerContactScan       ; 9562: 20 53 B7
    BCS L95B1                   ; 9565: B0 4A
    JSR L972C                   ; 9567: 20 2C 97
    JMP L975C                   ; 956A: 4C 5C 97
L956D:
    JSR LA698                   ; 956D: 20 98 A6
    JSR L9562                   ; 9570: 20 62 95
L9573:
    LDA ObjAirFlag,X            ; 9573: BD 40 01
    BEQ L95B1                   ; 9576: F0 39
    LDY ObjType,X               ; 9578: B4 60
    LDA $9581,Y                 ; 957A: B9 81 95
    TAY                         ; 957D: A8
    JMP SetSpriteByFlag         ; 957E: 4C 04 95
    .byte $1B,$24                                 ; 9581: 1B 24
L9583:
    LDA ObjXPage,X              ; 9583: BD 10 04
    BNE L95B1                   ; 9586: D0 29
    LDA ObjDirFlags,X           ; 9588: BD 10 05
    AND #$0C                    ; 958B: 29 0C
    BEQ L95DF                   ; 958D: F0 50
    AND #$04                    ; 958F: 29 04
    BNE L95B2                   ; 9591: D0 1F
    LDA ObjClimbCd,X            ; 9593: BD 70 01
    BEQ L95A0                   ; 9596: F0 08
    DEC ObjClimbCd,X            ; 9598: DE 70 01
    BNE L95B1                   ; 959B: D0 14
    JMP L966D                   ; 959D: 4C 6D 96
L95A0:
    LDA #$80                    ; 95A0: A9 80
    JSR L95FB                   ; 95A2: 20 FB 95
    LDA ClimbState              ; 95A5: AD FA 05
    LSR A                       ; 95A8: 4A
    BCS L95B1                   ; 95A9: B0 06
    JSR ObjMoveYSub             ; 95AB: 20 8F A5
    JMP L95D6                   ; 95AE: 4C D6 95
L95B1:
    RTS                         ; 95B1: 60
L95B2:
    LDA ObjClimbCd,X            ; 95B2: BD 70 01
    BEQ L95C8                   ; 95B5: F0 11
    DEC ObjClimbCd,X            ; 95B7: DE 70 01
    BNE L95B1                   ; 95BA: D0 F5
    LDA ObjY,X                  ; 95BC: BD 60 04
    LDY ObjType,X               ; 95BF: B4 60
    CLC                         ; 95C1: 18
    ADC $95F3,Y                 ; 95C2: 79 F3 95
    STA ObjY,X                  ; 95C5: 9D 60 04
L95C8:
    LDA #$40                    ; 95C8: A9 40
    JSR L95FB                   ; 95CA: 20 FB 95
    LDA ClimbState              ; 95CD: AD FA 05
    LSR A                       ; 95D0: 4A
    BCS L95B1                   ; 95D1: B0 DE
    JSR ObjMoveYAdd             ; 95D3: 20 70 A5
L95D6:
    LDY ObjType,X               ; 95D6: B4 60
    LDA $95F5,Y                 ; 95D8: B9 F5 95
    TAY                         ; 95DB: A8
    JMP AnimSpriteStep          ; 95DC: 4C FB A7
L95DF:
    LDA #$00                    ; 95DF: A9 00
    JSR L95FB                   ; 95E1: 20 FB 95
L95E4:
    LDY ObjType,X               ; 95E4: B4 60
    LDA ObjSprite,X             ; 95E6: B5 70
    CMP $95F9,Y                 ; 95E8: D9 F9 95
    BEQ L95F2                   ; 95EB: F0 05
    LDA $95F7,Y                 ; 95ED: B9 F7 95
    STA ObjSprite,X             ; 95F0: 95 70
L95F2:
    RTS                         ; 95F2: 60
    .byte $15,$20,$03,$09,$09,$2A,$13,$2F         ; 95F3: 15 20 03 09 09 2A 13 2F
L95FB:
    STA ClimbState              ; 95FB: 8D FA 05
L95FE:
    LDY ProxRec1,X              ; 95FE: BC 50 01
    CPY #$FF                    ; 9601: C0 FF
    BEQ L9610                   ; 9603: F0 0B
    LDA $0702,Y                 ; 9605: B9 02 07
    CMP #$3C                    ; 9608: C9 3C
    BCC L9610                   ; 960A: 90 04
    CMP #$43                    ; 960C: C9 43
    BCC ClimbProbe              ; 960E: 90 18
L9610:
    TXA                         ; 9610: 8A
    CLC                         ; 9611: 18
    ADC #$10                    ; 9612: 69 10
    TAX                         ; 9614: AA
    CPX #$20                    ; 9615: E0 20
    BCC L95FE                   ; 9617: 90 E5
    LDX ObjLoopSlot             ; 9619: A6 48
    LDA ObjState,X              ; 961B: B5 50
    CMP #$04                    ; 961D: C9 04
    BNE L9626                   ; 961F: D0 05
    LDA #$00                    ; 9621: A9 00
    JMP LA301                   ; 9623: 4C 01 A3
L9626:
    CLC                         ; 9626: 18
    RTS                         ; 9627: 60
ClimbProbe:
    ; 记录 id $3C-$42（梯/绳）：顶面 Y=$0703,Y+$9725[id-$3C]，玩家 $0460 匹配则贴面（L966D 落地/L9683 挂起 $0170=$0B）
    STY $3F                     ; 9628: 84 3F
    LDA $0704,Y                 ; 962A: B9 04 07
    CLC                         ; 962D: 18
    ADC #$04                    ; 962E: 69 04
    STA $40                     ; 9630: 85 40
    LDA $0702,Y                 ; 9632: B9 02 07
    SEC                         ; 9635: 38
    SBC #$3C                    ; 9636: E9 3C
    TAX                         ; 9638: AA
    LDA $0703,Y                 ; 9639: B9 03 07
    STA $30                     ; 963C: 85 30
    CLC                         ; 963E: 18
    ADC $9725,X                 ; 963F: 7D 25 97
    STA $31                     ; 9642: 85 31
    LDX ObjLoopSlot             ; 9644: A6 48
    LDA ObjState,X              ; 9646: B5 50
    BEQ L969F                   ; 9648: F0 55
    LDA ClimbState              ; 964A: AD FA 05
    ASL A                       ; 964D: 0A
    BCS L9655                   ; 964E: B0 05
    ASL A                       ; 9650: 0A
    BCS L9661                   ; 9651: B0 0E
L9653:
    CLC                         ; 9653: 18
    RTS                         ; 9654: 60
L9655:
    LDA ObjY,X                  ; 9655: BD 60 04
    SEC                         ; 9658: 38
    SBC #$09                    ; 9659: E9 09
    CMP $30                     ; 965B: C5 30
    BCC L9683                   ; 965D: 90 24
    CLC                         ; 965F: 18
    RTS                         ; 9660: 60
L9661:
    LDA ObjY,X                  ; 9661: BD 60 04
    SEC                         ; 9664: 38
    SBC #$01                    ; 9665: E9 01
    CMP $31                     ; 9667: C5 31
    BCS L966D                   ; 9669: B0 02
    CLC                         ; 966B: 18
    RTS                         ; 966C: 60
L966D:
    LDY ObjFloorBand,X          ; 966D: BC B0 04
    LDA $A2C8,Y                 ; 9670: B9 C8 A2
    STA ObjY,X                  ; 9673: 9D 60 04
    LDA #$00                    ; 9676: A9 00
    STA ObjState,X              ; 9678: 95 50
    STA ObjDirFlags,X           ; 967A: 9D 10 05
    JSR AnimIdleByDir           ; 967D: 20 E7 94
    PLA                         ; 9680: 68
    PLA                         ; 9681: 68
    RTS                         ; 9682: 60
L9683:
    LDA #$0B                    ; 9683: A9 0B
    STA ObjClimbCd,X            ; 9685: 9D 70 01
    LDY ObjFloorBand,X          ; 9688: BC B0 04
    LDA $A2C8,Y                 ; 968B: B9 C8 A2
    STA ObjY,X                  ; 968E: 9D 60 04
    LDY ObjType,X               ; 9691: B4 60
    LDA $95F9,Y                 ; 9693: B9 F9 95
    STA ObjSprite,X             ; 9696: 95 70
    LDA #$01                    ; 9698: A9 01
    STA ClimbState              ; 969A: 8D FA 05
    SEC                         ; 969D: 38
    RTS                         ; 969E: 60
L969F:
    LDA ObjXPage,X              ; 969F: BD 10 04
    BNE L9653                   ; 96A2: D0 AF
    LDA ObjX,X                  ; 96A4: BD 70 04
    CMP #$24                    ; 96A7: C9 24
    BCC L9653                   ; 96A9: 90 A8
    CMP #$DC                    ; 96AB: C9 DC
    BCS L9653                   ; 96AD: B0 A4
    LDA ClimbState              ; 96AF: AD FA 05
    ASL A                       ; 96B2: 0A
    BCC L96F3                   ; 96B3: 90 3E
    LDA $0702,Y                 ; 96B5: B9 02 07
    LDY ObjFloorBand,X          ; 96B8: BC B0 04
    CPY #$02                    ; 96BB: C0 02
    BEQ L96DB                   ; 96BD: F0 1C
    CPY #$05                    ; 96BF: C0 05
    BEQ L96D1                   ; 96C1: F0 0E
    CMP #$3C                    ; 96C3: C9 3C
    BEQ L96E1                   ; 96C5: F0 1A
    CMP #$3F                    ; 96C7: C9 3F
    BEQ L96E1                   ; 96C9: F0 16
    CMP #$41                    ; 96CB: C9 41
    BEQ L96E1                   ; 96CD: F0 12
    CLC                         ; 96CF: 18
    RTS                         ; 96D0: 60
L96D1:
    CMP #$3D                    ; 96D1: C9 3D
    BEQ L96E1                   ; 96D3: F0 0C
    CMP #$40                    ; 96D5: C9 40
    BEQ L96E1                   ; 96D7: F0 08
    CLC                         ; 96D9: 18
    RTS                         ; 96DA: 60
L96DB:
    CMP #$3E                    ; 96DB: C9 3E
    BEQ L96E1                   ; 96DD: F0 02
    CLC                         ; 96DF: 18
    RTS                         ; 96E0: 60
L96E1:
    LDY ObjFloorBand,X          ; 96E1: BC B0 04
    LDA $A2C8,Y                 ; 96E4: B9 C8 A2
    SEC                         ; 96E7: 38
    SBC #$04                    ; 96E8: E9 04
    STA ObjY,X                  ; 96EA: 9D 60 04
    JSR L95E4                   ; 96ED: 20 E4 95
    JMP L971A                   ; 96F0: 4C 1A 97
L96F3:
    LDA $0702,Y                 ; 96F3: B9 02 07
    LDY ObjFloorBand,X          ; 96F6: BC B0 04
    CPY #$02                    ; 96F9: C0 02
    BEQ L970D                   ; 96FB: F0 10
    CPY #$05                    ; 96FD: C0 05
    BEQ L9707                   ; 96FF: F0 06
    CMP #$42                    ; 9701: C9 42
    BEQ L9717                   ; 9703: F0 12
    CLC                         ; 9705: 18
    RTS                         ; 9706: 60
L9707:
    CMP #$41                    ; 9707: C9 41
    BEQ L9717                   ; 9709: F0 0C
    CLC                         ; 970B: 18
    RTS                         ; 970C: 60
L970D:
    CMP #$3F                    ; 970D: C9 3F
    BEQ L9717                   ; 970F: F0 06
    CMP #$40                    ; 9711: C9 40
    BEQ L9717                   ; 9713: F0 02
    CLC                         ; 9715: 18
    RTS                         ; 9716: 60
L9717:
    JSR L9683                   ; 9717: 20 83 96
L971A:
    LDA $40                     ; 971A: A5 40
    STA ObjX,X                  ; 971C: 9D 70 04
    LDA #$04                    ; 971F: A9 04
    STA ObjState,X              ; 9721: 95 50
    SEC                         ; 9723: 38
    RTS                         ; 9724: 60
    .byte $9D,$65,$2D,$6D,$35,$35,$1D             ; 9725: 9D 65 2D 6D 35 35 1D
L972C:
    LDA ObjDirFlags,X           ; 972C: BD 10 05
    AND #$02                    ; 972F: 29 02
    BEQ L9758                   ; 9731: F0 25
    CPX #$01                    ; 9733: E0 01
    BNE L974D                   ; 9735: D0 16
    LDA ObjX,X                  ; 9737: BD 70 04
    CMP #$14                    ; 973A: C9 14
    BCC L9750                   ; 973C: 90 12
    CMP #$60                    ; 973E: C9 60
    BCS L974D                   ; 9740: B0 0B
    JSR LA613                   ; 9742: 20 13 A6
    LDX ObjLoopSlot             ; 9745: A6 48
    LDA $1C                     ; 9747: A5 1C
    CMP #$02                    ; 9749: C9 02
    BEQ L975A                   ; 974B: F0 0D
L974D:
    JMP ObjMoveXSub             ; 974D: 4C F0 A5
L9750:
    LDA ObjDirFlags,X           ; 9750: BD 10 05
    AND #$FC                    ; 9753: 29 FC
    STA ObjDirFlags,X           ; 9755: 9D 10 05
L9758:
    CLC                         ; 9758: 18
    RTS                         ; 9759: 60
L975A:
    SEC                         ; 975A: 38
    RTS                         ; 975B: 60
L975C:
    LDA ObjDirFlags,X           ; 975C: BD 10 05
    AND #$01                    ; 975F: 29 01
    BEQ L9758                   ; 9761: F0 F5
    CPX #$01                    ; 9763: E0 01
    BNE L977D                   ; 9765: D0 16
    LDA ObjX,X                  ; 9767: BD 70 04
    CMP #$EB                    ; 976A: C9 EB
    BCS L9750                   ; 976C: B0 E2
    CMP #$A0                    ; 976E: C9 A0
    BCC L977D                   ; 9770: 90 0B
    JSR ScrollWorldObj          ; 9772: 20 0F A6
    LDX ObjLoopSlot             ; 9775: A6 48
    LDA $1C                     ; 9777: A5 1C
    CMP #$01                    ; 9779: C9 01
    BEQ L975A                   ; 977B: F0 DD
L977D:
    JMP ObjMoveXAdd             ; 977D: 4C B0 A5
L9780:
    LDY ObjPhase,X              ; 9780: BC 40 05
    BNE L9788                   ; 9783: D0 03
    JMP L9811                   ; 9785: 4C 11 98
L9788:
    DEY                         ; 9788: 88
    BEQ L97FC                   ; 9789: F0 71
    DEY                         ; 978B: 88
    BEQ L97DF                   ; 978C: F0 51
    DEY                         ; 978E: 88
    BEQ L97BF                   ; 978F: F0 2E
    DEY                         ; 9791: 88
    BEQ L979D                   ; 9792: F0 09
    DEC ObjTimer,X              ; 9794: DE 30 04
    BNE L97F6                   ; 9797: D0 5D
    INC $0335                   ; 9799: EE 35 03
    RTS                         ; 979C: 60
L979D:
    DEC ObjTimer,X              ; 979D: DE 30 04
    BNE L97F6                   ; 97A0: D0 54
    LDX #$0D                    ; 97A2: A2 0D
    LDA ObjX                    ; 97A4: AD 70 04
    SBC #$08                    ; 97A7: E9 08
    STA ObjX,X                  ; 97A9: 9D 70 04
    LDA ObjY                    ; 97AC: AD 60 04
    SBC #$0A                    ; 97AF: E9 0A
    STA ObjY,X                  ; 97B1: 9D 60 04
    LDY #$0C                    ; 97B4: A0 0C
    JSR TransformObj            ; 97B6: 20 90 9C
    LDX ObjLoopSlot             ; 97B9: A6 48
    LDA #$F0                    ; 97BB: A9 F0
    BNE L97F0                   ; 97BD: D0 31
L97BF:
    DEC ObjTimer,X              ; 97BF: DE 30 04
    BNE L97F6                   ; 97C2: D0 32
    LDA ObjY,X                  ; 97C4: BD 60 04
    STA $0461                   ; 97C7: 8D 61 04
    LDA ObjX,X                  ; 97CA: BD 70 04
    SEC                         ; 97CD: 38
    SBC #$16                    ; 97CE: E9 16
    STA $0471                   ; 97D0: 8D 71 04
    LDA #$07                    ; 97D3: A9 07
    STA $71                     ; 97D5: 85 71
    LDA #$78                    ; 97D7: A9 78
    STA ObjSprite,X             ; 97D9: 95 70
    LDA #$20                    ; 97DB: A9 20
    BNE L97F0                   ; 97DD: D0 11
L97DF:
    LDX #$0F                    ; 97DF: A2 0F
L97E1:
    JSR ClearObject             ; 97E1: 20 E7 A2
    DEX                         ; 97E4: CA
    CPX #$01                    ; 97E5: E0 01
    BNE L97E1                   ; 97E7: D0 F8
    LDX ObjLoopSlot             ; 97E9: A6 48
    INC DeathSeqFlag            ; 97EB: EE F1 05
    LDA #$28                    ; 97EE: A9 28
L97F0:
    STA ObjTimer,X              ; 97F0: 9D 30 04
    INC ObjPhase,X              ; 97F3: FE 40 05
L97F6:
    RTS                         ; 97F6: 60
L97F7:
    LDY ObjPhase,X              ; 97F7: BC 40 05
    BEQ L9811                   ; 97FA: F0 15
L97FC:
    LDA ObjTimer,X              ; 97FC: BD 30 04
    BEQ L9805                   ; 97FF: F0 04
    DEC ObjTimer,X              ; 9801: DE 30 04
    RTS                         ; 9804: 60
L9805:
    LDY ObjType,X               ; 9805: B4 60
    DEY                         ; 9807: 88
    DEY                         ; 9808: 88
    DEY                         ; 9809: 88
    LDA $981F,Y                 ; 980A: B9 1F 98
    TAY                         ; 980D: A8
    JMP AnimSpriteStep          ; 980E: 4C FB A7
L9811:
    LDY $05D0                   ; 9811: AC D0 05
    BEQ L981E                   ; 9814: F0 08
    LDA #$1C                    ; 9816: A9 1C
    STA ObjTimer,X              ; 9818: 9D 30 04
    INC ObjPhase,X              ; 981B: FE 40 05
L981E:
    RTS                         ; 981E: 60
    .byte $05,$19                                 ; 981F: 05 19
L9821:
    LDA ObjY,X                  ; 9821: BD 60 04
    CMP #$3A                    ; 9824: C9 3A
    BCC L982D                   ; 9826: 90 05
    CMP #$E6                    ; 9828: C9 E6
    BCS L9841                   ; 982A: B0 15
L982C:
    RTS                         ; 982C: 60
L982D:
    LDA ObjState,X              ; 982D: B5 50
    CMP #$04                    ; 982F: C9 04
    BNE L982C                   ; 9831: D0 F9
    LDA #$CE                    ; 9833: A9 CE
    CLC                         ; 9835: 18
    ADC #$08                    ; 9836: 69 08
    STA ObjY,X                  ; 9838: 9D 60 04
    JSR $CA0F                   ; 983B: 20 0F CA  -> Bank1:LCA0F
    JMP L9852                   ; 983E: 4C 52 98
L9841:
    LDA $51                     ; 9841: A5 51
    CMP #$04                    ; 9843: C9 04
    BNE L982C                   ; 9845: D0 E5
    LDA #$5E                    ; 9847: A9 5E
    SEC                         ; 9849: 38
    SBC #$18                    ; 984A: E9 18
    STA ObjY,X                  ; 984C: 9D 60 04
    JSR $CA0B                   ; 984F: 20 0B CA  -> Bank1:LCA0B
L9852:
    JMP ClearObjectList         ; 9852: 4C 09 A3
L9855:
    LDA #$C0                    ; 9855: A9 C0
    JSR $F08E                   ; 9857: 20 8E F0  -> Bank1:SoundCmd
    LDY #$10                    ; 985A: A0 10
    JSR SoundCmdC0              ; 985C: 20 1C 86
L985F:
    INC $05FF                   ; 985F: EE FF 05
    LDX #$01                    ; 9862: A2 01
    JSR ClearObject             ; 9864: 20 E7 A2
    INC $0A                     ; 9867: E6 0A
    RTS                         ; 9869: 60
L986A:
    JSR PauseCheck              ; 986A: 20 DC 99
    LDA PauseFlag               ; 986D: A5 1A
    BEQ L9872                   ; 986F: F0 01
    RTS                         ; 9871: 60
L9872:
    JSR L8146                   ; 9872: 20 46 81
    LDA HpDelta                 ; 9875: A5 9F
    BEQ L987C                   ; 9877: F0 03
    JSR LBE36                   ; 9879: 20 36 BE
L987C:
    JSR LBD39                   ; 987C: 20 39 BD
    JSR $CED6                   ; 987F: 20 D6 CE  -> Bank1:ObjProxScan
    JSR SpawnStreamAdv          ; 9882: 20 7B BA
    JSR ScanObjWindow           ; 9885: 20 F4 BA
    JSR StageTimerTick          ; 9888: 20 3D 9A
    JMP L9271                   ; 988B: 4C 71 92
L988E:
    INC SceneId                 ; 988E: E6 1F
    LDA #$01                    ; 9890: A9 01
    STA $16                     ; 9892: 85 16
    LDA #$00                    ; 9894: A9 00
    STA $05F9                   ; 9896: 8D F9 05
    LDX #$01                    ; 9899: A2 01
    LDY StageId                 ; 989B: A4 80
    LDA $D6BB,Y                 ; 989D: B9 BB D6  -> Bank1:LayoutPageTab
    LSR A                       ; 98A0: 4A
    TAY                         ; 98A1: A8
    LDA $98F8,Y                 ; 98A2: B9 F8 98
    BCS L98AB                   ; 98A5: B0 04
    LSR A                       ; 98A7: 4A
    LSR A                       ; 98A8: 4A
    LSR A                       ; 98A9: 4A
    LSR A                       ; 98AA: 4A
L98AB:
    AND #$0F                    ; 98AB: 29 0F
    ASL A                       ; 98AD: 0A
    TAY                         ; 98AE: A8
    LDA $9918,Y                 ; 98AF: B9 18 99
    STA ObjX,X                  ; 98B2: 9D 70 04
    LDA $9919,Y                 ; 98B5: B9 19 99
    STA ObjY,X                  ; 98B8: 9D 60 04
    LDY #$00                    ; 98BB: A0 00
    JSR InitObjByKindY          ; 98BD: 20 D1 AA
    STA InvincibleT             ; 98C0: 8D F6 05
    LDA #$04                    ; 98C3: A9 04
    JSR PpuBufPutStr            ; 98C5: 20 AD 86
    LDX BombAmmo                ; 98C8: AE F3 05
    BEQ L98DA                   ; 98CB: F0 0D
    DEX                         ; 98CD: CA
    BEQ L98D5                   ; 98CE: F0 05
    LDA #$00                    ; 98D0: A9 00
    JSR $EC07                   ; 98D2: 20 07 EC  -> Bank1:DrawHudItem
L98D5:
    LDA #$01                    ; 98D5: A9 01
    JSR $EC07                   ; 98D7: 20 07 EC  -> Bank1:DrawHudItem
L98DA:
    LDA #$09                    ; 98DA: A9 09
    LDX SlingAmmo               ; 98DC: AE F2 05
    BEQ L98E4                   ; 98DF: F0 03
    JSR $EC07                   ; 98E1: 20 07 EC  -> Bank1:DrawHudItem
L98E4:
    LDX #$02                    ; 98E4: A2 02
    LDY EquipBits               ; 98E6: A4 49
    STY JoyBits                 ; 98E8: 84 24
L98EA:
    LSR JoyBits                 ; 98EA: 46 24
    BCC L98F2                   ; 98EC: 90 04
    TXA                         ; 98EE: 8A
    JSR $EC07                   ; 98EF: 20 07 EC  -> Bank1:DrawHudItem
L98F2:
    INX                         ; 98F2: E8
    CPX #$09                    ; 98F3: E0 09
    BCC L98EA                   ; 98F5: 90 F3
    RTS                         ; 98F7: 60
    .byte $96,$74,$66,$57,$24,$33,$73,$33         ; 98F8: 96 74 66 57 24 33 73 33
    .byte $54,$18,$22,$27,$46,$66,$76,$83         ; 9900: 54 18 22 27 46 66 76 83
    .byte $74,$13,$03,$50,$20,$30,$17,$77         ; 9908: 74 13 03 50 20 30 17 77
    .byte $74,$56,$72,$51,$5A,$11,$11,$11         ; 9910: 74 56 72 51 5A 11 11 11
    .byte $30,$5E,$80,$5E,$C0,$5E,$30,$96         ; 9918: 30 5E 80 5E C0 5E 30 96
    .byte $80,$96,$C0,$96,$30,$CE,$80,$CE         ; 9920: 80 96 C0 96 30 CE 80 CE
    .byte $C0,$CE,$40,$5E,$D0,$96,$30,$CE         ; 9928: C0 CE 40 5E D0 96 30 CE
    .byte $60,$86,$20,$76,$28,$96,$B0,$76         ; 9930: 60 86 20 76 28 96 B0 76
L9938:
    JSR ClearLoadScreen0        ; 9938: 20 56 89
    JSR $CA43                   ; 993B: 20 43 CA  -> Bank1:StageLoad
    JSR LoadStageTimer          ; 993E: 20 16 9A
    LDA #$0C                    ; 9941: A9 0C
    JSR PpuBufPutStr            ; 9943: 20 AD 86
    LDA #$04                    ; 9946: A9 04
    JSR PpuBufPutStr            ; 9948: 20 AD 86
    LDX #$0C                    ; 994B: A2 0C
    LDA #$FF                    ; 994D: A9 FF
L994F:
    STA ProxRec1,X              ; 994F: 9D 50 01
    STA ProxRec2,X              ; 9952: 9D 60 01
    DEX                         ; 9955: CA
    BPL L994F                   ; 9956: 10 F7
    JSR RenderDelaySet17        ; 9958: 20 95 85
    RTS                         ; 995B: 60
L995C:
    JSR L9962                   ; 995C: 20 62 99
    JMP L986A                   ; 995F: 4C 6A 98
L9962:
    LDA SceneId                 ; 9962: A5 1F
    BMI L9967                   ; 9964: 30 01
    RTS                         ; 9966: 60
L9967:
    LDA JoyPressed              ; 9967: A5 05
    AND #$30                    ; 9969: 29 30
    BNE L999F                   ; 996B: D0 32
    LDA FrameCnt                ; 996D: A5 09
    LSR A                       ; 996F: 4A
    BCS L9984                   ; 9970: B0 12
    LDY $8D                     ; 9972: A4 8D
    BEQ L999E                   ; 9974: F0 28
L9976:
    LDA $99A2,Y                 ; 9976: B9 A2 99
    STA JoyPressed              ; 9979: 85 05
    STA JoyHeld                 ; 997B: 85 07
    LDA #$00                    ; 997D: A9 00
    STA $08                     ; 997F: 85 08
    STA $06                     ; 9981: 85 06
    RTS                         ; 9983: 60
L9984:
    LDY $8D                     ; 9984: A4 8D
    BEQ L998C                   ; 9986: F0 04
    LDA $8C                     ; 9988: A5 8C
    BNE L9999                   ; 998A: D0 0D
L998C:
    LDA $99A5,Y                 ; 998C: B9 A5 99
    STA $8C                     ; 998F: 85 8C
    CMP #$FF                    ; 9991: C9 FF
    BEQ L999F                   ; 9993: F0 0A
    INY                         ; 9995: C8
    INY                         ; 9996: C8
    STY $8D                     ; 9997: 84 8D
L9999:
    JSR L9976                   ; 9999: 20 76 99
    DEC $8C                     ; 999C: C6 8C
L999E:
    RTS                         ; 999E: 60
L999F:
    INC $0A                     ; 999F: E6 0A
    JMP InitSound               ; 99A1: 4C 14 86
    .byte $01,$48,$08,$10,$02,$20,$40,$10         ; 99A4: 01 48 08 10 02 20 40 10
    .byte $02,$28,$40,$07,$80,$08,$01,$22         ; 99AC: 02 28 40 07 80 08 01 22
    .byte $80,$04,$01,$40,$08,$30,$81,$B0         ; 99B4: 80 04 01 40 08 30 81 B0
    .byte $00,$28,$02,$20,$44,$04,$01,$20         ; 99BC: 00 28 02 20 44 04 01 20
    .byte $00,$48,$02,$2A,$08,$28,$02,$0C         ; 99C4: 00 48 02 2A 08 28 02 0C
    .byte $40,$20,$82,$40,$02,$20,$08,$40         ; 99CC: 40 20 82 40 02 20 08 40
    .byte $81,$A0,$00,$40,$FF,$FF,$FF,$FF         ; 99D4: 81 A0 00 40 FF FF FF FF
PauseCheck:
    ; $03|RenderDelay|$05F9|$05D1 非零则返；SceneId 位7 下 JoyPressed&$10 翻转 $1A：置位送声 $31、清 $0421；复位路径清 $1A/$B2 并 $4000=$30
    LDA $03                     ; 99DC: A5 03
    ORA RenderDelay             ; 99DE: 05 0C
    ORA $05F9                   ; 99E0: 0D F9 05
    ORA $05D1                   ; 99E3: 0D D1 05
    BNE L9A15                   ; 99E6: D0 2D
    LDA SceneId                 ; 99E8: A5 1F
    BPL L9A15                   ; 99EA: 10 29
    LDA JoyPressed              ; 99EC: A5 05
    LDY PauseFlag               ; 99EE: A4 1A
    BNE L9A04                   ; 99F0: D0 12
    AND #$10                    ; 99F2: 29 10
    BEQ L9A15                   ; 99F4: F0 1F
    LDA #$01                    ; 99F6: A9 01
    STA PauseFlag               ; 99F8: 85 1A
    LDA #$00                    ; 99FA: A9 00
    STA $0421                   ; 99FC: 8D 21 04
    LDA #$31                    ; 99FF: A9 31
    JMP $F08E                   ; 9A01: 4C 8E F0  -> Bank1:SoundCmd
L9A04:
    LDA JoyPressed              ; 9A04: A5 05
    AND #$10                    ; 9A06: 29 10
    BEQ L9A15                   ; 9A08: F0 0B
    LDA #$00                    ; 9A0A: A9 00
    STA PauseFlag               ; 9A0C: 85 1A
    STA $B2                     ; 9A0E: 85 B2
    LDA #$30                    ; 9A10: A9 30
    STA $4000                   ; 9A12: 8D 00 40
L9A15:
    RTS                         ; 9A15: 60
LoadStageTimer:
    ; Y=$A3*2，$9A29,Y→$91、$9A2A,Y→$90（初始倒计时 BCD 秒字表，$FFFF=不计时（推测，区域 0 不走 tick 路径）），$8F=0；bank1 $CAB2 JSR（StageLoad 路径）
    LDA StageArea               ; 9A16: A5 A3
    ASL A                       ; 9A18: 0A
    TAY                         ; 9A19: A8
    LDA $9A29,Y                 ; 9A1A: B9 29 9A
    STA $91                     ; 9A1D: 85 91
    LDA $9A2A,Y                 ; 9A1F: B9 2A 9A
    STA StageTimer              ; 9A22: 85 90
    LDA #$00                    ; 9A24: A9 00
    STA TimerFrame              ; 9A26: 85 8F
L9A28:
    RTS                         ; 9A28: 60
    .byte $FF,$FF,$01,$80,$03,$60,$01,$10         ; 9A29: FF FF 01 80 03 60 01 10
    .byte $04,$20,$05,$00,$00,$90,$04,$50         ; 9A31: 04 20 05 00 00 90 04 50
    .byte $00,$90,$01,$20                         ; 9A39: 00 90 01 20
StageTimerTick:
    ; $0337 非零直返；$8F 满 $3C（60 帧）调 StageTimerDec；归零 $51=1 并写串 8（TIME UP），$90==$50 时送告警音 $1F
    LDA BossDoorSeq             ; 9A3D: AD 37 03
    BNE L9A28                   ; 9A40: D0 E6
    INC TimerFrame              ; 9A42: E6 8F
    LDA TimerFrame              ; 9A44: A5 8F
    CMP #$3C                    ; 9A46: C9 3C
    BNE L9A28                   ; 9A48: D0 DE
    LDA #$00                    ; 9A4A: A9 00
    STA TimerFrame              ; 9A4C: 85 8F
    JSR StageTimerDec           ; 9A4E: 20 99 9A
    BCC L9A5C                   ; 9A51: 90 09
    LDA #$01                    ; 9A53: A9 01
    STA $51                     ; 9A55: 85 51
    LDA #$08                    ; 9A57: A9 08
    JMP PpuBufPutStr            ; 9A59: 4C AD 86
L9A5C:
    LDA $91                     ; 9A5C: A5 91
    BNE L9A28                   ; 9A5E: D0 C8
    LDA StageTimer              ; 9A60: A5 90
    CMP #$50                    ; 9A62: C9 50
    BNE L9A28                   ; 9A64: D0 C2
    LDA #$1F                    ; 9A66: A9 1F
    JMP $F08E                   ; 9A68: 4C 8E F0  -> Bank1:SoundCmd
L9A6B:
    LDA $07C9                   ; 9A6B: AD C9 07
    BNE L9A87                   ; 9A6E: D0 17
    JSR LBD46                   ; 9A70: 20 46 BD
    LDA #$06                    ; 9A73: A9 06
    JSR AddScore                ; 9A75: 20 D0 84
    JSR StageTimerDec           ; 9A78: 20 99 9A
    BCS L9A82                   ; 9A7B: B0 05
    JSR StageTimerDec           ; 9A7D: 20 99 9A
    BCC L9A28                   ; 9A80: 90 A6
L9A82:
    LDA #$01                    ; 9A82: A9 01
    STA $07C9                   ; 9A84: 8D C9 07
L9A87:
    LDA $C3                     ; 9A87: A5 C3
    CMP #$22                    ; 9A89: C9 22
    BEQ L9A28                   ; 9A8B: F0 9B
    LDX #$81                    ; 9A8D: A2 81
    STX SceneId                 ; 9A8F: 86 1F
    LDA #$00                    ; 9A91: A9 00
    STA $07C9                   ; 9A93: 8D C9 07
    JMP $F08E                   ; 9A96: 4C 8E F0  -> Bank1:SoundCmd
StageTimerDec:
    ; X=0..1 两位 BCD 递减：低半字节 <$0 借 $F9，高半字节 <$0 借 $9F；全 0 时清零并 SEC（超时）
    LDX #$00                    ; 9A99: A2 00
L9A9B:
    DEC StageTimer,X            ; 9A9B: D6 90
    LDA StageTimer,X            ; 9A9D: B5 90
    AND #$0F                    ; 9A9F: 29 0F
    CMP #$0F                    ; 9AA1: C9 0F
    BNE L9ACC                   ; 9AA3: D0 27
    LDA StageTimer,X            ; 9AA5: B5 90
    AND #$F9                    ; 9AA7: 29 F9
    STA StageTimer,X            ; 9AA9: 95 90
    LDA StageTimer,X            ; 9AAB: B5 90
    AND #$F0                    ; 9AAD: 29 F0
    CMP #$F0                    ; 9AAF: C9 F0
    BNE L9AB9                   ; 9AB1: D0 06
    LDA StageTimer,X            ; 9AB3: B5 90
    AND #$9F                    ; 9AB5: 29 9F
    STA StageTimer,X            ; 9AB7: 95 90
L9AB9:
    LDA StageTimer,X            ; 9AB9: B5 90
    CMP #$99                    ; 9ABB: C9 99
    BNE L9ACC                   ; 9ABD: D0 0D
    INX                         ; 9ABF: E8
    CPX #$02                    ; 9AC0: E0 02
    BNE L9A9B                   ; 9AC2: D0 D7
    LDX #$00                    ; 9AC4: A2 00
    STX StageTimer              ; 9AC6: 86 90
    STX $91                     ; 9AC8: 86 91
    SEC                         ; 9ACA: 38
    RTS                         ; 9ACB: 60
L9ACC:
    CLC                         ; 9ACC: 18
    RTS                         ; 9ACD: 60
DeathSequence:
    ; $05DD==0 直返 L9AFE；==3 且 $B2==0 送声 $16 并 DEC $05DD；随后按模式计时转 L9DC8（重生闪烁）或 LB85B+BGM 恢复
    LDA DeathSeqCnt             ; 9ACE: AD DD 05
    BEQ L9AFE                   ; 9AD1: F0 2B
    CMP #$03                    ; 9AD3: C9 03
    BNE L9AE3                   ; 9AD5: D0 0C
    LDA $B2                     ; 9AD7: A5 B2
    BNE L9AE3                   ; 9AD9: D0 08
    LDY #$16                    ; 9ADB: A0 16
    JSR SoundCmd80              ; 9ADD: 20 22 86
    DEC DeathSeqCnt             ; 9AE0: CE DD 05
L9AE3:
    JSR L8365                   ; 9AE3: 20 65 83
    BEQ L9AEE                   ; 9AE6: F0 06
    JSR PlayerVisibleInit       ; 9AE8: 20 C8 9D
    JMP L9B01                   ; 9AEB: 4C 01 9B
L9AEE:
    JSR LB85B                   ; 9AEE: 20 5B B8
    LDA $B2                     ; 9AF1: A5 B2
    CMP #$2E                    ; 9AF3: C9 2E
    BEQ L9AFE                   ; 9AF5: F0 07
    CMP #$31                    ; 9AF7: C9 31
    BEQ L9AFE                   ; 9AF9: F0 03
    JSR $CB90                   ; 9AFB: 20 90 CB  -> Bank1:BgmByStage
L9AFE:
    JSR PlayerBlinkTick         ; 9AFE: 20 D4 9D
L9B01:
    JSR LA8CE                   ; 9B01: 20 CE A8
    LDX #$0D                    ; 9B04: A2 0D
ObjMainLoop:
    ; 物体主循环头：X=$0D 起递减（STX $48 保存）；X=0 或 $05F1==0 时按类型门控（<$11 需 $05F9==0 或 $50,X==1，$12/$17/$19/$1A/$1C 特判动画/闪烁，≥$21 倒计时自毁），槽 1/7/8 恒分发
    STX ObjLoopSlot             ; 9B06: 86 48
    CPX #$00                    ; 9B08: E0 00
    BEQ L9B19                   ; 9B0A: F0 0D
    LDA DeathSeqFlag            ; 9B0C: AD F1 05
    BEQ L9B19                   ; 9B0F: F0 08
    LDY ObjType,X               ; 9B11: B4 60
    CPY #$27                    ; 9B13: C0 27
    BCS L9B78                   ; 9B15: B0 61
    BCC ObjLoopNext             ; 9B17: 90 3C
L9B19:
    CPX #$01                    ; 9B19: E0 01
    BEQ L9B52                   ; 9B1B: F0 35
    LDY ObjType,X               ; 9B1D: B4 60
    BEQ ObjLoopNext             ; 9B1F: F0 34
    CPX #$07                    ; 9B21: E0 07
    BEQ L9B52                   ; 9B23: F0 2D
    CPX #$08                    ; 9B25: E0 08
    BEQ L9B52                   ; 9B27: F0 29
    CPY #$11                    ; 9B29: C0 11
    BCC L9B47                   ; 9B2B: 90 1A
    CPY #$21                    ; 9B2D: C0 21
    BCS L9B7C                   ; 9B2F: B0 4B
    CPY #$1C                    ; 9B31: C0 1C
    BEQ L9B63                   ; 9B33: F0 2E
    CPY #$17                    ; 9B35: C0 17
    BEQ L9B5B                   ; 9B37: F0 22
    CPY #$12                    ; 9B39: C0 12
    BEQ L9B52                   ; 9B3B: F0 15
    CPY #$19                    ; 9B3D: C0 19
    BEQ L9B9C                   ; 9B3F: F0 5B
    CPY #$1A                    ; 9B41: C0 1A
    BEQ L9B9C                   ; 9B43: F0 57
    BNE ObjLoopNext             ; 9B45: D0 0E
L9B47:
    LDA ObjState,X              ; 9B47: B5 50
    CMP #$01                    ; 9B49: C9 01
    BEQ L9B52                   ; 9B4B: F0 05
    LDA $05F9                   ; 9B4D: AD F9 05
    BNE ObjLoopNext             ; 9B50: D0 03
L9B52:
    JSR ObjStateDispatch        ; 9B52: 20 B6 9B
ObjLoopNext:
    ; X=$48 后 DEX，BPL 回 $9B06 循环头，否则 RTS；19 项大状态处理器多以 JMP 此为循环尾
    LDX ObjLoopSlot             ; 9B55: A6 48
    DEX                         ; 9B57: CA
    BPL ObjMainLoop             ; 9B58: 10 AC
    RTS                         ; 9B5A: 60
L9B5B:
    LDY #$1C                    ; 9B5B: A0 1C
    JSR AnimSpriteStep          ; 9B5D: 20 FB A7
    JMP ObjLoopNext             ; 9B60: 4C 55 9B
L9B63:
    LDA #$02                    ; 9B63: A9 02
    STA $30                     ; 9B65: 85 30
    LDA #$07                    ; 9B67: A9 07
    AND FrameCnt                ; 9B69: 25 09
    BNE ObjLoopNext             ; 9B6B: D0 E8
    LDA ObjAttr,X               ; 9B6D: BD 20 04
    EOR $30                     ; 9B70: 45 30
    STA ObjAttr,X               ; 9B72: 9D 20 04
    JMP ObjLoopNext             ; 9B75: 4C 55 9B
L9B78:
    LDA #$03                    ; 9B78: A9 03
    BNE L9B7E                   ; 9B7A: D0 02
L9B7C:
    LDA #$01                    ; 9B7C: A9 01
L9B7E:
    AND FrameCnt                ; 9B7E: 25 09
    BNE L9B91                   ; 9B80: D0 0F
    DEC ObjY,X                  ; 9B82: DE 60 04
    DEC ObjTimer,X              ; 9B85: DE 30 04
    BNE ObjLoopNext             ; 9B88: D0 CB
    CPY #$27                    ; 9B8A: C0 27
    BEQ L9B94                   ; 9B8C: F0 06
L9B8E:
    JSR ClearObject             ; 9B8E: 20 E7 A2
L9B91:
    JMP ObjLoopNext             ; 9B91: 4C 55 9B
L9B94:
    LDY #$0D                    ; 9B94: A0 0D
    JSR TransformObj            ; 9B96: 20 90 9C
    JMP ObjLoopNext             ; 9B99: 4C 55 9B
L9B9C:
    JSR ObjStepY                ; 9B9C: 20 E4 A4
    DEC ObjTimer,X              ; 9B9F: DE 30 04
    BEQ L9B8E                   ; 9BA2: F0 EA
    LDA ObjProbeA,X             ; 9BA4: BD 20 05
    BNE ObjLoopNext             ; 9BA7: D0 AC
    LDA ObjY,X                  ; 9BA9: BD 60 04
    CMP #$DC                    ; 9BAC: C9 DC
    BCS ObjLoopNext             ; 9BAE: B0 A5
    INC ObjY,X                  ; 9BB0: FE 60 04
    JMP ObjLoopNext             ; 9BB3: 4C 55 9B
ObjStateDispatch:
    ; INC $0590,X；$05B0,X 非零递减；LDA $60,X 经 DispatchJump 走 $9BC6 表 19 项（类型 0=玩家 L92BD）
    INC ObjFrameCnt,X           ; 9BB6: FE 90 05
    LDA ObjShieldT,X            ; 9BB9: BD B0 05
    BEQ L9BC1                   ; 9BBC: F0 03
    DEC ObjShieldT,X            ; 9BBE: DE B0 05
L9BC1:
    LDA ObjType,X               ; 9BC1: B5 60
    JSR DispatchJump            ; 9BC3: 20 9A 85
    .byte $BD,$92,$85,$9E,$EB,$9E,$F7,$97         ; 9BC6: BD 92 85 9E EB 9E F7 97
    .byte $80,$97,$C5,$9E,$FC,$9E,$EA,$9F         ; 9BCE: 80 97 C5 9E FC 9E EA 9F
    .byte $EE,$9F,$F2,$9F,$41,$9F,$B5,$A0         ; 9BD6: EE 9F F2 9F 41 9F B5 A0
    .byte $89,$A0,$64,$B1,$19,$B1,$FF,$B0         ; 9BDE: 89 A0 64 B1 19 B1 FF B0
    .byte $F4,$B0,$D1,$B1,$EB,$9D                 ; 9BE6: F4 B0 D1 B1 EB 9D
L9BEC:
    LDY ObjPhase,X              ; 9BEC: BC 40 05
    BEQ L9C43                   ; 9BEF: F0 52
    DEY                         ; 9BF1: 88
    BEQ L9C1A                   ; 9BF2: F0 26
    LDA ObjType,X               ; 9BF4: B5 60
    CMP #$05                    ; 9BF6: C9 05
    BEQ L9C00                   ; 9BF8: F0 06
    DEC ObjY,X                  ; 9BFA: DE 60 04
    JMP L9C05                   ; 9BFD: 4C 05 9C
L9C00:
    LDA FrameCnt                ; 9C00: A5 09
    LSR A                       ; 9C02: 4A
    BCC L9C19                   ; 9C03: 90 14
L9C05:
    DEC ObjY,X                  ; 9C05: DE 60 04
    LDA $04BE                   ; 9C08: AD BE 04
    CMP ObjY,X                  ; 9C0B: DD 60 04
    BCC L9C19                   ; 9C0E: 90 09
    LDA #$00                    ; 9C10: A9 00
    JSR LA301                   ; 9C12: 20 01 A3
    STA $7E                     ; 9C15: 85 7E
    STA $6E                     ; 9C17: 85 6E
L9C19:
    RTS                         ; 9C19: 60
L9C1A:
    DEC $043E                   ; 9C1A: CE 3E 04
    BEQ L9C26                   ; 9C1D: F0 07
    LDX #$0E                    ; 9C1F: A2 0E
    LDY #$1A                    ; 9C21: A0 1A
    JMP AnimSpriteStep          ; 9C23: 4C FB A7
L9C26:
    JSR FacePlayer              ; 9C26: 20 0F A2
    LDY #$33                    ; 9C29: A0 33
    LDA ObjType,X               ; 9C2B: B5 60
    CMP #$05                    ; 9C2D: C9 05
    BEQ L9C33                   ; 9C2F: F0 02
    LDY #$3F                    ; 9C31: A0 3F
L9C33:
    LDA ObjDirFlags,X           ; 9C33: BD 10 05
    AND #$01                    ; 9C36: 29 01
    BNE L9C3C                   ; 9C38: D0 02
    INY                         ; 9C3A: C8
    INY                         ; 9C3B: C8
L9C3C:
    TYA                         ; 9C3C: 98
    STA ObjSprite,X             ; 9C3D: 95 70
L9C3F:
    INC ObjPhase,X              ; 9C3F: FE 40 05
    RTS                         ; 9C42: 60
L9C43:
    LDA #$09                    ; 9C43: A9 09
    JSR $F08E                   ; 9C45: 20 8E F0  -> Bank1:SoundCmd
    LDA #$3C                    ; 9C48: A9 3C
    STA $043E                   ; 9C4A: 8D 3E 04
    BNE L9C3F                   ; 9C4D: D0 F0
ObjExpireTick:
    ; $0540,X 三阶段：0→精灵 $6C+计时 $10；1→计时归零转 L9CC7（$70=0 藏）；2→闪烁后按 $9CE1/$9CE4 表变身 TransformObj
    LDY ObjPhase,X              ; 9C4F: BC 40 05
    BEQ L9C5D                   ; 9C52: F0 09
    DEY                         ; 9C54: 88
    BNE L9C72                   ; 9C55: D0 1B
L9C57:
    DEC ObjTimer,X              ; 9C57: DE 30 04
    BEQ L9CC7                   ; 9C5A: F0 6B
    RTS                         ; 9C5C: 60
L9C5D:
    LDA #$6C                    ; 9C5D: A9 6C
    STA ObjSprite,X             ; 9C5F: 95 70
    LDA #$10                    ; 9C61: A9 10
    STA ObjTimer,X              ; 9C63: 9D 30 04
    INC ObjPhase,X              ; 9C66: FE 40 05
    RTS                         ; 9C69: 60
L9C6A:
    LDY ObjPhase,X              ; 9C6A: BC 40 05
    BEQ L9CD2                   ; 9C6D: F0 63
    DEY                         ; 9C6F: 88
    BEQ L9CBA                   ; 9C70: F0 48
L9C72:
    DEC ObjTimer,X              ; 9C72: DE 30 04
    BNE L9CE0                   ; 9C75: D0 69
    LDA ObjType,X               ; 9C77: B5 60
    CMP #$07                    ; 9C79: C9 07
    BNE L9C86                   ; 9C7B: D0 09
    LDY ObjVariant,X            ; 9C7D: BC 50 05
    LDA $9CE1,Y                 ; 9C80: B9 E1 9C
    JMP L9C8F                   ; 9C83: 4C 8F 9C
L9C86:
    LDY ObjType,X               ; 9C86: B4 60
    LDA $9CE4,Y                 ; 9C88: B9 E4 9C
    CMP #$FF                    ; 9C8B: C9 FF
    BEQ L9CE0                   ; 9C8D: F0 51
L9C8F:
    TAY                         ; 9C8F: A8
TransformObj:
    ; Y=变身 kind（0-13）：$9CF6,Y→$60,X、$9D12,Y→$70,X、$9D20,Y→$0430,X，经 LAB47 补默认参数；$9D04,Y≠$FF 时 JMP AddScore
    LDA $9CF6,Y                 ; 9C90: B9 F6 9C
    STA ObjType,X               ; 9C93: 95 60
    LDA $9D12,Y                 ; 9C95: B9 12 9D
    STA ObjSprite,X             ; 9C98: 95 70
    LDA $9D20,Y                 ; 9C9A: B9 20 9D
    STA ObjTimer,X              ; 9C9D: 9D 30 04
    STY $3C                     ; 9CA0: 84 3C
    JSR LAB47                   ; 9CA2: 20 47 AB
    LDY $3C                     ; 9CA5: A4 3C
    CPY #$08                    ; 9CA7: C0 08
    BCC L9CB0                   ; 9CA9: 90 05
    LDA #$00                    ; 9CAB: A9 00
    STA ObjXPage,X              ; 9CAD: 9D 10 04
L9CB0:
    LDA $9D04,Y                 ; 9CB0: B9 04 9D
    CMP #$FF                    ; 9CB3: C9 FF
    BEQ L9CE0                   ; 9CB5: F0 29
    JMP AddScore                ; 9CB7: 4C D0 84
L9CBA:
    LDA #$01                    ; 9CBA: A9 01
    STA $30                     ; 9CBC: 85 30
    LDY #$18                    ; 9CBE: A0 18
    JSR AnimSpriteStep          ; 9CC0: 20 FB A7
    LDA $30                     ; 9CC3: A5 30
    BNE L9CE0                   ; 9CC5: D0 19
L9CC7:
    LDA #$10                    ; 9CC7: A9 10
    STA ObjTimer,X              ; 9CC9: 9D 30 04
    LDA #$00                    ; 9CCC: A9 00
    STA ObjSprite,X             ; 9CCE: 95 70
    BEQ L9CDD                   ; 9CD0: F0 0B
L9CD2:
    LDA #$00                    ; 9CD2: A9 00
    STA ObjAnimAcc,X            ; 9CD4: 9D 50 04
    STA ObjAnimFrac,X           ; 9CD7: 9D 40 04
    STA ObjAttr,X               ; 9CDA: 9D 20 04
L9CDD:
    INC ObjPhase,X              ; 9CDD: FE 40 05
L9CE0:
    RTS                         ; 9CE0: 60
    .byte $06,$05,$07,$00,$00,$00,$0A,$0C         ; 9CE1: 06 05 07 00 00 00 0A 0C
    .byte $01,$00,$00,$06,$06,$01,$02,$06         ; 9CE9: 01 00 00 06 06 01 02 06
    .byte $02,$01,$00,$00,$00,$21,$22,$23         ; 9CF1: 02 01 00 00 00 21 22 23
    .byte $24,$25,$08,$19,$1A,$17,$16,$24         ; 9CF9: 24 25 08 19 1A 17 16 24
    .byte $26,$27,$28,$00,$01,$02,$03,$04         ; 9D01: 26 27 28 00 01 02 03 04
    .byte $00,$00,$00,$02,$01,$03,$05,$FF         ; 9D09: 00 00 00 02 01 03 05 FF
    .byte $04,$74,$75,$18,$76,$19,$4A,$60         ; 9D11: 04 74 75 18 76 19 4A 60
    .byte $61,$73,$5C,$6F,$43,$82,$6F,$18         ; 9D19: 61 73 5C 6F 43 82 6F 18
    .byte $18,$18,$18,$18,$20,$FF,$FF,$FF         ; 9D21: 18 18 18 18 20 FF FF FF
    .byte $FF,$38,$18,$10,$20                     ; 9D29: FF 38 18 10 20
L9D2E:
    LDY ObjPhase,X              ; 9D2E: BC 40 05
    BEQ L9D5E                   ; 9D31: F0 2B
    DEY                         ; 9D33: 88
    BEQ L9D47                   ; 9D34: F0 11
    CPX #$01                    ; 9D36: E0 01
    BNE L9D3D                   ; 9D38: D0 03
    JMP L985F                   ; 9D3A: 4C 5F 98
L9D3D:
    LDA #$30                    ; 9D3D: A9 30
    STA $0115                   ; 9D3F: 8D 15 01
    LDA #$00                    ; 9D42: A9 00
    JMP LA301                   ; 9D44: 4C 01 A3
L9D47:
    DEC ObjTimer,X              ; 9D47: DE 30 04
    BEQ L9DC4                   ; 9D4A: F0 78
    LDA ObjTimer,X              ; 9D4C: BD 30 04
    CMP #$30                    ; 9D4F: C9 30
    BCC L9DC7                   ; 9D51: 90 74
    LDY #$0A                    ; 9D53: A0 0A
    CPX #$01                    ; 9D55: E0 01
    BNE L9D5B                   ; 9D57: D0 02
    LDY #$04                    ; 9D59: A0 04
L9D5B:
    JMP AnimSpriteStep          ; 9D5B: 4C FB A7
L9D5E:
    JSR LA694                   ; 9D5E: 20 94 A6
    LDA ObjType,X               ; 9D61: B5 60
    ORA ObjSprite,X             ; 9D63: 15 70
    BEQ L9DC7                   ; 9D65: F0 60
    LDA #$01                    ; 9D67: A9 01
    STA ObjState,X              ; 9D69: 95 50
    LDA ObjAirFlag,X            ; 9D6B: BD 40 01
    BEQ L9D98                   ; 9D6E: F0 28
    LDA #$30                    ; 9D70: A9 30
    CPX #$01                    ; 9D72: E0 01
    BNE L9D95                   ; 9D74: D0 1F
    STA $05F9                   ; 9D76: 8D F9 05
    LDY DoorPendRec             ; 9D79: AC 3A 03
    CPY #$FF                    ; 9D7C: C0 FF
    BEQ L9D93                   ; 9D7E: F0 13
    LDA $0702,Y                 ; 9D80: B9 02 07
    SEC                         ; 9D83: 38
    SBC #$18                    ; 9D84: E9 18
    AND #$07                    ; 9D86: 29 07
    TAY                         ; 9D88: A8
    LDA #$00                    ; 9D89: A9 00
    STA DoorRing,Y              ; 9D8B: 99 C0 07
    LDA #$FF                    ; 9D8E: A9 FF
    STA DoorPendRec             ; 9D90: 8D 3A 03
L9D93:
    LDA #$14                    ; 9D93: A9 14
L9D95:
    STA ObjSprite,X             ; 9D95: 95 70
    RTS                         ; 9D97: 60
L9D98:
    CPX #$01                    ; 9D98: E0 01
    BNE L9DA5                   ; 9D9A: D0 09
    LDY #$10                    ; 9D9C: A0 10
    JSR SoundCmdC0              ; 9D9E: 20 1C 86
    LDA #$15                    ; 9DA1: A9 15
    BNE L9DAC                   ; 9DA3: D0 07
L9DA5:
    LDA #$00                    ; 9DA5: A9 00
    JSR AddScore                ; 9DA7: 20 D0 84
    LDA #$31                    ; 9DAA: A9 31
L9DAC:
    STA ObjSprite,X             ; 9DAC: 95 70
    LDA #$F0                    ; 9DAE: A9 F0
    CPX #$01                    ; 9DB0: E0 01
    BNE L9DB6                   ; 9DB2: D0 02
    LDA #$A0                    ; 9DB4: A9 A0
L9DB6:
    STA ObjTimer,X              ; 9DB6: 9D 30 04
    LDA #$00                    ; 9DB9: A9 00
    STA ObjAnimAcc,X            ; 9DBB: 9D 50 04
    STA ObjAnimFrac,X           ; 9DBE: 9D 40 04
    STA ObjAttr,X               ; 9DC1: 9D 20 04
L9DC4:
    INC ObjPhase,X              ; 9DC4: FE 40 05
L9DC7:
    RTS                         ; 9DC7: 60
PlayerVisibleInit:
    LDA #$00                    ; 9DC8: A9 00
    STA InvincibleT             ; 9DCA: 8D F6 05
    LDA FrameCnt                ; 9DCD: A5 09
    AND #$03                    ; 9DCF: 29 03
    JMP L9DE7                   ; 9DD1: 4C E7 9D
PlayerBlinkTick:
    LDA InvincibleT             ; 9DD4: AD F6 05
    BEQ L9DE7                   ; 9DD7: F0 0E
    DEC InvincibleT             ; 9DD9: CE F6 05
    LDA #$03                    ; 9DDC: A9 03
    AND FrameCnt                ; 9DDE: 25 09
    BNE L9DEA                   ; 9DE0: D0 08
    LDA $0421                   ; 9DE2: AD 21 04
    EOR #$01                    ; 9DE5: 49 01
L9DE7:
    STA $0421                   ; 9DE7: 8D 21 04
L9DEA:
    RTS                         ; 9DEA: 60
DebrisUpdate:
    ; 碎片帧更新：$0550,X<4 时 $0470,X += $04C0,X（直接像素速）；$0430,X 归零转 TransformObj Y=3；$9BC6 表末项
    LDY ObjVariant,X            ; 9DEB: BC 50 05
    CPY #$04                    ; 9DEE: C0 04
    BCS L9DFB                   ; 9DF0: B0 09
    LDA ObjSpeedX,X             ; 9DF2: BD C0 04
    ADC ObjX,X                  ; 9DF5: 7D 70 04
    STA ObjX,X                  ; 9DF8: 9D 70 04
L9DFB:
    LDX ObjLoopSlot             ; 9DFB: A6 48
    DEC ObjTimer,X              ; 9DFD: DE 30 04
    BNE L9E35                   ; 9E00: D0 33
    LDY #$03                    ; 9E02: A0 03
    JMP TransformObj            ; 9E04: 4C 90 9C
SpawnDebris:
    ; $0550,X<4 时按 $9E36-$9E41 表布四角位与 ±1 X 速；类型 $12、精灵 $9E42,Y、计时 $9E4A,Y；LB73D（爆桶）调用
    LDY ObjVariant,X            ; 9E07: BC 50 05
    CPY #$04                    ; 9E0A: C0 04
    BCS L9E20                   ; 9E0C: B0 12
    LDA $9E36,Y                 ; 9E0E: B9 36 9E
    STA ObjX,X                  ; 9E11: 9D 70 04
    LDA $9E3A,Y                 ; 9E14: B9 3A 9E
    STA ObjY,X                  ; 9E17: 9D 60 04
    LDA $9E3E,Y                 ; 9E1A: B9 3E 9E
    STA ObjSpeedX,X             ; 9E1D: 9D C0 04
L9E20:
    LDA #$12                    ; 9E20: A9 12
    STA ObjType,X               ; 9E22: 95 60
    LDA $9E42,Y                 ; 9E24: B9 42 9E
    STA ObjSprite,X             ; 9E27: 95 70
    LDA $9E4A,Y                 ; 9E29: B9 4A 9E
    STA ObjTimer,X              ; 9E2C: 9D 30 04
    JSR LAB14                   ; 9E2F: 20 14 AB
    STA ObjXPage,X              ; 9E32: 9D 10 04
L9E35:
    RTS                         ; 9E35: 60
    .byte $08,$F8,$F8,$08,$50,$80,$C8,$60         ; 9E36: 08 F8 F8 08 50 80 C8 60
    .byte $01,$FF,$FF,$01,$71,$21,$5D,$6D         ; 9E3E: 01 FF FF 01 71 21 5D 6D
    .byte $1A,$68,$17,$17,$A0,$A0,$C0,$A0         ; 9E46: 1A 68 17 17 A0 A0 C0 A0
    .byte $60,$60,$60,$60,$A8,$18,$79,$58         ; 9E4E: 60 60 60 60 A8 18 79 58
    .byte $9E,$60,$02,$01,$00,$02,$01,$00         ; 9E56: 9E 60 02 01 00 02 01 00
    .byte $02,$01,$00                             ; 9E5E: 02 01 00
AnimByType1:
    ; Y=$60,X 查 $9E6A 动画索引表后 JMP AnimSpritePingpong；L9EF1（命中反应后）调用
    LDY ObjType,X               ; 9E61: B4 60
    LDA $9E6A,Y                 ; 9E63: B9 6A 9E
    TAY                         ; 9E66: A8
    JMP AnimSpritePingpong      ; 9E67: 4C A3 A7
    .byte $01,$07,$00,$00,$00,$0C,$0F,$12         ; 9E6A: 01 07 00 00 00 0C 0F 12
    .byte $14                                     ; 9E72: 14
AnimByType2:
    ; Y=$60,X 查 $9E7C 动画索引表后 JMP AnimSpritePingpong；L9EF9 调用
    LDY ObjType,X               ; 9E73: B4 60
    LDA $9E7C,Y                 ; 9E75: B9 7C 9E
    TAY                         ; 9E78: A8
    JMP AnimSpritePingpong      ; 9E79: 4C A3 A7
    .byte $00,$06,$00,$00,$00,$0B,$0E,$11         ; 9E7C: 00 06 00 00 00 0B 0E 11
    .byte $13                                     ; 9E84: 13
L9E85:
    JSR FloorBandScan           ; 9E85: 20 A6 A2
    JSR LA109                   ; 9E88: 20 09 A1
    LDY ObjVariant,X            ; 9E8B: BC 50 05
    LDA $9EA5,Y                 ; 9E8E: B9 A5 9E
    STA ObjSpeedX,X             ; 9E91: 9D C0 04
    LDA ObjState,X              ; 9E94: B5 50
    JSR DispatchJump            ; 9E96: 20 9A 85
    .byte $A9,$9E,$2E,$9D,$98,$A6,$EB,$9E         ; 9E99: A9 9E 2E 9D 98 A6 EB 9E
    .byte $83,$95,$46,$95,$0E,$10,$0E,$0C         ; 9EA1: 83 95 46 95 0E 10 0E 0C
L9EA9:
    JSR ObjThrowProj            ; 9EA9: 20 11 B2
    LDX ObjLoopSlot             ; 9EAC: A6 48
    LDA ObjPhase,X              ; 9EAE: BD 40 05
    BNE L9EEB                   ; 9EB1: D0 38
    LDA ObjFloorBand,X          ; 9EB3: BD B0 04
    CMP #$03                    ; 9EB6: C9 03
    BCS L9EC2                   ; 9EB8: B0 08
    LDA ObjDirFlags,X           ; 9EBA: BD 10 05
    AND #$F7                    ; 9EBD: 29 F7
    STA ObjDirFlags,X           ; 9EBF: 9D 10 05
L9EC2:
    JMP L9474                   ; 9EC2: 4C 74 94
L9EC5:
    JSR FloorBandScan           ; 9EC5: 20 A6 A2
    JSR LA1AC                   ; 9EC8: 20 AC A1
    LDA ObjState,X              ; 9ECB: B5 50
    JSR DispatchJump            ; 9ECD: 20 9A 85
    .byte $D8,$9E,$6A,$9C,$98,$A6,$EC,$9B         ; 9ED0: D8 9E 6A 9C 98 A6 EC 9B
L9ED8:
    JSR ObjThrowProj2           ; 9ED8: 20 80 B2
    LDX ObjLoopSlot             ; 9EDB: A6 48
    LDA ObjPhase,X              ; 9EDD: BD 40 05
    BNE L9EEB                   ; 9EE0: D0 09
    LDA ObjProbeA,X             ; 9EE2: BD 20 05
    BNE L9EEC                   ; 9EE5: D0 05
    LDA #$02                    ; 9EE7: A9 02
    STA ObjState,X              ; 9EE9: 95 50
L9EEB:
    RTS                         ; 9EEB: 60
L9EEC:
    JSR ObjMoveXSubIfDir        ; 9EEC: 20 E9 A5
    BCC L9EF4                   ; 9EEF: 90 03
    JSR AnimByType1             ; 9EF1: 20 61 9E
L9EF4:
    JSR ObjMoveXAddIfDir        ; 9EF4: 20 A7 A5
    BCC L9EEB                   ; 9EF7: 90 F2
    JMP AnimByType2             ; 9EF9: 4C 73 9E
L9EFC:
    JSR FloorBandScan           ; 9EFC: 20 A6 A2
    LDA ObjState,X              ; 9EFF: B5 50
    JSR DispatchJump            ; 9F01: 20 9A 85
    .byte $10,$9F,$4F,$9C,$40,$9F,$EC,$9B         ; 9F04: 10 9F 4F 9C 40 9F EC 9B
    .byte $1D,$9F,$10,$9F                         ; 9F0C: 1D 9F 10 9F
L9F10:
    LDY ObjPhase,X              ; 9F10: BC 40 05
    BEQ L9F38                   ; 9F13: F0 23
    LDA ObjTimer,X              ; 9F15: BD 30 04
    BEQ L9F1E                   ; 9F18: F0 04
    DEC ObjTimer,X              ; 9F1A: DE 30 04
L9F1D:
    RTS                         ; 9F1D: 60
L9F1E:
    LDY #$0E                    ; 9F1E: A0 0E
    JSR AnimPingpongByDir       ; 9F20: 20 29 95
    JSR ObjWalkByDir            ; 9F23: 20 34 95
    JSR TryClimbOrJump          ; 9F26: 20 65 A6
    JSR AttackPointProbe        ; 9F29: 20 45 A4
    BNE L9F35                   ; 9F2C: D0 07
    LDA ObjX,X                  ; 9F2E: BD 70 04
    AND #$F8                    ; 9F31: 29 F8
    BNE L9F40                   ; 9F33: D0 0B
L9F35:
    JMP ClearObject             ; 9F35: 4C E7 A2
L9F38:
    LDA #$08                    ; 9F38: A9 08
    STA ObjTimer,X              ; 9F3A: 9D 30 04
    INC ObjPhase,X              ; 9F3D: FE 40 05
L9F40:
    RTS                         ; 9F40: 60
L9F41:
    LDA ObjState,X              ; 9F41: B5 50
    BEQ L9F59                   ; 9F43: F0 14
    CMP #$03                    ; 9F45: C9 03
    BEQ L9F4C                   ; 9F47: F0 03
    JMP ObjExpireTick           ; 9F49: 4C 4F 9C
L9F4C:
    LDY #$02                    ; 9F4C: A0 02
    JSR AnimSpriteStep          ; 9F4E: 20 FB A7
    DEC ObjTimer,X              ; 9F51: DE 30 04
    BNE L9F99                   ; 9F54: D0 43
    JMP LA057                   ; 9F56: 4C 57 A0
L9F59:
    LDY ObjPhase,X              ; 9F59: BC 40 05
    BEQ L9F86                   ; 9F5C: F0 28
    JSR L9F9A                   ; 9F5E: 20 9A 9F
    LDY #$10                    ; 9F61: A0 10
    JSR AnimSpriteStep          ; 9F63: 20 FB A7
    JSR LA4AF                   ; 9F66: 20 AF A4
    BEQ L9F70                   ; 9F69: F0 05
    INC ObjY,X                  ; 9F6B: FE 60 04
    BNE L9F78                   ; 9F6E: D0 08
L9F70:
    JSR LA4B3                   ; 9F70: 20 B3 A4
    BEQ L9F78                   ; 9F73: F0 03
    DEC ObjY,X                  ; 9F75: DE 60 04
L9F78:
    JSR PlayerContactScan       ; 9F78: 20 53 B7
    BCS L9F83                   ; 9F7B: B0 06
    JSR LA1EB                   ; 9F7D: 20 EB A1
    JMP ObjWalkByDir            ; 9F80: 4C 34 95
L9F83:
    JMP LA1D2                   ; 9F83: 4C D2 A1
L9F86:
    LDY #$10                    ; 9F86: A0 10
    JSR AnimSpriteStep          ; 9F88: 20 FB A7
    LDA #$00                    ; 9F8B: A9 00
    STA ObjAirFlag,X            ; 9F8D: 9D 40 01
    STA ObjGrav,X               ; 9F90: 9D 80 05
    JSR LA1E4                   ; 9F93: 20 E4 A1
    INC ObjPhase,X              ; 9F96: FE 40 05
L9F99:
    RTS                         ; 9F99: 60
L9F9A:
    LDA #$20                    ; 9F9A: A9 20
    STA $35                     ; 9F9C: 85 35
    LDA #$80                    ; 9F9E: A9 80
    STA $36                     ; 9FA0: 85 36
    LDA ObjAirFlag,X            ; 9FA2: BD 40 01
    BNE L9FB5                   ; 9FA5: D0 0E
    LDA $35                     ; 9FA7: A5 35
    STA ObjTimer,X              ; 9FA9: 9D 30 04
    STA ObjAirFlag,X            ; 9FAC: 9D 40 01
    EOR ObjGrav,X               ; 9FAF: 5D 80 05
    STA ObjGrav,X               ; 9FB2: 9D 80 05
L9FB5:
    LDA ObjGrav,X               ; 9FB5: BD 80 05
    BEQ L9FCE                   ; 9FB8: F0 14
    LDA ObjVelY,X               ; 9FBA: BD F0 04
    CLC                         ; 9FBD: 18
    ADC $36                     ; 9FBE: 65 36
    STA ObjVelY,X               ; 9FC0: 9D F0 04
    LDA ObjY,X                  ; 9FC3: BD 60 04
    ADC #$00                    ; 9FC6: 69 00
    STA ObjY,X                  ; 9FC8: 9D 60 04
    JMP L9FDF                   ; 9FCB: 4C DF 9F
L9FCE:
    LDA ObjVelY,X               ; 9FCE: BD F0 04
    SEC                         ; 9FD1: 38
    SBC $36                     ; 9FD2: E5 36
    STA ObjVelY,X               ; 9FD4: 9D F0 04
    LDA ObjY,X                  ; 9FD7: BD 60 04
    SBC #$00                    ; 9FDA: E9 00
    STA ObjY,X                  ; 9FDC: 9D 60 04
L9FDF:
    DEC ObjTimer,X              ; 9FDF: DE 30 04
    BNE L9FE9                   ; 9FE2: D0 05
    LDA #$00                    ; 9FE4: A9 00
    STA ObjAirFlag,X            ; 9FE6: 9D 40 01
L9FE9:
    RTS                         ; 9FE9: 60
L9FEA:
    LDY #$00                    ; 9FEA: A0 00
    BEQ L9FF4                   ; 9FEC: F0 06
L9FEE:
    LDY #$01                    ; 9FEE: A0 01
    BNE L9FF4                   ; 9FF0: D0 02
L9FF2:
    LDY #$02                    ; 9FF2: A0 02
L9FF4:
    STY $05E1                   ; 9FF4: 8C E1 05
    LDA #$02                    ; 9FF7: A9 02
    STA ObjBoxProf,X            ; 9FF9: 9D 70 05
    JSR FloorBandScan           ; 9FFC: 20 A6 A2
    LDA ObjState,X              ; 9FFF: B5 50
    JSR DispatchJump            ; A001: 20 9A 85
    .byte $10,$A0,$6A,$9C,$98,$A6,$47,$A0         ; A004: 10 A0 6A 9C 98 A6 47 A0
    .byte $2A,$A0,$10,$A0                         ; A00C: 2A A0 10 A0
LA010:
    LDA ObjTimer,X              ; A010: BD 30 04
    BEQ LA019                   ; A013: F0 04
    DEC ObjTimer,X              ; A015: DE 30 04
    RTS                         ; A018: 60
LA019:
    JSR LA1DD                   ; A019: 20 DD A1
    LDA ObjAirFlag,X            ; A01C: BD 40 01
    BNE LA02B                   ; A01F: D0 0A
    LDA ObjProbeA,X             ; A021: BD 20 05
    BNE LA02B                   ; A024: D0 05
    LDA #$02                    ; A026: A9 02
    STA ObjState,X              ; A028: 95 50
LA02A:
    RTS                         ; A02A: 60
LA02B:
    LDY $05E1                   ; A02B: AC E1 05
    LDA $A086,Y                 ; A02E: B9 86 A0
    TAY                         ; A031: A8
    LDA ObjType,X               ; A032: B5 60
    CMP #$09                    ; A034: C9 09
    BNE LA03E                   ; A036: D0 06
    JSR AnimSpriteStep          ; A038: 20 FB A7
    JMP ObjWalkByDir            ; A03B: 4C 34 95
LA03E:
    JSR AnimPingpongByDir       ; A03E: 20 29 95
    JSR TryClimbOrJump          ; A041: 20 65 A6
    JMP ObjWalkByDir            ; A044: 4C 34 95
LA047:
    LDY ObjPhase,X              ; A047: BC 40 05
    BEQ LA077                   ; A04A: F0 2B
    DEY                         ; A04C: 88
    BEQ LA063                   ; A04D: F0 14
    DEC ObjTimer,X              ; A04F: DE 30 04
    BNE LA085                   ; A052: D0 31
    JSR LAA49                   ; A054: 20 49 AA
LA057:
    LDY ObjType,X               ; A057: B4 60
    LDA $AC1D,Y                 ; A059: B9 1D AC
    STA ObjSprite,X             ; A05C: 95 70
    LDA #$00                    ; A05E: A9 00
    JMP LA301                   ; A060: 4C 01 A3
LA063:
    LDA #$01                    ; A063: A9 01
    STA $30                     ; A065: 85 30
    LDY #$1B                    ; A067: A0 1B
    JSR AnimSpriteStep          ; A069: 20 FB A7
    LDA $30                     ; A06C: A5 30
    BNE LA085                   ; A06E: D0 15
    LDA #$18                    ; A070: A9 18
    STA ObjTimer,X              ; A072: 9D 30 04
    BNE LA082                   ; A075: D0 0B
LA077:
    LDA #$00                    ; A077: A9 00
    STA ObjAnimAcc,X            ; A079: 9D 50 04
    STA ObjAnimFrac,X           ; A07C: 9D 40 04
    STA ObjAttr,X               ; A07F: 9D 20 04
LA082:
    INC ObjPhase,X              ; A082: FE 40 05
LA085:
    RTS                         ; A085: 60
    .byte $11,$13,$15                             ; A086: 11 13 15
LA089:
    LDA ObjState,X              ; A089: B5 50
    BEQ LA090                   ; A08B: F0 03
    JMP ObjExpireTick           ; A08D: 4C 4F 9C
LA090:
    LDY ObjPhase,X              ; A090: BC 40 05
    BEQ LA0A9                   ; A093: F0 14
    JSR ObjWalkByDir            ; A095: 20 34 95
    LDY #$52                    ; A098: A0 52
    JSR SetSpriteByFlag         ; A09A: 20 04 95
    LDY #$0A                    ; A09D: A0 0A
    LDA FrameCnt                ; A09F: A5 09
    LSR A                       ; A0A1: 4A
    BCC LA0A6                   ; A0A2: 90 02
    LDY #$0C                    ; A0A4: A0 0C
LA0A6:
    JMP LA6B0                   ; A0A6: 4C B0 A6
LA0A9:
    LDA #$D8                    ; A0A9: A9 D8
    STA ObjY,X                  ; A0AB: 9D 60 04
    JSR FacePlayer              ; A0AE: 20 0F A2
    INC ObjPhase,X              ; A0B1: FE 40 05
    RTS                         ; A0B4: 60
LA0B5:
    LDA ObjState,X              ; A0B5: B5 50
    BEQ LA0BC                   ; A0B7: F0 03
    JMP ObjExpireTick           ; A0B9: 4C 4F 9C
LA0BC:
    LDY ObjPhase,X              ; A0BC: BC 40 05
    BEQ LA0E5                   ; A0BF: F0 24
    LDA ObjX,X                  ; A0C1: BD 70 04
    AND #$F0                    ; A0C4: 29 F0
    BEQ LA0D5                   ; A0C6: F0 0D
    DEC ObjAnimFrac,X           ; A0C8: DE 40 04
    BEQ LA0D5                   ; A0CB: F0 08
    LDY #$50                    ; A0CD: A0 50
    JSR SetSpriteByFlag         ; A0CF: 20 04 95
    JMP ObjWalkByDir            ; A0D2: 4C 34 95
LA0D5:
    LDA DifficultyGear          ; A0D5: A5 1B
    LSR A                       ; A0D7: 4A
    LSR A                       ; A0D8: 4A
    TAY                         ; A0D9: A8
    LDA $A0E3,Y                 ; A0DA: B9 E3 A0
    STA $011C                   ; A0DD: 8D 1C 01
    JMP ClearObject             ; A0E0: 4C E7 A2
    .byte $FF,$7F                                 ; A0E3: FF 7F
LA0E5:
    DEC ObjTimer,X              ; A0E5: DE 30 04
    LDA ObjTimer,X              ; A0E8: BD 30 04
    AND #$FE                    ; A0EB: 29 FE
    BNE LA0FB                   ; A0ED: D0 0C
    INC ObjPhase,X              ; A0EF: FE 40 05
    JSR FacePlayer              ; A0F2: 20 0F A2
    LDA #$C0                    ; A0F5: A9 C0
    STA ObjAnimFrac,X           ; A0F7: 9D 40 04
    RTS                         ; A0FA: 60
LA0FB:
    LDY #$50                    ; A0FB: A0 50
    JSR SetSpriteByFlag         ; A0FD: 20 04 95
    LDA FrameCnt                ; A100: A5 09
    AND #$03                    ; A102: 29 03
    BNE LA108                   ; A104: D0 02
    STA ObjSprite,X             ; A106: 95 70
LA108:
    RTS                         ; A108: 60
LA109:
    LDA #$00                    ; A109: A9 00
    STA ObjActFlags,X           ; A10B: 9D 00 05
    LDA ObjState,X              ; A10E: B5 50
    CMP #$05                    ; A110: C9 05
    BEQ LA136                   ; A112: F0 22
    CMP #$04                    ; A114: C9 04
    BNE LA11E                   ; A116: D0 06
    LDA #$10                    ; A118: A9 10
    STA ObjTimer2,X             ; A11A: 9D 00 04
    RTS                         ; A11D: 60
LA11E:
    LDA ObjTimer2,X             ; A11E: BD 00 04
    BEQ LA12C                   ; A121: F0 09
    DEC ObjTimer2,X             ; A123: DE 00 04
    LDA #$00                    ; A126: A9 00
    STA ObjDirFlags,X           ; A128: 9D 10 05
    RTS                         ; A12B: 60
LA12C:
    LDA ObjVariant,X            ; A12C: BD 50 05
    BNE LA131                   ; A12F: D0 00
LA131:
    LDA ObjPhase,X              ; A131: BD 40 05
    BEQ LA13C                   ; A134: F0 06
LA136:
    RTS                         ; A136: 60
LA137:
    LDA FloatScoreSta           ; A137: AD E3 05
    BNE LA19D                   ; A13A: D0 61
LA13C:
    LDA ObjFloorBand,X          ; A13C: BD B0 04
    CMP $04B1                   ; A13F: CD B1 04
    BEQ LA16D                   ; A142: F0 29
    LDA $51                     ; A144: A5 51
    CMP #$05                    ; A146: C9 05
    BEQ LA16D                   ; A148: F0 23
    LDY ObjVariant,X            ; A14A: BC 50 05
    LDA $A1A4,Y                 ; A14D: B9 A4 A1
    AND ObjFrameCnt,X           ; A150: 3D 90 05
    BNE LA16D                   ; A153: D0 18
    LDY #$04                    ; A155: A0 04
    LDA ObjFloorBand,X          ; A157: BD B0 04
    CMP $04B1                   ; A15A: CD B1 04
    BCC LA161                   ; A15D: 90 02
    LDY #$08                    ; A15F: A0 08
LA161:
    STY $37                     ; A161: 84 37
    LDA ObjDirFlags,X           ; A163: BD 10 05
    AND #$F3                    ; A166: 29 F3
    ORA $37                     ; A168: 05 37
    STA ObjDirFlags,X           ; A16A: 9D 10 05
LA16D:
    LDY ObjVariant,X            ; A16D: BC 50 05
    LDA $A1A8,Y                 ; A170: B9 A8 A1
    JSR LA1F0                   ; A173: 20 F0 A1
    JSR ObjFireCheck            ; A176: 20 2A A2
    BCS LA19D                   ; A179: B0 22
    JSR PlayerContactScan       ; A17B: 20 53 B7
    BCC LA19E                   ; A17E: 90 1E
    LDA $30                     ; A180: A5 30
    BNE LA1D2                   ; A182: D0 4E
    LDY #$0A                    ; A184: A0 0A
    JSR LA50D                   ; A186: 20 0D A5
    BNE LA1D2                   ; A189: D0 47
LA18B:
    LDA ObjXPage,X              ; A18B: BD 10 04
    BNE LA1D2                   ; A18E: D0 42
    LDA ObjDirFlags,X           ; A190: BD 10 05
    BEQ LA19D                   ; A193: F0 08
    LDA #$80                    ; A195: A9 80
    ORA ObjActFlags,X           ; A197: 1D 00 05
    STA ObjActFlags,X           ; A19A: 9D 00 05
LA19D:
    RTS                         ; A19D: 60
LA19E:
    JSR LA4DB                   ; A19E: 20 DB A4
    BEQ LA18B                   ; A1A1: F0 E8
    RTS                         ; A1A3: 60
    .byte $FF,$7F,$1F,$00,$3F,$FF,$7F,$3F         ; A1A4: FF 7F 1F 00 3F FF 7F 3F
LA1AC:
    LDA ObjState,X              ; A1AC: B5 50
    CMP #$03                    ; A1AE: C9 03
    BEQ LA1DC                   ; A1B0: F0 2A
    LDA #$00                    ; A1B2: A9 00
    STA ObjActFlags,X           ; A1B4: 9D 00 05
    JSR ObjFireCheck            ; A1B7: 20 2A A2
    JSR LA1EB                   ; A1BA: 20 EB A1
LA1BD:
    JSR LA4DB                   ; A1BD: 20 DB A4
    BEQ LA1D2                   ; A1C0: F0 10
LA1C2:
    JSR PlayerContactScan       ; A1C2: 20 53 B7
    BCS LA1D2                   ; A1C5: B0 0B
    BCC LA1E4                   ; A1C7: 90 1B
    LDA ObjDirFlags,X           ; A1C9: BD 10 05
    AND #$FC                    ; A1CC: 29 FC
    STA ObjDirFlags,X           ; A1CE: 9D 10 05
    RTS                         ; A1D1: 60
LA1D2:
    LDA ObjDirFlags,X           ; A1D2: BD 10 05
    BEQ FacePlayer              ; A1D5: F0 38
    EOR #$03                    ; A1D7: 49 03
    STA ObjDirFlags,X           ; A1D9: 9D 10 05
LA1DC:
    RTS                         ; A1DC: 60
LA1DD:
    LDA ObjAirFlag,X            ; A1DD: BD 40 01
    BNE LA1C2                   ; A1E0: D0 E0
    BEQ LA1BD                   ; A1E2: F0 D9
LA1E4:
    LDA ObjDirFlags,X           ; A1E4: BD 10 05
    AND #$03                    ; A1E7: 29 03
    BEQ LA1F5                   ; A1E9: F0 0A
LA1EB:
    LDY DifficultyGear          ; A1EB: A4 1B
    LDA $A207,Y                 ; A1ED: B9 07 A2
LA1F0:
    AND ObjFrameCnt,X           ; A1F0: 3D 90 05
    BNE LA205                   ; A1F3: D0 10
LA1F5:
    LDA InvincibleT             ; A1F5: AD F6 05
    BNE LA205                   ; A1F8: D0 0B
    LDA $51                     ; A1FA: A5 51
    CMP #$01                    ; A1FC: C9 01
    BEQ LA205                   ; A1FE: F0 05
    JSR FacePlayer              ; A200: 20 0F A2
    SEC                         ; A203: 38
    RTS                         ; A204: 60
LA205:
    CLC                         ; A205: 18
    RTS                         ; A206: 60
    .byte $FF,$FF,$FF,$7F,$7F,$3F,$3F,$1F         ; A207: FF FF FF 7F 7F 3F 3F 1F
FacePlayer:
    ; A=1/2 按 $0470,X vs $0471（玩家 X）定左右；$0410,X≠0（跨页）时 EOR #3；写 $0510,X 返 A&3
    LDA #$01                    ; A20F: A9 01
    LDY ObjX,X                  ; A211: BC 70 04
    CPY $0471                   ; A214: CC 71 04
    BCC LA21B                   ; A217: 90 02
    LDA #$02                    ; A219: A9 02
LA21B:
    LDY ObjXPage,X              ; A21B: BC 10 04
    BEQ LA222                   ; A21E: F0 02
    EOR #$03                    ; A220: 49 03
LA222:
    STA ObjDirFlags,X           ; A222: 9D 10 05
    AND #$03                    ; A225: 29 03
    RTS                         ; A227: 60
LA228:
    CLC                         ; A228: 18
    RTS                         ; A229: 60
ObjFireCheck:
    ; $0130,X 冷却中 CLC 返；同带（$04B0,X==$04B1）且射程窗（$40-$C0±$20 排除带）且朝向正确时置 $0500,X 位6，冷却=$A29E[$1B&7]
    LDA ObjFireCd,X             ; A22A: BD 30 01
    BEQ LA234                   ; A22D: F0 05
    DEC ObjFireCd,X             ; A22F: DE 30 01
    CLC                         ; A232: 18
    RTS                         ; A233: 60
LA234:
    LDA ObjXPage,X              ; A234: BD 10 04
    BNE LA27E                   ; A237: D0 45
    LDA #$01                    ; A239: A9 01
    CMP ObjState,X              ; A23B: D5 50
    BEQ LA27E                   ; A23D: F0 3F
    CMP $51                     ; A23F: C5 51
    BEQ LA27E                   ; A241: F0 3B
    LDA ObjX,X                  ; A243: BD 70 04
    CMP #$40                    ; A246: C9 40
    BCC LA27E                   ; A248: 90 34
    CMP #$C0                    ; A24A: C9 C0
    BCS LA27E                   ; A24C: B0 30
    ADC #$20                    ; A24E: 69 20
    CMP $0471                   ; A250: CD 71 04
    BCC LA25C                   ; A253: 90 07
    SBC #$40                    ; A255: E9 40
    CMP $0471                   ; A257: CD 71 04
    BCC LA27E                   ; A25A: 90 22
LA25C:
    LDA ObjType,X               ; A25C: B5 60
    CMP #$01                    ; A25E: C9 01
    BNE LA267                   ; A260: D0 05
    LDA ObjVariant,X            ; A262: BD 50 05
    BEQ LA289                   ; A265: F0 22
LA267:
    LDA ObjFloorBand,X          ; A267: BD B0 04
    CMP $04B1                   ; A26A: CD B1 04
    BNE LA27E                   ; A26D: D0 0F
    LDY ObjMoveDir,X            ; A26F: BC A0 04
    LDA ObjX,X                  ; A272: BD 70 04
    CMP $0471                   ; A275: CD 71 04
    BCC LA280                   ; A278: 90 06
    CPY #$02                    ; A27A: C0 02
    BEQ LA284                   ; A27C: F0 06
LA27E:
    CLC                         ; A27E: 18
    RTS                         ; A27F: 60
LA280:
    CPY #$01                    ; A280: C0 01
    BNE LA27E                   ; A282: D0 FA
LA284:
    JSR AttackPointProbe        ; A284: 20 45 A4
    BNE LA27E                   ; A287: D0 F5
LA289:
    LDA #$40                    ; A289: A9 40
    ORA ObjActFlags,X           ; A28B: 1D 00 05
    STA ObjActFlags,X           ; A28E: 9D 00 05
    LDA DifficultyGear          ; A291: A5 1B
    AND #$07                    ; A293: 29 07
    TAY                         ; A295: A8
    LDA $A29E,Y                 ; A296: B9 9E A2
    STA ObjFireCd,X             ; A299: 9D 30 01
    SEC                         ; A29C: 38
    RTS                         ; A29D: 60
    .byte $80,$70,$60,$50,$40,$30,$20,$10         ; A29E: 80 70 60 50 40 30 20 10
FloorBandScan:
    ; 先 ObjPhysicsStep，再 $0460,X 与 $A2BF,Y（Y=1..8）逐档比较得带号 0-8 写 $04B0,X；L92CE/$9E85 等玩家系路径调用
    JSR ObjPhysicsStep          ; A2A6: 20 F2 A4
    LDY #$01                    ; A2A9: A0 01
    LDA ObjY,X                  ; A2AB: BD 60 04
LA2AE:
    CMP $A2BF,Y                 ; A2AE: D9 BF A2
    BCC LA2BA                   ; A2B1: 90 07
    INY                         ; A2B3: C8
    CPY #$09                    ; A2B4: C0 09
    BCC LA2AE                   ; A2B6: 90 F6
    LDY #$08                    ; A2B8: A0 08
LA2BA:
    TYA                         ; A2BA: 98
    STA ObjFloorBand,X          ; A2BB: 9D B0 04
    RTS                         ; A2BE: 60
    .byte $59,$59,$69,$81,$91,$A1,$B9,$C9         ; A2BF: 59 59 69 81 91 A1 B9 C9
    .byte $D9,$4E,$4E,$5E,$76,$86,$96,$AE         ; A2C7: D9 4E 4E 5E 76 86 96 AE
    .byte $BE,$CE                                 ; A2CF: BE CE
LA2D1:
    INC ObjPhase,X              ; A2D1: FE 40 05
    RTS                         ; A2D4: 60
LA2D5:
    LDA ObjDirFlags,X           ; A2D5: BD 10 05
    AND #$F3                    ; A2D8: 29 F3
    STA ObjDirFlags,X           ; A2DA: 9D 10 05
    RTS                         ; A2DD: 60
LA2DE:
    LDA ObjDirFlags,X           ; A2DE: BD 10 05
    AND #$FC                    ; A2E1: 29 FC
    STA ObjDirFlags,X           ; A2E3: 9D 10 05
    RTS                         ; A2E6: 60
ClearObject:
    ; 清物体槽 X 全字段（$0460/$0470/$0410/$0420/$05B0/$0140/$70/$60/$50/$0540），Y=$F4 藏屏外
    LDA #$F4                    ; A2E7: A9 F4
    STA ObjY,X                  ; A2E9: 9D 60 04
    LDA #$00                    ; A2EC: A9 00
    STA ObjX,X                  ; A2EE: 9D 70 04
    STA ObjXPage,X              ; A2F1: 9D 10 04
    STA ObjSprite,X             ; A2F4: 95 70
    STA ObjType,X               ; A2F6: 95 60
    STA ObjAttr,X               ; A2F8: 9D 20 04
    STA ObjShieldT,X            ; A2FB: 9D B0 05
    STA ObjAirFlag,X            ; A2FE: 9D 40 01
LA301:
    STA ObjState,X              ; A301: 95 50
    LDA #$00                    ; A303: A9 00
    STA ObjPhase,X              ; A305: 9D 40 05
    RTS                         ; A308: 60
ClearObjectList:
    ; X=$0F..0 循环 ClearObject（跳过槽 1）
    LDX #$0F                    ; A309: A2 0F
LA30B:
    CPX #$01                    ; A30B: E0 01
    BEQ LA312                   ; A30D: F0 03
    JSR ClearObject             ; A30F: 20 E7 A2
LA312:
    DEX                         ; A312: CA
    BPL LA30B                   ; A313: 10 F6
    JSR HideOamSlots1to6        ; A315: 20 84 B3
    LDX ObjLoopSlot             ; A318: A6 48
    LDA #$00                    ; A31A: A9 00
    RTS                         ; A31C: 60
HitBoxTest:
    ; ($28,$29)vs($2C,$2D) 与 ($2A,$2B)vs($2E,$2F) 双轴：|中心差|-半径和<0 则 SEC；LA31D=完整双轴，LA361 从第二轴入
    LDY #$00                    ; A31D: A0 00
    LDA $28,Y                   ; A31F: B9 28 00
    CLC                         ; A322: 18
    ADC $2C,Y                   ; A323: 79 2C 00
    STA $37                     ; A326: 85 37
    LDA $29,Y                   ; A328: B9 29 00
    CLC                         ; A32B: 18
    ADC $28,Y                   ; A32C: 79 28 00
    SEC                         ; A32F: 38
    SBC $2D,Y                   ; A330: F9 2D 00
    BCC LA35E                   ; A333: 90 29
    CMP $37                     ; A335: C5 37
    BEQ LA33B                   ; A337: F0 02
    BCS LA35D                   ; A339: B0 22
LA33B:
    LDY #$02                    ; A33B: A0 02
    LDA $28,Y                   ; A33D: B9 28 00
    CLC                         ; A340: 18
    ADC $2C,Y                   ; A341: 79 2C 00
    STA $37                     ; A344: 85 37
    LDA $29,Y                   ; A346: B9 29 00
    CLC                         ; A349: 18
    ADC $28,Y                   ; A34A: 79 28 00
    BCC LA351                   ; A34D: 90 02
    LDA #$FF                    ; A34F: A9 FF
LA351:
    SEC                         ; A351: 38
    SBC $2D,Y                   ; A352: F9 2D 00
    BCC LA35D                   ; A355: 90 06
    CMP $37                     ; A357: C5 37
    BEQ LA35F                   ; A359: F0 04
    BCC LA35F                   ; A35B: 90 02
LA35D:
    CLC                         ; A35D: 18
LA35E:
    RTS                         ; A35E: 60
LA35F:
    SEC                         ; A35F: 38
    RTS                         ; A360: 60
HitBoxTest2:
    LDY #$02                    ; A361: A0 02
LA363:
    LDA $29,Y                   ; A363: B9 29 00
    CMP $2D,Y                   ; A366: D9 2D 00
    BCS LA35D                   ; A369: B0 F2
    CLC                         ; A36B: 18
    ADC $28,Y                   ; A36C: 79 28 00
    CMP $2D,Y                   ; A36F: D9 2D 00
    BCC LA35D                   ; A372: 90 E9
    DEY                         ; A374: 88
    DEY                         ; A375: 88
    BPL LA363                   ; A376: 10 EB
    SEC                         ; A378: 38
    RTS                         ; A379: 60
HitBoxBuild:
    ; A*4 索引 $A3C1：字节 0→$28,Y（Y 半径）、字节 1+$0460→$29,Y（Y 心）、字节 2→$2A,Y（X 半径）、字节 3（带符号）+$0470→$2B,Y（X 心，夹 $00/$FF）
    STX $3E                     ; A37A: 86 3E
    STY $3F                     ; A37C: 84 3F
    ASL A                       ; A37E: 0A
    ASL A                       ; A37F: 0A
    TAX                         ; A380: AA
    LDA $A3C1,X                 ; A381: BD C1 A3
    STA $28,Y                   ; A384: 99 28 00
    INX                         ; A387: E8
    LDY $3E                     ; A388: A4 3E
    LDA ObjY,Y                  ; A38A: B9 60 04
    CLC                         ; A38D: 18
    ADC $A3C1,X                 ; A38E: 7D C1 A3
    LDY $3F                     ; A391: A4 3F
    STA $29,Y                   ; A393: 99 29 00
    INX                         ; A396: E8
    LDA $A3C1,X                 ; A397: BD C1 A3
    STA $2A,Y                   ; A39A: 99 2A 00
    INX                         ; A39D: E8
    LDY $3E                     ; A39E: A4 3E
    LDA $A3C1,X                 ; A3A0: BD C1 A3
    BMI LA3B7                   ; A3A3: 30 12
    CLC                         ; A3A5: 18
    ADC ObjX,Y                  ; A3A6: 79 70 04
    BCC LA3AD                   ; A3A9: 90 02
    LDA #$FF                    ; A3AB: A9 FF
LA3AD:
    LDY $3F                     ; A3AD: A4 3F
    STA $2B,Y                   ; A3AF: 99 2B 00
    LDX $3E                     ; A3B2: A6 3E
    LDY $3F                     ; A3B4: A4 3F
    RTS                         ; A3B6: 60
LA3B7:
    CLC                         ; A3B7: 18
    ADC ObjX,Y                  ; A3B8: 79 70 04
    BCS LA3AD                   ; A3BB: B0 F0
    LDA #$00                    ; A3BD: A9 00
    BEQ LA3AD                   ; A3BF: F0 EC
    .byte $02,$FF,$02,$FF,$08,$F9,$0A,$FB         ; A3C1: 02 FF 02 FF 08 F9 0A FB
    .byte $0A,$F6,$06,$FD,$12,$EC,$08,$FB         ; A3C9: 0A F6 06 FD 12 EC 08 FB
    .byte $0A,$F7,$0C,$FA,$20,$E1,$14,$F6         ; A3D1: 0A F7 0C FA 20 E1 14 F6
    .byte $0C,$EF,$08,$05,$0C,$EF,$08,$F3         ; A3D9: 0C EF 08 05 0C EF 08 F3
    .byte $0F,$F0,$08,$FC,$08,$F6,$02,$FF         ; A3E1: 0F F0 08 FC 08 F6 02 FF
    .byte $02,$FC,$02,$FF                         ; A3E9: 02 FC 02 FF
TerrainBitTest:
    ; $40+ScrollX→$31、按 $34/进位合成页位 $32（EOR PpuCtrlShadow 位0）；$41 在 $20-$DF 间时：行位 ($41-$20)>>1 加页基 $60→$33，列 $31>>5，位 $31>>2&7 查 $A43D 位表 AND $0340,Y
    LDA $40                     ; A3ED: A5 40
    CLC                         ; A3EF: 18
    ADC ScrollX                 ; A3F0: 65 18
    STA $31                     ; A3F2: 85 31
    LDA PpuCtrlShadow           ; A3F4: A5 0E
    LDY $34                     ; A3F6: A4 34
    BEQ LA3FE                   ; A3F8: F0 04
    BCC LA400                   ; A3FA: 90 04
    BCS LA402                   ; A3FC: B0 04
LA3FE:
    BCC LA402                   ; A3FE: 90 02
LA400:
    EOR #$01                    ; A400: 49 01
LA402:
    AND #$01                    ; A402: 29 01
    STA $32                     ; A404: 85 32
    LDA $41                     ; A406: A5 41
    AND #$F8                    ; A408: 29 F8
    CMP #$E0                    ; A40A: C9 E0
    BCS LA439                   ; A40C: B0 2B
    CMP #$20                    ; A40E: C9 20
    BCC LA439                   ; A410: 90 27
    SBC #$20                    ; A412: E9 20
    LSR A                       ; A414: 4A
    LDY $32                     ; A415: A4 32
    BEQ LA41C                   ; A417: F0 03
    CLC                         ; A419: 18
    ADC #$60                    ; A41A: 69 60
LA41C:
    STA $33                     ; A41C: 85 33
    LDA $31                     ; A41E: A5 31
    LSR A                       ; A420: 4A
    LSR A                       ; A421: 4A
    LSR A                       ; A422: 4A
    PHA                         ; A423: 48
    AND #$07                    ; A424: 29 07
    STA $30                     ; A426: 85 30
    PLA                         ; A428: 68
    LSR A                       ; A429: 4A
    LSR A                       ; A42A: 4A
    LSR A                       ; A42B: 4A
    CLC                         ; A42C: 18
    ADC $33                     ; A42D: 65 33
    TAY                         ; A42F: A8
    LDA TerrainMap,Y            ; A430: B9 40 03
    LDY $30                     ; A433: A4 30
    AND $A43D,Y                 ; A435: 39 3D A4
LA438:
    RTS                         ; A438: 60
LA439:
    LDA #$00                    ; A439: A9 00
    BEQ LA438                   ; A43B: F0 FB
    .byte $01,$02,$04,$08,$10,$20,$40,$80         ; A43D: 01 02 04 08 10 20 40 80
AttackPointProbe:
    ; Y=$60,X：$A485,Y+$0460,X→$41，±$A496,Y（按 $0510 位0）+$0470,X→$40，尾转 TerrainBitTest 结果写 $05A0,X；LB753/LA284 调用
    LDY ObjType,X               ; A445: B4 60
    LDA $A496,Y                 ; A447: B9 96 A4
    STA $30                     ; A44A: 85 30
    LDA ObjDirFlags,X           ; A44C: BD 10 05
    AND #$01                    ; A44F: 29 01
    BNE LA45A                   ; A451: D0 07
    LDA #$00                    ; A453: A9 00
    SEC                         ; A455: 38
    SBC $30                     ; A456: E5 30
    STA $30                     ; A458: 85 30
LA45A:
    LDA $A485,Y                 ; A45A: B9 85 A4
    CLC                         ; A45D: 18
    ADC ObjY,X                  ; A45E: 7D 60 04
    STA $41                     ; A461: 85 41
    LDA $30                     ; A463: A5 30
    ROL A                       ; A465: 2A
    ROL A                       ; A466: 2A
    EOR ObjXPage,X              ; A467: 5D 10 04
    AND #$01                    ; A46A: 29 01
    STA $34                     ; A46C: 85 34
    LDA $30                     ; A46E: A5 30
    CLC                         ; A470: 18
    ADC ObjX,X                  ; A471: 7D 70 04
    STA $40                     ; A474: 85 40
    BCC LA47E                   ; A476: 90 06
    LDA $34                     ; A478: A5 34
    EOR #$01                    ; A47A: 49 01
    STA $34                     ; A47C: 85 34
LA47E:
    JSR TerrainBitTest          ; A47E: 20 ED A3
    STA ObjAtkProbe,X           ; A481: 9D A0 05
    RTS                         ; A484: 60
    .byte $F8,$F8,$F8,$00,$00,$F8,$FC,$FC         ; A485: F8 F8 F8 00 00 F8 FC FC
    .byte $FC,$FC,$FC,$00,$00,$00,$00,$00         ; A48D: FC FC FC 00 00 00 00 00
    .byte $00,$08,$08,$08,$00,$00,$08,$08         ; A495: 00 08 08 08 00 00 08 08
    .byte $08,$08,$08,$0A,$00,$00,$08,$04         ; A49D: 08 08 08 0A 00 00 08 04
    .byte $04,$04                                 ; A4A5: 04 04
LA4A7:
    LDY #$01                    ; A4A7: A0 01
    BNE ObjPosAddDelta          ; A4A9: D0 6A
    LDY #$03                    ; A4AB: A0 03
    BNE ObjPosAddDelta          ; A4AD: D0 66
LA4AF:
    LDY #$01                    ; A4AF: A0 01
    BNE ObjPosAddDelta          ; A4B1: D0 62
LA4B3:
    LDY #$02                    ; A4B3: A0 02
    BNE ObjPosAddDelta          ; A4B5: D0 5E
LA4B7:
    LDY #$09                    ; A4B7: A0 09
    BNE ObjPosAddDelta          ; A4B9: D0 5A
LA4BB:
    LDY #$00                    ; A4BB: A0 00
    LDA ObjType,X               ; A4BD: B5 60
    CMP #$00                    ; A4BF: C9 00
    BEQ ObjPosAddDelta          ; A4C1: F0 52
    CMP #$01                    ; A4C3: C9 01
    BEQ ObjPosAddDelta          ; A4C5: F0 4E
    LDY #$0E                    ; A4C7: A0 0E
    BNE ObjPosAddDelta          ; A4C9: D0 4A
LA4CB:
    LDY #$12                    ; A4CB: A0 12
    LDA ObjType,X               ; A4CD: B5 60
    CMP #$00                    ; A4CF: C9 00
    BEQ ObjPosAddDelta          ; A4D1: F0 42
    CMP #$01                    ; A4D3: C9 01
    BEQ ObjPosAddDelta          ; A4D5: F0 3E
    LDY #$13                    ; A4D7: A0 13
    BNE ObjPosAddDelta          ; A4D9: D0 3A
LA4DB:
    LDY #$04                    ; A4DB: A0 04
    JMP LA50D                   ; A4DD: 4C 0D A5
LA4E0:
    LDY #$06                    ; A4E0: A0 06
    BNE LA50D                   ; A4E2: D0 29
ObjStepY:
    ; 清 $0120,X 后 ObjPosAddDelta Y=8，结果写 $0520,X；类型≥2 的 Y 向地形步（LA4F2 分流）
    LDA #$00                    ; A4E4: A9 00
    STA ObjProbeB,X             ; A4E6: 9D 20 01
    LDY #$08                    ; A4E9: A0 08
    JSR ObjPosAddDelta          ; A4EB: 20 15 A5
    STA ObjProbeA,X             ; A4EE: 9D 20 05
    RTS                         ; A4F1: 60
ObjPhysicsStep:
    ; 类型 0/1（玩家/伙伴）：ObjPosAddDelta Y=$10 结果→$0520,X、Y=$11 结果→$0120,X；其余类型转 ObjStepY
    LDA ObjType,X               ; A4F2: B5 60
    CMP #$00                    ; A4F4: C9 00
    BEQ LA4FC                   ; A4F6: F0 04
    CMP #$01                    ; A4F8: C9 01
    BNE ObjStepY                ; A4FA: D0 E8
LA4FC:
    LDY #$10                    ; A4FC: A0 10
    JSR ObjPosAddDelta          ; A4FE: 20 15 A5
    STA ObjProbeA,X             ; A501: 9D 20 05
    LDY #$11                    ; A504: A0 11
    JSR ObjPosAddDelta          ; A506: 20 15 A5
    STA ObjProbeB,X             ; A509: 9D 20 01
    RTS                         ; A50C: 60
LA50D:
    LDA ObjDirFlags,X           ; A50D: BD 10 05
    AND #$01                    ; A510: 29 01
    BNE ObjPosAddDelta          ; A512: D0 01
    INY                         ; A514: C8
ObjPosAddDelta:
    ; TYA/ASL/TAY 后 $0460,X+$A541,Y→$41，$0470,X+$A542,Y→$40，进位异或翻 $34 位，尾转 $A3ED（滚动合成）
    TYA                         ; A515: 98
    ASL A                       ; A516: 0A
    TAY                         ; A517: A8
    LDA ObjY,X                  ; A518: BD 60 04
    CLC                         ; A51B: 18
    ADC $A541,Y                 ; A51C: 79 41 A5
    STA $41                     ; A51F: 85 41
    LDA $A542,Y                 ; A521: B9 42 A5
    ROL A                       ; A524: 2A
    ROL A                       ; A525: 2A
    EOR ObjXPage,X              ; A526: 5D 10 04
    AND #$01                    ; A529: 29 01
    STA $34                     ; A52B: 85 34
    LDA ObjX,X                  ; A52D: BD 70 04
    CLC                         ; A530: 18
    ADC $A542,Y                 ; A531: 79 42 A5
    STA $40                     ; A534: 85 40
    BCC LA53E                   ; A536: 90 06
    LDA $34                     ; A538: A5 34
    EOR #$01                    ; A53A: 49 01
    STA $34                     ; A53C: 85 34
LA53E:
    JMP TerrainBitTest          ; A53E: 4C ED A3
    .byte $F0,$04,$F8,$00,$08,$00,$FA,$00         ; A541: F0 04 F8 00 08 00 FA 00
    .byte $02,$05,$02,$FB,$FD,$08,$FD,$F9         ; A549: 02 05 02 FB FD 08 FD F9
    .byte $02,$00,$E8,$00,$E7,$08,$E7,$F8         ; A551: 02 00 E8 00 E7 08 E7 F8
    .byte $FC,$08,$FC,$F8,$FC,$07,$E8,$00         ; A559: FC 08 FC F8 FC 07 E8 00
    .byte $02,$04,$02,$FC,$F0,$FC,$FC,$F9         ; A561: 02 04 02 FC F0 FC FC F9
    .byte $BD,$10,$05,$29,$04,$F0,$3E             ; A569: BD 10 05 29 04 F0 3E
ObjMoveYAdd:
    ; Y=$04D0,X（Y 速索引）：$0480,X 加 $A648,Y（小数）、$0460,X 加 $A647,Y（整数），SEC 返；攀爬下降（L95CA 路径）
    LDY ObjSpeedY,X             ; A570: BC D0 04
    LDA ObjYFrac,X              ; A573: BD 80 04
    CLC                         ; A576: 18
    ADC $A648,Y                 ; A577: 79 48 A6
    STA ObjYFrac,X              ; A57A: 9D 80 04
    LDA ObjY,X                  ; A57D: BD 60 04
    ADC $A647,Y                 ; A580: 79 47 A6
    STA ObjY,X                  ; A583: 9D 60 04
    SEC                         ; A586: 38
    RTS                         ; A587: 60
LA588:
    LDA ObjDirFlags,X           ; A588: BD 10 05
    AND #$08                    ; A58B: 29 08
    BEQ LA5AE                   ; A58D: F0 1F
ObjMoveYSub:
    ; 同上作减：$0480,X-$A648,Y、$0460,X-$A647,Y；攀爬上升（L95AB 路径）
    LDY ObjSpeedY,X             ; A58F: BC D0 04
    LDA ObjYFrac,X              ; A592: BD 80 04
    SEC                         ; A595: 38
    SBC $A648,Y                 ; A596: F9 48 A6
    STA ObjYFrac,X              ; A599: 9D 80 04
    LDA ObjY,X                  ; A59C: BD 60 04
    SBC $A647,Y                 ; A59F: F9 47 A6
    STA ObjY,X                  ; A5A2: 9D 60 04
    SEC                         ; A5A5: 38
    RTS                         ; A5A6: 60
ObjMoveXAddIfDir:
    LDA ObjDirFlags,X           ; A5A7: BD 10 05
    AND #$01                    ; A5AA: 29 01
    BNE ObjMoveXAdd             ; A5AC: D0 02
LA5AE:
    CLC                         ; A5AE: 18
    RTS                         ; A5AF: 60
ObjMoveXAdd:
    ; $04A0,X=1；Y=$04C0,X：$0490,X 加小数、$0470,X 加整数；进位翻 $0410,X 位0（跨页）；跨页且屏位入 $40-$C0 时 ClearObject（卷出回收）
    LDA #$01                    ; A5B0: A9 01
    STA ObjMoveDir,X            ; A5B2: 9D A0 04
    LDY ObjSpeedX,X             ; A5B5: BC C0 04
    LDA ObjXFrac,X              ; A5B8: BD 90 04
    CLC                         ; A5BB: 18
    ADC $A648,Y                 ; A5BC: 79 48 A6
    STA ObjXFrac,X              ; A5BF: 9D 90 04
    LDA ObjX,X                  ; A5C2: BD 70 04
    ADC $A647,Y                 ; A5C5: 79 47 A6
LA5C8:
    STA ObjX,X                  ; A5C8: 9D 70 04
    BCC LA5D7                   ; A5CB: 90 0A
LA5CD:
    LDA ObjXPage,X              ; A5CD: BD 10 04
    EOR #$01                    ; A5D0: 49 01
    STA ObjXPage,X              ; A5D2: 9D 10 04
LA5D5:
    SEC                         ; A5D5: 38
    RTS                         ; A5D6: 60
LA5D7:
    LDY ObjXPage,X              ; A5D7: BC 10 04
    BEQ LA5D5                   ; A5DA: F0 F9
    CMP #$40                    ; A5DC: C9 40
    BCC LA5D5                   ; A5DE: 90 F5
    CMP #$C0                    ; A5E0: C9 C0
    BCS LA5D5                   ; A5E2: B0 F1
    JSR ClearObject             ; A5E4: 20 E7 A2
    SEC                         ; A5E7: 38
    RTS                         ; A5E8: 60
ObjMoveXSubIfDir:
    LDA ObjDirFlags,X           ; A5E9: BD 10 05
    AND #$02                    ; A5EC: 29 02
    BEQ LA5AE                   ; A5EE: F0 BE
ObjMoveXSub:
    ; $04A0,X=2；同上作减（左行），出口共用 LA5C8/LA5CD/LA5D7
    LDA #$02                    ; A5F0: A9 02
    STA ObjMoveDir,X            ; A5F2: 9D A0 04
    LDY ObjSpeedX,X             ; A5F5: BC C0 04
    LDA ObjXFrac,X              ; A5F8: BD 90 04
    SEC                         ; A5FB: 38
    SBC $A648,Y                 ; A5FC: F9 48 A6
    STA ObjXFrac,X              ; A5FF: 9D 90 04
    LDA ObjX,X                  ; A602: BD 70 04
    SBC $A647,Y                 ; A605: F9 47 A6
LA608:
    STA ObjX,X                  ; A608: 9D 70 04
    BCC LA5CD                   ; A60B: 90 C0
    BCS LA5D7                   ; A60D: B0 C8
ScrollWorldObj:
    ; A=1（LA613=2）写 $04A0,X；JSR ScrollStep；$1C≠0 时全槽按滚动方向 ±1 平移（LA621 循环，跨页翻 $0410,X）；L9772 调用
    LDA #$01                    ; A60F: A9 01
    BNE LA615                   ; A611: D0 02
LA613:
    LDA #$02                    ; A613: A9 02
LA615:
    STA ObjMoveDir,X            ; A615: 9D A0 04
    JSR $CBB6                   ; A618: 20 B6 CB  -> Bank1:ScrollStep
    LDA $1C                     ; A61B: A5 1C
    BEQ LA646                   ; A61D: F0 27
    LDX #$0F                    ; A61F: A2 0F
LA621:
    LDA ObjType,X               ; A621: B5 60
    BEQ LA641                   ; A623: F0 1C
    LDA $04A1                   ; A625: AD A1 04
    CMP #$01                    ; A628: C9 01
    BEQ LA638                   ; A62A: F0 0C
    SEC                         ; A62C: 38
    LDA ObjX,X                  ; A62D: BD 70 04
    ADC #$00                    ; A630: 69 00
    JSR LA5C8                   ; A632: 20 C8 A5
    JMP LA641                   ; A635: 4C 41 A6
LA638:
    CLC                         ; A638: 18
    LDA ObjX,X                  ; A639: BD 70 04
    SBC #$00                    ; A63C: E9 00
    JSR LA608                   ; A63E: 20 08 A6
LA641:
    DEX                         ; A641: CA
    BPL LA621                   ; A642: 10 DD
    LDX ObjLoopSlot             ; A644: A6 48
LA646:
    RTS                         ; A646: 60
    .byte $00,$01,$00,$20,$00,$40,$00,$60         ; A647: 00 01 00 20 00 40 00 60
    .byte $00,$80,$00,$A0,$00,$C0,$00,$E0         ; A64F: 00 80 00 A0 00 C0 00 E0
    .byte $01,$00,$01,$20,$01,$80,$02,$00         ; A657: 01 00 01 20 01 80 02 00
    .byte $03,$00,$04,$00,$05,$00                 ; A65F: 03 00 04 00 05 00
TryClimbOrJump:
    ; $0140,X≠0 或 $0550,X 位0=1 或（$0590,X&$7F)==0 的地形探测成立时：$50,X=5、$05E5=跳型（LA694/LA698/LA69C 预设 8/4/0-2），转 JumpInit
    LDA ObjAirFlag,X            ; A665: BD 40 01
    BNE LA66F                   ; A668: D0 05
    JSR LA4B7                   ; A66A: 20 B7 A4
    BNE LA6E4                   ; A66D: D0 75
LA66F:
    LDA ObjVariant,X            ; A66F: BD 50 05
    LSR A                       ; A672: 4A
    BCC LA6E4                   ; A673: 90 6F
    LDA ObjType,X               ; A675: B5 60
    CMP #$06                    ; A677: C9 06
    BEQ LA68C                   ; A679: F0 11
    LDA ObjAirFlag,X            ; A67B: BD 40 01
    BNE LA68C                   ; A67E: D0 0C
    LDA ObjFrameCnt,X           ; A680: BD 90 05
    AND #$7F                    ; A683: 29 7F
    BNE LA6E4                   ; A685: D0 5D
    JSR LA4DB                   ; A687: 20 DB A4
    BEQ LA6E4                   ; A68A: F0 58
LA68C:
    LDA #$05                    ; A68C: A9 05
    STA ObjState,X              ; A68E: 95 50
    LDY #$06                    ; A690: A0 06
    BNE LA6B0                   ; A692: D0 1C
LA694:
    LDY #$08                    ; A694: A0 08
    BNE LA6B0                   ; A696: D0 18
LA698:
    LDY #$04                    ; A698: A0 04
    BNE LA6B0                   ; A69A: D0 14
LA69C:
    LDY #$00                    ; A69C: A0 00
    LDA EquipBits               ; A69E: A5 49
    AND #$40                    ; A6A0: 29 40
    BEQ LA6B0                   ; A6A2: F0 0C
    LDA StageId                 ; A6A4: A5 80
    CMP #$43                    ; A6A6: C9 43
    BEQ LA6AE                   ; A6A8: F0 04
    CMP #$44                    ; A6AA: C9 44
    BNE LA6B0                   ; A6AC: D0 02
LA6AE:
    LDY #$02                    ; A6AE: A0 02
LA6B0:
    STY $05E5                   ; A6B0: 8C E5 05
    LDA ObjAirFlag,X            ; A6B3: BD 40 01
    BNE ObjGravity              ; A6B6: D0 2D
    LDA ObjFloorBand,X          ; A6B8: BD B0 04
    STA ObjBandBak,X            ; A6BB: 9D C0 05
    CPX #$01                    ; A6BE: E0 01
    BNE JumpInit                ; A6C0: D0 0B
    LDA ObjState,X              ; A6C2: B5 50
    CMP #$05                    ; A6C4: C9 05
    BNE JumpInit                ; A6C6: D0 05
    LDA #$08                    ; A6C8: A9 08
    JSR $F08E                   ; A6CA: 20 8E F0  -> Bank1:SoundCmd
JumpInit:
    ; Y=$05E5：$A795,Y→$04F0,X（初速）、$A796,Y→$0580,X（重力）、$04E0,X=0；INC $0140,X（滞空标志）
    LDY $05E5                   ; A6CD: AC E5 05
    LDA $A795,Y                 ; A6D0: B9 95 A7
    STA ObjVelY,X               ; A6D3: 9D F0 04
    LDA #$00                    ; A6D6: A9 00
    STA ObjVelYFrac,X           ; A6D8: 9D E0 04
    LDA $A796,Y                 ; A6DB: B9 96 A7
    STA ObjGrav,X               ; A6DE: 9D 80 05
    INC ObjAirFlag,X            ; A6E1: FE 40 01
LA6E4:
    RTS                         ; A6E4: 60
ObjGravity:
    ; $04E0/$04F0,X 16 位 -= $0580,X（重力，$04F0∈[$FE,$00) 不减速=终端速度）；$0460,X -= $04F0,X；≥$E8 非玩家 ClearObject、玩家转 L9855（坠亡）；落地贴 $A2C8[带] Y，玩家跨 ≥4 带跌落受伤（$0510=4、$05FC=$0E、送声 $05/$C6）
    LDA ObjVelY,X               ; A6E5: BD F0 04
    BPL LA6EE                   ; A6E8: 10 04
    CMP #$FE                    ; A6EA: C9 FE
    BCC LA700                   ; A6EC: 90 12
LA6EE:
    LDA ObjVelYFrac,X           ; A6EE: BD E0 04
    SEC                         ; A6F1: 38
    SBC ObjGrav,X               ; A6F2: FD 80 05
    STA ObjVelYFrac,X           ; A6F5: 9D E0 04
    LDA ObjVelY,X               ; A6F8: BD F0 04
    SBC #$00                    ; A6FB: E9 00
    STA ObjVelY,X               ; A6FD: 9D F0 04
LA700:
    LDA ObjY,X                  ; A700: BD 60 04
    SEC                         ; A703: 38
    SBC ObjVelY,X               ; A704: FD F0 04
    STA ObjY,X                  ; A707: 9D 60 04
    LDA StageArea               ; A70A: A5 A3
    CMP #$02                    ; A70C: C9 02
    BCS LA717                   ; A70E: B0 07
    LDA ObjFloorBand,X          ; A710: BD B0 04
    CMP #$02                    ; A713: C9 02
    BCC LA72B                   ; A715: 90 14
LA717:
    LDA ObjState,X              ; A717: B5 50
    CMP #$05                    ; A719: C9 05
    BNE LA72B                   ; A71B: D0 0E
    JSR LA4BB                   ; A71D: 20 BB A4
    BNE LA727                   ; A720: D0 05
    JSR LA4CB                   ; A722: 20 CB A4
    BEQ LA72B                   ; A725: F0 04
LA727:
    LDA #$02                    ; A727: A9 02
    BNE LA78D                   ; A729: D0 62
LA72B:
    LDA ObjY,X                  ; A72B: BD 60 04
    CMP #$E8                    ; A72E: C9 E8
    BCC LA73C                   ; A730: 90 0A
    CPX #$01                    ; A732: E0 01
    BEQ LA739                   ; A734: F0 03
    JMP ClearObject             ; A736: 4C E7 A2
LA739:
    JMP L9855                   ; A739: 4C 55 98
LA73C:
    LDA ObjVelY,X               ; A73C: BD F0 04
    BPL LA794                   ; A73F: 10 53
    LDA ObjType,X               ; A741: B5 60
    CMP #$0C                    ; A743: C9 0C
    BEQ LA794                   ; A745: F0 4D
    LDA ObjProbeA,X             ; A747: BD 20 05
    ORA ObjProbeB,X             ; A74A: 1D 20 01
    BEQ LA794                   ; A74D: F0 45
    LDY ObjFloorBand,X          ; A74F: BC B0 04
    LDA ObjY,X                  ; A752: BD 60 04
    CMP $A2C8,Y                 ; A755: D9 C8 A2
    BCC LA794                   ; A758: 90 3A
    LDA $A2C8,Y                 ; A75A: B9 C8 A2
    STA ObjY,X                  ; A75D: 9D 60 04
    CPX #$01                    ; A760: E0 01
    BNE LA789                   ; A762: D0 25
    LDA ObjFloorBand,X          ; A764: BD B0 04
    SEC                         ; A767: 38
    SBC ObjBandBak,X            ; A768: FD C0 05
    BEQ LA789                   ; A76B: F0 1C
    CMP #$04                    ; A76D: C9 04
    BCC LA789                   ; A76F: 90 18
    CMP #$FD                    ; A771: C9 FD
    BCS LA789                   ; A773: B0 14
    LDA #$04                    ; A775: A9 04
    STA ObjDirFlags,X           ; A777: 9D 10 05
    LDA #$0E                    ; A77A: A9 0E
    STA $05FC                   ; A77C: 8D FC 05
    LDA #$05                    ; A77F: A9 05
    JSR $F08E                   ; A781: 20 8E F0  -> Bank1:SoundCmd
    LDA #$C6                    ; A784: A9 C6
    JSR $F08E                   ; A786: 20 8E F0  -> Bank1:SoundCmd
LA789:
    LDX ObjLoopSlot             ; A789: A6 48
    LDA #$00                    ; A78B: A9 00
LA78D:
    STA ObjState,X              ; A78D: 95 50
    LDA #$00                    ; A78F: A9 00
    STA ObjAirFlag,X            ; A791: 9D 40 01
LA794:
    RTS                         ; A794: 60
    .byte $03,$1C,$05,$24,$FF,$08,$04,$40         ; A795: 03 1C 05 24 FF 08 04 40
    .byte $03,$20,$05,$18,$05,$22                 ; A79D: 03 20 05 18 05 22
AnimSpritePingpong:
    ; 非玩家且类型 0 直返；Y*2 查 $A83A 表→$33/$34：($33) 加 $0440,X，进位按 $0450,X 位7 反向 INC/DEC；&$70 非零清 0，超阈值置位 7 折返；$70,X=($33),Y+帧号
    CPX #$01                    ; A7A3: E0 01
    BEQ LA7AB                   ; A7A5: F0 04
    LDA ObjType,X               ; A7A7: B5 60
    BEQ LA7FA                   ; A7A9: F0 4F
LA7AB:
    TYA                         ; A7AB: 98
    ASL A                       ; A7AC: 0A
    TAY                         ; A7AD: A8
    LDA $A83A,Y                 ; A7AE: B9 3A A8
    STA $33                     ; A7B1: 85 33
    LDA $A83B,Y                 ; A7B3: B9 3B A8
    STA $34                     ; A7B6: 85 34
    LDY #$00                    ; A7B8: A0 00
    LDA ($33),Y                 ; A7BA: B1 33
    BEQ LA7F4                   ; A7BC: F0 36
    INY                         ; A7BE: C8
    CLC                         ; A7BF: 18
    ADC ObjAnimFrac,X           ; A7C0: 7D 40 04
    STA ObjAnimFrac,X           ; A7C3: 9D 40 04
    BCC LA7D5                   ; A7C6: 90 0D
    LDA ObjAnimAcc,X            ; A7C8: BD 50 04
    BMI LA7D2                   ; A7CB: 30 05
    INC ObjAnimAcc,X            ; A7CD: FE 50 04
    BNE LA7D5                   ; A7D0: D0 03
LA7D2:
    DEC ObjAnimAcc,X            ; A7D2: DE 50 04
LA7D5:
    LDA ObjAnimAcc,X            ; A7D5: BD 50 04
    AND #$7F                    ; A7D8: 29 7F
    STA $30                     ; A7DA: 85 30
    AND #$70                    ; A7DC: 29 70
    BEQ LA7E4                   ; A7DE: F0 04
    LDA #$00                    ; A7E0: A9 00
    BEQ LA7EC                   ; A7E2: F0 08
LA7E4:
    LDA ($33),Y                 ; A7E4: B1 33
    CMP $30                     ; A7E6: C5 30
    BCS LA7EF                   ; A7E8: B0 05
    ORA #$80                    ; A7EA: 09 80
LA7EC:
    STA ObjAnimAcc,X            ; A7EC: 9D 50 04
LA7EF:
    LDA ObjAnimAcc,X            ; A7EF: BD 50 04
    AND #$7F                    ; A7F2: 29 7F
LA7F4:
    INY                         ; A7F4: C8
    CLC                         ; A7F5: 18
    ADC ($33),Y                 ; A7F6: 71 33
    STA ObjSprite,X             ; A7F8: 95 70
LA7FA:
    RTS                         ; A7FA: 60
AnimSpriteStep:
    ; X=1 或 $60,X=0 时 RTS；否则 Y*2 取 $A83A 字表→$33/$34，($33),Y 流：字节0 加 $0440/$0450,X 夹阈值，写字节→$70,X
    CPX #$01                    ; A7FB: E0 01
    BEQ LA803                   ; A7FD: F0 04
    LDA ObjType,X               ; A7FF: B5 60
    BEQ LA839                   ; A801: F0 36
LA803:
    TYA                         ; A803: 98
    ASL A                       ; A804: 0A
    TAY                         ; A805: A8
    LDA $A83A,Y                 ; A806: B9 3A A8
    STA $33                     ; A809: 85 33
    LDA $A83B,Y                 ; A80B: B9 3B A8
    STA $34                     ; A80E: 85 34
    LDY #$00                    ; A810: A0 00
    LDA ($33),Y                 ; A812: B1 33
    INY                         ; A814: C8
    CLC                         ; A815: 18
    ADC ObjAnimFrac,X           ; A816: 7D 40 04
    STA ObjAnimFrac,X           ; A819: 9D 40 04
    BCC LA821                   ; A81C: 90 03
    INC ObjAnimAcc,X            ; A81E: FE 50 04
LA821:
    LDA ObjAnimAcc,X            ; A821: BD 50 04
    BMI LA82C                   ; A824: 30 06
    CMP ($33),Y                 ; A826: D1 33
    BCC LA833                   ; A828: 90 09
    BEQ LA833                   ; A82A: F0 07
LA82C:
    LDA #$00                    ; A82C: A9 00
    STA ObjAnimAcc,X            ; A82E: 9D 50 04
    STA $30                     ; A831: 85 30
LA833:
    INY                         ; A833: C8
    CLC                         ; A834: 18
    ADC ($33),Y                 ; A835: 71 33
    STA ObjSprite,X             ; A837: 95 70
LA839:
    RTS                         ; A839: 60
    .byte $74,$A8,$77,$A8,$A7,$A8,$7A,$A8         ; A83A: 74 A8 77 A8 A7 A8 7A A8
    .byte $7D,$A8,$83,$A8,$86,$A8,$89,$A8         ; A842: 7D A8 83 A8 86 A8 89 A8
    .byte $8C,$A8,$8F,$A8,$92,$A8,$95,$A8         ; A84A: 8C A8 8F A8 92 A8 95 A8
    .byte $98,$A8,$9B,$A8,$9E,$A8,$A1,$A8         ; A852: 98 A8 9B A8 9E A8 A1 A8
    .byte $A4,$A8,$AA,$A8,$AD,$A8,$B0,$A8         ; A85A: A4 A8 AA A8 AD A8 B0 A8
    .byte $B3,$A8,$B6,$A8,$B9,$A8,$BC,$A8         ; A862: B3 A8 B6 A8 B9 A8 BC A8
    .byte $C2,$A8,$C8,$A8,$BF,$A8,$C5,$A8         ; A86A: C2 A8 C8 A8 BF A8 C5 A8
    .byte $CB,$A8,$34,$02,$01,$34,$02,$04         ; A872: CB A8 34 02 01 34 02 04
    .byte $28,$01,$09,$20,$01,$15,$08,$01         ; A87A: 28 01 09 20 01 15 08 01
    .byte $1D,$10,$01,$1F,$30,$02,$22,$30         ; A882: 1D 10 01 1F 30 02 22 30
    .byte $02,$25,$06,$01,$28,$20,$01,$2A         ; A88A: 02 25 06 01 28 20 01 2A
    .byte $20,$01,$31,$20,$01,$33,$20,$01         ; A892: 20 01 31 20 01 33 20 01
    .byte $35,$80,$03,$39,$20,$01,$3F,$20         ; A89A: 35 80 03 39 20 01 3F 20
    .byte $01,$41,$28,$01,$44,$10,$01,$0F         ; A8A2: 01 41 28 01 44 10 01 0F
    .byte $30,$01,$46,$30,$01,$48,$40,$01         ; A8AA: 30 01 46 30 01 48 40 01
    .byte $4A,$40,$01,$4C,$10,$01,$4E,$80         ; A8B2: 4A 40 01 4C 10 01 4E 80
    .byte $01,$5E,$38,$04,$54,$20,$01,$62         ; A8BA: 01 5E 38 04 54 20 01 62
    .byte $20,$02,$69,$10,$05,$7C,$08,$01         ; A8C2: 20 02 69 10 05 7C 08 01
    .byte $77,$40,$01,$72                         ; A8CA: 77 40 01 72
LA8CE:
    LDA $05D1                   ; A8CE: AD D1 05
    ORA DeathSeqFlag            ; A8D1: 0D F1 05
    ORA $05F9                   ; A8D4: 0D F9 05
    BNE LA908                   ; A8D7: D0 2F
    LDA $51                     ; A8D9: A5 51
    CMP #$06                    ; A8DB: C9 06
    BEQ LA908                   ; A8DD: F0 29
    LDA #$00                    ; A8DF: A9 00
    STA $0112                   ; A8E1: 8D 12 01
    LDY #$06                    ; A8E4: A0 06
LA8E6:
    LDA ObjType,Y               ; A8E6: B9 60 00
    BEQ LA8F2                   ; A8E9: F0 07
    CMP #$0D                    ; A8EB: C9 0D
    BCS LA8F2                   ; A8ED: B0 03
    INC $0112                   ; A8EF: EE 12 01
LA8F2:
    DEY                         ; A8F2: 88
    CPY #$02                    ; A8F3: C0 02
    BCS LA8E6                   ; A8F5: B0 EF
    LDA $0112                   ; A8F7: AD 12 01
    CMP #$03                    ; A8FA: C9 03
    BCS LA908                   ; A8FC: B0 0A
    CMP #$01                    ; A8FE: C9 01
    BCS LA905                   ; A900: B0 03
    JSR LA9FE                   ; A902: 20 FE A9
LA905:
    JSR DoorProxSpawn           ; A905: 20 68 B8
LA908:
    RTS                         ; A908: 60
DoorContent:
    ; $4A 经 DispatchJump 走 $A90E 表 13 项（种类 0-12：门后内容生成/道具发放；L948（门开）调用）
    LDA ObjKind                 ; A909: A5 4A
    JSR DispatchJump            ; A90B: 20 9A 85
    .byte $33,$A9,$34,$A9,$33,$A9,$33,$A9         ; A90E: 33 A9 34 A9 33 A9 33 A9
    .byte $33,$A9,$95,$A9,$A2,$A9,$CA,$AA         ; A916: 33 A9 95 A9 A2 A9 CA AA
    .byte $CA,$AA,$CA,$AA,$B1,$AA,$33,$A9         ; A91E: CA AA CA AA B1 AA 33 A9
    .byte $A4,$AA                                 ; A926: A4 AA
LA928:
    LDA #$C7                    ; A928: A9 C7
LA92A:
    CMP StageId                 ; A92A: C5 80
    SEC                         ; A92C: 38
    BEQ LA933                   ; A92D: F0 04
    SBC #$0A                    ; A92F: E9 0A
    BCS LA92A                   ; A931: B0 F7
LA933:
    RTS                         ; A933: 60
LA934:
    LDY $40                     ; A934: A4 40
    CPY #$10                    ; A936: C0 10
    BCC LA945                   ; A938: 90 0B
    CPY #$F0                    ; A93A: C0 F0
    BCS LA945                   ; A93C: B0 07
LA93E:
    LDA #$07                    ; A93E: A9 07
    STA ObjKind                 ; A940: 85 4A
    JMP LAACA                   ; A942: 4C CA AA
LA945:
    LDA #$01                    ; A945: A9 01
    JSR LA967                   ; A947: 20 67 A9
    LDA TypeCount               ; A94A: A5 4E
    CMP #$02                    ; A94C: C9 02
    BCS LA93E                   ; A94E: B0 EE
    LDY PowerLevel              ; A950: A4 1D
    BNE LA958                   ; A952: D0 04
    CMP #$01                    ; A954: C9 01
    BCS LA93E                   ; A956: B0 E6
LA958:
    JSR LAACA                   ; A958: 20 CA AA
    INC $0114                   ; A95B: EE 14 01
    LDA $0114                   ; A95E: AD 14 01
    AND #$03                    ; A961: 29 03
    STA ObjVariant,X            ; A963: 9D 50 05
    RTS                         ; A966: 60
LA967:
    LDY #$00                    ; A967: A0 00
    STY TypeCount               ; A969: 84 4E
    LDY #$06                    ; A96B: A0 06
LA96D:
    CMP ObjType,Y               ; A96D: D9 60 00
    BNE LA974                   ; A970: D0 02
    INC TypeCount               ; A972: E6 4E
LA974:
    DEY                         ; A974: 88
    CPY #$02                    ; A975: C0 02
    BCS LA96D                   ; A977: B0 F4
    RTS                         ; A979: 60
LA97A:
    LDY #$00                    ; A97A: A0 00
    STY TypeCount               ; A97C: 84 4E
    LDY #$06                    ; A97E: A0 06
LA980:
    LDA ObjType,Y               ; A980: B9 60 00
    BEQ LA98F                   ; A983: F0 0A
    LDA ObjFloorBand,X          ; A985: BD B0 04
    CMP ObjFloorBand,Y          ; A988: D9 B0 04
    BNE LA98F                   ; A98B: D0 02
    INC TypeCount               ; A98D: E6 4E
LA98F:
    DEY                         ; A98F: 88
    CPY #$02                    ; A990: C0 02
    BCS LA980                   ; A992: B0 EC
    RTS                         ; A994: 60
LA995:
    JSR LA9BB                   ; A995: 20 BB A9
    LDY ObjFloorBand,X          ; A998: BC B0 04
    LDA $A2C8,Y                 ; A99B: B9 C8 A2
    STA $04BE                   ; A99E: 8D BE 04
    RTS                         ; A9A1: 60
LA9A2:
    LDA ObjFloorBand,X          ; A9A2: BD B0 04
    CMP $04B1                   ; A9A5: CD B1 04
    BNE LA9B7                   ; A9A8: D0 0D
    JSR LA9BB                   ; A9AA: 20 BB A9
    LDA ObjY,X                  ; A9AD: BD 60 04
    SEC                         ; A9B0: 38
    SBC $A9B8,Y                 ; A9B1: F9 B8 A9
    STA $04BE                   ; A9B4: 8D BE 04
LA9B7:
    RTS                         ; A9B7: 60
    .byte $22,$12,$12                             ; A9B8: 22 12 12
LA9BB:
    LDA $7E                     ; A9BB: A5 7E
    BEQ SpawnRescued            ; A9BD: F0 03
    PLA                         ; A9BF: 68
    PLA                         ; A9C0: 68
    RTS                         ; A9C1: 60
SpawnRescued:
    ; InitObjByKind 后续写：$0410,X→$041E（槽 $0E 跨页）、$7E=$64、$0460,X+$12→$046E、$0470,X→$047E、$6E=$30；INC $011D 按 &7/&3 轮转 $0550,X 服装；门开救人（L9C12 等）
    JSR InitObjByKind           ; A9C2: 20 D8 AA
    LDA ObjXPage,X              ; A9C5: BD 10 04
    STA $041E                   ; A9C8: 8D 1E 04
    LDA #$64                    ; A9CB: A9 64
    STA $7E                     ; A9CD: 85 7E
    LDA ObjY,X                  ; A9CF: BD 60 04
    CLC                         ; A9D2: 18
    ADC #$12                    ; A9D3: 69 12
    STA ObjY,X                  ; A9D5: 9D 60 04
    STA $046E                   ; A9D8: 8D 6E 04
    LDA ObjX,X                  ; A9DB: BD 70 04
    STA $047E                   ; A9DE: 8D 7E 04
    LDA #$30                    ; A9E1: A9 30
    STA $6E                     ; A9E3: 85 6E
    INC $011D                   ; A9E5: EE 1D 01
    LDY #$01                    ; A9E8: A0 01
    LDA $011D                   ; A9EA: AD 1D 01
    AND #$07                    ; A9ED: 29 07
    BEQ LA9F9                   ; A9EF: F0 08
    LDY #$02                    ; A9F1: A0 02
    AND #$03                    ; A9F3: 29 03
    BEQ LA9F9                   ; A9F5: F0 02
    LDY #$00                    ; A9F7: A0 00
LA9F9:
    TYA                         ; A9F9: 98
    STA ObjVariant,X            ; A9FA: 9D 50 05
LA9FD:
    RTS                         ; A9FD: 60
LA9FE:
    LDY StageArea               ; A9FE: A4 A3
    CPY #$04                    ; AA00: C0 04
    BCC LA9FD                   ; AA02: 90 F9
    LDA PowerLevel              ; AA04: A5 1D
    BNE LAA0D                   ; AA06: D0 05
    LDA FrameCnt                ; AA08: A5 09
    LSR A                       ; AA0A: 4A
    BCS LA9FD                   ; AA0B: B0 F0
LAA0D:
    DEC $011C                   ; AA0D: CE 1C 01
    BNE LA9FD                   ; AA10: D0 EB
    JSR FindFreeObjLo           ; AA12: 20 64 AB
    BCC LA9FD                   ; AA15: 90 E6
    JSR LAB94                   ; AA17: 20 94 AB
    LDA $0511                   ; AA1A: AD 11 05
    BEQ LAA2B                   ; AA1D: F0 0C
    LDY #$00                    ; AA1F: A0 00
    LDA $0471                   ; AA21: AD 71 04
    CMP #$80                    ; AA24: C9 80
    BCS LAA29                   ; AA26: B0 01
    INY                         ; AA28: C8
LAA29:
    BNE LAA30                   ; AA29: D0 05
LAA2B:
    LDA FrameCnt                ; AA2B: A5 09
    AND #$03                    ; AA2D: 29 03
    TAY                         ; AA2F: A8
LAA30:
    LDA $AA45,Y                 ; AA30: B9 45 AA
    STA ObjX,X                  ; AA33: 9D 70 04
    JSR FacePlayer              ; AA36: 20 0F A2
    STA ObjMoveDir,X            ; AA39: 9D A0 04
    LDY #$0B                    ; AA3C: A0 0B
    STY ObjKind                 ; AA3E: 84 4A
    LDA #$40                    ; AA40: A9 40
    JMP LAACC                   ; AA42: 4C CC AA
    .byte $E0,$20,$40,$C0                         ; AA45: E0 20 40 C0
LAA49:
    LDA ObjType,X               ; AA49: B5 60
    CMP #$07                    ; AA4B: C9 07
    BNE LAA99                   ; AA4D: D0 4A
    LDY #$07                    ; AA4F: A0 07
    LDA PowerLevel              ; AA51: A5 1D
    BEQ LAA57                   ; AA53: F0 02
    LDY #$01                    ; AA55: A0 01
LAA57:
    STY $37                     ; AA57: 84 37
    INC $0119                   ; AA59: EE 19 01
    LDY #$02                    ; AA5C: A0 02
    LDA $0119                   ; AA5E: AD 19 01
    AND #$1F                    ; AA61: 29 1F
    BEQ LAA6B                   ; AA63: F0 06
    DEY                         ; AA65: 88
    AND $37                     ; AA66: 25 37
    BEQ LAA6B                   ; AA68: F0 01
    DEY                         ; AA6A: 88
LAA6B:
    LDA $AAA1,Y                 ; AA6B: B9 A1 AA
    STA ObjAttr,X               ; AA6E: 9D 20 04
    LDA $AA9A,Y                 ; AA71: B9 9A AA
    STA ObjVariant,X            ; AA74: 9D 50 05
    LDY #$03                    ; AA77: A0 03
    LDA PowerLevel              ; AA79: A5 1D
    AND #$FC                    ; AA7B: 29 FC
    BNE LAA81                   ; AA7D: D0 02
    LDY PowerLevel              ; AA7F: A4 1D
LAA81:
    LDA $AA9D,Y                 ; AA81: B9 9D AA
LAA84:
    STA $37                     ; AA84: 85 37
    CPY #$0D                    ; AA86: C0 0D
    BCS LAA94                   ; AA88: B0 0A
    LDA $0119                   ; AA8A: AD 19 01
    LSR A                       ; AA8D: 4A
    BCC LAA94                   ; AA8E: 90 04
    DEC $37                     ; AA90: C6 37
    DEC $37                     ; AA92: C6 37
LAA94:
    LDA $37                     ; AA94: A5 37
    STA ObjSpeedX,X             ; AA96: 9D C0 04
LAA99:
    RTS                         ; AA99: 60
    .byte $00,$01,$02,$0A,$0C,$0E,$10,$00         ; AA9A: 00 01 02 0A 0C 0E 10 00
    .byte $01,$02                                 ; AAA2: 01 02
LAAA4:
    LDY ObjFloorBand,X          ; AAA4: BC B0 04
    CPY #$08                    ; AAA7: C0 08
    BEQ InitObjByKind           ; AAA9: F0 2D
    LDA #$09                    ; AAAB: A9 09
    STA ObjKind                 ; AAAD: 85 4A
    BNE LAACA                   ; AAAF: D0 19
LAAB1:
    INC $011B                   ; AAB1: EE 1B 01
    LDA $011B                   ; AAB4: AD 1B 01
    AND #$01                    ; AAB7: 29 01
    TAY                         ; AAB9: A8
    LDA $AAC8,Y                 ; AABA: B9 C8 AA
    CLC                         ; AABD: 18
    ADC ObjY,X                  ; AABE: 7D 60 04
    STA ObjY,X                  ; AAC1: 9D 60 04
    LDA #$40                    ; AAC4: A9 40
    BNE LAACC                   ; AAC6: D0 04
    BEQ $AAB2                   ; AAC8: F0 E8
LAACA:
    LDA #$20                    ; AACA: A9 20
LAACC:
    STA ObjTimer,X              ; AACC: 9D 30 04
    BNE InitObjByKind           ; AACF: D0 07
InitObjByKindY:
    LDA #$00                    ; AAD1: A9 00
    STA ObjXPage,X              ; AAD3: 9D 10 04
    BEQ LAADF                   ; AAD6: F0 07
InitObjByKind:
    ; 清 $0410,X 后 LDY $4A 入 LAADF：$ABD6,Y→$04D0,X（Y 速索引）、$ABD9,Y 经 LAA84→$04C0,X（X 速索引，困难 -2）、$ABEA,Y→$60,X、$AC2E,Y→$0570,X、$ABFB,Y 选直写/标志法取 $AC1D,Y→$70,X，LAB0C 清 $0140/$0550 后 LAB14 补尾
    LDA #$00                    ; AAD8: A9 00
    STA ObjXPage,X              ; AADA: 9D 10 04
    LDY ObjKind                 ; AADD: A4 4A
LAADF:
    STY ObjKind                 ; AADF: 84 4A
    LDA $ABD6,Y                 ; AAE1: B9 D6 AB
    STA ObjSpeedY,X             ; AAE4: 9D D0 04
    LDA $ABD9,Y                 ; AAE7: B9 D9 AB
    JSR LAA84                   ; AAEA: 20 84 AA
    LDA $ABEA,Y                 ; AAED: B9 EA AB
    STA ObjType,X               ; AAF0: 95 60
    LDA $AC2E,Y                 ; AAF2: B9 2E AC
    STA ObjBoxProf,X            ; AAF5: 9D 70 05
    LDA $ABFB,Y                 ; AAF8: B9 FB AB
    BNE LAB05                   ; AAFB: D0 08
    LDA $AC1D,Y                 ; AAFD: B9 1D AC
    STA ObjSprite,X             ; AB00: 95 70
    JMP LAB0C                   ; AB02: 4C 0C AB
LAB05:
    LDA $AC1D,Y                 ; AB05: B9 1D AC
    TAY                         ; AB08: A8
    JSR SetSpriteByFlag         ; AB09: 20 04 95
LAB0C:
    LDA #$00                    ; AB0C: A9 00
    STA ObjAirFlag,X            ; AB0E: 9D 40 01
    STA ObjVariant,X            ; AB11: 9D 50 05
LAB14:
    LDA #$FF                    ; AB14: A9 FF
    STA ObjRecLink,X            ; AB16: 9D 30 05
    LDA #$0C                    ; AB19: A9 0C
    LDY ObjType,X               ; AB1B: B4 60
    CPY #$0D                    ; AB1D: C0 0D
    BCC LAB27                   ; AB1F: 90 06
    CPY #$12                    ; AB21: C0 12
    BCS LAB27                   ; AB23: B0 02
    LDA #$00                    ; AB25: A9 00
LAB27:
    STA ObjShieldT,X            ; AB27: 9D B0 05
    LDA $AC0C,Y                 ; AB2A: B9 0C AC
    STA ObjState,X              ; AB2D: 95 50
    LDA #$00                    ; AB2F: A9 00
    STA ObjPhase,X              ; AB31: 9D 40 05
    STA ObjAttr,X               ; AB34: 9D 20 04
    RTS                         ; AB37: 60
SpawnObjAtSlot:
    ; 存 $37=类型/$3F=精灵，LABAE 定位（按 $16/$04A1 选位）；$70,X=$3F、$60,X=$37、$0570,X=$0A，LAB14 补 $0530=$FF/$05B0/初始 $50,X；LB595（生成流入口）调用
    STA $37                     ; AB38: 85 37
    STY $3F                     ; AB3A: 84 3F
    JSR LABAE                   ; AB3C: 20 AE AB
    LDA $3F                     ; AB3F: A5 3F
    STA ObjSprite,X             ; AB41: 95 70
    LDA $37                     ; AB43: A5 37
    STA ObjType,X               ; AB45: 95 60
LAB47:
    LDA #$0A                    ; AB47: A9 0A
    STA ObjBoxProf,X            ; AB49: 9D 70 05
    JSR LAB14                   ; AB4C: 20 14 AB
    LDA ObjType,X               ; AB4F: B5 60
    CMP #$11                    ; AB51: C9 11
    BCC LAB59                   ; AB53: 90 04
    LDA #$00                    ; AB55: A9 00
    STA ObjState,X              ; AB57: 95 50
LAB59:
    RTS                         ; AB59: 60
FindFreeObjHi:
    ; X=$0D..$0B 扫 $60,X==0 空槽：找到 SEC（LAb78）、未找 CLC；LB6F8（钥匙开门生成）调用
    STA $37                     ; AB5A: 85 37
    LDX #$0B                    ; AB5C: A2 0B
    STX $3E                     ; AB5E: 86 3E
    LDX #$0D                    ; AB60: A2 0D
    BNE LAB6C                   ; AB62: D0 08
FindFreeObjLo:
    ; X=$06..$02 扫空槽（敌人槽段）；LB239/LB2A6/LAA12/LB8E4 调用
    STA $37                     ; AB64: 85 37
    LDX #$02                    ; AB66: A2 02
    STX $3E                     ; AB68: 86 3E
    LDX #$06                    ; AB6A: A2 06
LAB6C:
    LDA ObjType,X               ; AB6C: B5 60
    BEQ LAB78                   ; AB6E: F0 08
    DEX                         ; AB70: CA
    CPX $3E                     ; AB71: E4 3E
    BCS LAB6C                   ; AB73: B0 F7
    LDA $37                     ; AB75: A5 37
    RTS                         ; AB77: 60
LAB78:
    LDA $37                     ; AB78: A5 37
    SEC                         ; AB7A: 38
    RTS                         ; AB7B: 60
FindFreeObjEx:
    ; X=$0B..$09 扫 $60,X==0 或 ==$17（可顶替）槽；LB590（门/道具生成）调用
    STA $37                     ; AB7C: 85 37
    LDX #$0B                    ; AB7E: A2 0B
LAB80:
    LDA ObjType,X               ; AB80: B5 60
    BEQ LAB78                   ; AB82: F0 F4
    CMP #$17                    ; AB84: C9 17
    BEQ LAB78                   ; AB86: F0 F0
    DEX                         ; AB88: CA
    CPX #$09                    ; AB89: E0 09
    BCS LAB80                   ; AB8B: B0 F3
    LDA $37                     ; AB8D: A5 37
    RTS                         ; AB8F: 60
LAB90:
    LDY $41                     ; AB90: A4 41
    BPL LAB97                   ; AB92: 10 03
LAB94:
    LDY $04B1                   ; AB94: AC B1 04
LAB97:
    LDA $ABA5,Y                 ; AB97: B9 A5 AB
    STA ObjFloorBand,X          ; AB9A: 9D B0 04
    TAY                         ; AB9D: A8
    LDA $A2C8,Y                 ; AB9E: B9 C8 A2
    STA ObjY,X                  ; ABA1: 9D 60 04
    RTS                         ; ABA4: 60
    .byte $00,$01,$02,$03,$04,$05,$06,$07         ; ABA5: 00 01 02 03 04 05 06 07
    .byte $08                                     ; ABAD: 08
LABAE:
    JSR LAB90                   ; ABAE: 20 90 AB
    LDA $16                     ; ABB1: A5 16
    BEQ LABC1                   ; ABB3: F0 0C
    LDA $40                     ; ABB5: A5 40
    STA ObjX,X                  ; ABB7: 9D 70 04
    LDA #$00                    ; ABBA: A9 00
    STA ObjXPage,X              ; ABBC: 9D 10 04
    BEQ LABD2                   ; ABBF: F0 11
LABC1:
    LDA #$00                    ; ABC1: A9 00
    STA ObjX,X                  ; ABC3: 9D 70 04
    LDY $04A1                   ; ABC6: AC A1 04
    CPY #$02                    ; ABC9: C0 02
    BEQ LABCF                   ; ABCB: F0 02
    LDA #$01                    ; ABCD: A9 01
LABCF:
    STA ObjXPage,X              ; ABCF: 9D 10 04
LABD2:
    JSR FacePlayer              ; ABD2: 20 0F A2
    RTS                         ; ABD5: 60
    .byte $0A,$06,$06,$10,$0E,$0A,$0C,$0C         ; ABD6: 0A 06 06 10 0E 0A 0C 0C
    .byte $0A,$14,$10,$08,$06,$10,$12,$10         ; ABDE: 0A 14 10 08 06 10 12 10
    .byte $18,$16,$18,$1C,$00,$01,$02,$03         ; ABE6: 18 16 18 1C 00 01 02 03
    .byte $04,$05,$06,$07,$08,$09,$0A,$0B         ; ABEE: 04 05 06 07 08 09 0A 0B
    .byte $0C,$0D,$0E,$0F,$10,$01,$01,$01         ; ABF6: 0C 0D 0E 0F 10 01 01 01
    .byte $01,$01,$01,$01,$01,$01,$00,$00         ; ABFE: 01 01 01 01 01 01 00 00
    .byte $01,$01,$01,$00,$00,$00,$00,$00         ; AC06: 01 01 01 00 00 00 00 00
    .byte $00,$00,$00,$03,$03,$03,$00,$03         ; AC0E: 00 00 00 03 03 03 00 03
    .byte $03,$00,$00,$00,$00,$00,$00,$07         ; AC16: 03 00 00 00 00 00 00 07
    .byte $28,$28,$1D,$77,$3F,$3F,$7C,$4A         ; AC1E: 28 28 1D 77 3F 3F 7C 4A
    .byte $7C,$44,$50,$52,$3F,$00,$00,$00         ; AC26: 7C 44 50 52 3F 00 00 00
    .byte $03,$03,$03,$03,$03,$03,$01,$02         ; AC2E: 03 03 03 03 03 03 01 02
    .byte $02,$02,$01,$02,$02,$00,$00,$00         ; AC36: 02 02 01 02 02 00 00 00
    .byte $01,$47,$AC,$59,$AC,$69,$AC,$79         ; AC3E: 01 47 AC 59 AC 69 AC 79
    .byte $AC,$00,$01,$01,$01,$01,$01,$01         ; AC46: AC 00 01 01 01 01 01 01
    .byte $01,$01,$01,$01,$01,$01,$01,$01         ; AC4E: 01 01 01 01 01 01 01 01
    .byte $01,$00,$00,$00,$01,$01,$00,$00         ; AC56: 01 00 00 00 01 01 00 00
    .byte $01,$01,$01,$01,$01,$01,$00,$01         ; AC5E: 01 01 01 01 01 01 00 01
    .byte $01,$01,$00,$00,$01,$01,$00,$00         ; AC66: 01 01 00 00 01 01 00 00
    .byte $01,$01,$01,$01,$01,$01,$01,$01         ; AC6E: 01 01 01 01 01 01 01 01
    .byte $01,$01,$00,$01,$01,$01,$00,$00         ; AC76: 01 01 00 01 01 01 00 00
    .byte $01,$01,$01,$01,$01,$01,$01,$01         ; AC7E: 01 01 01 01 01 01 01 01
    .byte $01,$01,$01                             ; AC86: 01 01 01
AttackHitScan:
    ; X=1 玩家：$50,X≠6/1 且 $05F4≠0 时按 $0430,X≥8 选攻击 0/1；X=7 弹弓存活→攻击 2；X=8 炸弹 $0540≥2 且 $0430<$68→攻击 3；各经 AttackBoxRun
    LDX #$01                    ; AC89: A2 01
    LDA ObjState,X              ; AC8B: B5 50
    CMP #$06                    ; AC8D: C9 06
    BEQ LACE4                   ; AC8F: F0 53
    CMP #$01                    ; AC91: C9 01
    BEQ LACC0                   ; AC93: F0 2B
    LDA AttackFlag              ; AC95: AD F4 05
    BEQ LACB9                   ; AC98: F0 1F
    LDA #$09                    ; AC9A: A9 09
    STA ObjBoxProf,X            ; AC9C: 9D 70 05
    LDA ObjTimer,X              ; AC9F: BD 30 04
    CMP #$08                    ; ACA2: C9 08
    BCC LACB9                   ; ACA4: 90 13
    LDA #$06                    ; ACA6: A9 06
    LDY ObjMoveDir,X            ; ACA8: BC A0 04
    CPY #$01                    ; ACAB: C0 01
    BEQ LACB1                   ; ACAD: F0 02
    LDA #$07                    ; ACAF: A9 07
LACB1:
    STA ObjBoxProf,X            ; ACB1: 9D 70 05
    LDA #$01                    ; ACB4: A9 01
    JSR AttackBoxRun            ; ACB6: 20 E5 AC
LACB9:
    LDX #$01                    ; ACB9: A2 01
    LDA #$00                    ; ACBB: A9 00
    JSR AttackBoxRun            ; ACBD: 20 E5 AC
LACC0:
    LDX #$07                    ; ACC0: A2 07
    LDA ObjType,X               ; ACC2: B5 60
    BEQ LACCB                   ; ACC4: F0 05
    LDA #$02                    ; ACC6: A9 02
    JSR AttackBoxRun            ; ACC8: 20 E5 AC
LACCB:
    LDX #$08                    ; ACCB: A2 08
    LDA ObjType,X               ; ACCD: B5 60
    BEQ LACE4                   ; ACCF: F0 13
    LDA ObjPhase,X              ; ACD1: BD 40 05
    CMP #$02                    ; ACD4: C9 02
    BCC LACE4                   ; ACD6: 90 0C
    LDA ObjTimer,X              ; ACD8: BD 30 04
    CMP #$68                    ; ACDB: C9 68
    BCS LACE4                   ; ACDD: B0 05
    LDA #$03                    ; ACDF: A9 03
    JSR AttackBoxRun            ; ACE1: 20 E5 AC
LACE4:
    RTS                         ; ACE4: 60
AttackBoxRun:
    ; A=攻击 id 存 $05FE；*2 查 $AC3F→$33/$34 可击类型表；$0570,X 经 HitBoxBuild（Y=0）建攻击盒，$05F0 存攻方槽；LAD06 循环 X=$0D..0：跨页/免疫（状态 1/3）/类型越界跳过，($33)[类型]=0 跳过，HitBoxBuild（Y=4）+HitBoxTest/2 命中转 HitReact
    LDY ObjXPage,X              ; ACE5: BC 10 04
    BNE LACE4                   ; ACE8: D0 FA
    STA AttackId                ; ACEA: 8D FE 05
    ASL A                       ; ACED: 0A
    TAY                         ; ACEE: A8
    LDA $AC3F,Y                 ; ACEF: B9 3F AC
    STA $33                     ; ACF2: 85 33
    LDA $AC40,Y                 ; ACF4: B9 40 AC
    STA $34                     ; ACF7: 85 34
    LDA ObjBoxProf,X            ; ACF9: BD 70 05
    LDY #$00                    ; ACFC: A0 00
    JSR HitBoxBuild             ; ACFE: 20 7A A3
    STX $05F0                   ; AD01: 8E F0 05
    LDX #$0D                    ; AD04: A2 0D
LAD06:
    STX ObjLoopSlot             ; AD06: 86 48
    LDA ObjXPage,X              ; AD08: BD 10 04
    BNE LAD58                   ; AD0B: D0 4B
    LDY ObjType,X               ; AD0D: B4 60
    BNE LAD15                   ; AD0F: D0 04
    CPX #$01                    ; AD11: E0 01
    BNE LAD58                   ; AD13: D0 43
LAD15:
    LDA AttackId                ; AD15: AD FE 05
    BEQ LAD20                   ; AD18: F0 06
    CPY #$10                    ; AD1A: C0 10
    BCS LAD58                   ; AD1C: B0 3A
    BCC LAD32                   ; AD1E: 90 12
LAD20:
    CPY #$1E                    ; AD20: C0 1E
    BCS LAD58                   ; AD22: B0 34
    LDA ObjShieldT,X            ; AD24: BD B0 05
    BEQ LAD2E                   ; AD27: F0 05
    DEC ObjShieldT,X            ; AD29: DE B0 05
    BNE LAD58                   ; AD2C: D0 2A
LAD2E:
    CPY #$12                    ; AD2E: C0 12
    BCS LAD40                   ; AD30: B0 0E
LAD32:
    LDA ($33),Y                 ; AD32: B1 33
    BEQ LAD58                   ; AD34: F0 22
    LDA ObjState,X              ; AD36: B5 50
    CMP #$01                    ; AD38: C9 01
    BEQ LAD58                   ; AD3A: F0 1C
    CMP #$03                    ; AD3C: C9 03
    BEQ LAD58                   ; AD3E: F0 18
LAD40:
    LDA ObjBoxProf,X            ; AD40: BD 70 05
    LDY #$04                    ; AD43: A0 04
    JSR HitBoxBuild             ; AD45: 20 7A A3
    CPX #$09                    ; AD48: E0 09
    BCS LAD53                   ; AD4A: B0 07
    JSR HitBoxTest              ; AD4C: 20 1D A3
    BCS HitReact                ; AD4F: B0 5E
    BCC LAD58                   ; AD51: 90 05
LAD53:
    JSR HitBoxTest2             ; AD53: 20 61 A3
    BCS HitReact                ; AD56: B0 57
LAD58:
    LDX ObjLoopSlot             ; AD58: A6 48
    DEX                         ; AD5A: CA
    BPL LAD06                   ; AD5B: 10 A9
    LDA AttackId                ; AD5D: AD FE 05
    BNE LAD86                   ; AD60: D0 24
    LDX #$04                    ; AD62: A2 04
LAD64:
    LDA OamBuf,X                ; AD64: BD 00 02
    CMP #$F4                    ; AD67: C9 F4
    BEQ LAD7B                   ; AD69: F0 10
    ADC #$06                    ; AD6B: 69 06
    STA $2D                     ; AD6D: 85 2D
    LDA $0203,X                 ; AD6F: BD 03 02
    ADC #$04                    ; AD72: 69 04
    STA $2F                     ; AD74: 85 2F
    JSR HitBoxTest2             ; AD76: 20 61 A3
    BCS LAD87                   ; AD79: B0 0C
LAD7B:
    TXA                         ; AD7B: 8A
    CLC                         ; AD7C: 18
    ADC #$04                    ; AD7D: 69 04
    CMP #$40                    ; AD7F: C9 40
    BCS LAD86                   ; AD81: B0 03
    TAX                         ; AD83: AA
    BNE LAD64                   ; AD84: D0 DE
LAD86:
    RTS                         ; AD86: 60
LAD87:
    LDY $0201,X                 ; AD87: BC 01 02
    LDA #$04                    ; AD8A: A9 04
    CPY #$ED                    ; AD8C: C0 ED
    BEQ LAD98                   ; AD8E: F0 08
    LDA #$01                    ; AD90: A9 01
    CPY #$74                    ; AD92: C0 74
    BEQ LAD98                   ; AD94: F0 02
    LDA #$02                    ; AD96: A9 02
LAD98:
    AND EquipBits               ; AD98: 25 49
    BNE LADA1                   ; AD9A: D0 05
    LDY #$12                    ; AD9C: A0 12
    JMP LAE45                   ; AD9E: 4C 45 AE
LADA1:
    RTS                         ; ADA1: 60
LADA2:
    LDA $05D1                   ; ADA2: AD D1 05
    ORA DeathSeqCnt             ; ADA5: 0D DD 05
    BNE LADAE                   ; ADA8: D0 04
    LDA #$01                    ; ADAA: A9 01
    STA $51                     ; ADAC: 85 51
LADAE:
    RTS                         ; ADAE: 60
HitReact:
    ; $05FE==0（拳）：$60,X 经 DispatchJump 走 $ADB9 表 30 项（按类型反应：灭/变身/僵直）；≠0：攻击 3 且 X=1 玩家受爆风（LADA2）；攻击 2 清槽 7 弹丸；类型<$0F 送 $AE34 音效；LA301 置态 1
    LDA AttackId                ; ADAF: AD FE 05
    BNE LADF5                   ; ADB2: D0 41
    LDA ObjType,X               ; ADB4: B5 60
    JSR DispatchJump            ; ADB6: 20 9A 85
    .byte $8E,$AE,$7F,$AE,$7F,$AE,$8F,$AE         ; ADB9: 8E AE 7F AE 7F AE 8F AE
    .byte $8F,$AE,$7F,$AE,$86,$AE,$7F,$AE         ; ADC1: 8F AE 7F AE 86 AE 7F AE
    .byte $7F,$AE,$7F,$AE,$86,$AE,$7F,$AE         ; ADC9: 7F AE 7F AE 86 AE 7F AE
    .byte $7F,$AE,$F6,$AF,$DA,$AF,$DA,$AF         ; ADD1: 7F AE F6 AF DA AF DA AF
    .byte $8E,$AE,$8E,$AE,$44,$AF,$D1,$AE         ; ADD9: 8E AE 8E AE 44 AF D1 AE
    .byte $DC,$AE,$8E,$AE,$27,$AF,$51,$AF         ; ADE1: DC AE 8E AE 27 AF 51 AF
    .byte $AA,$AF,$B7,$AF,$78,$AF,$8E,$AE         ; ADE9: AA AF B7 AF 78 AF 8E AE
    .byte $0C,$AF,$FF,$AE                         ; ADF1: 0C AF FF AE
LADF5:
    LDA AttackId                ; ADF5: AD FE 05
    CMP #$03                    ; ADF8: C9 03
    BNE LAE0B                   ; ADFA: D0 0F
    CPX #$01                    ; ADFC: E0 01
    BNE LAE2F                   ; ADFE: D0 2F
    LDA ObjState,X              ; AE00: B5 50
    CMP #$01                    ; AE02: C9 01
    BEQ LADAE                   ; AE04: F0 A8
    CMP #$06                    ; AE06: C9 06
    BNE LADA2                   ; AE08: D0 98
    RTS                         ; AE0A: 60
LAE0B:
    CMP #$02                    ; AE0B: C9 02
    BNE LAE16                   ; AE0D: D0 07
    LDX #$07                    ; AE0F: A2 07
    JSR ClearObject             ; AE11: 20 E7 A2
    LDX ObjLoopSlot             ; AE14: A6 48
LAE16:
    LDY ObjType,X               ; AE16: B4 60
    CPY #$0F                    ; AE18: C0 0F
    BCS LAE2F                   ; AE1A: B0 13
    LDA $AE34,Y                 ; AE1C: B9 34 AE
    CPY #$05                    ; AE1F: C0 05
    BEQ LAE27                   ; AE21: F0 04
    CPY #$06                    ; AE23: C0 06
    BNE LAE2C                   ; AE25: D0 05
LAE27:
    JSR $F08E                   ; AE27: 20 8E F0  -> Bank1:SoundCmd
    LDA #$D3                    ; AE2A: A9 D3
LAE2C:
    JSR $F08E                   ; AE2C: 20 8E F0  -> Bank1:SoundCmd
LAE2F:
    LDA #$01                    ; AE2F: A9 01
    JMP LA301                   ; AE31: 4C 01 A3
    .byte $00,$0F,$0E,$00,$00,$12,$12,$11         ; AE34: 00 0F 0E 00 00 12 12 11
    .byte $10,$0E,$0E,$0E,$0E,$0E,$0E             ; AE3C: 10 0E 0E 0E 0E 0E 0E
PlayerDamage:
    ; Y=$60,X（LAE45 直入点）：$05DD|$05D1|$05F6 非零跳过；$9F=$1D*2+$AE6C,Y（带符号血量增量），$05F6=$50、清 $0421、送声 $1D；LAD9E（OAM 静态物触碰）/LAEDB 等调用
    LDY ObjType,X               ; AE43: B4 60
LAE45:
    LDA DeathSeqCnt             ; AE45: AD DD 05
    ORA $05D1                   ; AE48: 0D D1 05
    BNE LAE6A                   ; AE4B: D0 1D
    LDA InvincibleT             ; AE4D: AD F6 05
    BNE LAE6A                   ; AE50: D0 18
    LDA PowerLevel              ; AE52: A5 1D
    ASL A                       ; AE54: 0A
    CLC                         ; AE55: 18
    ADC $AE6C,Y                 ; AE56: 79 6C AE
    STA HpDelta                 ; AE59: 85 9F
    LDA #$50                    ; AE5B: A9 50
    STA InvincibleT             ; AE5D: 8D F6 05
    LDA #$00                    ; AE60: A9 00
    STA $0421                   ; AE62: 8D 21 04
    LDA #$1D                    ; AE65: A9 1D
    JSR $F08E                   ; AE67: 20 8E F0  -> Bank1:SoundCmd
LAE6A:
    CLC                         ; AE6A: 18
    RTS                         ; AE6B: 60
    .byte $00,$84,$88,$00,$00,$85,$82,$82         ; AE6C: 00 84 88 00 00 85 82 82
    .byte $81,$82,$81,$83,$82,$85,$84,$88         ; AE74: 81 82 81 83 82 85 84 88
    .byte $85,$81,$84                             ; AE7C: 85 81 84
LAE7F:
    LDA DeathSeqCnt             ; AE7F: AD DD 05
    BNE LAE16                   ; AE82: D0 92
    BEQ PlayerDamage            ; AE84: F0 BD
LAE86:
    LDA DeathSeqCnt             ; AE86: AD DD 05
    BNE LAE16                   ; AE89: D0 8B
    JMP LAFED                   ; AE8B: 4C ED AF
LAE8E:
    RTS                         ; AE8E: 60
LAE8F:
    LDA $51                     ; AE8F: A5 51
    BNE LAE8E                   ; AE91: D0 FB
    LDY ObjPhase,X              ; AE93: BC 40 05
    DEY                         ; AE96: 88
    BNE LAE8E                   ; AE97: D0 F5
    STY $05D0                   ; AE99: 8C D0 05
    INC $05D6                   ; AE9C: EE D6 05
    INC $05F8                   ; AE9F: EE F8 05
    LDA ObjType,X               ; AEA2: B5 60
    CMP #$04                    ; AEA4: C9 04
    BEQ LAEC4                   ; AEA6: F0 1C
    LDA $05F8                   ; AEA8: AD F8 05
    CMP #$04                    ; AEAB: C9 04
    BEQ LAEB9                   ; AEAD: F0 0A
    JSR InitSound               ; AEAF: 20 14 86
    LDY #$2B                    ; AEB2: A0 2B
    JSR SoundCmd80              ; AEB4: 20 22 86
    BCS LAEBE                   ; AEB7: B0 05
LAEB9:
    LDY #$1F                    ; AEB9: A0 1F
    JSR SoundCmdC0              ; AEBB: 20 1C 86
LAEBE:
    JSR LAEF2                   ; AEBE: 20 F2 AE
    JMP L9C86                   ; AEC1: 4C 86 9C
LAEC4:
    JSR InitSound               ; AEC4: 20 14 86
    LDY #$24                    ; AEC7: A0 24
    JSR SoundCmd80              ; AEC9: 20 22 86
    INC ObjPhase,X              ; AECC: FE 40 05
    BCS LAEF2                   ; AECF: B0 21
LAED1:
    LDY #$08                    ; AED1: A0 08
    STY HpDelta                 ; AED3: 84 9F
    LDA #$20                    ; AED5: A9 20
    JSR $F08E                   ; AED7: 20 8E F0  -> Bank1:SoundCmd
    BCS LAEEF                   ; AEDA: B0 13
LAEDC:
    LDA $46                     ; AEDC: A5 46
    CLC                         ; AEDE: 18
    ADC #$01                    ; AEDF: 69 01
    CMP #$80                    ; AEE1: C9 80
    BCS LAEE7                   ; AEE3: B0 02
    STA $46                     ; AEE5: 85 46
LAEE7:
    JSR InitSound               ; AEE7: 20 14 86
    LDY #$29                    ; AEEA: A0 29
    JSR SoundCmd80              ; AEEC: 20 22 86
LAEEF:
    JSR ClearObject             ; AEEF: 20 E7 A2
LAEF2:
    LDY ObjRecLink,X            ; AEF2: BC 30 05
    CPY #$FF                    ; AEF5: C0 FF
    BEQ LAEFE                   ; AEF7: F0 05
    LDA #$FF                    ; AEF9: A9 FF
    STA DoorSlotLk,Y            ; AEFB: 99 D0 07
LAEFE:
    RTS                         ; AEFE: 60
LAEFF:
    JSR LAEF2                   ; AEFF: 20 F2 AE
    LDA #$1A                    ; AF02: A9 1A
    JSR $F08E                   ; AF04: 20 8E F0  -> Bank1:SoundCmd
    LDY #$0B                    ; AF07: A0 0B
    JMP TransformObj            ; AF09: 4C 90 9C
LAF0C:
    INC KeyCount                ; AF0C: EE DF 05
    INC $05F8                   ; AF0F: EE F8 05
    LDA $05F8                   ; AF12: AD F8 05
    CMP #$04                    ; AF15: C9 04
    BNE LAF20                   ; AF17: D0 07
    LDY #$1F                    ; AF19: A0 1F
    JSR SoundCmdC0              ; AF1B: 20 1C 86
    BCS LAEEF                   ; AF1E: B0 CF
LAF20:
    LDA #$1A                    ; AF20: A9 1A
    JSR $F08E                   ; AF22: 20 8E F0  -> Bank1:SoundCmd
    BCS LAEEF                   ; AF25: B0 C8
LAF27:
    LDY ObjVariant,X            ; AF27: BC 50 05
    LDA $CECE,Y                 ; AF2A: B9 CE CE
    ORA EquipBits               ; AF2D: 05 49
    STA EquipBits               ; AF2F: 85 49
    LDA $AF3C,Y                 ; AF31: B9 3C AF
    JSR $EC07                   ; AF34: 20 07 EC  -> Bank1:DrawHudItem
    LDA #$19                    ; AF37: A9 19
    JMP LAF98                   ; AF39: 4C 98 AF
    .byte $02,$03,$04,$05,$06,$07,$08,$00         ; AF3C: 02 03 04 05 06 07 08 00
LAF44:
    JSR InitSound               ; AF44: 20 14 86
    LDY #$29                    ; AF47: A0 29
    JSR SoundCmd80              ; AF49: 20 22 86
    LDY #$04                    ; AF4C: A0 04
    JMP TransformObj            ; AF4E: 4C 90 9C
LAF51:
    INC $05D8                   ; AF51: EE D8 05
    LDA $05D8                   ; AF54: AD D8 05
    AND #$1F                    ; AF57: 29 1F
    BNE LAF5D                   ; AF59: D0 02
    INC $93                     ; AF5B: E6 93
LAF5D:
    LDY #$02                    ; AF5D: A0 02
    LDA $05D8                   ; AF5F: AD D8 05
    AND #$07                    ; AF62: 29 07
    BNE LAF6E                   ; AF64: D0 08
    LDA #$18                    ; AF66: A9 18
    STA HpDelta                 ; AF68: 85 9F
    LDA #$20                    ; AF6A: A9 20
    BNE LAF70                   ; AF6C: D0 02
LAF6E:
    LDA #$18                    ; AF6E: A9 18
LAF70:
    JSR $F08E                   ; AF70: 20 8E F0  -> Bank1:SoundCmd
    LDX ObjLoopSlot             ; AF73: A6 48
    JMP TransformObj            ; AF75: 4C 90 9C
LAF78:
    LDA #$03                    ; AF78: A9 03
    STA DeathSeqCnt             ; AF7A: 8D DD 05
    LDA PlayerHp                ; AF7D: A5 A0
    LDY #$03                    ; AF7F: A0 03
LAF81:
    CMP $AF9E,Y                 ; AF81: D9 9E AF
    BCS LAF89                   ; AF84: B0 03
    DEY                         ; AF86: 88
    BNE LAF81                   ; AF87: D0 F8
LAF89:
    LDA $AFA2,Y                 ; AF89: B9 A2 AF
    STA $4C                     ; AF8C: 85 4C
    LDA $AFA6,Y                 ; AF8E: B9 A6 AF
    STA $4B                     ; AF91: 85 4B
    JSR InitSound               ; AF93: 20 14 86
    LDA #$19                    ; AF96: A9 19
LAF98:
    JSR $F08E                   ; AF98: 20 8E F0  -> Bank1:SoundCmd
    JMP ClearObject             ; AF9B: 4C E7 A2
    .byte $00,$06,$0C,$12,$00,$02,$03,$03         ; AF9E: 00 06 0C 12 00 02 03 03
    .byte $E2,$02,$22,$E2                         ; AFA6: E2 02 22 E2
LAFAA:
    LDY #$32                    ; AFAA: A0 32
    STY SlingAmmo               ; AFAC: 8C F2 05
    LDA #$09                    ; AFAF: A9 09
    JSR LAFCE                   ; AFB1: 20 CE AF
    JMP LAEF2                   ; AFB4: 4C F2 AE
LAFB7:
    LDY #$00                    ; AFB7: A0 00
    LDX BombAmmo                ; AFB9: AE F3 05
    BEQ LAFC8                   ; AFBC: F0 0A
    LDA EquipBits               ; AFBE: A5 49
    AND #$10                    ; AFC0: 29 10
    BEQ LAFEC                   ; AFC2: F0 28
    CPX #$02                    ; AFC4: E0 02
    BCS LAFEC                   ; AFC6: B0 24
LAFC8:
    INC BombAmmo                ; AFC8: EE F3 05
    LDA $AFD8,X                 ; AFCB: BD D8 AF
LAFCE:
    LDX ObjLoopSlot             ; AFCE: A6 48
    JSR $EC07                   ; AFD0: 20 07 EC  -> Bank1:DrawHudItem
    LDA #$19                    ; AFD3: A9 19
    JMP LAF98                   ; AFD5: 4C 98 AF
    .byte $01,$00                                 ; AFD8: 01 00
LAFDA:
    JSR LAFED                   ; AFDA: 20 ED AF
    LDA #$00                    ; AFDD: A9 00
    STA ObjSprite,X             ; AFDF: 95 70
    STA ObjType,X               ; AFE1: 95 60
    STA ObjPhase,X              ; AFE3: 9D 40 05
    LDY ObjParent,X             ; AFE6: BC 60 05
    STA ObjPhase,Y              ; AFE9: 99 40 05
LAFEC:
    RTS                         ; AFEC: 60
LAFED:
    LDA EquipBits               ; AFED: A5 49
    AND #$20                    ; AFEF: 29 20
    BNE LAFEC                   ; AFF1: D0 F9
    JMP PlayerDamage            ; AFF3: 4C 43 AE
LAFF6:
    JSR LAFED                   ; AFF6: 20 ED AF
    LDA ObjPhase,X              ; AFF9: BD 40 05
    CMP #$02                    ; AFFC: C9 02
    BEQ LAFEC                   ; AFFE: F0 EC
    JMP LB1C4                   ; B000: 4C C4 B1
LB003:
    LDA ObjState,X              ; B003: B5 50
    CMP #$04                    ; B005: C9 04
    BEQ LB03E                   ; B007: F0 35
    CMP #$01                    ; B009: C9 01
    BEQ LB03E                   ; B00B: F0 31
    CMP #$06                    ; B00D: C9 06
    BEQ LB03E                   ; B00F: F0 2D
    JSR LB04D                   ; B011: 20 4D B0
    LDA BombActive              ; B014: A5 94
    BNE LB03E                   ; B016: D0 26
    JSR LB0A9                   ; B018: 20 A9 B0
    LDA AttackFlag              ; B01B: AD F4 05
    BNE LB028                   ; B01E: D0 08
    LDA SlingAmmo               ; B020: AD F2 05
    ORA $05D7                   ; B023: 0D D7 05
    BNE LB03E                   ; B026: D0 16
LB028:
    LDX ObjLoopSlot             ; B028: A6 48
    LDA AttackFlag              ; B02A: AD F4 05
    BNE LB03F                   ; B02D: D0 10
    LDA ObjActFlags,X           ; B02F: BD 00 05
    AND #$40                    ; B032: 29 40
    BEQ LB03E                   ; B034: F0 08
    LDA #$10                    ; B036: A9 10
    STA ObjTimer,X              ; B038: 9D 30 04
LB03B:
    STA AttackFlag              ; B03B: 8D F4 05
LB03E:
    RTS                         ; B03E: 60
LB03F:
    LDY #$0B                    ; B03F: A0 0B
    JSR SetSpriteByFlag         ; B041: 20 04 95
    LDA ObjTimer,X              ; B044: BD 30 04
    BEQ LB03B                   ; B047: F0 F2
    DEC ObjTimer,X              ; B049: DE 30 04
LB04C:
    RTS                         ; B04C: 60
LB04D:
    LDA BombAmmo                ; B04D: AD F3 05
    BEQ LB04C                   ; B050: F0 FA
    LDA $0501                   ; B052: AD 01 05
    AND #$40                    ; B055: 29 40
    BEQ LB04C                   ; B057: F0 F3
    LDA $0511                   ; B059: AD 11 05
    AND #$04                    ; B05C: 29 04
    BEQ LB04C                   ; B05E: F0 EC
    LDX #$08                    ; B060: A2 08
    LDY ObjPhase,X              ; B062: BC 40 05
    BNE LB04C                   ; B065: D0 E5
    INC ObjPhase,X              ; B067: FE 40 05
    LDA #$70                    ; B06A: A9 70
    STA ObjTimer,X              ; B06C: 9D 30 04
    LDA #$08                    ; B06F: A9 08
    LDY $04A1                   ; B071: AC A1 04
    CPY #$01                    ; B074: C0 01
    BEQ LB07A                   ; B076: F0 02
    LDA #$F8                    ; B078: A9 F8
LB07A:
    ADC $0471                   ; B07A: 6D 71 04
    STA ObjX,X                  ; B07D: 9D 70 04
    LDA $0461                   ; B080: AD 61 04
    STA ObjY,X                  ; B083: 9D 60 04
    LDA #$11                    ; B086: A9 11
    STA ObjType,X               ; B088: 95 60
    LDA #$05                    ; B08A: A9 05
    STA ObjBoxProf,X            ; B08C: 9D 70 05
    LDA #$00                    ; B08F: A9 00
    STA ObjXPage,X              ; B091: 9D 10 04
    INC BombActive              ; B094: E6 94
    LDX #$00                    ; B096: A2 00
    DEC BombAmmo                ; B098: CE F3 05
    LDA BombAmmo                ; B09B: AD F3 05
    BEQ LB0A1                   ; B09E: F0 01
    INX                         ; B0A0: E8
LB0A1:
    LDA $AFD8,X                 ; B0A1: BD D8 AF
    ORA #$80                    ; B0A4: 09 80
    JMP $EC07                   ; B0A6: 4C 07 EC  -> Bank1:DrawHudItem
LB0A9:
    LDA SlingAmmo               ; B0A9: AD F2 05
    BEQ LB0B5                   ; B0AC: F0 07
    LDX #$07                    ; B0AE: A2 07
    LDY ObjPhase,X              ; B0B0: BC 40 05
    BEQ LB0B6                   ; B0B3: F0 01
LB0B5:
    RTS                         ; B0B5: 60
LB0B6:
    LDA $0501                   ; B0B6: AD 01 05
    AND #$40                    ; B0B9: 29 40
    BEQ LB0B5                   ; B0BB: F0 F8
    LDA #$0C                    ; B0BD: A9 0C
    JSR $F08E                   ; B0BF: 20 8E F0  -> Bank1:SoundCmd
    LDY ObjLoopSlot             ; B0C2: A4 48
    LDA ObjMoveDir,Y            ; B0C4: B9 A0 04
    STA ObjDirFlags,X           ; B0C7: 9D 10 05
    LDA #$00                    ; B0CA: A9 00
    JSR ProjPosInit             ; B0CC: 20 F1 B2
    LDA #$10                    ; B0CF: A9 10
    STA ObjKind                 ; B0D1: 85 4A
    JSR InitObjByKind           ; B0D3: 20 D8 AA
    INC ObjPhase,X              ; B0D6: FE 40 05
    LDA #$14                    ; B0D9: A9 14
    STA $05D7                   ; B0DB: 8D D7 05
    LDX #$01                    ; B0DE: A2 01
    LDY #$11                    ; B0E0: A0 11
    JSR SetSpriteByFlag         ; B0E2: 20 04 95
    DEC SlingAmmo               ; B0E5: CE F2 05
    BEQ LB0EF                   ; B0E8: F0 05
    LDA #$09                    ; B0EA: A9 09
    JMP $EC07                   ; B0EC: 4C 07 EC  -> Bank1:DrawHudItem
LB0EF:
    LDA #$89                    ; B0EF: A9 89
    JMP $EC07                   ; B0F1: 4C 07 EC  -> Bank1:DrawHudItem
LB0F4:
    LDY ObjPhase,X              ; B0F4: BC 40 05
    BEQ LB146                   ; B0F7: F0 4D
    LDA #$59                    ; B0F9: A9 59
    STA ObjSprite,X             ; B0FB: 95 70
    BNE LB134                   ; B0FD: D0 35
LB0FF:
    LDY #$00                    ; B0FF: A0 00
    STY ProjKind                ; B101: 8C EE 05
    LDA ObjState,X              ; B104: B5 50
    BEQ LB10B                   ; B106: F0 03
    JMP ClearObject             ; B108: 4C E7 A2
LB10B:
    LDY ObjPhase,X              ; B10B: BC 40 05
    BEQ LB147                   ; B10E: F0 37
    DEY                         ; B110: 88
    BEQ LB157                   ; B111: F0 44
    LDA #$5A                    ; B113: A9 5A
    STA ObjSprite,X             ; B115: 95 70
    BNE LB134                   ; B117: D0 1B
LB119:
    LDY #$01                    ; B119: A0 01
    STY ProjKind                ; B11B: 8C EE 05
    LDA ObjState,X              ; B11E: B5 50
    CMP #$00                    ; B120: C9 00
    BEQ LB127                   ; B122: F0 03
    JMP ObjExpireTick           ; B124: 4C 4F 9C
LB127:
    LDY ObjPhase,X              ; B127: BC 40 05
    BEQ LB147                   ; B12A: F0 1B
    DEY                         ; B12C: 88
    BEQ LB157                   ; B12D: F0 28
    LDY #$0D                    ; B12F: A0 0D
    JSR AnimSpriteStep          ; B131: 20 FB A7
LB134:
    JSR PlayerContactScan       ; B134: 20 53 B7
    BCS LB143                   ; B137: B0 0A
    LDA ObjX,X                  ; B139: BD 70 04
    AND #$F0                    ; B13C: 29 F0
    BEQ LB143                   ; B13E: F0 03
    JMP ObjWalkByDir            ; B140: 4C 34 95
LB143:
    JMP ClearObject             ; B143: 4C E7 A2
LB146:
    RTS                         ; B146: 60
LB147:
    LDY ObjParent,X             ; B147: BC 60 05
    LDA ObjState,Y              ; B14A: B9 50 00
    CMP #$01                    ; B14D: C9 01
    BEQ LB143                   ; B14F: F0 F2
    DEC ObjAnimFrac,X           ; B151: DE 40 04
    BEQ LB160                   ; B154: F0 0A
    RTS                         ; B156: 60
LB157:
    LDY ProjKind                ; B157: AC EE 05
    LDA $B32D,Y                 ; B15A: B9 2D B3
    JSR $F08E                   ; B15D: 20 8E F0  -> Bank1:SoundCmd
LB160:
    INC ObjPhase,X              ; B160: FE 40 05
    RTS                         ; B163: 60
LB164:
    LDA ObjState,X              ; B164: B5 50
    CMP #$00                    ; B166: C9 00
    BEQ LB178                   ; B168: F0 0E
    LDY ObjPhase,X              ; B16A: BC 40 05
    BEQ LB172                   ; B16D: F0 03
    JMP L9C57                   ; B16F: 4C 57 9C
LB172:
    JSR LB1B8                   ; B172: 20 B8 B1
    JMP L9C5D                   ; B175: 4C 5D 9C
LB178:
    LDY ObjPhase,X              ; B178: BC 40 05
    BEQ LB1CB                   ; B17B: F0 4E
    DEY                         ; B17D: 88
    BEQ LB1A1                   ; B17E: F0 21
    LDY ObjParent,X             ; B180: BC 60 05
    LDA ObjMoveDir,Y            ; B183: B9 A0 04
    AND #$01                    ; B186: 29 01
    BNE LB18E                   ; B188: D0 04
    LDA #$41                    ; B18A: A9 41
    BNE LB190                   ; B18C: D0 02
LB18E:
    LDA #$3F                    ; B18E: A9 3F
LB190:
    STA ObjSprite,X             ; B190: 95 70
    JSR ObjWalkByDir            ; B192: 20 34 95
    LDY ObjParent,X             ; B195: BC 60 05
    LDA ObjX,X                  ; B198: BD 70 04
    CMP ObjX,Y                  ; B19B: D9 70 04
    BEQ LB1B5                   ; B19E: F0 15
    RTS                         ; B1A0: 60
LB1A1:
    LDY #$0E                    ; B1A1: A0 0E
    JSR AnimPingpongByDir       ; B1A3: 20 29 95
    JSR ObjWalkByDir            ; B1A6: 20 34 95
    JSR PlayerContactScan       ; B1A9: 20 53 B7
    BCS LB1C4                   ; B1AC: B0 16
    LDA ObjX,X                  ; B1AE: BD 70 04
    AND #$F0                    ; B1B1: 29 F0
    BNE LB1CA                   ; B1B3: D0 15
LB1B5:
    JSR ClearObject             ; B1B5: 20 E7 A2
LB1B8:
    LDY ObjParent,X             ; B1B8: BC 60 05
    LDA #$00                    ; B1BB: A9 00
    STA ObjState,Y              ; B1BD: 99 50 00
    STA ObjPhase,Y              ; B1C0: 99 40 05
    RTS                         ; B1C3: 60
LB1C4:
    JSR LA1D2                   ; B1C4: 20 D2 A1
LB1C7:
    INC ObjPhase,X              ; B1C7: FE 40 05
LB1CA:
    RTS                         ; B1CA: 60
LB1CB:
    DEC ObjAnimFrac,X           ; B1CB: DE 40 04
    BEQ LB1C7                   ; B1CE: F0 F7
LB1D0:
    RTS                         ; B1D0: 60
LB1D1:
    LDY ObjPhase,X              ; B1D1: BC 40 05
    BEQ LB1D0                   ; B1D4: F0 FA
    DEY                         ; B1D6: 88
    BEQ LB1E7                   ; B1D7: F0 0E
    LDY #$17                    ; B1D9: A0 17
    JSR AnimSpriteStep          ; B1DB: 20 FB A7
    DEC ObjTimer,X              ; B1DE: DE 30 04
    BEQ LB1E4                   ; B1E1: F0 01
    RTS                         ; B1E3: 60
LB1E4:
    JMP ClearObject             ; B1E4: 4C E7 A2
LB1E7:
    LDA #$00                    ; B1E7: A9 00
    STA BombActive              ; B1E9: 85 94
    JSR ObjStepY                ; B1EB: 20 E4 A4
    BNE LB1FA                   ; B1EE: D0 0A
    LDA ObjY,X                  ; B1F0: BD 60 04
    CMP #$D8                    ; B1F3: C9 D8
    BCS LB1E4                   ; B1F5: B0 ED
    INC ObjY,X                  ; B1F7: FE 60 04
LB1FA:
    LDY #$16                    ; B1FA: A0 16
    JSR AnimSpriteStep          ; B1FC: 20 FB A7
    DEC ObjTimer,X              ; B1FF: DE 30 04
    BNE LB1D0                   ; B202: D0 CC
    LDY #$04                    ; B204: A0 04
    JSR SoundCmd80              ; B206: 20 22 86
    LDA #$70                    ; B209: A9 70
    STA ObjTimer,X              ; B20B: 9D 30 04
    JMP LA2D1                   ; B20E: 4C D1 A2
ObjThrowProj:
    ; $50,X==0 且 $0550,X==0→LB32F；$0500,X 位6 时 FindFreeObjLo：父子槽 $0560 互链、朝向继承、$B323[$05EE] 组参发弹（ObjThrowProj 族，$9EA9 调用）
    LDA ObjState,X              ; B211: B5 50
    BNE LB27F                   ; B213: D0 6A
    LDA ObjVariant,X            ; B215: BD 50 05
    BNE LB21D                   ; B218: D0 03
    JMP LB32F                   ; B21A: 4C 2F B3
LB21D:
    LDA #$00                    ; B21D: A9 00
    STA ProjKind                ; B21F: 8D EE 05
    LDY ObjPhase,X              ; B222: BC 40 05
    BEQ LB232                   ; B225: F0 0B
    DEC ObjTimer,X              ; B227: DE 30 04
    BNE LB27F                   ; B22A: D0 53
LB22C:
    LDA #$00                    ; B22C: A9 00
    STA ObjPhase,X              ; B22E: 9D 40 05
    RTS                         ; B231: 60
LB232:
    LDA ObjActFlags,X           ; B232: BD 00 05
    AND #$40                    ; B235: 29 40
    BEQ LB27F                   ; B237: F0 46
    JSR FindFreeObjLo           ; B239: 20 64 AB
    BCC LB27F                   ; B23C: 90 41
    LDY ObjLoopSlot             ; B23E: A4 48
    TXA                         ; B240: 8A
    STA ObjParent,Y             ; B241: 99 60 05
    TYA                         ; B244: 98
    STA ObjParent,X             ; B245: 9D 60 05
    LDA ObjMoveDir,Y            ; B248: B9 A0 04
    STA ObjDirFlags,X           ; B24B: 9D 10 05
    LDY ProjKind                ; B24E: AC EE 05
    LDA $B323,Y                 ; B251: B9 23 B3
    STA ObjAnimFrac,X           ; B254: 9D 40 04
    LDA $B329,Y                 ; B257: B9 29 B3
    LDY ObjLoopSlot             ; B25A: A4 48
    JSR ProjPosInit             ; B25C: 20 F1 B2
    LDY ProjKind                ; B25F: AC EE 05
    LDA $B32B,Y                 ; B262: B9 2B B3
    STA ObjKind                 ; B265: 85 4A
    JSR InitObjByKind           ; B267: 20 D8 AA
    LDY ProjKind                ; B26A: AC EE 05
    LDX ObjLoopSlot             ; B26D: A6 48
    LDA $B325,Y                 ; B26F: B9 25 B3
    STA ObjTimer,X              ; B272: 9D 30 04
    LDA $B327,Y                 ; B275: B9 27 B3
    TAY                         ; B278: A8
    JSR SetSpriteByFlag         ; B279: 20 04 95
    INC ObjPhase,X              ; B27C: FE 40 05
LB27F:
    RTS                         ; B27F: 60
ObjThrowProj2:
    ; $0550,X 位0=0 变体（$05EE=1）：头顶 $0460,Y-$10 发弹、精灵 $3F/$41 按朝向；$9ED8 调用
    LDA ObjVariant,X            ; B280: BD 50 05
    LSR A                       ; B283: 4A
    BCC LB289                   ; B284: 90 03
    JMP LB299                   ; B286: 4C 99 B2
LB289:
    LDA #$01                    ; B289: A9 01
    STA ProjKind                ; B28B: 8D EE 05
    LDY ObjPhase,X              ; B28E: BC 40 05
    BEQ LB232                   ; B291: F0 9F
    DEC ObjTimer,X              ; B293: DE 30 04
    BEQ LB22C                   ; B296: F0 94
    RTS                         ; B298: 60
LB299:
    LDY ObjPhase,X              ; B299: BC 40 05
    BEQ LB29F                   ; B29C: F0 01
LB29E:
    RTS                         ; B29E: 60
LB29F:
    LDA ObjActFlags,X           ; B29F: BD 00 05
    AND #$40                    ; B2A2: 29 40
    BEQ LB29E                   ; B2A4: F0 F8
    JSR FindFreeObjLo           ; B2A6: 20 64 AB
    BCC LB29E                   ; B2A9: 90 F3
    LDY ObjLoopSlot             ; B2AB: A4 48
    TXA                         ; B2AD: 8A
    STA ObjParent,Y             ; B2AE: 99 60 05
    LDA ObjMoveDir,Y            ; B2B1: B9 A0 04
    STA ObjDirFlags,X           ; B2B4: 9D 10 05
    TYA                         ; B2B7: 98
    STA ObjParent,X             ; B2B8: 9D 60 05
    LDA ObjX,Y                  ; B2BB: B9 70 04
    STA ObjX,X                  ; B2BE: 9D 70 04
    LDA ObjY,Y                  ; B2C1: B9 60 04
    SBC #$10                    ; B2C4: E9 10
    STA ObjY,X                  ; B2C6: 9D 60 04
    LDA #$1E                    ; B2C9: A9 1E
    STA ObjAnimFrac,X           ; B2CB: 9D 40 04
    LDY #$0D                    ; B2CE: A0 0D
    STY ObjKind                 ; B2D0: 84 4A
    JSR InitObjByKind           ; B2D2: 20 D8 AA
    LDY ObjParent,X             ; B2D5: BC 60 05
    LDA ObjMoveDir,Y            ; B2D8: B9 A0 04
    AND #$01                    ; B2DB: 29 01
    BNE LB2E3                   ; B2DD: D0 04
    LDA #$41                    ; B2DF: A9 41
    BNE LB2E5                   ; B2E1: D0 02
LB2E3:
    LDA #$3F                    ; B2E3: A9 3F
LB2E5:
    STA ObjSprite,X             ; B2E5: 95 70
    LDX ObjLoopSlot             ; B2E7: A6 48
    LDY #$3D                    ; B2E9: A0 3D
    JSR SetSpriteByFlag         ; B2EB: 20 04 95
    JMP LA2D1                   ; B2EE: 4C D1 A2
ProjPosInit:
    ; X=弹型索引：$B31A,X+$0460,Y→$41（Y 出生位），$B31D,X*2+朝向位+$0470,Y→弹丸 $0470；LB0CC/LB25C 调用
    STX $3E                     ; B2F1: 86 3E
    TAX                         ; B2F3: AA
    LDA $B31A,X                 ; B2F4: BD 1A B3
    CLC                         ; B2F7: 18
    ADC ObjY,Y                  ; B2F8: 79 60 04
    STA $41                     ; B2FB: 85 41
    TXA                         ; B2FD: 8A
    ASL A                       ; B2FE: 0A
    TAX                         ; B2FF: AA
    LDA ObjMoveDir,Y            ; B300: B9 A0 04
    AND #$01                    ; B303: 29 01
    BNE LB308                   ; B305: D0 01
    INX                         ; B307: E8
LB308:
    LDA $B31D,X                 ; B308: BD 1D B3
    CLC                         ; B30B: 18
    ADC ObjX,Y                  ; B30C: 79 70 04
    LDX $3E                     ; B30F: A6 3E
    STA ObjX,X                  ; B311: 9D 70 04
    LDA $41                     ; B314: A5 41
    STA ObjY,X                  ; B316: 9D 60 04
    RTS                         ; B319: 60
    .byte $F6,$EF,$F0,$00,$00,$0C,$F4,$0A         ; B31A: F6 EF F0 00 00 0C F4 0A
    .byte $F6,$20,$10,$60,$10,$2C,$37,$01         ; B322: F6 20 10 60 10 2C 37 01
    .byte $02,$0F,$0E,$0B,$0A                     ; B32A: 02 0F 0E 0B 0A
LB32F:
    LDY ObjPhase,X              ; B32F: BC 40 05
    BEQ LB33F                   ; B332: F0 0B
    DEC ObjTimer,X              ; B334: DE 30 04
    BNE LB375                   ; B337: D0 3C
    LDA #$00                    ; B339: A9 00
    STA ObjPhase,X              ; B33B: 9D 40 05
    RTS                         ; B33E: 60
LB33F:
    LDA ObjActFlags,X           ; B33F: BD 00 05
    AND #$40                    ; B342: 29 40
    BEQ LB375                   ; B344: F0 2F
    LDA ObjXPage,X              ; B346: BD 10 04
    BNE LB375                   ; B349: D0 2A
    LDA #$F0                    ; B34B: A9 F0
    LDY #$04                    ; B34D: A0 04
LB34F:
    CMP OamBuf,Y                ; B34F: D9 00 02
    BCS LB375                   ; B352: B0 21
    INY                         ; B354: C8
    INY                         ; B355: C8
    INY                         ; B356: C8
    INY                         ; B357: C8
    CPY #$1C                    ; B358: C0 1C
    BCC LB34F                   ; B35A: 90 F3
    STX $05E2                   ; B35C: 8E E2 05
    LDA #$2E                    ; B35F: A9 2E
    STA ObjSprite,X             ; B361: 95 70
    LDA #$10                    ; B363: A9 10
    STA FloatScoreTtl           ; B365: 8D E4 05
    LDA #$40                    ; B368: A9 40
    STA ObjTimer,X              ; B36A: 9D 30 04
    LDA #$01                    ; B36D: A9 01
    STA FloatScoreSta           ; B36F: 8D E3 05
    STA ObjPhase,X              ; B372: 9D 40 05
LB375:
    RTS                         ; B375: 60
LB376:
    LDX $05E2                   ; B376: AE E2 05
    LDY FloatScoreSta           ; B379: AC E3 05
    BEQ LB398                   ; B37C: F0 1A
    DEY                         ; B37E: 88
    BEQ LB3D2                   ; B37F: F0 51
    DEY                         ; B381: 88
    BEQ FloatScoreDrift         ; B382: F0 15
HideOamSlots1to6:
    ; $05E3=0；Y=4 起步 4 循环 OamBuf,Y=$F4 至 Y=$1C（槽 1-6 隐藏）；bank1 $CB59 JSR
    LDA #$00                    ; B384: A9 00
    STA FloatScoreSta           ; B386: 8D E3 05
    LDY #$04                    ; B389: A0 04
    LDA #$F4                    ; B38B: A9 F4
LB38D:
    STA OamBuf,Y                ; B38D: 99 00 02
    INY                         ; B390: C8
    INY                         ; B391: C8
    INY                         ; B392: C8
    INY                         ; B393: C8
    CPY #$1C                    ; B394: C0 1C
    BCC LB38D                   ; B396: 90 F5
LB398:
    RTS                         ; B398: 60
FloatScoreDrift:
    ; $05E4 归零转 LB419（INC $05E3）；OAM 槽 1-6：Y≠$F4 则 X 按 $B41D,X 漂移、Y 按 $B41D,X+1 漂移，X 出 $08-$F8 或 Y 出界藏 $F4
    DEC FloatScoreTtl           ; B399: CE E4 05
    BEQ LB419                   ; B39C: F0 7B
    LDY #$04                    ; B39E: A0 04
    LDX #$00                    ; B3A0: A2 00
LB3A2:
    LDA OamBuf,Y                ; B3A2: B9 00 02
    CMP #$F4                    ; B3A5: C9 F4
    BCS LB3B0                   ; B3A7: B0 07
    CLC                         ; B3A9: 18
    ADC $B41D,X                 ; B3AA: 7D 1D B4
    STA OamBuf,Y                ; B3AD: 99 00 02
LB3B0:
    INX                         ; B3B0: E8
    INY                         ; B3B1: C8
    INY                         ; B3B2: C8
    INY                         ; B3B3: C8
    LDA OamBuf,Y                ; B3B4: B9 00 02
    CLC                         ; B3B7: 18
    ADC $B41D,X                 ; B3B8: 7D 1D B4
    STA OamBuf,Y                ; B3BB: 99 00 02
    CMP #$08                    ; B3BE: C9 08
    BCC LB3C6                   ; B3C0: 90 04
    CMP #$F8                    ; B3C2: C9 F8
    BCC LB3CB                   ; B3C4: 90 05
LB3C6:
    LDA #$F4                    ; B3C6: A9 F4
    STA $01FD,Y                 ; B3C8: 99 FD 01
LB3CB:
    INX                         ; B3CB: E8
    INY                         ; B3CC: C8
    CPY #$1C                    ; B3CD: C0 1C
    BCC LB3A2                   ; B3CF: 90 D1
    RTS                         ; B3D1: 60
LB3D2:
    LDA ObjState,X              ; B3D2: B5 50
    CMP #$01                    ; B3D4: C9 01
    BEQ HideOamSlots1to6        ; B3D6: F0 AC
    DEC FloatScoreTtl           ; B3D8: CE E4 05
    BEQ FloatScoreShow          ; B3DB: F0 0C
    LDA ObjXPage,X              ; B3DD: BD 10 04
    BNE HideOamSlots1to6        ; B3E0: D0 A2
    LDA ObjState,X              ; B3E2: B5 50
    CMP #$01                    ; B3E4: C9 01
    BEQ HideOamSlots1to6        ; B3E6: F0 9C
    RTS                         ; B3E8: 60
FloatScoreShow:
    ; OAM 槽 1-6 填四元组：Y=$0460,X-$10、tile $74、attr 1、X=$0470,X；$05E4=$20、送声 $0D；LB375（命中得分）路径
    LDA ObjY,X                  ; B3E9: BD 60 04
    ADC #$F0                    ; B3EC: 69 F0
    STA $41                     ; B3EE: 85 41
    LDY #$04                    ; B3F0: A0 04
LB3F2:
    LDA $41                     ; B3F2: A5 41
    STA OamBuf,Y                ; B3F4: 99 00 02
    INY                         ; B3F7: C8
    LDA #$74                    ; B3F8: A9 74
    STA OamBuf,Y                ; B3FA: 99 00 02
    INY                         ; B3FD: C8
    LDA #$01                    ; B3FE: A9 01
    STA OamBuf,Y                ; B400: 99 00 02
    INY                         ; B403: C8
    LDA ObjX,X                  ; B404: BD 70 04
    STA OamBuf,Y                ; B407: 99 00 02
    INY                         ; B40A: C8
    CPY #$1C                    ; B40B: C0 1C
    BCC LB3F2                   ; B40D: 90 E3
    LDA #$20                    ; B40F: A9 20
    STA FloatScoreTtl           ; B411: 8D E4 05
    LDA #$0D                    ; B414: A9 0D
    JSR $F08E                   ; B416: 20 8E F0  -> Bank1:SoundCmd
LB419:
    INC FloatScoreSta           ; B419: EE E3 05
    RTS                         ; B41C: 60
    .byte $02,$FE,$00,$FD,$FE,$FE,$FE,$02         ; B41D: 02 FE 00 FD FE FE FE 02
    .byte $00,$03,$02,$02                         ; B425: 00 03 02 02
DoorOpenScan:
    ; $05E0=1；X=$60 倒扫记录环：id $18-$2F（门类）且门环 $07C0,Y==3（已开）且 $07D8,Y≠0 且 $07D0,Y 链槽匹配，则 LB475 按动作号分发（$B4F7 表）
    LDA #$01                    ; B429: A9 01
    STA $05E0                   ; B42B: 8D E0 05
    LDX #$60                    ; B42E: A2 60
LB430:
    STX RecCur                  ; B430: 8E E2 07
    LDA $0702,X                 ; B433: BD 02 07
    BMI LB46A                   ; B436: 30 32
    SEC                         ; B438: 38
    SBC #$18                    ; B439: E9 18
    BCC LB46A                   ; B43B: 90 2D
    CMP #$18                    ; B43D: C9 18
    BCS LB46A                   ; B43F: B0 29
    AND #$07                    ; B441: 29 07
    TAY                         ; B443: A8
    LDA DoorRing,Y              ; B444: B9 C0 07
    CMP #$03                    ; B447: C9 03
    BNE LB46A                   ; B449: D0 1F
    STY DoorCur                 ; B44B: 8C E1 07
    LDA DoorTimer,Y             ; B44E: B9 D8 07
    BEQ LB46A                   ; B451: F0 17
    LDA DoorSlotLk,Y            ; B453: B9 D0 07
    CMP #$FF                    ; B456: C9 FF
    BEQ LB46A                   ; B458: F0 10
    TAX                         ; B45A: AA
    LDA ObjType,X               ; B45B: B5 60
    BEQ LB467                   ; B45D: F0 08
    LDA ObjRecLink,X            ; B45F: BD 30 05
    CMP DoorCur                 ; B462: CD E1 07
    BEQ LB46A                   ; B465: F0 03
LB467:
    JSR LB475                   ; B467: 20 75 B4
LB46A:
    LDX RecCur                  ; B46A: AE E2 07
    TXA                         ; B46D: 8A
    SEC                         ; B46E: 38
    SBC #$06                    ; B46F: E9 06
    TAX                         ; B471: AA
    BCS LB430                   ; B472: B0 BC
    RTS                         ; B474: 60
LB475:
    LDY DoorCur                 ; B475: AC E1 07
    LDA DoorTimer,Y             ; B478: B9 D8 07
    JSR LB4F4                   ; B47B: 20 F4 B4
    LDA RenderDelay             ; B47E: A5 0C
    ORA $16                     ; B480: 05 16
    BEQ LB488                   ; B482: F0 04
    LDA #$00                    ; B484: A9 00
    BEQ LB497                   ; B486: F0 0F
LB488:
    LDA $04A1                   ; B488: AD A1 04
    CMP #$02                    ; B48B: C9 02
    BEQ LB49A                   ; B48D: F0 0B
    LDY DoorCur                 ; B48F: AC E1 07
    LDX DoorSlotLk,Y            ; B492: BE D0 07
    LDA #$01                    ; B495: A9 01
LB497:
    STA ObjXPage,X              ; B497: 9D 10 04
LB49A:
    RTS                         ; B49A: 60
DoorCloseCheck:
    ; $05E0=0；$033A≠$FF 时取记录：$07C0==3 转 LB4DE（完成，StageId==$4D 置 $07E8=1）；$0548==0 且 $0418==0 时复位 $0705/$07C0/$033A（玩家离开门），否则置状态 2
    LDA #$00                    ; B49B: A9 00
    STA $05E0                   ; B49D: 8D E0 05
    LDY DoorPendRec             ; B4A0: AC 3A 03
    CPY #$FF                    ; B4A3: C0 FF
    BEQ LB49A                   ; B4A5: F0 F3
    STY RecCur                  ; B4A7: 8C E2 07
    LDA $0702,Y                 ; B4AA: B9 02 07
    SEC                         ; B4AD: 38
    SBC #$18                    ; B4AE: E9 18
    AND #$07                    ; B4B0: 29 07
    STA DoorCur                 ; B4B2: 8D E1 07
    TAY                         ; B4B5: A8
    LDA DoorRing,Y              ; B4B6: B9 C0 07
    CMP #$03                    ; B4B9: C9 03
    BEQ LB4DE                   ; B4BB: F0 21
    LDA $0548                   ; B4BD: AD 48 05
    BNE LB49A                   ; B4C0: D0 D8
    LDX DoorPendRec             ; B4C2: AE 3A 03
    LDA $0418                   ; B4C5: AD 18 04
    BEQ LB4D8                   ; B4C8: F0 0E
    LDA #$00                    ; B4CA: A9 00
    STA $0705,X                 ; B4CC: 9D 05 07
    STA DoorRing,Y              ; B4CF: 99 C0 07
    LDA #$FF                    ; B4D2: A9 FF
    STA DoorPendRec             ; B4D4: 8D 3A 03
    RTS                         ; B4D7: 60
LB4D8:
    LDA #$02                    ; B4D8: A9 02
    STA DoorRing,Y              ; B4DA: 99 C0 07
    RTS                         ; B4DD: 60
LB4DE:
    LDA #$FF                    ; B4DE: A9 FF
    STA DoorPendRec             ; B4E0: 8D 3A 03
    LDA StageId                 ; B4E3: A5 80
    CMP #$4D                    ; B4E5: C9 4D
    BNE LB4EE                   ; B4E7: D0 05
    LDA #$01                    ; B4E9: A9 01
    STA DoorAnim,Y              ; B4EB: 99 E8 07
LB4EE:
    LDA DoorAnim,Y              ; B4EE: B9 E8 07
    STA DoorTimer,Y             ; B4F1: 99 D8 07
LB4F4:
    JSR DispatchJump            ; B4F4: 20 9A 85
    .byte $DE,$B5,$09,$B5,$27,$B5,$69,$B5         ; B4F7: DE B5 09 B5 27 B5 69 B5
    .byte $86,$B5,$80,$B5,$44,$B5,$40,$B5         ; B4FF: 86 B5 80 B5 44 B5 40 B5
    .byte $3C,$B5                                 ; B507: 3C B5
LB509:
    LDY $05D0                   ; B509: AC D0 05
    BNE LB513                   ; B50C: D0 05
    LDA #$01                    ; B50E: A9 01
    STA $05D0                   ; B510: 8D D0 05
LB513:
    LDX #$00                    ; B513: A2 00
    LDA StageArea               ; B515: A5 A3
    CMP #$09                    ; B517: C9 09
    BNE LB51F                   ; B519: D0 04
    LDY #$04                    ; B51B: A0 04
    BNE LB521                   ; B51D: D0 02
LB51F:
    LDY #$03                    ; B51F: A0 03
LB521:
    JSR InitObjByKindY          ; B521: 20 D1 AA
    JMP LB598                   ; B524: 4C 98 B5
LB527:
    LDA StageArea               ; B527: A5 A3
    CMP #$09                    ; B529: C9 09
    BEQ LB533                   ; B52B: F0 06
    LDA #$1C                    ; B52D: A9 1C
    LDY #$5B                    ; B52F: A0 5B
    BNE LB590                   ; B531: D0 5D
LB533:
    LDA $05DE                   ; B533: AD DE 05
    LSR A                       ; B536: 4A
    BCC LB544                   ; B537: 90 0B
    LSR A                       ; B539: 4A
    BCC LB540                   ; B53A: 90 04
LB53C:
    LDY #$02                    ; B53C: A0 02
    BNE LB546                   ; B53E: D0 06
LB540:
    LDY #$01                    ; B540: A0 01
    BNE LB546                   ; B542: D0 02
LB544:
    LDY #$00                    ; B544: A0 00
LB546:
    LDA $B563,Y                 ; B546: B9 63 B5
    LDX DoorCur                 ; B549: AE E1 07
    STA DoorTimer,X             ; B54C: 9D D8 07
    LDA $B560,Y                 ; B54F: B9 60 B5
    ORA $05DE                   ; B552: 0D DE 05
    STA $05DE                   ; B555: 8D DE 05
    LDA $B566,Y                 ; B558: B9 66 B5
    TAY                         ; B55B: A8
    LDA #$1D                    ; B55C: A9 1D
    BNE LB590                   ; B55E: D0 30
    .byte $01,$02,$04,$06,$07,$08,$79,$7B         ; B560: 01 02 04 06 07 08 79 7B
    .byte $7A                                     ; B568: 7A
LB569:
    LDA SlingAmmo               ; B569: AD F2 05
    BNE LB586                   ; B56C: D0 18
    LDA #$18                    ; B56E: A9 18
    LDY #$65                    ; B570: A0 65
    BNE LB590                   ; B572: D0 1C
LB574:
    LDA #$00                    ; B574: A9 00
    STA $93                     ; B576: 85 93
    LDY DoorCur                 ; B578: AC E1 07
    LDA #$05                    ; B57B: A9 05
    STA DoorTimer,Y             ; B57D: 99 D8 07
LB580:
    LDA #$14                    ; B580: A9 14
    LDY #$67                    ; B582: A0 67
    BNE LB590                   ; B584: D0 0A
LB586:
    LDA $93                     ; B586: A5 93
    BNE LB574                   ; B588: D0 EA
    LDA #$13                    ; B58A: A9 13
    LDY #$66                    ; B58C: A0 66
    BNE LB590                   ; B58E: D0 00
LB590:
    JSR FindFreeObjEx           ; B590: 20 7C AB
    BCC LB5DE                   ; B593: 90 49
    JSR SpawnObjAtSlot          ; B595: 20 38 AB
LB598:
    LDY RecCur                  ; B598: AC E2 07
    LDA $0702,Y                 ; B59B: B9 02 07
    BMI LB5AE                   ; B59E: 30 0E
    LDA $0704,Y                 ; B5A0: B9 04 07
    CMP #$E0                    ; B5A3: C9 E0
    BCC LB5B2                   ; B5A5: 90 0B
    LDA StageId                 ; B5A7: A5 80
    CMP $0701,Y                 ; B5A9: D9 01 07
    BNE LB5B2                   ; B5AC: D0 04
LB5AE:
    LDA #$01                    ; B5AE: A9 01
    BNE LB5B4                   ; B5B0: D0 02
LB5B2:
    LDA #$00                    ; B5B2: A9 00
LB5B4:
    STA ObjXPage,X              ; B5B4: 9D 10 04
    LDA $0704,Y                 ; B5B7: B9 04 07
    CLC                         ; B5BA: 18
    ADC #$0F                    ; B5BB: 69 0F
    STA ObjX,X                  ; B5BD: 9D 70 04
    BCC LB5CA                   ; B5C0: 90 08
    LDA ObjXPage,X              ; B5C2: BD 10 04
    EOR #$01                    ; B5C5: 49 01
    STA ObjXPage,X              ; B5C7: 9D 10 04
LB5CA:
    LDA $0703,Y                 ; B5CA: B9 03 07
    CLC                         ; B5CD: 18
    ADC #$1E                    ; B5CE: 69 1E
    STA ObjY,X                  ; B5D0: 9D 60 04
    LDA DoorCur                 ; B5D3: AD E1 07
    STA ObjRecLink,X            ; B5D6: 9D 30 05
    TAY                         ; B5D9: A8
    TXA                         ; B5DA: 8A
    STA DoorSlotLk,Y            ; B5DB: 99 D0 07
LB5DE:
    RTS                         ; B5DE: 60
InitObjRing:
    LDY StageArea               ; B5DF: A4 A3
    LDA $B618,Y                 ; B5E1: B9 18 B6
    STA $30                     ; B5E4: 85 30
    LDA FrameCnt                ; B5E6: A5 09
    AND #$07                    ; B5E8: 29 07
    CMP $30                     ; B5EA: C5 30
    BCC LB5F0                   ; B5EC: 90 02
    SBC $30                     ; B5EE: E5 30
LB5F0:
    TAY                         ; B5F0: A8
    LDX #$00                    ; B5F1: A2 00
LB5F3:
    LDA $B610,X                 ; B5F3: BD 10 B6
    STA DoorAnim,Y              ; B5F6: 99 E8 07
    LDA #$00                    ; B5F9: A9 00
    STA DoorTimer,Y             ; B5FB: 99 D8 07
    LDA #$FF                    ; B5FE: A9 FF
    STA DoorSlotLk,Y            ; B600: 99 D0 07
    INY                         ; B603: C8
    CPY $30                     ; B604: C4 30
    BCC LB60A                   ; B606: 90 02
    LDY #$00                    ; B608: A0 00
LB60A:
    INX                         ; B60A: E8
    CPX $30                     ; B60B: E4 30
    BCC LB5F3                   ; B60D: 90 E4
    RTS                         ; B60F: 60
    .byte $01,$02,$02,$02,$03,$04,$04,$04         ; B610: 01 02 02 02 03 04 04 04
    .byte $00,$04,$07,$00,$08,$08,$00,$08         ; B618: 00 04 07 00 08 08 00 08
    .byte $00,$04                                 ; B620: 00 04
PlayerInteract:
    ; 两轮（X 与 X+$10=$0150/$0160 邻近记录）：id<$18 转 LB6E2（钥匙位检测开门）；$39-$3C→LB6BB（Boss 门入店）；$43-$45/$45-$47 装备门（$49 位检测）；其余跳过
    LDA ObjState,X              ; B622: B5 50
    CMP #$01                    ; B624: C9 01
    BEQ LB66E                   ; B626: F0 46
    LDA #$02                    ; B628: A9 02
    STA $32                     ; B62A: 85 32
LB62C:
    STX $3E                     ; B62C: 86 3E
    LDY ProxRec1,X              ; B62E: BC 50 01
    CPY #$FF                    ; B631: C0 FF
    BEQ LB662                   ; B633: F0 2D
    STY RecCur                  ; B635: 8C E2 07
    LDA $0702,Y                 ; B638: B9 02 07
    CMP #$18                    ; B63B: C9 18
    BCS LB642                   ; B63D: B0 03
    JMP LB6E2                   ; B63F: 4C E2 B6
LB642:
    CMP #$30                    ; B642: C9 30
    BCC LB662                   ; B644: 90 1C
    CMP #$36                    ; B646: C9 36
    BCC LB662                   ; B648: 90 18
    CMP #$38                    ; B64A: C9 38
    BCC LB662                   ; B64C: 90 14
    CMP #$39                    ; B64E: C9 39
    BCC LB6BB                   ; B650: 90 69
    CMP #$3C                    ; B652: C9 3C
    BCC LB698                   ; B654: 90 42
    CMP #$43                    ; B656: C9 43
    BCC LB662                   ; B658: 90 08
    CMP #$45                    ; B65A: C9 45
    BCC LB672                   ; B65C: 90 14
    CMP #$47                    ; B65E: C9 47
    BCC LB67C                   ; B660: 90 1A
LB662:
    DEC $32                     ; B662: C6 32
    BEQ LB66E                   ; B664: F0 08
    LDA $3E                     ; B666: A5 3E
    CLC                         ; B668: 18
    ADC #$10                    ; B669: 69 10
    TAX                         ; B66B: AA
    BNE LB62C                   ; B66C: D0 BE
LB66E:
    CLC                         ; B66E: 18
    LDX ObjLoopSlot             ; B66F: A6 48
    RTS                         ; B671: 60
LB672:
    LDY #$10                    ; B672: A0 10
    LDA #$08                    ; B674: A9 08
    AND EquipBits               ; B676: 25 49
    BEQ LB695                   ; B678: F0 1B
LB67A:
    CLC                         ; B67A: 18
    RTS                         ; B67B: 60
LB67C:
    LDY #$11                    ; B67C: A0 11
    LDA #$02                    ; B67E: A9 02
    AND EquipBits               ; B680: 25 49
    ORA DeathSeqCnt             ; B682: 0D DD 05
    BNE LB67A                   ; B685: D0 F3
    LDX ObjLoopSlot             ; B687: A6 48
    LDA #$02                    ; B689: A9 02
    CMP ObjState,X              ; B68B: D5 50
    BEQ LB695                   ; B68D: F0 06
    JSR LA301                   ; B68F: 20 01 A3
    STA ObjDirFlags,X           ; B692: 9D 10 05
LB695:
    JMP LAE45                   ; B695: 4C 45 AE
LB698:
    LDA $0705,Y                 ; B698: B9 05 07
    BMI LB6B1                   ; B69B: 30 14
    LDA $0704,Y                 ; B69D: B9 04 07
    SBC #$01                    ; B6A0: E9 01
    CMP $0471                   ; B6A2: CD 71 04
    BCS LB6B1                   ; B6A5: B0 0A
    ADC #$12                    ; B6A7: 69 12
    CMP $0471                   ; B6A9: CD 71 04
    BCC LB6B1                   ; B6AC: 90 03
    JMP LADA2                   ; B6AE: 4C A2 AD
LB6B1:
    LDA $0511                   ; B6B1: AD 11 05
    AND #$FC                    ; B6B4: 29 FC
    STA $0511                   ; B6B6: 8D 11 05
    SEC                         ; B6B9: 38
    RTS                         ; B6BA: 60
LB6BB:
    LDX ObjLoopSlot             ; B6BB: A6 48
    LDA ObjState,X              ; B6BD: B5 50
    CMP #$05                    ; B6BF: C9 05
    BEQ LB6E0                   ; B6C1: F0 1D
    LDA ObjDirFlags,X           ; B6C3: BD 10 05
    AND #$08                    ; B6C6: 29 08
    BEQ LB6E0                   ; B6C8: F0 16
    LDA $0704,Y                 ; B6CA: B9 04 07
    CLC                         ; B6CD: 18
    ADC #$10                    ; B6CE: 69 10
    STA $05DA                   ; B6D0: 8D DA 05
    LDA $0703,Y                 ; B6D3: B9 03 07
    CLC                         ; B6D6: 18
    ADC #$20                    ; B6D7: 69 20
    STA $05DB                   ; B6D9: 8D DB 05
    LDA #$06                    ; B6DC: A9 06
    STA ObjState,X              ; B6DE: 95 50
LB6E0:
    CLC                         ; B6E0: 18
    RTS                         ; B6E1: 60
LB6E2:
    AND #$07                    ; B6E2: 29 07
    STA $31                     ; B6E4: 85 31
    TAX                         ; B6E6: AA
    LDA $0702,Y                 ; B6E7: B9 02 07
    LSR A                       ; B6EA: 4A
    LSR A                       ; B6EB: 4A
    LSR A                       ; B6EC: 4A
    STA $30                     ; B6ED: 85 30
    TAY                         ; B6EF: A8
    LDA $A4,Y                   ; B6F0: B9 A4 00
    AND $CECE,X                 ; B6F3: 3D CE CE
    BNE LB74A                   ; B6F6: D0 52
    JSR FindFreeObjHi           ; B6F8: 20 5A AB
    BCC LB74A                   ; B6FB: 90 4D
    LDA $31                     ; B6FD: A5 31
    STA ObjVariant,X            ; B6FF: 9D 50 05
    LDY $30                     ; B702: A4 30
    LDA $A4,Y                   ; B704: B9 A4 00
    LDY $31                     ; B707: A4 31
    ORA $CECE,Y                 ; B709: 19 CE CE
    LDY $30                     ; B70C: A4 30
    STA $A4,Y                   ; B70E: 99 A4 00
    LDY $30                     ; B711: A4 30
    LDA $B750,Y                 ; B713: B9 50 B7
    CPY #$02                    ; B716: C0 02
    BNE LB71E                   ; B718: D0 04
    CLC                         ; B71A: 18
    ADC ObjVariant,X            ; B71B: 7D 50 05
LB71E:
    STA $3F                     ; B71E: 85 3F
    LDY RecCur                  ; B720: AC E2 07
    LDA $0704,Y                 ; B723: B9 04 07
    STA ObjX,X                  ; B726: 9D 70 04
    LDA $0703,Y                 ; B729: B9 03 07
    STA ObjY,X                  ; B72C: 9D 60 04
    LDY $3F                     ; B72F: A4 3F
    LDA $30                     ; B731: A5 30
    CMP #$02                    ; B733: C9 02
    BEQ LB73D                   ; B735: F0 06
    JSR TransformObj            ; B737: 20 90 9C
    JMP LB740                   ; B73A: 4C 40 B7
LB73D:
    JSR SpawnDebris             ; B73D: 20 07 9E
LB740:
    LDY $30                     ; B740: A4 30
    DEY                         ; B742: 88
    BNE LB74A                   ; B743: D0 05
    LDA #$17                    ; B745: A9 17
    JSR $F08E                   ; B747: 20 8E F0  -> Bank1:SoundCmd
LB74A:
    LDX ObjLoopSlot             ; B74A: A6 48
    CLC                         ; B74C: 18
    RTS                         ; B74D: 60
    .byte $18,$60,$08,$09,$00                     ; B74E: 18 60 08 09 00
PlayerContactScan:
    ; 先 AttackPointProbe；两轮邻近记录 id $30-$36（危险物）：按 $0704+$04/$0C 与本槽 X 比左右，$0510 位0/位1 仅作接触方向测试并（仅玩家，B7D7/B7E3）清对应位；接触位累积在 $0100,X，==3（双向夹）则 ClearObject（夹碎，B7A4-B7AE）；$30/$31 且 $05DF≥3 触发 Boss 门序列（$0337/$05D1/$05D2/$05D3）
    JSR AttackPointProbe        ; B753: 20 45 A4
    BNE LB788                   ; B756: D0 30
    LDA #$02                    ; B758: A9 02
    STA $32                     ; B75A: 85 32
LB75C:
    STX $3E                     ; B75C: 86 3E
    LDY ProxRec1,X              ; B75E: BC 50 01
    CPY #$FF                    ; B761: C0 FF
    BEQ LB773                   ; B763: F0 0E
    STY RecCur                  ; B765: 8C E2 07
    LDA $0702,Y                 ; B768: B9 02 07
    CMP #$30                    ; B76B: C9 30
    BCC LB773                   ; B76D: 90 04
    CMP #$36                    ; B76F: C9 36
    BCC LB7B4                   ; B771: 90 41
LB773:
    DEC $32                     ; B773: C6 32
    BEQ LB77F                   ; B775: F0 08
    LDA $3E                     ; B777: A5 3E
    CLC                         ; B779: 18
    ADC #$10                    ; B77A: 69 10
    TAX                         ; B77C: AA
    BNE LB75C                   ; B77D: D0 DD
LB77F:
    CLC                         ; B77F: 18
    LDX ObjLoopSlot             ; B780: A6 48
    LDA #$00                    ; B782: A9 00
    STA ObjContactBits,X        ; B784: 9D 00 01
    RTS                         ; B787: 60
LB788:
    LDA #$00                    ; B788: A9 00
    STA $30                     ; B78A: 85 30
    LDA ObjDirFlags,X           ; B78C: BD 10 05
    AND #$01                    ; B78F: 29 01
    BNE LB7DC                   ; B791: D0 49
    BEQ LB7D0                   ; B793: F0 3B
LB795:
    LDA #$01                    ; B795: A9 01
    BNE LB79B                   ; B797: D0 02
LB799:
    LDA #$02                    ; B799: A9 02
LB79B:
    AND ObjDirFlags,X           ; B79B: 3D 10 05
    BEQ LB77F                   ; B79E: F0 DF
    LDY $30                     ; B7A0: A4 30
    BEQ LB7EC                   ; B7A2: F0 48
    ORA ObjContactBits,X        ; B7A4: 1D 00 01
    STA ObjContactBits,X        ; B7A7: 9D 00 01
    CMP #$03                    ; B7AA: C9 03
    BNE LB7EC                   ; B7AC: D0 3E
    JSR ClearObject             ; B7AE: 20 E7 A2
    PLA                         ; B7B1: 68
    PLA                         ; B7B2: 68
    RTS                         ; B7B3: 60
LB7B4:
    LDA #$01                    ; B7B4: A9 01
    STA $30                     ; B7B6: 85 30
    LDX ObjLoopSlot             ; B7B8: A6 48
    LDA ObjDirFlags,X           ; B7BA: BD 10 05
    AND #$01                    ; B7BD: 29 01
    BNE LB7C5                   ; B7BF: D0 04
    LDA #$04                    ; B7C1: A9 04
    BNE LB7C7                   ; B7C3: D0 02
LB7C5:
    LDA #$0C                    ; B7C5: A9 0C
LB7C7:
    CLC                         ; B7C7: 18
    ADC $0704,Y                 ; B7C8: 79 04 07
    CMP ObjX,X                  ; B7CB: DD 70 04
    BCS LB7DC                   ; B7CE: B0 0C
LB7D0:
    LDA ObjDirFlags,X           ; B7D0: BD 10 05
    CPX #$01                    ; B7D3: E0 01
    BNE LB799                   ; B7D5: D0 C2
    AND #$FD                    ; B7D7: 29 FD
    JMP LB7E5                   ; B7D9: 4C E5 B7
LB7DC:
    LDA ObjDirFlags,X           ; B7DC: BD 10 05
    CPX #$01                    ; B7DF: E0 01
    BNE LB795                   ; B7E1: D0 B2
    AND #$FE                    ; B7E3: 29 FE
LB7E5:
    STA ObjDirFlags,X           ; B7E5: 9D 10 05
    CPX #$01                    ; B7E8: E0 01
    BEQ LB7EE                   ; B7EA: F0 02
LB7EC:
    SEC                         ; B7EC: 38
    RTS                         ; B7ED: 60
LB7EE:
    LDA BossDoorSeq             ; B7EE: AD 37 03
    BNE LB859                   ; B7F1: D0 66
    LDA $30                     ; B7F3: A5 30
    BEQ LB7EC                   ; B7F5: F0 F5
    LDY RecCur                  ; B7F7: AC E2 07
    LDA $0702,Y                 ; B7FA: B9 02 07
    CMP #$30                    ; B7FD: C9 30
    BEQ LB805                   ; B7FF: F0 04
    CMP #$31                    ; B801: C9 31
    BNE LB7EC                   ; B803: D0 E7
LB805:
    LDA KeyCount                ; B805: AD DF 05
    CMP #$03                    ; B808: C9 03
    BCC LB859                   ; B80A: 90 4D
    INC BossDoorSeq             ; B80C: EE 37 03
    INC $05D1                   ; B80F: EE D1 05
    LDA #$50                    ; B812: A9 50
    STA $05D3                   ; B814: 8D D3 05
    STA $05D2                   ; B817: 8D D2 05
    LDY #$26                    ; B81A: A0 26
    JSR SoundCmdC0              ; B81C: 20 1C 86
    LDY RecCur                  ; B81F: AC E2 07
    LDA $0704,Y                 ; B822: B9 04 07
    CLC                         ; B825: 18
    ADC #$08                    ; B826: 69 08
    CMP $0471                   ; B828: CD 71 04
    BCC LB831                   ; B82B: 90 04
    LDA #$01                    ; B82D: A9 01
    BNE LB833                   ; B82F: D0 02
LB831:
    LDA #$02                    ; B831: A9 02
LB833:
    STA $04A1                   ; B833: 8D A1 04
    LDA #$00                    ; B836: A9 00
    STA $0511                   ; B838: 8D 11 05
    STA $0501                   ; B83B: 8D 01 05
    JSR ClearObjectList         ; B83E: 20 09 A3
    LDA #$00                    ; B841: A9 00
    STA $51                     ; B843: 85 51
    STA $0501                   ; B845: 8D 01 05
    STA AttackFlag              ; B848: 8D F4 05
    STA $0547                   ; B84B: 8D 47 05
    STA $0548                   ; B84E: 8D 48 05
    STA InvincibleT             ; B851: 8D F6 05
    JSR LB85B                   ; B854: 20 5B B8
    PLA                         ; B857: 68
    PLA                         ; B858: 68
LB859:
    CLC                         ; B859: 18
    RTS                         ; B85A: 60
LB85B:
    ; 清 $4B/$4C/$0421/$05DD 四状态（回复道具参数/玩家可见/死亡序列计数）；bank1 $CB56 JSR
    LDA #$00                    ; B85B: A9 00
    STA $4B                     ; B85D: 85 4B
    STA $4C                     ; B85F: 85 4C
    STA $0421                   ; B861: 8D 21 04
    STA DeathSeqCnt             ; B864: 8D DD 05
    RTS                         ; B867: 60
DoorProxSpawn:
    ; $16==0 且 $05E6≠0 时仅递减；否则 LA928（StageId mod 10）选边，$B98F[$D6BB[StageId]*4+$05E8] 非 0 且在滚动窗内则 FindFreeObjLo 生成门物体（种类 $B967[$A3*4+$05E7&3]，区域 7/9 带 8 改 $0C），$05E6=$B963[$1D]，$05E8=(+1)&3
    LDA $16                     ; B868: A5 16
    BNE LB875                   ; B86A: D0 09
    LDA DoorCd                  ; B86C: AD E6 05
    BEQ LB875                   ; B86F: F0 04
    DEC DoorCd                  ; B871: CE E6 05
    RTS                         ; B874: 60
LB875:
    JSR LA928                   ; B875: 20 28 A9
    ROL A                       ; B878: 2A
    AND #$01                    ; B879: 29 01
    STA $05FB                   ; B87B: 8D FB 05
    LDY StageId                 ; B87E: A4 80
    LDA $D6BB,Y                 ; B880: B9 BB D6  -> Bank1:LayoutPageTab
    ASL A                       ; B883: 0A
    ASL A                       ; B884: 0A
    STA $33                     ; B885: 85 33
    LDX $05FB                   ; B887: AE FB 05
    BNE LB892                   ; B88A: D0 06
    INY                         ; B88C: C8
    LDA $D6BB,Y                 ; B88D: B9 BB D6  -> Bank1:LayoutPageTab
    ASL A                       ; B890: 0A
    ASL A                       ; B891: 0A
LB892:
    STA $34                     ; B892: 85 34
    LDA $33                     ; B894: A5 33
    CLC                         ; B896: 18
    ADC DoorScanPhase           ; B897: 6D E8 05
    TAY                         ; B89A: A8
    LDA $B98F,Y                 ; B89B: B9 8F B9
    BEQ LB8B4                   ; B89E: F0 14
    STA $30                     ; B8A0: 85 30
    AND #$07                    ; B8A2: 29 07
    STA $41                     ; B8A4: 85 41
    LDA $30                     ; B8A6: A5 30
    AND #$F8                    ; B8A8: 29 F8
    CMP ScrollX                 ; B8AA: C5 18
    BCC LB8B4                   ; B8AC: 90 06
    SEC                         ; B8AE: 38
    SBC ScrollX                 ; B8AF: E5 18
    JMP LB8E2                   ; B8B1: 4C E2 B8
LB8B4:
    LDA $34                     ; B8B4: A5 34
    CMP $33                     ; B8B6: C5 33
    BNE LB8BD                   ; B8B8: D0 03
    JMP LB957                   ; B8BA: 4C 57 B9
LB8BD:
    CLC                         ; B8BD: 18
    ADC DoorScanPhase           ; B8BE: 6D E8 05
    TAY                         ; B8C1: A8
    LDA $B98F,Y                 ; B8C2: B9 8F B9
    BNE LB8CA                   ; B8C5: D0 03
    JMP LB957                   ; B8C7: 4C 57 B9
LB8CA:
    STA $30                     ; B8CA: 85 30
    AND #$07                    ; B8CC: 29 07
    STA $41                     ; B8CE: 85 41
    LDA $30                     ; B8D0: A5 30
    AND #$F8                    ; B8D2: 29 F8
    CMP ScrollX                 ; B8D4: C5 18
    BCS LB957                   ; B8D6: B0 7F
    STA $31                     ; B8D8: 85 31
    LDA #$00                    ; B8DA: A9 00
    SEC                         ; B8DC: 38
    SBC ScrollX                 ; B8DD: E5 18
    CLC                         ; B8DF: 18
    ADC $31                     ; B8E0: 65 31
LB8E2:
    STA $40                     ; B8E2: 85 40
    JSR FindFreeObjLo           ; B8E4: 20 64 AB
    BCS LB8EA                   ; B8E7: B0 01
    RTS                         ; B8E9: 60
LB8EA:
    LDA $40                     ; B8EA: A5 40
    STA ObjX,X                  ; B8EC: 9D 70 04
    LDA $41                     ; B8EF: A5 41
    CLC                         ; B8F1: 18
    ADC #$01                    ; B8F2: 69 01
    STA $41                     ; B8F4: 85 41
    JSR LAB90                   ; B8F6: 20 90 AB
    LDA PowerLevel              ; B8F9: A5 1D
    BNE LB90C                   ; B8FB: D0 0F
    LDA StageId                 ; B8FD: A5 80
    CMP #$23                    ; B8FF: C9 23
    BEQ LB90C                   ; B901: F0 09
    JSR LA97A                   ; B903: 20 7A A9
    LDA TypeCount               ; B906: A5 4E
    CMP #$01                    ; B908: C9 01
    BCS LB94B                   ; B90A: B0 3F
LB90C:
    LDY #$03                    ; B90C: A0 03
    LDA PowerLevel              ; B90E: A5 1D
    AND #$FC                    ; B910: 29 FC
    BNE LB916                   ; B912: D0 02
    LDY PowerLevel              ; B914: A4 1D
LB916:
    LDA $B963,Y                 ; B916: B9 63 B9
    STA DoorCd                  ; B919: 8D E6 05
    LDA DoorKindCycle           ; B91C: AD E7 05
    INC DoorKindCycle           ; B91F: EE E7 05
    AND #$03                    ; B922: 29 03
    STA $32                     ; B924: 85 32
    LDA StageArea               ; B926: A5 A3
    ASL A                       ; B928: 0A
    ASL A                       ; B929: 0A
    CLC                         ; B92A: 18
    ADC $32                     ; B92B: 65 32
    TAY                         ; B92D: A8
    LDA $B967,Y                 ; B92E: B9 67 B9
    STA ObjKind                 ; B931: 85 4A
    LDA StageArea               ; B933: A5 A3
    CMP #$09                    ; B935: C9 09
    BEQ LB93D                   ; B937: F0 04
    CMP #$07                    ; B939: C9 07
    BNE LB948                   ; B93B: D0 0B
LB93D:
    LDA ObjFloorBand,X          ; B93D: BD B0 04
    CMP #$08                    ; B940: C9 08
    BNE LB948                   ; B942: D0 04
    LDA #$0C                    ; B944: A9 0C
    STA ObjKind                 ; B946: 85 4A
LB948:
    JSR DoorContent             ; B948: 20 09 A9
LB94B:
    LDA DoorScanPhase           ; B94B: AD E8 05
    CLC                         ; B94E: 18
    ADC #$01                    ; B94F: 69 01
    AND #$03                    ; B951: 29 03
    STA DoorScanPhase           ; B953: 8D E8 05
    RTS                         ; B956: 60
LB957:
    LDA $05F7                   ; B957: AD F7 05
    CLC                         ; B95A: 18
    ADC #$01                    ; B95B: 69 01
    STA $05F7                   ; B95D: 8D F7 05
    BCS LB94B                   ; B960: B0 E9
    RTS                         ; B962: 60
    .byte $28,$18,$10,$08,$01,$01,$01,$01         ; B963: 28 18 10 08 01 01 01 01
    .byte $01,$01,$01,$01,$01,$01,$01,$01         ; B96B: 01 01 01 01 01 01 01 01
    .byte $0A,$06,$05,$0A,$07,$01,$07,$01         ; B973: 0A 06 05 0A 07 01 07 01
    .byte $01,$05,$01,$07,$05,$0A,$0A,$06         ; B97B: 01 05 01 07 05 0A 0A 06
    .byte $0C,$01,$0C,$01,$06,$05,$05,$0A         ; B983: 0C 01 0C 01 06 05 05 0A
    .byte $0C,$01,$0C,$01,$C9,$44,$A4,$97         ; B98B: 0C 01 0C 01 C9 44 A4 97
    .byte $60,$5C,$A4,$27,$81,$C4,$17,$C7         ; B993: 60 5C A4 27 81 C4 17 C7
    .byte $C1,$94,$37,$E7,$11,$B3,$57,$F7         ; B99B: C1 94 37 E7 11 B3 57 F7
    .byte $71,$57,$B7,$64,$E4,$77,$27,$93         ; B9A3: 71 57 B7 64 E4 77 27 93
    .byte $B1,$62,$D4,$47,$51,$94,$57,$87         ; B9AB: B1 62 D4 47 51 94 57 87
    .byte $54,$FC,$00,$00,$81,$D4,$00,$00         ; B9B3: 54 FC 00 00 81 D4 00 00
    .byte $9C,$14,$00,$00,$67,$FC,$A4,$00         ; B9BB: 9C 14 00 00 67 FC A4 00
    .byte $71,$34,$00,$00,$14,$81,$E4,$11         ; B9C3: 71 34 00 00 14 81 E4 11
    .byte $34,$00,$00,$00,$21,$D4,$24,$00         ; B9CB: 34 00 00 00 21 D4 24 00
    .byte $44,$81,$00,$00,$34,$00,$00,$00         ; B9D3: 44 81 00 00 34 00 00 00
    .byte $21,$00,$00,$00,$91,$B4,$47,$00         ; B9DB: 21 00 00 00 91 B4 47 00
    .byte $87,$00,$00,$00,$14,$54,$73,$37         ; B9E3: 87 00 00 00 14 54 73 37
    .byte $31,$E4,$67,$B7,$54,$74,$94,$B4         ; B9EB: 31 E4 67 B7 54 74 94 B4
    .byte $C1,$14,$00,$00,$E4,$12,$00,$00         ; B9F3: C1 14 00 00 E4 12 00 00
    .byte $57,$81,$00,$00,$C3,$F9,$00,$00         ; B9FB: 57 81 00 00 C3 F9 00 00
    .byte $C9,$44,$17,$01,$45,$00,$00,$00         ; BA03: C9 44 17 01 45 00 00 00
    .byte $87,$74,$00,$00,$00,$00,$00,$00         ; BA0B: 87 74 00 00 00 00 00 00
    .byte $27,$87,$40,$E7,$47,$87,$C7,$66         ; BA13: 27 87 40 E7 47 87 C7 66
    .byte $17,$67,$D7,$84,$00,$00,$00,$00         ; BA1B: 17 67 D7 84 00 00 00 00
    .byte $7A,$00,$00,$00,$02,$F4,$A7,$00         ; BA23: 7A 00 00 00 02 F4 A7 00
    .byte $23,$91,$00,$00,$54,$E1,$47,$00         ; BA2B: 23 91 00 00 54 E1 47 00
    .byte $67,$A7,$01,$00,$64,$21,$00,$00         ; BA33: 67 A7 01 00 64 21 00 00
    .byte $77,$00,$00,$00,$F4,$A4,$99,$34         ; BA3B: 77 00 00 00 F4 A4 99 34
    .byte $27,$93,$14,$B7,$C1,$9A,$5C,$A7         ; BA43: 27 93 14 B7 C1 9A 5C A7
    .byte $07,$B7,$6C,$44,$24,$61,$84,$00         ; BA4B: 07 B7 6C 44 24 61 84 00
    .byte $E4,$84,$14,$00,$A4,$E4,$34,$00         ; BA53: E4 84 14 00 A4 E4 34 00
    .byte $37,$A9,$F4,$00,$C7,$54,$00,$00         ; BA5B: 37 A9 F4 00 C7 54 00 00
    .byte $00,$00,$00,$00,$97,$FC,$54,$71         ; BA63: 00 00 00 00 97 FC 54 71
    .byte $71,$C1,$54,$00,$B4,$87,$14,$00         ; BA6B: 71 C1 54 00 B4 87 14 00
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; BA73: 00 00 00 00 00 00 00 00
SpawnStreamAdv:
    ; LBBA3（滚动窗 $30/$32）后 $88/$89≠$8A/$8B（窗移动）时：按 $0511 位1 选前/后边界记录（$87±6，回绕 $FA→$5A），LBACE 载入并推进 $8A/$8B
    JSR LBBA3                   ; BA7B: 20 A3 BB
    BCC LBA91                   ; BA7E: 90 11
    LDA $0511                   ; BA80: AD 11 05
    AND #$02                    ; BA83: 29 02
    BNE LBA92                   ; BA85: D0 0B
    LDA #$00                    ; BA87: A9 00
    STA $0338                   ; BA89: 8D 38 03
    LDX $87                     ; BA8C: A6 87
    JSR LBAA7                   ; BA8E: 20 A7 BA
LBA91:
    RTS                         ; BA91: 60
LBA92:
    LDA #$01                    ; BA92: A9 01
    STA $0338                   ; BA94: 8D 38 03
    LDA $87                     ; BA97: A5 87
    SEC                         ; BA99: 38
    SBC #$06                    ; BA9A: E9 06
    CMP #$FA                    ; BA9C: C9 FA
    BNE LBAA2                   ; BA9E: D0 02
    LDA #$5A                    ; BAA0: A9 5A
LBAA2:
    TAX                         ; BAA2: AA
    JSR LBAA7                   ; BAA3: 20 A7 BA
    RTS                         ; BAA6: 60
LBAA7:
    LDA $89                     ; BAA7: A5 89
    CMP $8B                     ; BAA9: C5 8B
    BNE LBAB4                   ; BAAB: D0 07
    LDA $88                     ; BAAD: A5 88
    CMP $8A                     ; BAAF: C5 8A
    BNE LBAB4                   ; BAB1: D0 01
    RTS                         ; BAB3: 60
LBAB4:
    LDA $0511                   ; BAB4: AD 11 05
    AND #$02                    ; BAB7: 29 02
    BNE LBACC                   ; BAB9: D0 11
    INC $32                     ; BABB: E6 32
    INC $32                     ; BABD: E6 32
    DEY                         ; BABF: 88
    DEY                         ; BAC0: 88
    BPL LBAC7                   ; BAC1: 10 04
    DEC $32                     ; BAC3: C6 32
    LDY #$0E                    ; BAC5: A0 0E
LBAC7:
    STY $3F                     ; BAC7: 84 3F
    JMP LBACE                   ; BAC9: 4C CE BA
LBACC:
    STY $3F                     ; BACC: 84 3F
LBACE:
    JSR SpawnRecordLoad         ; BACE: 20 2C BC
    LDA $88                     ; BAD1: A5 88
    STA $8A                     ; BAD3: 85 8A
    LDA $89                     ; BAD5: A5 89
    STA $8B                     ; BAD7: 85 8B
    RTS                         ; BAD9: 60
SpawnRingFill:
    ; LBBA3 后 $87=0/$0338=0，$033D=$10 循环 16 次 LBACE：整环初始化载入（StageLoad 路径，bank1 $CA68 JSR）
    JSR LBBA3                   ; BADA: 20 A3 BB
    LDA #$00                    ; BADD: A9 00
    STA $87                     ; BADF: 85 87
    STA $0338                   ; BAE1: 8D 38 03
    LDA #$10                    ; BAE4: A9 10
    STA $033D                   ; BAE6: 8D 3D 03
LBAE9:
    LDX $87                     ; BAE9: A6 87
    JSR LBACE                   ; BAEB: 20 CE BA
    DEC $033D                   ; BAEE: CE 3D 03
    BNE LBAE9                   ; BAF1: D0 F6
    RTS                         ; BAF3: 60
ScanObjWindow:
    ; StageInit 尾转：$33/$34=StageId 页、$35/$36=ScrollX±$3C 窗，16 记录（6 字节/条）扫描，窗外 $0704,X=$FF/$0705,X=0（id&$7F∈[$39,$3C) 例外），LBB6A 路径维护 $0702,X 位7 激活
    LDX #$00                    ; BAF4: A2 00
    LDY StageId                 ; BAF6: A4 80
    STY $33                     ; BAF8: 84 33
    INY                         ; BAFA: C8
    STY $34                     ; BAFB: 84 34
    LDA ScrollX                 ; BAFD: A5 18
    SEC                         ; BAFF: 38
    SBC #$3C                    ; BB00: E9 3C
    BCS LBB13                   ; BB02: B0 0F
    DEC $33                     ; BB04: C6 33
    LDY $33                     ; BB06: A4 33
    INY                         ; BB08: C8
    BNE LBB13                   ; BB09: D0 08
    LDA #$00                    ; BB0B: A9 00
    STA $33                     ; BB0D: 85 33
    STA $35                     ; BB0F: 85 35
    BEQ LBB15                   ; BB11: F0 02
LBB13:
    STA $35                     ; BB13: 85 35
LBB15:
    LDA ScrollX                 ; BB15: A5 18
    CLC                         ; BB17: 18
    ADC #$3C                    ; BB18: 69 3C
    STA $36                     ; BB1A: 85 36
    BCC LBB20                   ; BB1C: 90 02
    INC $34                     ; BB1E: E6 34
LBB20:
    LDA #$10                    ; BB20: A9 10
    STA $31                     ; BB22: 85 31
LBB24:
    LDA $0702,X                 ; BB24: BD 02 07
    CMP #$FF                    ; BB27: C9 FF
    BEQ LBB49                   ; BB29: F0 1E
    LDY SpawnRing,X             ; BB2B: BC 00 07
    LDA $0701,X                 ; BB2E: BD 01 07
    CMP $33                     ; BB31: C5 33
    BEQ LBB3F                   ; BB33: F0 0A
    BCC LBB49                   ; BB35: 90 12
    CMP $34                     ; BB37: C5 34
    BEQ LBB45                   ; BB39: F0 0A
    BCS LBB49                   ; BB3B: B0 0C
    BCC LBB6A                   ; BB3D: 90 2B
LBB3F:
    CPY $35                     ; BB3F: C4 35
    BCS LBB6A                   ; BB41: B0 27
    BCC LBB49                   ; BB43: 90 04
LBB45:
    CPY $36                     ; BB45: C4 36
    BCC LBB6A                   ; BB47: 90 21
LBB49:
    LDA $0702,X                 ; BB49: BD 02 07
    AND #$7F                    ; BB4C: 29 7F
    CMP #$39                    ; BB4E: C9 39
    BCC LBB56                   ; BB50: 90 04
    CMP #$3C                    ; BB52: C9 3C
    BCC LBB60                   ; BB54: 90 0A
LBB56:
    LDA #$FF                    ; BB56: A9 FF
    STA $0704,X                 ; BB58: 9D 04 07
    LDA #$00                    ; BB5B: A9 00
    STA $0705,X                 ; BB5D: 9D 05 07
LBB60:
    TXA                         ; BB60: 8A
    CLC                         ; BB61: 18
    ADC #$06                    ; BB62: 69 06
    TAX                         ; BB64: AA
    DEC $31                     ; BB65: C6 31
    BNE LBB24                   ; BB67: D0 BB
    RTS                         ; BB69: 60
LBB6A:
    LDA StageId                 ; BB6A: A5 80
    STA $30                     ; BB6C: 85 30
    LDA $0701,X                 ; BB6E: BD 01 07
    CMP $30                     ; BB71: C5 30
    BNE LBB7F                   ; BB73: D0 0A
    TYA                         ; BB75: 98
    CLC                         ; BB76: 18
    ADC #$0E                    ; BB77: 69 0E
    CMP ScrollX                 ; BB79: C5 18
    BCS LBB89                   ; BB7B: B0 0C
    BCC LBB91                   ; BB7D: 90 12
LBB7F:
    INC $30                     ; BB7F: E6 30
    CMP $30                     ; BB81: C5 30
    BNE LBB91                   ; BB83: D0 0C
    CPY ScrollX                 ; BB85: C4 18
    BCS LBB91                   ; BB87: B0 08
LBB89:
    LDA $0702,X                 ; BB89: BD 02 07
    AND #$7F                    ; BB8C: 29 7F
    JMP LBB96                   ; BB8E: 4C 96 BB
LBB91:
    LDA $0702,X                 ; BB91: BD 02 07
    ORA #$80                    ; BB94: 09 80
LBB96:
    STA $0702,X                 ; BB96: 9D 02 07
    TYA                         ; BB99: 98
    SEC                         ; BB9A: 38
    SBC ScrollX                 ; BB9B: E5 18
    STA $0704,X                 ; BB9D: 9D 04 07
    JMP LBB60                   ; BBA0: 4C 60 BB
LBBA3:
    LDA StageId                 ; BBA3: A5 80
    STA $32                     ; BBA5: 85 32
    LDA ScrollX                 ; BBA7: A5 18
    SEC                         ; BBA9: 38
    SBC #$80                    ; BBAA: E9 80
    STA $30                     ; BBAC: 85 30
    BPL LBBBE                   ; BBAE: 10 0E
    LDA $32                     ; BBB0: A5 32
    BNE LBBBC                   ; BBB2: D0 08
    LDA #$00                    ; BBB4: A9 00
    STA $30                     ; BBB6: 85 30
    STA $32                     ; BBB8: 85 32
    BEQ LBBBE                   ; BBBA: F0 02
LBBBC:
    DEC $32                     ; BBBC: C6 32
LBBBE:
    JSR SpawnStreamPtr          ; BBBE: 20 FB BB
    LDY #$00                    ; BBC1: A0 00
    STY $31                     ; BBC3: 84 31
LBBC5:
    LDA ($35),Y                 ; BBC5: B1 35
    AND #$F8                    ; BBC7: 29 F8
    CMP $30                     ; BBC9: C5 30
    BCS LBBDF                   ; BBCB: B0 12
    INY                         ; BBCD: C8
    INY                         ; BBCE: C8
    INC $31                     ; BBCF: E6 31
    LDA $31                     ; BBD1: A5 31
    CMP #$08                    ; BBD3: C9 08
    BNE LBBC5                   ; BBD5: D0 EE
    LDY #$00                    ; BBD7: A0 00
    STY $3F                     ; BBD9: 84 3F
    INC $32                     ; BBDB: E6 32
    CLC                         ; BBDD: 18
    RTS                         ; BBDE: 60
LBBDF:
    STY $3F                     ; BBDF: 84 3F
    LDA $32                     ; BBE1: A5 32
    LDX #$03                    ; BBE3: A2 03
    JSR Word16ShlX              ; BBE5: 20 E4 BC
    LDA $21                     ; BBE8: A5 21
    STA $89                     ; BBEA: 85 89
    LDA $22                     ; BBEC: A5 22
    CLC                         ; BBEE: 18
    ADC $31                     ; BBEF: 65 31
    STA $88                     ; BBF1: 85 88
    BCC LBBF7                   ; BBF3: 90 02
    INC $89                     ; BBF5: E6 89
LBBF7:
    LDY $3F                     ; BBF7: A4 3F
    SEC                         ; BBF9: 38
    RTS                         ; BBFA: 60
SpawnStreamPtr:
    ; $35/$36 = SpawnBasePtr($D229 值 $D22B) + SpawnPageTab[$32]*16（Word16ShlX X=4）：关卡生成流页基址；LBC2C/SpawnStreamAdv 共用
    LDX $32                     ; BBFB: A6 32
    LDA $D161,X                 ; BBFD: BD 61 D1  -> Bank1:SpawnPageTab
    LDX #$04                    ; BC00: A2 04
    JSR Word16ShlX              ; BC02: 20 E4 BC
    LDA $D229                   ; BC05: AD 29 D2  -> Bank1:SpawnBasePtr
    CLC                         ; BC08: 18
    ADC $22                     ; BC09: 65 22
    STA $35                     ; BC0B: 85 35
    LDA $D22A                   ; BC0D: AD 2A D2
    ADC $21                     ; BC10: 65 21
    STA $36                     ; BC12: 85 36
    RTS                         ; BC14: 60
SpawnRingInit:
    ; A→$32（页）、$3F=0/$0338=0，16 次 SpawnRecordLoad：StageInit 整窗重填（$8442 JSR）
    STA $32                     ; BC15: 85 32
    LDA #$00                    ; BC17: A9 00
    STA $3F                     ; BC19: 85 3F
    STA $0338                   ; BC1B: 8D 38 03
    LDA #$10                    ; BC1E: A9 10
    STA $31                     ; BC20: 85 31
LBC22:
    LDX $87                     ; BC22: A6 87
    JSR SpawnRecordLoad         ; BC24: 20 2C BC
    DEC $31                     ; BC27: C6 31
    BNE LBC22                   ; BC29: D0 F7
    RTS                         ; BC2B: 60
SpawnRecordLoad:
    ; 流字节 0：&$F8→$0700,X（X 格位）、&7 存 $30；字节 1=$FF 直取桶 0，否则 $BCA8 区间夹逼得桶号 $38；$BCC9[$BCBE[桶]+$30]→$0703,X（Y 参数）；$0701,X=$32、$0702,X=字节 1|$80（激活）、$0704,X=$FF、$0705,X=0；流指针 $3F 步 2，满 $10 换页
    TXA                         ; BC2C: 8A
    PHA                         ; BC2D: 48
    JSR SpawnStreamPtr          ; BC2E: 20 FB BB
    PLA                         ; BC31: 68
    TAX                         ; BC32: AA
    LDY $3F                     ; BC33: A4 3F
    LDA ($35),Y                 ; BC35: B1 35
    AND #$F8                    ; BC37: 29 F8
    STA SpawnRing,X             ; BC39: 9D 00 07
    LDA ($35),Y                 ; BC3C: B1 35
    AND #$07                    ; BC3E: 29 07
    STA $30                     ; BC40: 85 30
    INY                         ; BC42: C8
    TYA                         ; BC43: 98
    PHA                         ; BC44: 48
    LDA ($35),Y                 ; BC45: B1 35
    LDY #$00                    ; BC47: A0 00
    STY $38                     ; BC49: 84 38
    CMP #$FF                    ; BC4B: C9 FF
    BEQ LBC5F                   ; BC4D: F0 10
LBC4F:
    CMP $BCA8,Y                 ; BC4F: D9 A8 BC
    BCC LBC59                   ; BC52: 90 05
    CMP $BCA9,Y                 ; BC54: D9 A9 BC
    BCC LBC5F                   ; BC57: 90 06
LBC59:
    INC $38                     ; BC59: E6 38
    INY                         ; BC5B: C8
    INY                         ; BC5C: C8
    BNE LBC4F                   ; BC5D: D0 F0
LBC5F:
    LDY $38                     ; BC5F: A4 38
    LDA $BCBE,Y                 ; BC61: B9 BE BC
    CLC                         ; BC64: 18
    ADC $30                     ; BC65: 65 30
    TAY                         ; BC67: A8
    LDA $BCC9,Y                 ; BC68: B9 C9 BC
    STA $0703,X                 ; BC6B: 9D 03 07
    PLA                         ; BC6E: 68
    TAY                         ; BC6F: A8
    LDA $32                     ; BC70: A5 32
    STA $0701,X                 ; BC72: 9D 01 07
    LDA ($35),Y                 ; BC75: B1 35
    ORA #$80                    ; BC77: 09 80
    STA $0702,X                 ; BC79: 9D 02 07
    LDA #$FF                    ; BC7C: A9 FF
    STA $0704,X                 ; BC7E: 9D 04 07
    LDA #$00                    ; BC81: A9 00
    STA $0705,X                 ; BC83: 9D 05 07
    INY                         ; BC86: C8
    CPY #$10                    ; BC87: C0 10
    BNE LBC8F                   ; BC89: D0 04
    INC $32                     ; BC8B: E6 32
    LDY #$00                    ; BC8D: A0 00
LBC8F:
    STY $3F                     ; BC8F: 84 3F
    TXA                         ; BC91: 8A
    LDX $0338                   ; BC92: AE 38 03
    BNE LBCA0                   ; BC95: D0 09
    CLC                         ; BC97: 18
    ADC #$06                    ; BC98: 69 06
    CMP #$60                    ; BC9A: C9 60
    BNE LBCA0                   ; BC9C: D0 02
    LDA #$00                    ; BC9E: A9 00
LBCA0:
    STA $87                     ; BCA0: 85 87
    LDA #$00                    ; BCA2: A9 00
    STA $0338                   ; BCA4: 8D 38 03
    RTS                         ; BCA7: 60
    .byte $00,$18,$18,$20,$30,$38,$38,$39         ; BCA8: 00 18 18 20 30 38 38 39
    .byte $39,$3C,$3C,$43,$43,$45,$45,$47         ; BCB0: 39 3C 3C 43 43 45 45 47
    .byte $47,$4D,$4E,$5A,$FF,$FF,$10,$0D         ; BCB8: 47 4D 4E 5A FF FF 10 0D
    .byte $18,$0D,$0A,$00,$00,$0D,$04,$07         ; BCC0: 18 0D 0A 00 00 0D 04 07
    .byte $00,$30,$60,$98,$D0,$48,$80,$B8         ; BCC8: 00 30 60 98 D0 48 80 B8
    .byte $38,$68,$A0,$40,$68,$70,$40,$78         ; BCD0: 38 68 A0 40 68 70 40 78
    .byte $B0,$48,$58,$68,$78,$88,$98,$A8         ; BCD8: B0 48 58 68 78 88 98 A8
    .byte $B0,$30,$68,$A0                         ; BCE0: B0 30 68 A0
Word16ShlX:
    ; A→$22、0→$21，DEX 循环 ASL $22/ROL $21：16 位左移 X 次；bank1 $CCE5 JSR
    STA $22                     ; BCE4: 85 22
    LDA #$00                    ; BCE6: A9 00
    STA $21                     ; BCE8: 85 21
LBCEA:
    ASL $22                     ; BCEA: 06 22
    ROL $21                     ; BCEC: 26 21
    DEX                         ; BCEE: CA
    BNE LBCEA                   ; BCEF: D0 F9
    RTS                         ; BCF1: 60
LBCF2:
    ; ($21/$22)=A<<3X 与 ($23/$24)=A<<2X 求和（X=1 时=×12）：滚动渲染行算；bank1 $CC79 JSR
    STA $22                     ; BCF2: 85 22
    STA JoyBits                 ; BCF4: 85 24
    LDA #$00                    ; BCF6: A9 00
    STA $21                     ; BCF8: 85 21
    STA $23                     ; BCFA: 85 23
LBCFC:
    LDY #$03                    ; BCFC: A0 03
LBCFE:
    ASL $22                     ; BCFE: 06 22
    ROL $21                     ; BD00: 26 21
    DEY                         ; BD02: 88
    BNE LBCFE                   ; BD03: D0 F9
    LDY #$02                    ; BD05: A0 02
LBD07:
    ASL JoyBits                 ; BD07: 06 24
    ROL $23                     ; BD09: 26 23
    DEY                         ; BD0B: 88
    BNE LBD07                   ; BD0C: D0 F9
    DEX                         ; BD0E: CA
    BNE LBCFC                   ; BD0F: D0 EB
    LDA $22                     ; BD11: A5 22
    CLC                         ; BD13: 18
    ADC JoyBits                 ; BD14: 65 24
    STA $22                     ; BD16: 85 22
    LDA $21                     ; BD18: A5 21
    ADC $23                     ; BD1A: 65 23
    STA $21                     ; BD1C: 85 21
    RTS                         ; BD1E: 60
LBD1F:
    LDA $98                     ; BD1F: A5 98
    STA $32                     ; BD21: 85 32
    LDA $99                     ; BD23: A5 99
    STA $30                     ; BD25: 85 30
    JSR $CC6E                   ; BD27: 20 6E CC  -> Bank1:LCC6E
    INC $4D                     ; BD2A: E6 4D
    LDA $4D                     ; BD2C: A5 4D
    CMP #$03                    ; BD2E: C9 03
    BNE LBD38                   ; BD30: D0 06
    LDA #$00                    ; BD32: A9 00
    STA $4D                     ; BD34: 85 4D
    STA $86                     ; BD36: 85 86
LBD38:
    RTS                         ; BD38: 60
LBD39:
    LDA FrameCnt                ; BD39: A5 09
    AND #$01                    ; BD3B: 29 01
    BNE LBD42                   ; BD3D: D0 03
    JMP LBDC6                   ; BD3F: 4C C6 BD
LBD42:
    LDA $86                     ; BD42: A5 86
    BNE LBD1F                   ; BD44: D0 D9
LBD46:
    LDA PpuBufIdx               ; BD46: A5 11
    CMP #$10                    ; BD48: C9 10
    BCS LBDBC                   ; BD4A: B0 70
    LDA #$05                    ; BD4C: A9 05
    JSR L8456                   ; BD4E: 20 56 84
    LDA #$0A                    ; BD51: A9 0A
    JSR L8456                   ; BD53: 20 56 84
    LDA #$0F                    ; BD56: A9 0F
    JSR L8456                   ; BD58: 20 56 84
    LDA #$07                    ; BD5B: A9 07
    JSR PpuBufPutStr            ; BD5D: 20 AD 86
    LDA #$07                    ; BD60: A9 07
    STA TmpPtr                  ; BD62: 85 20
    LDA $05D8                   ; BD64: AD D8 05
    AND #$07                    ; BD67: 29 07
    TAY                         ; BD69: A8
    BEQ LBD71                   ; BD6A: F0 05
    LDA #$22                    ; BD6C: A9 22
    JSR LBDA3                   ; BD6E: 20 A3 BD
LBD71:
    JSR LBDAD                   ; BD71: 20 AD BD
    LDA #$17                    ; BD74: A9 17
    JSR PpuBufPutStr            ; BD76: 20 AD 86
    LDA #$05                    ; BD79: A9 05
    STA TmpPtr                  ; BD7B: 85 20
    LDY $05D6                   ; BD7D: AC D6 05
    BEQ LBD87                   ; BD80: F0 05
    LDA #$24                    ; BD82: A9 24
    JSR LBDA3                   ; BD84: 20 A3 BD
LBD87:
    JSR LBDAD                   ; BD87: 20 AD BD
    LDA #$16                    ; BD8A: A9 16
    JSR PpuBufPutStr            ; BD8C: 20 AD 86
    LDA #$02                    ; BD8F: A9 02
    STA TmpPtr                  ; BD91: 85 20
    LDY KeyCount                ; BD93: AC DF 05
    BEQ LBD9D                   ; BD96: F0 05
    LDA #$3C                    ; BD98: A9 3C
    JSR LBDA3                   ; BD9A: 20 A3 BD
LBD9D:
    JSR LBDAD                   ; BD9D: 20 AD BD
    JMP LBDBC                   ; BDA0: 4C BC BD
LBDA3:
    STA PpuBuf,X                ; BDA3: 9D 00 06
    INX                         ; BDA6: E8
    DEC TmpPtr                  ; BDA7: C6 20
    DEY                         ; BDA9: 88
    BNE LBDA3                   ; BDAA: D0 F7
    RTS                         ; BDAC: 60
LBDAD:
    LDA #$00                    ; BDAD: A9 00
LBDAF:
    STA PpuBuf,X                ; BDAF: 9D 00 06
    INX                         ; BDB2: E8
    DEC TmpPtr                  ; BDB3: C6 20
    BPL LBDAF                   ; BDB5: 10 F8
    STX PpuBufIdx               ; BDB7: 86 11
    JMP PpuBufPutFF             ; BDB9: 4C 00 87
LBDBC:
    LDA PlayerHp                ; BDBC: A5 A0
    CMP PlayerHpShown           ; BDBE: C5 A1
    BEQ LBDC5                   ; BDC0: F0 03
    JSR LBE87                   ; BDC2: 20 87 BE
LBDC5:
    RTS                         ; BDC5: 60
LBDC6:
    LDA $9A                     ; BDC6: A5 9A
    BEQ DispatchObjAi           ; BDC8: F0 0B
    CLC                         ; BDCA: 18
    ADC #$01                    ; BDCB: 69 01
    CMP #$04                    ; BDCD: C9 04
    BCC LBDD3                   ; BDCF: 90 02
    LDA #$00                    ; BDD1: A9 00
LBDD3:
    STA $9A                     ; BDD3: 85 9A
DispatchObjAi:
    ; $51==1 返；$8E&1 选 X=0/$5A 扫槽，$0702,X&$7F→Y，FrameCnt&2 相位与 Y/$43 门控，PpuBufIdx<$28 时 TYA→ObjTypeRemap→DispatchJump $BF10 表；bank1 $CB41 JSR
    LDA $51                     ; BDD5: A5 51
    CMP #$01                    ; BDD7: C9 01
    BEQ LBDC5                   ; BDD9: F0 EA
    LDX #$00                    ; BDDB: A2 00
    LDA $8E                     ; BDDD: A5 8E
    AND #$01                    ; BDDF: 29 01
    BNE LBDE5                   ; BDE1: D0 02
    LDX #$5A                    ; BDE3: A2 5A
LBDE5:
    LDA $0704,X                 ; BDE5: BD 04 07
    CMP #$FF                    ; BDE8: C9 FF
    BEQ LBE13                   ; BDEA: F0 27
    STX $3E                     ; BDEC: 86 3E
    LDA $0702,X                 ; BDEE: BD 02 07
    AND #$7F                    ; BDF1: 29 7F
    TAY                         ; BDF3: A8
    LDA FrameCnt                ; BDF4: A5 09
    AND #$02                    ; BDF6: 29 02
    BEQ LBE00                   ; BDF8: F0 06
    CPY #$43                    ; BDFA: C0 43
    BCS LBE13                   ; BDFC: B0 15
    BCC LBE04                   ; BDFE: 90 04
LBE00:
    CPY #$43                    ; BE00: C0 43
    BCC LBE13                   ; BE02: 90 0F
LBE04:
    LDA PpuBufIdx               ; BE04: A5 11
    CMP #$28                    ; BE06: C9 28
    BCS LBE35                   ; BE08: B0 2B
    TYA                         ; BE0A: 98
    JSR ObjTypeRemap            ; BE0B: 20 F8 BE
    JSR LBF0D                   ; BE0E: 20 0D BF
    LDX $3E                     ; BE11: A6 3E
LBE13:
    LDA $8E                     ; BE13: A5 8E
    AND #$01                    ; BE15: 29 01
    BNE LBE24                   ; BE17: D0 0B
    TXA                         ; BE19: 8A
    SEC                         ; BE1A: 38
    SBC #$06                    ; BE1B: E9 06
    TAX                         ; BE1D: AA
    CMP #$FA                    ; BE1E: C9 FA
    BEQ LBE2D                   ; BE20: F0 0B
    BNE LBDE5                   ; BE22: D0 C1
LBE24:
    TXA                         ; BE24: 8A
    CLC                         ; BE25: 18
    ADC #$06                    ; BE26: 69 06
    TAX                         ; BE28: AA
    CMP #$60                    ; BE29: C9 60
    BCC LBDE5                   ; BE2B: 90 B8
LBE2D:
    LDA FrameCnt                ; BE2D: A5 09
    AND #$02                    ; BE2F: 29 02
    BEQ LBE35                   ; BE31: F0 02
    INC $8E                     ; BE33: E6 8E
LBE35:
    RTS                         ; BE35: 60
LBE36:
    LDA HpDelta                 ; BE36: A5 9F
    AND #$7F                    ; BE38: 29 7F
    STA $30                     ; BE3A: 85 30
    LDA PlayerHp                ; BE3C: A5 A0
    LDY HpDelta                 ; BE3E: A4 9F
    BMI LBE54                   ; BE40: 30 12
    CMP #$17                    ; BE42: C9 17
    BEQ LBE7D                   ; BE44: F0 37
    CLC                         ; BE46: 18
    ADC $30                     ; BE47: 65 30
    CMP #$17                    ; BE49: C9 17
    BCC LBE4F                   ; BE4B: 90 02
    LDA #$17                    ; BE4D: A9 17
LBE4F:
    STA PlayerHp                ; BE4F: 85 A0
    JMP LBE82                   ; BE51: 4C 82 BE
LBE54:
    CMP #$FF                    ; BE54: C9 FF
    BEQ LBE7D                   ; BE56: F0 25
    SEC                         ; BE58: 38
    SBC $30                     ; BE59: E5 30
    BCS LBE5F                   ; BE5B: B0 02
    LDA #$FF                    ; BE5D: A9 FF
LBE5F:
    STA PlayerHp                ; BE5F: 85 A0
    CMP #$06                    ; BE61: C9 06
    BCS LBE7D                   ; BE63: B0 18
    LDA $51                     ; BE65: A5 51
    CMP #$01                    ; BE67: C9 01
    BEQ LBE7D                   ; BE69: F0 12
    LDA $07CB                   ; BE6B: AD CB 07
    BNE LBE82                   ; BE6E: D0 12
    LDA #$01                    ; BE70: A9 01
    STA $07CB                   ; BE72: 8D CB 07
    LDA #$1E                    ; BE75: A9 1E
    JSR $F08E                   ; BE77: 20 8E F0  -> Bank1:SoundCmd
    JMP LBE82                   ; BE7A: 4C 82 BE
LBE7D:
    LDA #$00                    ; BE7D: A9 00
    STA $07CB                   ; BE7F: 8D CB 07
LBE82:
    LDA #$00                    ; BE82: A9 00
    STA HpDelta                 ; BE84: 85 9F
    RTS                         ; BE86: 60
LBE87:
    LDA PlayerHp                ; BE87: A5 A0
    CMP #$FF                    ; BE89: C9 FF
    BEQ LBEA2                   ; BE8B: F0 15
    CMP PlayerHpShown           ; BE8D: C5 A1
    BCC LBEA2                   ; BE8F: 90 11
    INC PlayerHpShown           ; BE91: E6 A1
    LDA PlayerHpShown           ; BE93: A5 A1
    CMP #$17                    ; BE95: C9 17
    BCC LBE9F                   ; BE97: 90 06
    LDA #$17                    ; BE99: A9 17
    STA PlayerHpShown           ; BE9B: 85 A1
    STA PlayerHp                ; BE9D: 85 A0
LBE9F:
    JMP LBEB0                   ; BE9F: 4C B0 BE
LBEA2:
    DEC PlayerHpShown           ; BEA2: C6 A1
    LDA PlayerHpShown           ; BEA4: A5 A1
    CMP #$FF                    ; BEA6: C9 FF
    BNE LBEB0                   ; BEA8: D0 06
    LDA #$FF                    ; BEAA: A9 FF
    STA PlayerHpShown           ; BEAC: 85 A1
    STA PlayerHp                ; BEAE: 85 A0
LBEB0:
    LDA #$20                    ; BEB0: A9 20
    STA $36                     ; BEB2: 85 36
    LDA #$86                    ; BEB4: A9 86
    STA $35                     ; BEB6: 85 35
    LDA PlayerHpShown           ; BEB8: A5 A1
    CMP #$FF                    ; BEBA: C9 FF
    BEQ LBEE2                   ; BEBC: F0 24
    AND #$FC                    ; BEBE: 29 FC
    LSR A                       ; BEC0: 4A
    LSR A                       ; BEC1: 4A
    JSR $C013                   ; BEC2: 20 13 C0  -> Bank1:Ptr16Add
    LDA PlayerHpShown           ; BEC5: A5 A1
    CMP #$17                    ; BEC7: C9 17
    BEQ LBEED                   ; BEC9: F0 22
    AND #$03                    ; BECB: 29 03
    TAY                         ; BECD: A8
LBECE:
    JSR PpuBufPutAddr           ; BECE: 20 A4 BF
LBED1:
    LDA $BEF2,Y                 ; BED1: B9 F2 BE
    INX                         ; BED4: E8
    STA PpuBuf,X                ; BED5: 9D 00 06
    CPY #$03                    ; BED8: C0 03
    BNE LBEDF                   ; BEDA: D0 03
    INY                         ; BEDC: C8
    BNE LBED1                   ; BEDD: D0 F2
LBEDF:
    JMP PpuBufCloseAtX          ; BEDF: 4C 13 87
LBEE2:
    LDX #$01                    ; BEE2: A2 01
    LDA #$01                    ; BEE4: A9 01
    JSR LA301                   ; BEE6: 20 01 A3
    LDY #$04                    ; BEE9: A0 04
    BNE LBECE                   ; BEEB: D0 E1
LBEED:
    LDY #$05                    ; BEED: A0 05
    BNE LBECE                   ; BEEF: D0 DD
    RTS                         ; BEF1: 60
    .byte $AF,$AE,$AD,$AC,$9F,$AC                 ; BEF2: AF AE AD AC 9F AC
ObjTypeRemap:
    ; A<$18→0、<$30→1、否则 A-$2E；DispatchObjAi 内 JSR，bank1 $CF4D/$CF79 亦 JSR
    CMP #$18                    ; BEF8: C9 18
    BCS LBF00                   ; BEFA: B0 04
    LDA #$00                    ; BEFC: A9 00
    BEQ LBF0C                   ; BEFE: F0 0C
LBF00:
    CMP #$30                    ; BF00: C9 30
    BCS LBF09                   ; BF02: B0 05
    LDA #$01                    ; BF04: A9 01
    JMP LBF0C                   ; BF06: 4C 0C BF
LBF09:
    SEC                         ; BF09: 38
    SBC #$2E                    ; BF0A: E9 2E
LBF0C:
    RTS                         ; BF0C: 60
LBF0D:
    JSR DispatchJump            ; BF0D: 20 9A 85
    .byte $0C,$C7,$04,$C9,$55,$C2,$55,$C2         ; BF10: 0C C7 04 C9 55 C2 55 C2
    .byte $D9,$C3,$D9,$C3,$D9,$C3,$92,$C2         ; BF18: D9 C3 D9 C3 D9 C3 92 C2
    .byte $92,$C2,$52,$C2,$75,$C9,$E0,$C5         ; BF20: 92 C2 52 C2 75 C9 E0 C5
    .byte $E6,$C5,$EC,$C5,$3C,$C4,$3C,$C4         ; BF28: E6 C5 EC C5 3C C4 3C C4
    .byte $3C,$C4,$3C,$C4,$3C,$C4,$3C,$C4         ; BF30: 3C C4 3C C4 3C C4 3C C4
    .byte $3C,$C4,$F3,$C4,$F3,$C4,$97,$C6         ; BF38: 3C C4 F3 C4 F3 C4 97 C6
    .byte $9F,$C6,$E0,$C7,$E4,$C7,$E8,$C7         ; BF40: 9F C6 E0 C7 E4 C7 E8 C7
    .byte $E0,$C7,$E4,$C7,$E8,$C7,$EE,$C0         ; BF48: E0 C7 E4 C7 E8 C7 EE C0
    .byte $EF,$C0,$F5,$C0,$FB,$C0,$EF,$C0         ; BF50: EF C0 F5 C0 FB C0 EF C0
    .byte $F5,$C0,$EF,$C0,$EF,$C0,$F5,$C0         ; BF58: F5 C0 EF C0 EF C0 F5 C0
    .byte $FB,$C0,$EF,$C0,$F5,$C0,$EF,$C0         ; BF60: FB C0 EF C0 F5 C0 EF C0
ObjPpuAddr:
    STX $33                     ; BF68: 86 33
    STA $34                     ; BF6A: 85 34
    LDX $3E                     ; BF6C: A6 3E
    LDY #$20                    ; BF6E: A0 20
    LDA $0701,X                 ; BF70: BD 01 07
    AND #$01                    ; BF73: 29 01
    BEQ LBF79                   ; BF75: F0 02
    LDY #$24                    ; BF77: A0 24
LBF79:
    STY $36                     ; BF79: 84 36
    LDA SpawnRing,X             ; BF7B: BD 00 07
    AND #$F8                    ; BF7E: 29 F8
    LSR A                       ; BF80: 4A
    LSR A                       ; BF81: 4A
    LSR A                       ; BF82: 4A
    STA $35                     ; BF83: 85 35
    LDA $0703,X                 ; BF85: BD 03 07
    AND #$F8                    ; BF88: 29 F8
    LSR A                       ; BF8A: 4A
    LSR A                       ; BF8B: 4A
    LSR A                       ; BF8C: 4A
    STX $3E                     ; BF8D: 86 3E
    LDX #$05                    ; BF8F: A2 05
    JSR Word16ShlX              ; BF91: 20 E4 BC
    LDX $3E                     ; BF94: A6 3E
    LDA $35                     ; BF96: A5 35
    CLC                         ; BF98: 18
    ADC $22                     ; BF99: 65 22
    STA $35                     ; BF9B: 85 35
    LDA $36                     ; BF9D: A5 36
    ADC $21                     ; BF9F: 65 21
    STA $36                     ; BFA1: 85 36
    RTS                         ; BFA3: 60
PpuBufPutAddr:
    ; PpuBuf 写入命令头 $01+PPU 地址（$36=高/$35=低）；DrawHudItem/LCC6E 等建屏路径的生产端
    LDA #$01                    ; BFA4: A9 01
LBFA6:
    JSR PpuBufPut               ; BFA6: 20 0A 87
    LDA $36                     ; BFA9: A5 36
    STA PpuBuf,X                ; BFAB: 9D 00 06
    INX                         ; BFAE: E8
    LDA $35                     ; BFAF: A5 35
    STA PpuBuf,X                ; BFB1: 9D 00 06
    RTS                         ; BFB4: 60
PpuBufPutTiles:
    JSR PpuBufPutAddr           ; BFB5: 20 A4 BF
    JMP PpuBufTileStream        ; BFB8: 4C C0 BF
PpuBufPutAddrV:
    ; A=2 入 $BFA6：命令 2（垂直写）版 PpuBufPutAddr
    LDA #$02                    ; BFBB: A9 02
    JSR LBFA6                   ; BFBD: 20 A6 BF
PpuBufTileStream:
    INX                         ; BFC0: E8
    LDA ($33),Y                 ; BFC1: B1 33
    CMP #$30                    ; BFC3: C9 30
    BEQ LBFD3                   ; BFC5: F0 0C
    STA PpuBuf,X                ; BFC7: 9D 00 06
    INY                         ; BFCA: C8
    CMP #$FF                    ; BFCB: C9 FF
    BNE PpuBufTileStream        ; BFCD: D0 F1
    INX                         ; BFCF: E8
    STX PpuBufIdx               ; BFD0: 86 11
    RTS                         ; BFD2: 60
LBFD3:
    INY                         ; BFD3: C8
    LDA ($33),Y                 ; BFD4: B1 33
    STA TmpPtr                  ; BFD6: 85 20
    INY                         ; BFD8: C8
    LDA ($33),Y                 ; BFD9: B1 33
LBFDB:
    STA PpuBuf,X                ; BFDB: 9D 00 06
    INX                         ; BFDE: E8
    DEC TmpPtr                  ; BFDF: C6 20
    BNE LBFDB                   ; BFE1: D0 F8
    DEX                         ; BFE3: CA
    INY                         ; BFE4: C8
    JMP PpuBufTileStream        ; BFE5: 4C C0 BF
LBFE8:
    STA $37                     ; BFE8: 85 37
LBFEA:
    JSR PpuBufPutAddr           ; BFEA: 20 A4 BF
LBFED:
    INX                         ; BFED: E8
    LDA ($33),Y                 ; BFEE: B1 33
    STA PpuBuf,X                ; BFF0: 9D 00 06
    INY                         ; BFF3: C8
    LDA ($33),Y                 ; BFF4: B1 33
    CMP #$FE                    ; BFF6: C9 FE
    BEQ $C00F                   ; BFF8: F0 15  -> Bank1:LC00F
    LDA $37                     ; BFFA: A5 37
    BEQ LBFED                   ; BFFC: F0 EF
    ; 跨界指令 JSR $8713：第三字节在 bank1 $C000；RTS 后 CPU 流入 bank1 $C001（TileStreamAdv8）
    JSR PpuBufCloseAtX          ; BFFE: 20 13 87
