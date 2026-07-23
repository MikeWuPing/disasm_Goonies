; === Goonies RC809 — Bank 1 (base $C000) ===
; 本文件由 tools/disasm 自动生成，请勿手工编辑
.include "goonies.inc"

    .byte $87                                     ; C000: 87
TileStreamAdv8:
    ; tile 流跨界续段：bank0 $BFFE JSR $8713 返回后流入；$35/$36 += 8（进位 INC $36）后 JMP $BFEA 重发地址续写
    LDA $35                     ; C001: A5 35
    CLC                         ; C003: 18
    ADC #$08                    ; C004: 69 08
    STA $35                     ; C006: 85 35
    BCC $BFEA                   ; C008: 90 E0  -> Bank0:LBFEA
    INC $36                     ; C00A: E6 36
    JMP $BFEA                   ; C00C: 4C EA BF  -> Bank0:LBFEA
LC00F:
    JSR $8713                   ; C00F: 20 13 87  -> Bank0:PpuBufCloseAtX
    RTS                         ; C012: 60
Ptr16Add:
    ; CLC 后 $35 += A、进位 INC $36：16 位指针加；HP 条 $BEB2 与 AI $C2F1/$C400 等多处 JSR
    CLC                         ; C013: 18
    ADC $35                     ; C014: 65 35
    STA $35                     ; C016: 85 35
    BCC LC01C                   ; C018: 90 02
    INC $36                     ; C01A: E6 36
LC01C:
    RTS                         ; C01C: 60
RecAttrAddr:
    ; $35/$36 双右移×2：低 3 位→$30，再 ×2 取 & $38 ORA；$0701,X 位0 选基 $23/$27，$35=$C0+$30（属性表 $23C0/$27C0）；LC47B 等门绘制路径调用
    STY $3F                     ; C01D: 84 3F
    LSR $36                     ; C01F: 46 36
    ROR $35                     ; C021: 66 35
    LSR $36                     ; C023: 46 36
    ROR $35                     ; C025: 66 35
    LDA $35                     ; C027: A5 35
    AND #$07                    ; C029: 29 07
    STA $30                     ; C02B: 85 30
    LSR $36                     ; C02D: 46 36
    ROR $35                     ; C02F: 66 35
    LSR $36                     ; C031: 46 36
    ROR $35                     ; C033: 66 35
    LDA $35                     ; C035: A5 35
    AND #$38                    ; C037: 29 38
    ORA $30                     ; C039: 05 30
    STA $30                     ; C03B: 85 30
    LDY #$23                    ; C03D: A0 23
    LDX $3E                     ; C03F: A6 3E
    LDA $0701,X                 ; C041: BD 01 07
    AND #$01                    ; C044: 29 01
    BEQ LC04A                   ; C046: F0 02
    LDY #$27                    ; C048: A0 27
LC04A:
    STY $36                     ; C04A: 84 36
    LDA #$C0                    ; C04C: A9 C0
    CLC                         ; C04E: 18
    ADC $30                     ; C04F: 65 30
    STA $35                     ; C051: 85 35
    BCC LC057                   ; C053: 90 02
    INC $36                     ; C055: E6 36
LC057:
    LDY $3F                     ; C057: A4 3F
    RTS                         ; C059: 60
LC05A:
    LDA #$38                    ; C05A: A9 38
    LDY #$12                    ; C05C: A0 12
    BNE LC064                   ; C05E: D0 04
RecProxCheck:
    ; 距离阈值（$32/$31 零页）预设 #$32/#$20（LC05A 变体 #$38/#$12，LC089 为直写桩）：$0548≠0 时以槽 8 位（或玩家位 LC08D）与记录 $0703/$0704 算双向距离，$0702 位7（已激活）跳过；双轴均入阈值则 SEC；LC0FF 公共尾与 $BF10 表多处理器调用
    LDA #$32                    ; C060: A9 32
    LDY #$20                    ; C062: A0 20
LC064:
    STA $32                     ; C064: 85 32
    STY $31                     ; C066: 84 31
    LDA $0548                   ; C068: AD 48 05
    BEQ LC0E7                   ; C06B: F0 7A
    LDA $0468                   ; C06D: AD 68 04
    STA $33                     ; C070: 85 33
    LDA $0478                   ; C072: AD 78 04
    CMP #$0C                    ; C075: C9 0C
    BCC LC07F                   ; C077: 90 06
    SEC                         ; C079: 38
    SBC #$0C                    ; C07A: E9 0C
    JMP LC084                   ; C07C: 4C 84 C0
LC07F:
    LDA #$0C                    ; C07F: A9 0C
    SBC $0478                   ; C081: ED 78 04
LC084:
    STA $34                     ; C084: 85 34
    JMP LC097                   ; C086: 4C 97 C0
LC089:
    STA $32                     ; C089: 85 32
    STY $31                     ; C08B: 84 31
LC08D:
    LDA $0461                   ; C08D: AD 61 04
    STA $33                     ; C090: 85 33
    LDA $0471                   ; C092: AD 71 04
    STA $34                     ; C095: 85 34
LC097:
    LDA $0418                   ; C097: AD 18 04
    BNE LC0E7                   ; C09A: D0 4B
    LDA $0702,X                 ; C09C: BD 02 07
    AND #$80                    ; C09F: 29 80
    BNE LC0E7                   ; C0A1: D0 44
    LDA $33                     ; C0A3: A5 33
    CMP $0703,X                 ; C0A5: DD 03 07
    BCC LC0E7                   ; C0A8: 90 3D
    SEC                         ; C0AA: 38
    SBC $0703,X                 ; C0AB: FD 03 07
    CMP $32                     ; C0AE: C5 32
    BCS LC0E7                   ; C0B0: B0 35
    LDA $0704,X                 ; C0B2: BD 04 07
    STA $A2                     ; C0B5: 85 A2
    LDA $0702,X                 ; C0B7: BD 02 07
    CMP #$18                    ; C0BA: C9 18
    BCC LC0D3                   ; C0BC: 90 15
    CMP #$20                    ; C0BE: C9 20
    BCS LC0D3                   ; C0C0: B0 11
    LDA StageId                 ; C0C2: A5 80
    CMP $0701,X                 ; C0C4: DD 01 07
    BNE LC0D3                   ; C0C7: D0 0A
    LDA $A2                     ; C0C9: A5 A2
    CMP #$E0                    ; C0CB: C9 E0
    BCC LC0D3                   ; C0CD: 90 04
    LDA #$00                    ; C0CF: A9 00
    STA $A2                     ; C0D1: 85 A2
LC0D3:
    LDA $34                     ; C0D3: A5 34
    SEC                         ; C0D5: 38
    SBC $A2                     ; C0D6: E5 A2
    STA $30                     ; C0D8: 85 30
    BCS LC0E1                   ; C0DA: B0 05
    LDA #$00                    ; C0DC: A9 00
    SEC                         ; C0DE: 38
    SBC $30                     ; C0DF: E5 30
LC0E1:
    CMP $31                     ; C0E1: C5 31
    BCS LC0E7                   ; C0E3: B0 02
    SEC                         ; C0E5: 38
    RTS                         ; C0E6: 60
LC0E7:
    LDA #$00                    ; C0E7: A9 00
    STA $0339                   ; C0E9: 8D 39 03
    CLC                         ; C0EC: 18
    RTS                         ; C0ED: 60
LC0EE:
    RTS                         ; C0EE: 60
LC0EF:
    LDY #$03                    ; C0EF: A0 03
    LDA #$38                    ; C0F1: A9 38
    BNE LC0FF                   ; C0F3: D0 0A
LC0F5:
    LDY #$04                    ; C0F5: A0 04
    LDA #$70                    ; C0F7: A9 70
    BNE LC0FF                   ; C0F9: D0 04
LC0FB:
    LDY #$06                    ; C0FB: A0 06
    LDA #$90                    ; C0FD: A9 90
LC0FF:
    STY $37                     ; C0FF: 84 37
    STA $32                     ; C101: 85 32
    LDX $3E                     ; C103: A6 3E
    LDA $0702,X                 ; C105: BD 02 07
    AND #$7F                    ; C108: 29 7F
    STA $39                     ; C10A: 85 39
    LDA $0705,X                 ; C10C: BD 05 07
    BNE LC137                   ; C10F: D0 26
    LDA $0702,X                 ; C111: BD 02 07
    BMI LC136                   ; C114: 30 20
    LDA $0704,X                 ; C116: BD 04 07
    CMP #$10                    ; C119: C9 10
    BCC LC136                   ; C11B: 90 19
    CMP #$F0                    ; C11D: C9 F0
    BCS LC136                   ; C11F: B0 15
    LDA $39                     ; C121: A5 39
    CMP #$54                    ; C123: C9 54
    BCS LC137                   ; C125: B0 10
    LDA FrameCnt                ; C127: A5 09
    AND #$03                    ; C129: 29 03
    TAY                         ; C12B: A8
    LDA $C23E,Y                 ; C12C: B9 3E C2
    STA $31                     ; C12F: 85 31
    JSR LC08D                   ; C131: 20 8D C0
    BCS LC137                   ; C134: B0 01
LC136:
    RTS                         ; C136: 60
LC137:
    LDA $39                     ; C137: A5 39
    CMP #$54                    ; C139: C9 54
    BCC LC142                   ; C13B: 90 05
    SBC #$54                    ; C13D: E9 54
    JMP LC145                   ; C13F: 4C 45 C1
LC142:
    SEC                         ; C142: 38
    SBC #$4E                    ; C143: E9 4E
LC145:
    ASL A                       ; C145: 0A
    TAY                         ; C146: A8
    LDA $C246,Y                 ; C147: B9 46 C2
    STA $32                     ; C14A: 85 32
    LDA $C247,Y                 ; C14C: B9 47 C2
    STA $31                     ; C14F: 85 31
    LDA $0705,X                 ; C151: BD 05 07
    BEQ LC159                   ; C154: F0 03
    JMP LC1DB                   ; C156: 4C DB C1
LC159:
    LDY #$00                    ; C159: A0 00
StaticOamAlloc:
    ; $021C,Y（槽 7-10）步 4 找 Y==$F4 空槽：写入记录 Y 参数/X 位/帧相位动画 tile（$ED/$EA 系），$0705,X 置位 7-4 作占用标记；LC137（静态记录物绘制）体内
    LDA $021C,Y                 ; C15B: B9 1C 02
    CMP #$F4                    ; C15E: C9 F4
    BEQ LC16B                   ; C160: F0 09
    INY                         ; C162: C8
    INY                         ; C163: C8
    INY                         ; C164: C8
    INY                         ; C165: C8
    CPY #$10                    ; C166: C0 10
    BNE StaticOamAlloc          ; C168: D0 F1
    RTS                         ; C16A: 60
LC16B:
    TYA                         ; C16B: 98
    ORA #$F0                    ; C16C: 09 F0
    STA $0705,X                 ; C16E: 9D 05 07
    LDA $0703,X                 ; C171: BD 03 07
    STA $021C,Y                 ; C174: 99 1C 02
    LDA $0704,X                 ; C177: BD 04 07
    STA $021F,Y                 ; C17A: 99 1F 02
    LDA $39                     ; C17D: A5 39
    CMP #$54                    ; C17F: C9 54
    BCC LC18E                   ; C181: 90 0B
    LDA #$EA                    ; C183: A9 EA
    STA $021D,Y                 ; C185: 99 1D 02
    LDA #$22                    ; C188: A9 22
    STA $021E,Y                 ; C18A: 99 1E 02
    RTS                         ; C18D: 60
LC18E:
    LDA #$ED                    ; C18E: A9 ED
    STA $021D,Y                 ; C190: 99 1D 02
    LDA #$20                    ; C193: A9 20
    LDX StageArea               ; C195: A6 A3
    CPX #$04                    ; C197: E0 04
    BNE LC1A1                   ; C199: D0 06
    LDX StageId                 ; C19B: A6 80
    CPX #$64                    ; C19D: E0 64
    BCS LC1A3                   ; C19F: B0 02
LC1A1:
    LDA #$23                    ; C1A1: A9 23
LC1A3:
    STA $021E,Y                 ; C1A3: 99 1E 02
    STY $3F                     ; C1A6: 84 3F
    LDX $C242                   ; C1A8: AE 42 C2
    LDA $C243                   ; C1AB: AD 43 C2
    JSR $BF68                   ; C1AE: 20 68 BF  -> Bank0:ObjPpuAddr
    LDA $35                     ; C1B1: A5 35
    LDY $36                     ; C1B3: A4 36
    JSR LCE94                   ; C1B5: 20 94 CE
    LDY #$02                    ; C1B8: A0 02
    LDX $9D                     ; C1BA: A6 9D
LC1BC:
    LDA TerrainMap,X            ; C1BC: BD 40 03
    ORA $9E                     ; C1BF: 05 9E
    EOR $9E                     ; C1C1: 45 9E
    STA TerrainMap,X            ; C1C3: 9D 40 03
    DEY                         ; C1C6: 88
    BEQ LC1D4                   ; C1C7: F0 0B
    CLC                         ; C1C9: 18
    ASL $9E                     ; C1CA: 06 9E
    BCC LC1BC                   ; C1CC: 90 EE
    ROL $9E                     ; C1CE: 26 9E
    INX                         ; C1D0: E8
    JMP LC1BC                   ; C1D1: 4C BC C1
LC1D4:
    LDY #$00                    ; C1D4: A0 00
    JSR $BFB5                   ; C1D6: 20 B5 BF  -> Bank0:PpuBufPutTiles
    LDX $3E                     ; C1D9: A6 3E
LC1DB:
    LDA $0705,X                 ; C1DB: BD 05 07
    AND #$0F                    ; C1DE: 29 0F
    TAY                         ; C1E0: A8
    LDA $0702,X                 ; C1E1: BD 02 07
    BMI LC21F                   ; C1E4: 30 39
    LDA $0704,X                 ; C1E6: BD 04 07
    CMP #$F8                    ; C1E9: C9 F8
    BCS LC21F                   ; C1EB: B0 32
    STA $021F,Y                 ; C1ED: 99 1F 02
    LDA $39                     ; C1F0: A5 39
    CMP #$54                    ; C1F2: C9 54
    BCC LC20E                   ; C1F4: 90 18
    LDA $0705,X                 ; C1F6: BD 05 07
    AND #$F0                    ; C1F9: 29 F0
    CMP #$80                    ; C1FB: C9 80
    BEQ LC209                   ; C1FD: F0 0A
    LDA $0705,X                 ; C1FF: BD 05 07
    SEC                         ; C202: 38
    SBC #$10                    ; C203: E9 10
    STA $0705,X                 ; C205: 9D 05 07
    RTS                         ; C208: 60
LC209:
    LDA #$EB                    ; C209: A9 EB
    STA $021D,Y                 ; C20B: 99 1D 02
LC20E:
    LDA $0703,X                 ; C20E: BD 03 07
    CLC                         ; C211: 18
    ADC $37                     ; C212: 65 37
    CMP $32                     ; C214: C5 32
    BCS LC21F                   ; C216: B0 07
    STA $0703,X                 ; C218: 9D 03 07
    STA $021C,Y                 ; C21B: 99 1C 02
    RTS                         ; C21E: 60
LC21F:
    LDA #$F4                    ; C21F: A9 F4
    STA $021C,Y                 ; C221: 99 1C 02
    LDA $39                     ; C224: A5 39
    CMP #$54                    ; C226: C9 54
    BCC LC235                   ; C228: 90 0B
    LDA $31                     ; C22A: A5 31
    STA $0703,X                 ; C22C: 9D 03 07
    LDA #$00                    ; C22F: A9 00
    STA $0705,X                 ; C231: 9D 05 07
    RTS                         ; C234: 60
LC235:
    LDA #$FF                    ; C235: A9 FF
    STA $0702,X                 ; C237: 9D 02 07
    STA $0704,X                 ; C23A: 9D 04 07
    RTS                         ; C23D: 60
    .byte $30,$28,$20,$10,$44,$C2,$00,$FF         ; C23E: 30 28 20 10 44 C2 00 FF
    .byte $5C,$3D,$94,$3D,$CC,$3D,$94,$6D         ; C246: 5C 3D 94 3D CC 3D 94 6D
    .byte $CC,$6D,$CC,$A3                         ; C24E: CC 6D CC A3
LC252:
    JMP LC292                   ; C252: 4C 92 C2
LC255:
    LDX $3E                     ; C255: A6 3E
    LDA $0705,X                 ; C257: BD 05 07
    BEQ LC27D                   ; C25A: F0 21
    AND #$F0                    ; C25C: 29 F0
    CMP #$B0                    ; C25E: C9 B0
    BNE LC27A                   ; C260: D0 18
    LDY BossDoorSeq             ; C262: AC 37 03
    BEQ LC291                   ; C265: F0 2A
    CPY #$02                    ; C267: C0 02
    BEQ LC291                   ; C269: F0 26
    LDA #$00                    ; C26B: A9 00
    STA KeyCount                ; C26D: 8D DF 05
    LDA #$C4                    ; C270: A9 C4
    STA $0705,X                 ; C272: 9D 05 07
    LDA #$02                    ; C275: A9 02
    STA BossDoorSeq             ; C277: 8D 37 03
LC27A:
    JMP LC292                   ; C27A: 4C 92 C2
LC27D:
    LDA BossDoorSeq             ; C27D: AD 37 03
    BEQ LC28E                   ; C280: F0 0C
    LDA #$37                    ; C282: A9 37
    STA $0702,X                 ; C284: 9D 02 07
    LDA #$B0                    ; C287: A9 B0
    STA $0705,X                 ; C289: 9D 05 07
    BNE LC291                   ; C28C: D0 03
LC28E:
    JMP LC3D9                   ; C28E: 4C D9 C3
LC291:
    RTS                         ; C291: 60
LC292:
    LDA #$05                    ; C292: A9 05
    STA $32                     ; C294: 85 32
    LDX $3E                     ; C296: A6 3E
    LDA $0705,X                 ; C298: BD 05 07
    BPL LC2A8                   ; C29B: 10 0B
    AND #$F0                    ; C29D: 29 F0
    CMP #$80                    ; C29F: C9 80
    BEQ LC2CA                   ; C2A1: F0 27
    CMP #$B0                    ; C2A3: C9 B0
    BNE LC2C5                   ; C2A5: D0 1E
LC2A7:
    RTS                         ; C2A7: 60
LC2A8:
    LDA $0705,X                 ; C2A8: BD 05 07
    BEQ LC2A7                   ; C2AB: F0 FA
    CMP #$05                    ; C2AD: C9 05
    BCC LC2CA                   ; C2AF: 90 19
    LDA $0705,X                 ; C2B1: BD 05 07
    SEC                         ; C2B4: 38
    SBC #$01                    ; C2B5: E9 01
    STA $0705,X                 ; C2B7: 9D 05 07
    CMP #$06                    ; C2BA: C9 06
    BNE LC2A7                   ; C2BC: D0 E9
    LDA #$00                    ; C2BE: A9 00
    STA $0705,X                 ; C2C0: 9D 05 07
    BEQ LC2D3                   ; C2C3: F0 0E
LC2C5:
    LDA $0548                   ; C2C5: AD 48 05
    BNE LC343                   ; C2C8: D0 79
LC2CA:
    LDA FrameCnt                ; C2CA: A5 09
    AND #$0E                    ; C2CC: 29 0E
    CMP #$0E                    ; C2CE: C9 0E
    BEQ LC2D3                   ; C2D0: F0 01
    RTS                         ; C2D2: 60
LC2D3:
    LDX $C34E                   ; C2D3: AE 4E C3
    LDA $C34F                   ; C2D6: AD 4F C3
    JSR $BF68                   ; C2D9: 20 68 BF  -> Bank0:ObjPpuAddr
    JSR LC423                   ; C2DC: 20 23 C4
    LDA $0705,X                 ; C2DF: BD 05 07
    AND #$0F                    ; C2E2: 29 0F
    CLC                         ; C2E4: 18
    ADC $30                     ; C2E5: 65 30
    TAY                         ; C2E7: A8
    LDA $C344,Y                 ; C2E8: B9 44 C3
    TAY                         ; C2EB: A8
    JSR $BFBB                   ; C2EC: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDA #$01                    ; C2EF: A9 01
    JSR Ptr16Add                ; C2F1: 20 13 C0
    JSR $BFBB                   ; C2F4: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDX $3E                     ; C2F7: A6 3E
    LDA $0705,X                 ; C2F9: BD 05 07
    AND #$C0                    ; C2FC: 29 C0
    CMP #$C0                    ; C2FE: C9 C0
    BNE LC31D                   ; C300: D0 1B
    DEC $0705,X                 ; C302: DE 05 07
    LDA $0705,X                 ; C305: BD 05 07
    AND #$0F                    ; C308: 29 0F
    BNE LC343                   ; C30A: D0 37
    LDY #$36                    ; C30C: A0 36
    LDA $0702,X                 ; C30E: BD 02 07
    CMP #$35                    ; C311: C9 35
    BEQ LC317                   ; C313: F0 02
    LDY #$37                    ; C315: A0 37
LC317:
    TYA                         ; C317: 98
    STA $0702,X                 ; C318: 9D 02 07
    BNE LC343                   ; C31B: D0 26
LC31D:
    INC $0705,X                 ; C31D: FE 05 07
    LDA $0705,X                 ; C320: BD 05 07
    AND #$0F                    ; C323: 29 0F
    CMP #$01                    ; C325: C9 01
    BNE LC33A                   ; C327: D0 11
    LDY #$35                    ; C329: A0 35
    LDA $0702,X                 ; C32B: BD 02 07
    CMP #$36                    ; C32E: C9 36
    BEQ LC334                   ; C330: F0 02
    LDY #$30                    ; C332: A0 30
LC334:
    TYA                         ; C334: 98
    STA $0702,X                 ; C335: 9D 02 07
    BNE LC343                   ; C338: D0 09
LC33A:
    CMP $32                     ; C33A: C5 32
    BNE LC343                   ; C33C: D0 05
    ORA #$B0                    ; C33E: 09 B0
    STA $0705,X                 ; C340: 9D 05 07
LC343:
    RTS                         ; C343: 60
    .byte $00,$08,$16,$24,$32,$40,$48,$54         ; C344: 00 08 16 24 32 40 48 54
    .byte $62,$70,$50,$C3,$30,$06,$00,$FF         ; C34C: 62 70 50 C3 30 06 00 FF
    .byte $30,$06,$00,$FF,$3A,$4A,$4A,$6A         ; C354: 30 06 00 FF 3A 4A 4A 6A
    .byte $6A,$7A,$FF,$3B,$4B,$4B,$6B,$6B         ; C35C: 6A 7A FF 3B 4B 4B 6B 6B
    .byte $7B,$FF,$C4,$D4,$D4,$6A,$6A,$7A         ; C364: 7B FF C4 D4 D4 6A 6A 7A
    .byte $FF,$C7,$D7,$D7,$E7,$E7,$F7,$FF         ; C36C: FF C7 D7 D7 E7 E7 F7 FF
    .byte $A8,$B8,$B8,$A2,$A2,$C5,$FF,$A9         ; C374: A8 B8 B8 A2 A2 C5 FF A9
    .byte $B9,$B9,$A3,$A3,$C6,$FF,$8A,$98         ; C37C: B9 B9 A3 A3 C6 FF 8A 98
    .byte $98,$9A,$9A,$AA,$FF,$8B,$99,$99         ; C384: 98 9A 9A AA FF 8B 99 99
    .byte $9B,$9B,$AB,$FF,$30,$06,$00,$FF         ; C38C: 9B 9B AB FF 30 06 00 FF
    .byte $30,$06,$00,$FF,$07,$30,$04,$07         ; C394: 30 06 00 FF 07 30 04 07
    .byte $07,$FF,$08,$30,$04,$08,$08,$FF         ; C39C: 07 FF 08 30 04 08 08 FF
    .byte $09,$09,$09,$09,$09,$09,$FF,$0A         ; C3A4: 09 09 09 09 09 09 FF 0A
    .byte $0A,$0A,$0A,$0A,$0A,$FF,$0B,$0B         ; C3AC: 0A 0A 0A 0A 0A FF 0B 0B
    .byte $0B,$0B,$0B,$0B,$FF,$0C,$0C,$0C         ; C3B4: 0B 0B 0B 0B FF 0C 0C 0C
    .byte $0C,$0C,$0C,$FF,$30,$06,$0D,$FF         ; C3BC: 0C 0C 0C FF 30 06 0D FF
    .byte $30,$06,$0E,$FF,$20,$21,$FF,$31         ; C3C4: 30 06 0E FF 20 21 FF 31
    .byte $FF,$32,$FF,$33,$FF,$34,$FF,$35         ; C3CC: FF 32 FF 33 FF 34 FF 35
    .byte $FF,$36,$FF,$37,$FF                     ; C3D4: FF 36 FF 37 FF
LC3D9:
    LDX $3E                     ; C3D9: A6 3E
    LDA $0705,X                 ; C3DB: BD 05 07
    BNE LC422                   ; C3DE: D0 42
    LDA #$B0                    ; C3E0: A9 B0
    STA $0705,X                 ; C3E2: 9D 05 07
    LDX $C34E                   ; C3E5: AE 4E C3
    LDA $C34F                   ; C3E8: AD 4F C3
    JSR $BF68                   ; C3EB: 20 68 BF  -> Bank0:ObjPpuAddr
    JSR LC423                   ; C3EE: 20 23 C4
    LDA $30                     ; C3F1: A5 30
    CLC                         ; C3F3: 18
    ADC #$04                    ; C3F4: 69 04
    TAY                         ; C3F6: A8
    LDA $C344,Y                 ; C3F7: B9 44 C3
    TAY                         ; C3FA: A8
    JSR $BFBB                   ; C3FB: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDA #$01                    ; C3FE: A9 01
    JSR Ptr16Add                ; C400: 20 13 C0
    JSR $BFBB                   ; C403: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDX $3E                     ; C406: A6 3E
    LDA $0702,X                 ; C408: BD 02 07
    AND #$7F                    ; C40B: 29 7F
    CMP #$32                    ; C40D: C9 32
    BCS LC422                   ; C40F: B0 11
    LDY #$42                    ; C411: A0 42
    CMP #$30                    ; C413: C9 30
    BEQ LC419                   ; C415: F0 02
    LDY #$3D                    ; C417: A0 3D
LC419:
    TYA                         ; C419: 98
    JSR Ptr16Add                ; C41A: 20 13 C0
    LDY #$78                    ; C41D: A0 78
    JSR $BFBB                   ; C41F: 20 BB BF  -> Bank0:PpuBufPutAddrV
LC422:
    RTS                         ; C422: 60
LC423:
    LDY #$05                    ; C423: A0 05
    LDA StageArea               ; C425: A5 A3
    CMP #$03                    ; C427: C9 03
    BCC LC439                   ; C429: 90 0E
    LDY #$00                    ; C42B: A0 00
    CMP #$04                    ; C42D: C9 04
    BCC LC439                   ; C42F: 90 08
    LDY #$05                    ; C431: A0 05
    CMP #$05                    ; C433: C9 05
    BCC LC439                   ; C435: 90 02
    LDY #$00                    ; C437: A0 00
LC439:
    STY $30                     ; C439: 84 30
    RTS                         ; C43B: 60
LC43C:
    LDX $3E                     ; C43C: A6 3E
    LDA $0702,X                 ; C43E: BD 02 07
    AND #$7F                    ; C441: 29 7F
    SEC                         ; C443: 38
    SBC #$3C                    ; C444: E9 3C
    STA $32                     ; C446: 85 32
    STA $30                     ; C448: 85 30
    LDY StageArea               ; C44A: A4 A3
    LDA $C48C,Y                 ; C44C: B9 8C C4
    CLC                         ; C44F: 18
    ADC $30                     ; C450: 65 30
    TAY                         ; C452: A8
    LDA $C496,Y                 ; C453: B9 96 C4
    STA $30                     ; C456: 85 30
    LDX $3E                     ; C458: A6 3E
    LDA $0705,X                 ; C45A: BD 05 07
    BNE LC422                   ; C45D: D0 C3
    INC $0705,X                 ; C45F: FE 05 07
    LDX $C4AB                   ; C462: AE AB C4
    LDA $C4AC                   ; C465: AD AC C4
    JSR $BF68                   ; C468: 20 68 BF  -> Bank0:ObjPpuAddr
    LDY $30                     ; C46B: A4 30
    JSR $BFBB                   ; C46D: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDA $30                     ; C470: A5 30
    CMP #$0F                    ; C472: C9 0F
    BCC LC422                   ; C474: 90 AC
    LDA #$01                    ; C476: A9 01
    JSR Ptr16Add                ; C478: 20 13 C0
    JSR $BFBB                   ; C47B: 20 BB BF  -> Bank0:PpuBufPutAddrV
    JSR RecAttrAddr             ; C47E: 20 1D C0
    LDY $32                     ; C481: A4 32
    LDA $C4A4,Y                 ; C483: B9 A4 C4
    TAY                         ; C486: A8
    LDA #$01                    ; C487: A9 01
    JMP $BFE8                   ; C489: 4C E8 BF  -> Bank0:LBFE8
    .byte $00,$00,$00,$07,$00,$07,$07,$07         ; C48C: 00 00 00 07 00 07 07 07
    .byte $07,$00,$00,$04,$08,$04,$08,$08         ; C494: 07 00 00 04 08 04 08 08
    .byte $0C,$0F,$16,$1D,$16,$1D,$1D,$24         ; C49C: 0C 0F 16 1D 16 1D 1D 24
    .byte $29,$30,$35,$38,$3D,$40,$44,$AD         ; C4A4: 29 30 35 38 3D 40 44 AD
    .byte $C4,$30,$13,$10,$FF,$30,$0D,$10         ; C4AC: C4 30 13 10 FF 30 0D 10
    .byte $FF,$30,$06,$10,$FF,$10,$10,$FF         ; C4B4: FF 30 06 10 FF 10 10 FF
    .byte $FE,$30,$12,$E1,$FF,$EE,$FF,$FE         ; C4BC: FE 30 12 E1 FF EE FF FE
    .byte $30,$0B,$E1,$FF,$EE,$FF,$FE,$30         ; C4C4: 30 0B E1 FF EE FF FE 30
    .byte $04,$E1,$FF,$EE,$FF,$FE,$E1,$FF         ; C4CC: 04 E1 FF EE FF FE E1 FF
    .byte $EE,$FF,$85,$88,$88,$88,$88,$08         ; C4D4: EE FF 85 88 88 88 88 08
    .byte $FE,$85,$88,$88,$08,$FE,$85,$88         ; C4DC: FE 85 88 88 08 FE 85 88
    .byte $FE,$88,$88,$88,$08,$FE,$88,$08         ; C4E4: FE 88 88 88 08 FE 88 08
    .byte $FE,$88,$88,$08,$FE,$88,$FE             ; C4EC: FE 88 88 08 FE 88 FE
LC4F3:
    LDA #$03                    ; C4F3: A9 03
    STA $32                     ; C4F5: 85 32
    LDX $3E                     ; C4F7: A6 3E
    LDA $0705,X                 ; C4F9: BD 05 07
    AND #$F0                    ; C4FC: 29 F0
    BMI LC514                   ; C4FE: 30 14
    BEQ LC546                   ; C500: F0 44
    DEC $0705,X                 ; C502: DE 05 07
    LDA $0705,X                 ; C505: BD 05 07
    CMP #$0F                    ; C508: C9 0F
    BEQ LC50D                   ; C50A: F0 01
    RTS                         ; C50C: 60
LC50D:
    LDA #$00                    ; C50D: A9 00
    STA $0705,X                 ; C50F: 9D 05 07
    BEQ LC546                   ; C512: F0 32
LC514:
    CMP #$80                    ; C514: C9 80
    BEQ LC546                   ; C516: F0 2E
    LDA $0705,X                 ; C518: BD 05 07
    SEC                         ; C51B: 38
    SBC #$04                    ; C51C: E9 04
    CMP #$8F                    ; C51E: C9 8F
    STA $0705,X                 ; C520: 9D 05 07
    BCS LC52C                   ; C523: B0 07
    LDA #$82                    ; C525: A9 82
    STA $0705,X                 ; C527: 9D 05 07
    BNE LC546                   ; C52A: D0 1A
LC52C:
    STA $0705,X                 ; C52C: 9D 05 07
    AND #$01                    ; C52F: 29 01
    BEQ LC53C                   ; C531: F0 09
    LDA $0705,X                 ; C533: BD 05 07
    AND #$F0                    ; C536: 29 F0
    ORA #$01                    ; C538: 09 01
    BNE LC543                   ; C53A: D0 07
LC53C:
    LDA $0705,X                 ; C53C: BD 05 07
    AND #$F0                    ; C53F: 29 F0
    ORA #$02                    ; C541: 09 02
LC543:
    STA $0705,X                 ; C543: 9D 05 07
LC546:
    CMP #$01                    ; C546: C9 01
    BCC LC54F                   ; C548: 90 05
    LDA #$43                    ; C54A: A9 43
    STA $0702,X                 ; C54C: 9D 02 07
LC54F:
    LDX $C5C0                   ; C54F: AE C0 C5
    LDA $C5C1                   ; C552: AD C1 C5
    JSR $BF68                   ; C555: 20 68 BF  -> Bank0:ObjPpuAddr
    LDX $3E                     ; C558: A6 3E
    LDA $0705,X                 ; C55A: BD 05 07
    AND #$0F                    ; C55D: 29 0F
    BEQ LC570                   ; C55F: F0 0F
    PHA                         ; C561: 48
    LDA #$07                    ; C562: A9 07
    JSR SoundCmd                ; C564: 20 8E F0
    PLA                         ; C567: 68
    LDY #$0A                    ; C568: A0 0A
    CMP #$01                    ; C56A: C9 01
    BEQ LC571                   ; C56C: F0 03
    LDA #$14                    ; C56E: A9 14
LC570:
    TAY                         ; C570: A8
LC571:
    LDA $0703,X                 ; C571: BD 03 07
    CMP #$70                    ; C574: C9 70
    BEQ LC58E                   ; C576: F0 16
    JSR $BFBB                   ; C578: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDA #$01                    ; C57B: A9 01
    JSR Ptr16Add                ; C57D: 20 13 C0
    JSR $BFBB                   ; C580: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDA #$01                    ; C583: A9 01
    JSR Ptr16Add                ; C585: 20 13 C0
    JSR $BFBB                   ; C588: 20 BB BF  -> Bank0:PpuBufPutAddrV
    JMP LC593                   ; C58B: 4C 93 C5
LC58E:
    INY                         ; C58E: C8
    INY                         ; C58F: C8
    JSR $BFBB                   ; C590: 20 BB BF  -> Bank0:PpuBufPutAddrV
LC593:
    LDX $3E                     ; C593: A6 3E
    LDA $0705,X                 ; C595: BD 05 07
    BMI LC5AB                   ; C598: 30 11
    INC $0705,X                 ; C59A: FE 05 07
    LDA $0705,X                 ; C59D: BD 05 07
    CMP $32                     ; C5A0: C5 32
    BNE LC5BF                   ; C5A2: D0 1B
    LDA #$FF                    ; C5A4: A9 FF
    STA $0705,X                 ; C5A6: 9D 05 07
    BNE LC5BF                   ; C5A9: D0 14
LC5AB:
    DEC $0705,X                 ; C5AB: DE 05 07
    LDA $0705,X                 ; C5AE: BD 05 07
    CMP #$7F                    ; C5B1: C9 7F
    BNE LC5BF                   ; C5B3: D0 0A
    LDA #$1A                    ; C5B5: A9 1A
    STA $0705,X                 ; C5B7: 9D 05 07
    LDA #$44                    ; C5BA: A9 44
    STA $0702,X                 ; C5BC: 9D 02 07
LC5BF:
    RTS                         ; C5BF: 60
    .byte $C2,$C5,$41,$FF,$41,$DB,$00,$00         ; C5C0: C2 C5 41 FF 41 DB 00 00
    .byte $00,$FF,$40,$FF,$41,$FF,$41,$DB         ; C5C8: 00 FF 40 FF 41 FF 41 DB
    .byte $EB,$FB,$00,$FF,$40,$FF,$41,$FF         ; C5D0: EB FB 00 FF 40 FF 41 FF
    .byte $41,$DB,$DC,$EC,$FC,$FF,$40,$FF         ; C5D8: 41 DB DC EC FC FF 40 FF
LC5E0:
    LDX #$40                    ; C5E0: A2 40
    LDA #$08                    ; C5E2: A9 08
    BNE LC5F2                   ; C5E4: D0 0C
LC5E6:
    LDX #$68                    ; C5E6: A2 68
    LDA #$0A                    ; C5E8: A9 0A
    BNE LC5F2                   ; C5EA: D0 06
LC5EC:
    LDX #$40                    ; C5EC: A2 40
    LDA #$0F                    ; C5EE: A9 0F
    BNE LC5F2                   ; C5F0: D0 00
LC5F2:
    STX $31                     ; C5F2: 86 31
    STA $32                     ; C5F4: 85 32
    LDX $3E                     ; C5F6: A6 3E
    LDA $0705,X                 ; C5F8: BD 05 07
    AND #$1F                    ; C5FB: 29 1F
    BNE LC604                   ; C5FD: D0 05
    LDA $31                     ; C5FF: A5 31
    STA $0703,X                 ; C601: 9D 03 07
LC604:
    LDX $C67F                   ; C604: AE 7F C6
    LDA $C680                   ; C607: AD 80 C6
    JSR $BF68                   ; C60A: 20 68 BF  -> Bank0:ObjPpuAddr
    LDX $3E                     ; C60D: A6 3E
    LDY #$00                    ; C60F: A0 00
    LDA $0705,X                 ; C611: BD 05 07
    BEQ LC627                   ; C614: F0 11
    CMP #$01                    ; C616: C9 01
    BNE LC623                   ; C618: D0 09
    LDA FrameCnt                ; C61A: A5 09
    CMP #$B0                    ; C61C: C9 B0
    BCS LC65E                   ; C61E: B0 3E
    LDA $0705,X                 ; C620: BD 05 07
LC623:
    AND #$80                    ; C623: 29 80
    BEQ LC629                   ; C625: F0 02
LC627:
    LDY #$0C                    ; C627: A0 0C
LC629:
    STX $3E                     ; C629: 86 3E
    JSR $BFBB                   ; C62B: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDA #$01                    ; C62E: A9 01
    JSR Ptr16Add                ; C630: 20 13 C0
    JSR $BFBB                   ; C633: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDX $3E                     ; C636: A6 3E
    LDA $0705,X                 ; C638: BD 05 07
    AND #$80                    ; C63B: 29 80
    BEQ LC65F                   ; C63D: F0 20
    LDA FrameCnt                ; C63F: A5 09
    AND #$04                    ; C641: 29 04
    BEQ LC67E                   ; C643: F0 39
    DEC $0705,X                 ; C645: DE 05 07
    LDA $0705,X                 ; C648: BD 05 07
    CMP #$80                    ; C64B: C9 80
    BNE LC655                   ; C64D: D0 06
    LDA #$00                    ; C64F: A9 00
    STA $0705,X                 ; C651: 9D 05 07
    RTS                         ; C654: 60
LC655:
    LDA $0703,X                 ; C655: BD 03 07
    SEC                         ; C658: 38
    SBC #$08                    ; C659: E9 08
    STA $0703,X                 ; C65B: 9D 03 07
LC65E:
    RTS                         ; C65E: 60
LC65F:
    INC $0705,X                 ; C65F: FE 05 07
    LDA $0705,X                 ; C662: BD 05 07
    CMP #$01                    ; C665: C9 01
    BEQ LC67E                   ; C667: F0 15
    CMP $32                     ; C669: C5 32
    BNE LC675                   ; C66B: D0 08
    LDA $0705,X                 ; C66D: BD 05 07
    ORA #$80                    ; C670: 09 80
    STA $0705,X                 ; C672: 9D 05 07
LC675:
    LDA $0703,X                 ; C675: BD 03 07
    CLC                         ; C678: 18
    ADC #$08                    ; C679: 69 08
    STA $0703,X                 ; C67B: 9D 03 07
LC67E:
    RTS                         ; C67E: 60
    .byte $81,$C6,$00,$00,$D5,$E5,$F5,$FF         ; C67F: 81 C6 00 00 D5 E5 F5 FF
    .byte $E2,$E2,$D6,$E6,$F6,$FF,$D5,$E5         ; C687: E2 E2 D6 E6 F6 FF D5 E5
    .byte $F5,$00,$FF,$D6,$E6,$F6,$00,$FF         ; C68F: F5 00 FF D6 E6 F6 00 FF
LC697:
    LDA #$09                    ; C697: A9 09
    LDY #$00                    ; C699: A0 00
    LDX #$40                    ; C69B: A2 40
    BNE LC6A5                   ; C69D: D0 06
LC69F:
    LDA #$09                    ; C69F: A9 09
    LDY #$12                    ; C6A1: A0 12
    LDX #$40                    ; C6A3: A2 40
LC6A5:
    STA $32                     ; C6A5: 85 32
    STX $31                     ; C6A7: 86 31
    STY $3B                     ; C6A9: 84 3B
    LDX $3E                     ; C6AB: A6 3E
    LDA $0705,X                 ; C6AD: BD 05 07
    AND #$0F                    ; C6B0: 29 0F
    BNE LC6CC                   ; C6B2: D0 18
    LDA $0702,X                 ; C6B4: BD 02 07
    BMI LC6C7                   ; C6B7: 30 0E
    LDA $0705,X                 ; C6B9: BD 05 07
    BEQ LC6C2                   ; C6BC: F0 04
    CMP #$10                    ; C6BE: C9 10
    BNE LC6C7                   ; C6C0: D0 05
LC6C2:
    LDA #$D4                    ; C6C2: A9 D4
    JSR SoundCmd                ; C6C4: 20 8E F0
LC6C7:
    LDA $31                     ; C6C7: A5 31
    STA $0703,X                 ; C6C9: 9D 03 07
LC6CC:
    LDA $0705,X                 ; C6CC: BD 05 07
    AND #$F0                    ; C6CF: 29 F0
    BEQ LC6E4                   ; C6D1: F0 11
    BMI LC6E4                   ; C6D3: 30 0F
    DEC $0705,X                 ; C6D5: DE 05 07
    LDA $0705,X                 ; C6D8: BD 05 07
    CMP #$0F                    ; C6DB: C9 0F
    BNE LC70C                   ; C6DD: D0 2D
    LDA #$00                    ; C6DF: A9 00
    STA $0705,X                 ; C6E1: 9D 05 07
LC6E4:
    LDA $0705,X                 ; C6E4: BD 05 07
    BPL LC6EE                   ; C6E7: 10 05
    TYA                         ; C6E9: 98
    CLC                         ; C6EA: 18
    ADC #$09                    ; C6EB: 69 09
    TAY                         ; C6ED: A8
LC6EE:
    STY $3F                     ; C6EE: 84 3F
    LDX $3E                     ; C6F0: A6 3E
    LDA $0705,X                 ; C6F2: BD 05 07
    AND #$F0                    ; C6F5: 29 F0
    BPL LC70D                   ; C6F7: 10 14
    CMP #$80                    ; C6F9: C9 80
    BEQ LC70D                   ; C6FB: F0 10
    DEC $0705,X                 ; C6FD: DE 05 07
    LDA $0705,X                 ; C700: BD 05 07
    CMP #$8F                    ; C703: C9 8F
    BNE LC70C                   ; C705: D0 05
    LDA #$80                    ; C707: A9 80
    STA $0705,X                 ; C709: 9D 05 07
LC70C:
    RTS                         ; C70C: 60
LC70D:
    LDX $C79E                   ; C70D: AE 9E C7
    LDA $C79F                   ; C710: AD 9F C7
    JSR $BF68                   ; C713: 20 68 BF  -> Bank0:ObjPpuAddr
    LDA $0705,X                 ; C716: BD 05 07
    AND #$0F                    ; C719: 29 0F
    CLC                         ; C71B: 18
    ADC $3F                     ; C71C: 65 3F
    TAY                         ; C71E: A8
    LDA $32                     ; C71F: A5 32
    CMP #$09                    ; C721: C9 09
    BEQ LC735                   ; C723: F0 10
    LDA $0705,X                 ; C725: BD 05 07
    CMP #$80                    ; C728: C9 80
    BNE LC735                   ; C72A: D0 09
    LDY #$26                    ; C72C: A0 26
    LDA $32                     ; C72E: A5 32
    CMP #$06                    ; C730: C9 06
    BEQ LC735                   ; C732: F0 01
    INY                         ; C734: C8
LC735:
    LDA $C776,Y                 ; C735: B9 76 C7
    STA $3F                     ; C738: 85 3F
    TAY                         ; C73A: A8
    STX $3E                     ; C73B: 86 3E
    JSR $BFBB                   ; C73D: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDA ($33),Y                 ; C740: B1 33
    CMP #$FE                    ; C742: C9 FE
    BNE LC748                   ; C744: D0 02
    LDY $3F                     ; C746: A4 3F
LC748:
    LDA #$01                    ; C748: A9 01
    JSR Ptr16Add                ; C74A: 20 13 C0
    JSR $BFBB                   ; C74D: 20 BB BF  -> Bank0:PpuBufPutAddrV
    LDX $3E                     ; C750: A6 3E
    LDA $0703,X                 ; C752: BD 03 07
    CLC                         ; C755: 18
    ADC #$10                    ; C756: 69 10
    STA $0703,X                 ; C758: 9D 03 07
    INC $0705,X                 ; C75B: FE 05 07
    LDA $0705,X                 ; C75E: BD 05 07
    AND #$0F                    ; C761: 29 0F
    CMP $32                     ; C763: C5 32
    BNE LC775                   ; C765: D0 0E
    LDA $0705,X                 ; C767: BD 05 07
    BMI LC770                   ; C76A: 30 04
    LDA #$9C                    ; C76C: A9 9C
    BNE LC772                   ; C76E: D0 02
LC770:
    LDA #$20                    ; C770: A9 20
LC772:
    STA $0705,X                 ; C772: 9D 05 07
LC775:
    RTS                         ; C775: 60
    .byte $3B,$00,$05,$00,$00,$00,$00,$00         ; C776: 3B 00 05 00 00 00 00 00
    .byte $0A,$0F,$14,$19,$14,$14,$14,$14         ; C77E: 0A 0F 14 19 14 14 14 14
    .byte $14,$1E,$3B,$00,$00,$00,$00,$00         ; C786: 14 1E 3B 00 00 00 00 00
    .byte $00,$00,$0A,$0F,$14,$14,$14,$14         ; C78E: 00 00 0A 0F 14 14 14 14
    .byte $14,$14,$14,$1E,$26,$2B,$30,$36         ; C796: 14 14 14 1E 26 2B 30 36
    .byte $A0,$C7,$FA,$FA,$DA,$FF,$FE,$CA         ; C79E: A0 C7 FA FA DA FF FE CA
    .byte $FA,$DA,$FF,$FE,$FA,$FA,$CA,$FF         ; C7A6: FA DA FF FE FA FA CA FF
    .byte $FE,$75,$00,$D9,$FF,$FE,$00,$00         ; C7AE: FE 75 00 D9 FF FE 00 00
    .byte $D9,$FF,$FE,$86,$00,$D9,$FF,$FE         ; C7B6: D9 FF FE 86 00 D9 FF FE
    .byte $00,$00,$02,$FF,$00,$00,$01,$FF         ; C7BE: 00 00 02 FF 00 00 01 FF
    .byte $CA,$FA,$DA,$FF,$FE,$FA,$CA,$DA         ; C7C6: CA FA DA FF FE FA CA DA
    .byte $FF,$FE,$80,$00,$00,$DA,$FF,$FE         ; C7CE: FF FE 80 00 00 DA FF FE
    .byte $80,$00,$DA,$FF,$FE,$D9,$FA,$DA         ; C7D6: 80 00 DA FF FE D9 FA DA
    .byte $FF,$FE                                 ; C7DE: FF FE
LC7E0:
    LDA #$47                    ; C7E0: A9 47
    BNE LC7EA                   ; C7E2: D0 06
LC7E4:
    LDA #$7F                    ; C7E4: A9 7F
    BNE LC7EA                   ; C7E6: D0 02
LC7E8:
    LDA #$B7                    ; C7E8: A9 B7
LC7EA:
    STA $31                     ; C7EA: 85 31
    LDX $3E                     ; C7EC: A6 3E
    LDA $0705,X                 ; C7EE: BD 05 07
    BNE LC815                   ; C7F1: D0 22
    LDA #$80                    ; C7F3: A9 80
    STA $0705,X                 ; C7F5: 9D 05 07
    LDX $C8FE                   ; C7F8: AE FE C8
    LDA $C8FF                   ; C7FB: AD FF C8
    JSR $BF68                   ; C7FE: 20 68 BF  -> Bank0:ObjPpuAddr
    LDY #$00                    ; C801: A0 00
    LDX $3E                     ; C803: A6 3E
    LDA $0702,X                 ; C805: BD 02 07
    AND #$7F                    ; C808: 29 7F
    CMP #$4A                    ; C80A: C9 4A
    BCC LC810                   ; C80C: 90 02
    LDY #$02                    ; C80E: A0 02
LC810:
    JSR $BFB5                   ; C810: 20 B5 BF  -> Bank0:PpuBufPutTiles
    LDX $3E                     ; C813: A6 3E
LC815:
    LDA $0702,X                 ; C815: BD 02 07
    AND #$80                    ; C818: 29 80
    BEQ LC827                   ; C81A: F0 0B
    LDA $0705,X                 ; C81C: BD 05 07
    AND #$40                    ; C81F: 29 40
    BEQ LC826                   ; C821: F0 03
    JMP LC8ED                   ; C823: 4C ED C8
LC826:
    RTS                         ; C826: 60
LC827:
    LDA $0705,X                 ; C827: BD 05 07
    AND #$40                    ; C82A: 29 40
    BNE LC897                   ; C82C: D0 69
    LDA $0704,X                 ; C82E: BD 04 07
    CMP #$18                    ; C831: C9 18
    BCC LC855                   ; C833: 90 20
    CMP #$E8                    ; C835: C9 E8
    BCS LC855                   ; C837: B0 1C
    LDA $0705,X                 ; C839: BD 05 07
    AND #$0F                    ; C83C: 29 0F
    BEQ LC844                   ; C83E: F0 04
    DEC $0705,X                 ; C840: DE 05 07
    RTS                         ; C843: 60
LC844:
    LDY #$00                    ; C844: A0 00
LC846:
    LDA $0238,Y                 ; C846: B9 38 02
    CMP #$F4                    ; C849: C9 F4
    BEQ LC856                   ; C84B: F0 09
    INY                         ; C84D: C8
    INY                         ; C84E: C8
    INY                         ; C84F: C8
    INY                         ; C850: C8
    CPY #$08                    ; C851: C0 08
    BNE LC846                   ; C853: D0 F1
LC855:
    RTS                         ; C855: 60
LC856:
    TYA                         ; C856: 98
    ORA #$C0                    ; C857: 09 C0
    STA $0705,X                 ; C859: 9D 05 07
    LDA $31                     ; C85C: A5 31
    STA $0238,Y                 ; C85E: 99 38 02
    LDA #$B4                    ; C861: A9 B4
    STA $0239,Y                 ; C863: 99 39 02
    LDA #$02                    ; C866: A9 02
    STA $32                     ; C868: 85 32
    LDA #$0A                    ; C86A: A9 0A
    STA $33                     ; C86C: 85 33
    LDA $0702,X                 ; C86E: BD 02 07
    AND #$7F                    ; C871: 29 7F
    CMP #$4A                    ; C873: C9 4A
    BCC LC87F                   ; C875: 90 08
    LDA #$42                    ; C877: A9 42
    STA $32                     ; C879: 85 32
    LDA #$F6                    ; C87B: A9 F6
    STA $33                     ; C87D: 85 33
LC87F:
    LDA $32                     ; C87F: A5 32
    STA $023A,Y                 ; C881: 99 3A 02
    LDA $0704,X                 ; C884: BD 04 07
    CLC                         ; C887: 18
    ADC $33                     ; C888: 65 33
    STA $023B,Y                 ; C88A: 99 3B 02
    TYA                         ; C88D: 98
    LSR A                       ; C88E: 4A
    LSR A                       ; C88F: 4A
    TAY                         ; C890: A8
    LDA #$00                    ; C891: A9 00
    STA $9B,Y                   ; C893: 99 9B 00
    RTS                         ; C896: 60
LC897:
    LDA $0705,X                 ; C897: BD 05 07
    AND #$3F                    ; C89A: 29 3F
    LSR A                       ; C89C: 4A
    LSR A                       ; C89D: 4A
    TAY                         ; C89E: A8
    LDA $9B,Y                   ; C89F: B9 9B 00
    STA $30                     ; C8A2: 85 30
    LDA #$A0                    ; C8A4: A9 A0
    LDX $3E                     ; C8A6: A6 3E
    CMP $30                     ; C8A8: C5 30
    BCC LC8ED                   ; C8AA: 90 41
    LDA $9B,Y                   ; C8AC: B9 9B 00
    CLC                         ; C8AF: 18
    ADC #$05                    ; C8B0: 69 05
    STA $9B,Y                   ; C8B2: 99 9B 00
    LDA $0702,X                 ; C8B5: BD 02 07
    AND #$7F                    ; C8B8: 29 7F
    CMP #$4A                    ; C8BA: C9 4A
    BCS LC8DA                   ; C8BC: B0 1C
    LDA $9B,Y                   ; C8BE: B9 9B 00
    CLC                         ; C8C1: 18
    ADC #$0A                    ; C8C2: 69 0A
    CLC                         ; C8C4: 18
    ADC $0704,X                 ; C8C5: 7D 04 07
    STA $30                     ; C8C8: 85 30
LC8CA:
    CMP #$F0                    ; C8CA: C9 F0
    BCS LC8ED                   ; C8CC: B0 1F
    LDA $0705,X                 ; C8CE: BD 05 07
    AND #$3F                    ; C8D1: 29 3F
    TAY                         ; C8D3: A8
    LDA $30                     ; C8D4: A5 30
    STA $023B,Y                 ; C8D6: 99 3B 02
    RTS                         ; C8D9: 60
LC8DA:
    LDA $9B,Y                   ; C8DA: B9 9B 00
    STA $30                     ; C8DD: 85 30
    LDA $0704,X                 ; C8DF: BD 04 07
    SEC                         ; C8E2: 38
    SBC #$0A                    ; C8E3: E9 0A
    SEC                         ; C8E5: 38
    SBC $30                     ; C8E6: E5 30
    STA $30                     ; C8E8: 85 30
    JMP LC8CA                   ; C8EA: 4C CA C8
LC8ED:
    LDA $0705,X                 ; C8ED: BD 05 07
    AND #$3F                    ; C8F0: 29 3F
    TAY                         ; C8F2: A8
    LDA #$F4                    ; C8F3: A9 F4
    STA $0238,Y                 ; C8F5: 99 38 02
    LDA #$8F                    ; C8F8: A9 8F
    STA $0705,X                 ; C8FA: 9D 05 07
    RTS                         ; C8FD: 60
    .byte $00,$C9,$D8,$FF,$C8,$FF                 ; C8FE: 00 C9 D8 FF C8 FF
LC904:
    LDX $3E                     ; C904: A6 3E
    LDA $0702,X                 ; C906: BD 02 07
    SEC                         ; C909: 38
    SBC #$18                    ; C90A: E9 18
    STA $39                     ; C90C: 85 39
    AND #$07                    ; C90E: 29 07
    STA $3F                     ; C910: 85 3F
    TAY                         ; C912: A8
    LDA $0705,X                 ; C913: BD 05 07
    BNE LC93B                   ; C916: D0 23
    INC $0705,X                 ; C918: FE 05 07
    LDA DoorRing,Y              ; C91B: B9 C0 07
    BNE LC925                   ; C91E: D0 05
    LDA #$01                    ; C920: A9 01
    STA DoorRing,Y              ; C922: 99 C0 07
LC925:
    LDA DoorRing,Y              ; C925: B9 C0 07
    TAY                         ; C928: A8
    CPY #$03                    ; C929: C0 03
    BNE LC92E                   ; C92B: D0 01
    DEY                         ; C92D: 88
LC92E:
    DEY                         ; C92E: 88
    LDA $C9C1,Y                 ; C92F: B9 C1 C9
    STA $30                     ; C932: 85 30
    LDA #$41                    ; C934: A9 41
    STA $32                     ; C936: 85 32
    JMP LC987                   ; C938: 4C 87 C9
LC93B:
    LDX $3E                     ; C93B: A6 3E
    LDA $0705,X                 ; C93D: BD 05 07
    CMP #$01                    ; C940: C9 01
    BEQ LC956                   ; C942: F0 12
    LDA DoorRing,Y              ; C944: B9 C0 07
    CMP #$02                    ; C947: C9 02
    BNE LC974                   ; C949: D0 29
    LDA #$03                    ; C94B: A9 03
    STA DoorRing,Y              ; C94D: 99 C0 07
    JSR LC96D                   ; C950: 20 6D C9
    JMP LC925                   ; C953: 4C 25 C9
LC956:
    LDA DoorRing,Y              ; C956: B9 C0 07
    CMP #$02                    ; C959: C9 02
    BCS LC974                   ; C95B: B0 17
    JSR RecProxCheck            ; C95D: 20 60 C0
    BCC LC96D                   ; C960: 90 0B
    LDX $3E                     ; C962: A6 3E
    LDA #$70                    ; C964: A9 70
    STA $0705,X                 ; C966: 9D 05 07
    STX DoorPendRec             ; C969: 8E 3A 03
    RTS                         ; C96C: 60
LC96D:
    LDX $3E                     ; C96D: A6 3E
    LDA #$01                    ; C96F: A9 01
    STA $0705,X                 ; C971: 9D 05 07
LC974:
    RTS                         ; C974: 60
LC975:
    LDA #$00                    ; C975: A9 00
    LDX #$3C                    ; C977: A2 3C
    STA $30                     ; C979: 85 30
    STX $32                     ; C97B: 86 32
    LDX $3E                     ; C97D: A6 3E
    LDA $0705,X                 ; C97F: BD 05 07
    BNE LC9C0                   ; C982: D0 3C
    INC $0705,X                 ; C984: FE 05 07
LC987:
    LDX $C9C3                   ; C987: AE C3 C9
    LDA $C9C4                   ; C98A: AD C4 C9
    JSR $BF68                   ; C98D: 20 68 BF  -> Bank0:ObjPpuAddr
    LDA #$04                    ; C990: A9 04
    STA $31                     ; C992: 85 31
    LDY $30                     ; C994: A4 30
LC996:
    JSR $BFB5                   ; C996: 20 B5 BF  -> Bank0:PpuBufPutTiles
    LDA #$20                    ; C999: A9 20
    JSR Ptr16Add                ; C99B: 20 13 C0
    DEC $31                     ; C99E: C6 31
    BNE LC996                   ; C9A0: D0 F4
    LDX $C9C3                   ; C9A2: AE C3 C9
    LDA $C9C4                   ; C9A5: AD C4 C9
    JSR $BF68                   ; C9A8: 20 68 BF  -> Bank0:ObjPpuAddr
    LDY $32                     ; C9AB: A4 32
    LDX $3E                     ; C9AD: A6 3E
    LDA $0703,X                 ; C9AF: BD 03 07
    CMP #$B0                    ; C9B2: C9 B0
    BCC LC9B8                   ; C9B4: 90 02
    INY                         ; C9B6: C8
    INY                         ; C9B7: C8
LC9B8:
    JSR RecAttrAddr             ; C9B8: 20 1D C0
    LDA #$01                    ; C9BB: A9 01
    JSR $BFE8                   ; C9BD: 20 E8 BF  -> Bank0:LBFE8
LC9C0:
    RTS                         ; C9C0: 60
    .byte $14,$28,$C5,$C9,$C0,$C1,$C2,$C3         ; C9C1: 14 28 C5 C9 C0 C1 C2 C3
    .byte $FF,$D0,$D1,$D2,$D3,$FF,$E0,$00         ; C9C9: FF D0 D1 D2 D3 FF E0 00
    .byte $00,$E3,$FF,$F0,$F1,$F2,$F3,$FF         ; C9D1: 00 E3 FF F0 F1 F2 F3 FF
    .byte $2B,$29,$2A,$0F,$FF,$28,$1A,$1B         ; C9D9: 2B 29 2A 0F FF 28 1A 1B
    .byte $2C,$FF,$27,$1C,$1D,$2D,$FF,$26         ; C9E1: 2C FF 27 1C 1D 2D FF 26
    .byte $1E,$1F,$2E,$FF,$2B,$29,$2A,$0F         ; C9E9: 1E 1F 2E FF 2B 29 2A 0F
    .byte $FF,$28,$00,$00,$2C,$FF,$27,$00         ; C9F1: FF 28 00 00 2C FF 27 00
    .byte $00,$2D,$FF,$26,$00,$00,$2E,$FF         ; C9F9: 00 2D FF 26 00 00 2E FF
    .byte $55,$FE,$50,$05,$FE,$00,$FE,$00         ; CA01: 55 FE 50 05 FE 00 FE 00
    .byte $00,$FE                                 ; CA09: 00 FE
LCA0B:
    LDA #$0A                    ; CA0B: A9 0A
    BNE LCA11                   ; CA0D: D0 02
LCA0F:
    LDA #$F6                    ; CA0F: A9 F6
LCA11:
    JSR LCA1F                   ; CA11: 20 1F CA
    JSR $8591                   ; CA14: 20 91 85  -> Bank0:RenderDelaySet9
    LDA #$01                    ; CA17: A9 01
    STA $07C8                   ; CA19: 8D C8 07
    JMP LCA53                   ; CA1C: 4C 53 CA
LCA1F:
    CLC                         ; CA1F: 18
    ADC StageId                 ; CA20: 65 80
    STA StageId                 ; CA22: 85 80
    STA $32                     ; CA24: 85 32
    CMP #$4D                    ; CA26: C9 4D
    BNE LCA2F                   ; CA28: D0 05
    LDA #$00                    ; CA2A: A9 00
    STA DoorRing                ; CA2C: 8D C0 07
LCA2F:
    RTS                         ; CA2F: 60
LCA30:
    JSR $8595                   ; CA30: 20 95 85  -> Bank0:RenderDelaySet17
    LDA #$9C                    ; CA33: A9 9C
    LDX StageId                 ; CA35: A6 80
    CPX #$64                    ; CA37: E0 64
    BCS LCA3D                   ; CA39: B0 02
    LDA #$64                    ; CA3B: A9 64
LCA3D:
    JSR LCA1F                   ; CA3D: 20 1F CA
    JMP LCA53                   ; CA40: 4C 53 CA
StageLoad:
    LDA $81                     ; CA43: A5 81
    CMP #$10                    ; CA45: C9 10
    BCC LCA4B                   ; CA47: 90 02
    INC StageId                 ; CA49: E6 80
LCA4B:
    LDX #$00                    ; CA4B: A2 00
    STX $81                     ; CA4D: 86 81
    STX $87                     ; CA4F: 86 87
    STX ScrollX                 ; CA51: 86 18
LCA53:
    JSR $8614                   ; CA53: 20 14 86  -> Bank0:InitSound
    JSR $8115                   ; CA56: 20 15 81  -> Bank0:PpuOff
    LDX #$04                    ; CA59: A2 04
    LDA #$40                    ; CA5B: A9 40
    JSR $8A6D                   ; CA5D: 20 6D 8A  -> Bank0:ClearOamRange
    LDX #$00                    ; CA60: A2 00
    STX $0334                   ; CA62: 8E 34 03
    INX                         ; CA65: E8
    STX $9A                     ; CA66: 86 9A
    JSR $BADA                   ; CA68: 20 DA BA  -> Bank0:SpawnRingFill
    JSR $BAF4                   ; CA6B: 20 F4 BA  -> Bank0:ScanObjWindow
    LDA #$01                    ; CA6E: A9 01
    STA $37                     ; CA70: 85 37
    LDA #$07                    ; CA72: A9 07
    STA $033E                   ; CA74: 8D 3E 03
    JSR LCEE7                   ; CA77: 20 E7 CE
    LDA StageId                 ; CA7A: A5 80
    STA $32                     ; CA7C: 85 32
    LDA $81                     ; CA7E: A5 81
    CMP #$10                    ; CA80: C9 10
    BCC LCA86                   ; CA82: 90 02
    INC $32                     ; CA84: E6 32
LCA86:
    LDA #$FF                    ; CA86: A9 FF
    TAY                         ; CA88: A8
    STA $30                     ; CA89: 85 30
LCA8B:
    INY                         ; CA8B: C8
    INC $30                     ; CA8C: E6 30
    JMP LCA93                   ; CA8E: 4C 93 CA
LCA91:
    INY                         ; CA91: C8
    INY                         ; CA92: C8
LCA93:
    LDA StageAreaMapTab,Y       ; CA93: B9 CC D7
    CMP #$FF                    ; CA96: C9 FF
    BEQ LCAD8                   ; CA98: F0 3E
    CMP #$FE                    ; CA9A: C9 FE
    BEQ LCA8B                   ; CA9C: F0 ED
    LDA $32                     ; CA9E: A5 32
    CMP StageAreaMapTab,Y       ; CAA0: D9 CC D7
    BCC LCA91                   ; CAA3: 90 EC
    CMP $D7CD,Y                 ; CAA5: D9 CD D7
    BCS LCA91                   ; CAA8: B0 E7
    LDA $30                     ; CAAA: A5 30
    CMP StageArea               ; CAAC: C5 A3
    BEQ LCAD8                   ; CAAE: F0 28
    STA StageArea               ; CAB0: 85 A3
    JSR $9A16                   ; CAB2: 20 16 9A  -> Bank0:LoadStageTimer
    JSR $B5DF                   ; CAB5: 20 DF B5  -> Bank0:InitObjRing
    LDA #$00                    ; CAB8: A9 00
    STA $05D1                   ; CABA: 8D D1 05
    STA $05D4                   ; CABD: 8D D4 05
    STA $011A                   ; CAC0: 8D 1A 01
    STA KeyCount                ; CAC3: 8D DF 05
    STA $05F8                   ; CAC6: 8D F8 05
    LDY #$07                    ; CAC9: A0 07
    LDA #$00                    ; CACB: A9 00
    STA BossDoorSeq             ; CACD: 8D 37 03
    STA $A4                     ; CAD0: 85 A4
LCAD2:
    STA DoorRing,Y              ; CAD2: 99 C0 07
    DEY                         ; CAD5: 88
    BPL LCAD2                   ; CAD6: 10 FA
LCAD8:
    LDA StageId                 ; CAD8: A5 80
    STA $32                     ; CADA: 85 32
    JSR $8115                   ; CADC: 20 15 81  -> Bank0:PpuOff
    LDA #$10                    ; CADF: A9 10
    STA $39                     ; CAE1: 85 39
    LDA $81                     ; CAE3: A5 81
    SEC                         ; CAE5: 38
    SBC #$0C                    ; CAE6: E9 0C
    STA $30                     ; CAE8: 85 30
    BCS LCAFF                   ; CAEA: B0 13
    LDA $30                     ; CAEC: A5 30
    CLC                         ; CAEE: 18
    ADC #$20                    ; CAEF: 69 20
    STA $30                     ; CAF1: 85 30
    LDA $32                     ; CAF3: A5 32
    BNE LCAFD                   ; CAF5: D0 06
    LDA #$00                    ; CAF7: A9 00
    STA $30                     ; CAF9: 85 30
    BEQ LCAFF                   ; CAFB: F0 02
LCAFD:
    DEC $32                     ; CAFD: C6 32
LCAFF:
    LDA $30                     ; CAFF: A5 30
    AND #$FC                    ; CB01: 29 FC
    STA $30                     ; CB03: 85 30
    LDA #$00                    ; CB05: A9 00
    STA $4D                     ; CB07: 85 4D
LCB09:
    JSR LCC6E                   ; CB09: 20 6E CC
    INC $4D                     ; CB0C: E6 4D
    LDA $4D                     ; CB0E: A5 4D
    CMP #$03                    ; CB10: C9 03
    BNE LCB09                   ; CB12: D0 F5
    LDA #$00                    ; CB14: A9 00
    STA $4D                     ; CB16: 85 4D
    LDY #$04                    ; CB18: A0 04
LCB1A:
    LDA $30                     ; CB1A: A5 30
    CLC                         ; CB1C: 18
    ADC #$01                    ; CB1D: 69 01
    STA $30                     ; CB1F: 85 30
    CMP #$20                    ; CB21: C9 20
    BNE LCB2B                   ; CB23: D0 06
    INC $32                     ; CB25: E6 32
    LDA #$00                    ; CB27: A9 00
    STA $30                     ; CB29: 85 30
LCB2B:
    DEY                         ; CB2B: 88
    BNE LCB1A                   ; CB2C: D0 EC
    JSR $865B                   ; CB2E: 20 5B 86  -> Bank0:FlushPpuBuf
    DEC $39                     ; CB31: C6 39
    BNE LCAFF                   ; CB33: D0 CA
    LDA StageId                 ; CB35: A5 80
    LSR A                       ; CB37: 4A
    LDA PpuCtrlShadow           ; CB38: A5 0E
    AND #$FE                    ; CB3A: 29 FE
    ADC #$00                    ; CB3C: 69 00
    STA PPU_CTRL                ; CB3E: 8D 00 20
    JSR $BDD5                   ; CB41: 20 D5 BD  -> Bank0:DispatchObjAi
    JSR $865B                   ; CB44: 20 5B 86  -> Bank0:FlushPpuBuf
    LDA #$01                    ; CB47: A9 01
    STA $0336                   ; CB49: 8D 36 03
    LDA #$00                    ; CB4C: A9 00
    STA DoorCd                  ; CB4E: 8D E6 05
    LDA #$02                    ; CB51: A9 02
    STA $04A1                   ; CB53: 8D A1 04
    JSR $B85B                   ; CB56: 20 5B B8  -> Bank0:LB85B
    JSR $B384                   ; CB59: 20 84 B3  -> Bank0:HideOamSlots1to6
    JSR $8595                   ; CB5C: 20 95 85  -> Bank0:RenderDelaySet17
    JSR BgmByStage              ; CB5F: 20 90 CB
    JSR StageScreenSetup        ; CB62: 20 69 CB
    JMP $811E                   ; CB65: 4C 1E 81  -> Bank0:L811E
LCB68:
    RTS                         ; CB68: 60
StageScreenSetup:
    ; 清 $0336/$07CA/PpuBufIdx；$A3<2 时 Y=2 否则 Y=0 写 MapperShadow；A=$A3*2（StageId≥$64 再 +1），X=$D80B,Y，A=$18 尾转 PpuBufPutStrChain(bank0 $8718)
    LDY #$00                    ; CB69: A0 00
    STY $0336                   ; CB6B: 8C 36 03
    STY $07CA                   ; CB6E: 8C CA 07
    STY PpuBufIdx               ; CB71: 84 11
    LDA StageArea               ; CB73: A5 A3
    CMP #$02                    ; CB75: C9 02
    BCS LCB7B                   ; CB77: B0 02
    LDY #$02                    ; CB79: A0 02
LCB7B:
    STY MapperShadow            ; CB7B: 84 1E
    ASL A                       ; CB7D: 0A
    TAY                         ; CB7E: A8
    LDA StageId                 ; CB7F: A5 80
    CMP #$64                    ; CB81: C9 64
    BCC LCB86                   ; CB83: 90 01
    INY                         ; CB85: C8
LCB86:
    LDA StageNameStrTab,Y       ; CB86: B9 0B D8
    TAX                         ; CB89: AA
    LDA #$18                    ; CB8A: A9 18
    JMP $8718                   ; CB8C: 4C 18 87  -> Bank0:PpuBufPutStrChain
LCB8F:
    RTS                         ; CB8F: 60
BgmByStage:
    ; 按 $A3 查 $CBAC 声音 ID 表（CPY #$06 特判），经 $861C/$8622 提交播放；$03 非零直接 RTS；bank0 $9AFB JSR
    JSR $8614                   ; CB90: 20 14 86  -> Bank0:InitSound
    LDA $03                     ; CB93: A5 03
    BEQ LCB98                   ; CB95: F0 01
    RTS                         ; CB97: 60
LCB98:
    LDX StageArea               ; CB98: A6 A3
    LDY $CBAC,X                 ; CB9A: BC AC CB
    CPY #$06                    ; CB9D: C0 06
    BNE LCBAA                   ; CB9F: D0 09
    LDA $DE                     ; CBA1: A5 DE
    BNE LCBA8                   ; CBA3: D0 03
    JMP $861C                   ; CBA5: 4C 1C 86  -> Bank0:SoundCmdC0
LCBA8:
    LDY #$18                    ; CBA8: A0 18
LCBAA:
    JMP $8622                   ; CBAA: 4C 22 86  -> Bank0:SoundCmd80
    .byte $06,$0B,$09,$18,$0B,$09,$22,$09         ; CBAD: 06 0B 09 18 0B 09 22 09
    .byte $18                                     ; CBB5: 18
ScrollStep:
    ; 滚动步进：$0511 门控（低 2 位），INC ScrollX($18)，$18&$0F∈{0,8} 时 INC $81 列计数（比 $20）；首次 LCE41 取列数据
    LDA $0511                   ; CBB6: AD 11 05
    AND #$03                    ; CBB9: 29 03
    BEQ LCB8F                   ; CBBB: F0 D2
    LDA $0511                   ; CBBD: AD 11 05
    AND #$01                    ; CBC0: 29 01
    BEQ LCC13                   ; CBC2: F0 4F
    LDX ScrollX                 ; CBC4: A6 18
    BNE LCBCD                   ; CBC6: D0 05
    JSR LCE41                   ; CBC8: 20 41 CE
    BCS LCB8F                   ; CBCB: B0 C2
LCBCD:
    LDA #$01                    ; CBCD: A9 01
    STA $1C                     ; CBCF: 85 1C
    INC ScrollX                 ; CBD1: E6 18
    LDA ScrollX                 ; CBD3: A5 18
    AND #$0F                    ; CBD5: 29 0F
    BEQ LCBDD                   ; CBD7: F0 04
    CMP #$08                    ; CBD9: C9 08
    BNE LCB8F                   ; CBDB: D0 B2
LCBDD:
    INC $81                     ; CBDD: E6 81
    LDA $81                     ; CBDF: A5 81
    CMP #$20                    ; CBE1: C9 20
    BNE LCBEB                   ; CBE3: D0 06
    LDA #$00                    ; CBE5: A9 00
    STA $81                     ; CBE7: 85 81
    INC StageId                 ; CBE9: E6 80
LCBEB:
    LDX StageId                 ; CBEB: A6 80
    INX                         ; CBED: E8
    LDA $81                     ; CBEE: A5 81
    CLC                         ; CBF0: 18
    ADC #$0B                    ; CBF1: 69 0B
    CMP #$20                    ; CBF3: C9 20
    BCC LCBFD                   ; CBF5: 90 06
    STA $30                     ; CBF7: 85 30
    SEC                         ; CBF9: 38
    SBC #$20                    ; CBFA: E9 20
    INX                         ; CBFC: E8
LCBFD:
    LDY #$00                    ; CBFD: A0 00
LCBFF:
    CMP $CE29,Y                 ; CBFF: D9 29 CE
    BEQ LCC0A                   ; CC02: F0 06
    INY                         ; CC04: C8
    CPY #$08                    ; CC05: C0 08
    BNE LCBFF                   ; CC07: D0 F6
    RTS                         ; CC09: 60
LCC0A:
    STA $99                     ; CC0A: 85 99
    STX $98                     ; CC0C: 86 98
    LDA #$01                    ; CC0E: A9 01
    STA $86                     ; CC10: 85 86
    RTS                         ; CC12: 60
LCC13:
    LDA ScrollX                 ; CC13: A5 18
    BNE LCC2A                   ; CC15: D0 13
    LDX #$00                    ; CC17: A2 00
LCC19:
    LDA ScrollLockLtTab,X       ; CC19: BD 9E D7
    CMP StageId                 ; CC1C: C5 80
    BNE LCC25                   ; CC1E: D0 05
    LDA #$00                    ; CC20: A9 00
    STA $1C                     ; CC22: 85 1C
    RTS                         ; CC24: 60
LCC25:
    INX                         ; CC25: E8
    CMP #$FF                    ; CC26: C9 FF
    BNE LCC19                   ; CC28: D0 EF
LCC2A:
    LDA #$02                    ; CC2A: A9 02
    STA $1C                     ; CC2C: 85 1C
    DEC ScrollX                 ; CC2E: C6 18
    LDX ScrollX                 ; CC30: A6 18
    INX                         ; CC32: E8
    BNE LCC35                   ; CC33: D0 00
LCC35:
    LDA ScrollX                 ; CC35: A5 18
    AND #$0F                    ; CC37: 29 0F
    CMP #$0F                    ; CC39: C9 0F
    BEQ LCC41                   ; CC3B: F0 04
    CMP #$07                    ; CC3D: C9 07
    BNE LCC6D                   ; CC3F: D0 2C
LCC41:
    DEC $81                     ; CC41: C6 81
    LDX $81                     ; CC43: A6 81
    INX                         ; CC45: E8
    BNE LCC4E                   ; CC46: D0 06
    LDA #$1F                    ; CC48: A9 1F
    STA $81                     ; CC4A: 85 81
    DEC StageId                 ; CC4C: C6 80
LCC4E:
    LDX StageId                 ; CC4E: A6 80
    LDA $81                     ; CC50: A5 81
    SEC                         ; CC52: 38
    SBC #$0B                    ; CC53: E9 0B
    BCS LCC6A                   ; CC55: B0 13
    STA $30                     ; CC57: 85 30
    LDA #$00                    ; CC59: A9 00
    SEC                         ; CC5B: 38
    SBC $30                     ; CC5C: E5 30
    STA $30                     ; CC5E: 85 30
    LDA #$20                    ; CC60: A9 20
    SEC                         ; CC62: 38
    SBC $30                     ; CC63: E5 30
    DEX                         ; CC65: CA
    CPX #$FF                    ; CC66: E0 FF
    BEQ LCC6D                   ; CC68: F0 03
LCC6A:
    JMP LCBFD                   ; CC6A: 4C FD CB
LCC6D:
    RTS                         ; CC6D: 60
LCC6E:
    LDX $32                     ; CC6E: A6 32
    LDA LayoutPageTab,X         ; CC70: BD BB D6
    STA JoyBits                 ; CC73: 85 24
    LDA JoyBits                 ; CC75: A5 24
    LDX #$01                    ; CC77: A2 01
    JSR $BCF2                   ; CC79: 20 F2 BC  -> Bank0:LBCF2
    LDA PageDescPtr             ; CC7C: AD F3 DD
    CLC                         ; CC7F: 18
    ADC $22                     ; CC80: 65 22
    STA $35                     ; CC82: 85 35
    LDA $DDF4                   ; CC84: AD F4 DD
    ADC $21                     ; CC87: 65 21
    STA $36                     ; CC89: 85 36
    LDY #$24                    ; CC8B: A0 24
    LDA $32                     ; CC8D: A5 32
    AND #$01                    ; CC8F: 29 01
    BNE LCC95                   ; CC91: D0 02
    LDY #$20                    ; CC93: A0 20
LCC95:
    LDA $4D                     ; CC95: A5 4D
    ASL A                       ; CC97: 0A
    TAX                         ; CC98: AA
    LDA $CE37,X                 ; CC99: BD 37 CE
    CLC                         ; CC9C: 18
    ADC $30                     ; CC9D: 65 30
    STA $3D                     ; CC9F: 85 3D
    TYA                         ; CCA1: 98
    ADC $CE38,X                 ; CCA2: 7D 38 CE
    STA $3C                     ; CCA5: 85 3C
    LDA $3C                     ; CCA7: A5 3C
    PHA                         ; CCA9: 48
    LDA $3D                     ; CCAA: A5 3D
    PHA                         ; CCAC: 48
    LDY $3C                     ; CCAD: A4 3C
    JSR LCE94                   ; CCAF: 20 94 CE
    PLA                         ; CCB2: 68
    STA $3D                     ; CCB3: 85 3D
    PLA                         ; CCB5: 68
    STA $3C                     ; CCB6: 85 3C
    LDY #$00                    ; CCB8: A0 00
LCCBA:
    LDA $30                     ; CCBA: A5 30
    CMP $CE3D,Y                 ; CCBC: D9 3D CE
    BCC LCCC4                   ; CCBF: 90 03
    INY                         ; CCC1: C8
    BNE LCCBA                   ; CCC2: D0 F6
LCCC4:
    LDX #$00                    ; CCC4: A2 00
    LDA $CE3D,Y                 ; CCC6: B9 3D CE
    SEC                         ; CCC9: 38
    SBC #$05                    ; CCCA: E9 05
    CMP $30                     ; CCCC: C5 30
    BCS LCCD1                   ; CCCE: B0 01
    INX                         ; CCD0: E8
LCCD1:
    STX $3E                     ; CCD1: 86 3E
    LDX $4D                     ; CCD3: A6 4D
    BEQ LCCDF                   ; CCD5: F0 08
    TYA                         ; CCD7: 98
LCCD8:
    CLC                         ; CCD8: 18
    ADC #$04                    ; CCD9: 69 04
    DEX                         ; CCDB: CA
    BNE LCCD8                   ; CCDC: D0 FA
    TAY                         ; CCDE: A8
LCCDF:
    LDA ($35),Y                 ; CCDF: B1 35
    STY $3F                     ; CCE1: 84 3F
    LDX #$02                    ; CCE3: A2 02
    JSR $BCE4                   ; CCE5: 20 E4 BC  -> Bank0:Word16ShlX
    LDY #$FE                    ; CCE8: A0 FE
LCCEA:
    INY                         ; CCEA: C8
    INY                         ; CCEB: C8
    LDA AltQuadRangeTab,Y       ; CCEC: B9 B9 D7
    CMP #$FF                    ; CCEF: C9 FF
    BEQ LCD07                   ; CCF1: F0 14
    LDA $32                     ; CCF3: A5 32
    CMP AltQuadRangeTab,Y       ; CCF5: D9 B9 D7
    BCC LCCEA                   ; CCF8: 90 F0
    CMP $D7BA,Y                 ; CCFA: D9 BA D7
    BCS LCCEA                   ; CCFD: B0 EB
    LDX QuadBaseAlt             ; CCFF: AE 61 DB
    LDY $DB62                   ; CD02: AC 62 DB
    BNE LCD0D                   ; CD05: D0 06
LCD07:
    LDX QuadBaseDef             ; CD07: AE 1F D8
    LDY $D820                   ; CD0A: AC 20 D8
LCD0D:
    TXA                         ; CD0D: 8A
    CLC                         ; CD0E: 18
    ADC $22                     ; CD0F: 65 22
    STA $40                     ; CD11: 85 40
    TYA                         ; CD13: 98
    ADC $21                     ; CD14: 65 21
    STA $41                     ; CD16: 85 41
    LDA #$02                    ; CD18: A9 02
    STA $31                     ; CD1A: 85 31
    LDA $4D                     ; CD1C: A5 4D
    ASL A                       ; CD1E: 0A
    STA $27                     ; CD1F: 85 27
LCD21:
    LDY #$27                    ; CD21: A0 27
    LDA $32                     ; CD23: A5 32
    AND #$01                    ; CD25: 29 01
    BNE LCD2B                   ; CD27: D0 02
    LDY #$23                    ; CD29: A0 23
LCD2B:
    LDX $27                     ; CD2B: A6 27
    LDA $30                     ; CD2D: A5 30
    LSR A                       ; CD2F: 4A
    LSR A                       ; CD30: 4A
    CLC                         ; CD31: 18
    ADC $CE31,X                 ; CD32: 7D 31 CE
    PHA                         ; CD35: 48
    JSR $8704                   ; CD36: 20 04 87  -> Bank0:PpuBufPut01
    TYA                         ; CD39: 98
    STA PpuBuf,X                ; CD3A: 9D 00 06
    INX                         ; CD3D: E8
    PLA                         ; CD3E: 68
    STA PpuBuf,X                ; CD3F: 9D 00 06
    LDY $3E                     ; CD42: A4 3E
    LDA ($40),Y                 ; CD44: B1 40
    TAY                         ; CD46: A8
    LDA MetaAttrTab,Y           ; CD47: B9 B9 E0
    INX                         ; CD4A: E8
    STA PpuBuf,X                ; CD4B: 9D 00 06
    JSR $8713                   ; CD4E: 20 13 87  -> Bank0:PpuBufCloseAtX
    LDA #$00                    ; CD51: A9 00
    STA $34                     ; CD53: 85 34
    LDY $3E                     ; CD55: A4 3E
    LDA ($40),Y                 ; CD57: B1 40
    STA $33                     ; CD59: 85 33
    ASL $33                     ; CD5B: 06 33
    BCC LCD61                   ; CD5D: 90 02
    INC $34                     ; CD5F: E6 34
LCD61:
    LDA MetaStreamPtrPtr        ; CD61: AD AD E1
    CLC                         ; CD64: 18
    ADC $33                     ; CD65: 65 33
    STA $33                     ; CD67: 85 33
    LDA $E1AE                   ; CD69: AD AE E1
    ADC $34                     ; CD6C: 65 34
    STA $34                     ; CD6E: 85 34
    LDY #$00                    ; CD70: A0 00
    LDA ($33),Y                 ; CD72: B1 33
    STA $3A                     ; CD74: 85 3A
    INY                         ; CD76: C8
    LDA ($33),Y                 ; CD77: B1 33
    STA $3B                     ; CD79: 85 3B
    LDY #$04                    ; CD7B: A0 04
    LDA $4D                     ; CD7D: A5 4D
    BNE LCD89                   ; CD7F: D0 08
    LDA $31                     ; CD81: A5 31
    CMP #$02                    ; CD83: C9 02
    BNE LCD89                   ; CD85: D0 02
    LDY #$02                    ; CD87: A0 02
LCD89:
    STY $38                     ; CD89: 84 38
    LDY #$00                    ; CD8B: A0 00
LCD8D:
    LDA $9E                     ; CD8D: A5 9E
    STA JoyBits2                ; CD8F: 85 25
    LDA #$04                    ; CD91: A9 04
    STA $37                     ; CD93: 85 37
    JSR $8704                   ; CD95: 20 04 87  -> Bank0:PpuBufPut01
    LDA $3C                     ; CD98: A5 3C
    STA PpuBuf,X                ; CD9A: 9D 00 06
    INX                         ; CD9D: E8
    LDA $3D                     ; CD9E: A5 3D
    JSR $870C                   ; CDA0: 20 0C 87  -> Bank0:PpuBufPutAtX
LCDA3:
    LDA ($3A),Y                 ; CDA3: B1 3A
    CMP #$30                    ; CDA5: C9 30
    BCC LCDCC                   ; CDA7: 90 23
    CMP #$3A                    ; CDA9: C9 3A
    BCS LCDCC                   ; CDAB: B0 1F
    CMP #$38                    ; CDAD: C9 38
    BNE LCDC0                   ; CDAF: D0 0F
    INY                         ; CDB1: C8
    LDA ($3A),Y                 ; CDB2: B1 3A
    TAX                         ; CDB4: AA
    INY                         ; CDB5: C8
    LDA ($3A),Y                 ; CDB6: B1 3A
    STA $3B                     ; CDB8: 85 3B
    STX $3A                     ; CDBA: 86 3A
    LDY #$00                    ; CDBC: A0 00
    BEQ LCDA3                   ; CDBE: F0 E3
LCDC0:
    AND #$0F                    ; CDC0: 29 0F
    TAX                         ; CDC2: AA
    LDA $CE1F,X                 ; CDC3: BD 1F CE
    LDX $37                     ; CDC6: A6 37
    CPX #$01                    ; CDC8: E0 01
    BNE LCDCD                   ; CDCA: D0 01
LCDCC:
    INY                         ; CDCC: C8
LCDCD:
    STA $33                     ; CDCD: 85 33
    JSR $870A                   ; CDCF: 20 0A 87  -> Bank0:PpuBufPut
    CMP #$14                    ; CDD2: C9 14
    BCS LCDE5                   ; CDD4: B0 0F
    LDX $9D                     ; CDD6: A6 9D
    LDA TerrainMap,X            ; CDD8: BD 40 03
    ORA JoyBits2                ; CDDB: 05 25
    EOR JoyBits2                ; CDDD: 45 25
    STA TerrainMap,X            ; CDDF: 9D 40 03
    JMP LCDEF                   ; CDE2: 4C EF CD
LCDE5:
    LDX $9D                     ; CDE5: A6 9D
    LDA TerrainMap,X            ; CDE7: BD 40 03
    ORA JoyBits2                ; CDEA: 05 25
    STA TerrainMap,X            ; CDEC: 9D 40 03
LCDEF:
    ASL JoyBits2                ; CDEF: 06 25
    DEC $37                     ; CDF1: C6 37
    BNE LCDA3                   ; CDF3: D0 AE
    JSR $8700                   ; CDF5: 20 00 87  -> Bank0:PpuBufPutFF
    LDA #$04                    ; CDF8: A9 04
    CLC                         ; CDFA: 18
    ADC $9D                     ; CDFB: 65 9D
    STA $9D                     ; CDFD: 85 9D
    LDA $3D                     ; CDFF: A5 3D
    CLC                         ; CE01: 18
    ADC #$20                    ; CE02: 69 20
    STA $3D                     ; CE04: 85 3D
    BCC LCE0A                   ; CE06: 90 02
    INC $3C                     ; CE08: E6 3C
LCE0A:
    DEC $38                     ; CE0A: C6 38
    BEQ LCE11                   ; CE0C: F0 03
    JMP LCD8D                   ; CE0E: 4C 8D CD
LCE11:
    DEC $31                     ; CE11: C6 31
    BEQ LCE1E                   ; CE13: F0 09
    INC $3E                     ; CE15: E6 3E
    INC $3E                     ; CE17: E6 3E
    INC $27                     ; CE19: E6 27
    JMP LCD21                   ; CE1B: 4C 21 CD
LCE1E:
    RTS                         ; CE1E: 60
    .byte $00,$01,$02,$03,$04,$05,$06,$07         ; CE1F: 00 01 02 03 04 05 06 07
    .byte $00,$41,$00,$04,$08,$0C,$10,$14         ; CE27: 00 41 00 04 08 0C 10 14
    .byte $18,$1C,$C8,$D0,$D8,$E0,$E8,$F0         ; CE2F: 18 1C C8 D0 D8 E0 E8 F0
    .byte $C0,$00,$80,$01,$80,$02,$08,$10         ; CE37: C0 00 80 01 80 02 08 10
    .byte $18,$20                                 ; CE3F: 18 20
LCE41:
    LDX #$00                    ; CE41: A2 00
LCE43:
    LDA ScrollLockRtTab,X       ; CE43: BD 83 D7
    CMP StageId                 ; CE46: C5 80
    BEQ LCE51                   ; CE48: F0 07
    INX                         ; CE4A: E8
    CMP #$FF                    ; CE4B: C9 FF
    BNE LCE43                   ; CE4D: D0 F4
    CLC                         ; CE4F: 18
    RTS                         ; CE50: 60
LCE51:
    LDA #$00                    ; CE51: A9 00
    STA $1C                     ; CE53: 85 1C
    SEC                         ; CE55: 38
    RTS                         ; CE56: 60
ResetScroll:
    ; 读 PPU_STATUS 复位锁存，$2005 双写 0：滚动归零；NMI 切 CHR bank 后调用
    LDA PPU_STATUS              ; CE57: AD 02 20
    LDA #$00                    ; CE5A: A9 00
    STA PPU_SCROLL              ; CE5C: 8D 05 20
    STA PPU_SCROLL              ; CE5F: 8D 05 20
    RTS                         ; CE62: 60
WaitSprite0:
    ; sprite-0 命中等待（PPU_STATUS AND #$40 先等清再等置）；命中后 JSR ApplyScroll(bank0 $8400)，末尾以 MapperShadow 恢复 $6000
    LDA SceneId                 ; CE63: A5 1F
    BPL LCE86                   ; CE65: 10 1F
    LDA RenderDelay             ; CE67: A5 0C
    BNE LCE86                   ; CE69: D0 1B
LCE6B:
    LDA PPU_STATUS              ; CE6B: AD 02 20
    AND #$40                    ; CE6E: 29 40
    BNE LCE6B                   ; CE70: D0 F9
    LDA SceneId                 ; CE72: A5 1F
    BPL LCE86                   ; CE74: 10 10
    LDA RenderDelay             ; CE76: A5 0C
    BNE LCE8E                   ; CE78: D0 14
LCE7A:
    LDA PPU_STATUS              ; CE7A: AD 02 20
    AND #$40                    ; CE7D: 29 40
    BEQ LCE7A                   ; CE7F: F0 F9
    LDY #$06                    ; CE81: A0 06
LCE83:
    DEY                         ; CE83: 88
    BNE LCE83                   ; CE84: D0 FD
LCE86:
    JSR $8400                   ; CE86: 20 00 84  -> Bank0:ApplyScroll
    LDA $07CA                   ; CE89: AD CA 07
    BEQ LCE8E                   ; CE8C: F0 00
LCE8E:
    LDA MapperShadow            ; CE8E: A5 1E
    STA MAPPER87                ; CE90: 8D 00 60
    RTS                         ; CE93: 60
LCE94:
    STA $3C                     ; CE94: 85 3C
    SEC                         ; CE96: 38
    SBC #$80                    ; CE97: E9 80
    STA $3C                     ; CE99: 85 3C
    BCS LCE9E                   ; CE9B: B0 01
    DEY                         ; CE9D: 88
LCE9E:
    LDA #$00                    ; CE9E: A9 00
    CPY #$24                    ; CEA0: C0 24
    BCC LCEA6                   ; CEA2: 90 02
    LDA #$60                    ; CEA4: A9 60
LCEA6:
    PHA                         ; CEA6: 48
    TYA                         ; CEA7: 98
    AND #$03                    ; CEA8: 29 03
    STA $3D                     ; CEAA: 85 3D
    LDA $3C                     ; CEAC: A5 3C
    AND #$07                    ; CEAE: 29 07
    TAY                         ; CEB0: A8
    LDA $CECE,Y                 ; CEB1: B9 CE CE
    STA $9E                     ; CEB4: 85 9E
    PLA                         ; CEB6: 68
    TAY                         ; CEB7: A8
    CLC                         ; CEB8: 18
    LSR $3D                     ; CEB9: 46 3D
    ROR $3C                     ; CEBB: 66 3C
    CLC                         ; CEBD: 18
    LSR $3D                     ; CEBE: 46 3D
    ROR $3C                     ; CEC0: 66 3C
    CLC                         ; CEC2: 18
    LSR $3D                     ; CEC3: 46 3D
    ROR $3C                     ; CEC5: 66 3C
    TYA                         ; CEC7: 98
    CLC                         ; CEC8: 18
    ADC $3C                     ; CEC9: 65 3C
    STA $9D                     ; CECB: 85 9D
    RTS                         ; CECD: 60
    .byte $01,$02,$04,$08,$10,$20,$40,$80         ; CECE: 01 02 04 08 10 20 40 80
ObjProxScan:
    ; 每帧物体邻近扫描：FrameCnt&3 相位取 $D096 表起始槽/数量，遍历活动物体（类型<$11）按 $D09E 类型参数对与 $D0C0 类档索引→$D0E9 距离框记录算 X/Y 向距离框，匹配键位（$D082/$D08C 掩码，$A3==7 改按 $05F2&B）后把记录序号写 $0150,X/$0160,X（$FF=无）
    LDA FrameCnt                ; CED6: A5 09
    AND #$03                    ; CED8: 29 03
    ASL A                       ; CEDA: 0A
    TAY                         ; CEDB: A8
    LDA $D096,Y                 ; CEDC: B9 96 D0
    STA $37                     ; CEDF: 85 37
    LDA $D097,Y                 ; CEE1: B9 97 D0
    STA $033E                   ; CEE4: 8D 3E 03
LCEE7:
    LDA #$00                    ; CEE7: A9 00
    STA $32                     ; CEE9: 85 32
    LDX $37                     ; CEEB: A6 37
    LDA ObjType,X               ; CEED: B5 60
    BNE LCEF8                   ; CEEF: D0 07
    LDY ObjSprite,X             ; CEF1: B4 70
    BNE LCEF8                   ; CEF3: D0 03
    JMP LCFD3                   ; CEF5: 4C D3 CF
LCEF8:
    CMP #$11                    ; CEF8: C9 11
    BCC LCEFF                   ; CEFA: 90 03
    JMP LCFDB                   ; CEFC: 4C DB CF
LCEFF:
    ASL A                       ; CEFF: 0A
    TAY                         ; CF00: A8
    LDA $D09E,Y                 ; CF01: B9 9E D0
    STA $33                     ; CF04: 85 33
    LDA $D09F,Y                 ; CF06: B9 9F D0
    STA $34                     ; CF09: 85 34
    LDX #$00                    ; CF0B: A2 00
    STX $3E                     ; CF0D: 86 3E
LCF0F:
    LDX $3E                     ; CF0F: A6 3E
    LDA $0702,X                 ; CF11: BD 02 07
    BPL LCF19                   ; CF14: 10 03
LCF16:
    JMP LD059                   ; CF16: 4C 59 D0
LCF19:
    LDA $0702,X                 ; CF19: BD 02 07
    CMP #$36                    ; CF1C: C9 36
    BEQ LCF16                   ; CF1E: F0 F6
    CMP #$37                    ; CF20: C9 37
    BEQ LCF16                   ; CF22: F0 F2
    CMP #$44                    ; CF24: C9 44
    BEQ LCF16                   ; CF26: F0 EE
    CMP #$2F                    ; CF28: C9 2F
    BCS LCF32                   ; CF2A: B0 06
    LDA $37                     ; CF2C: A5 37
    CMP #$01                    ; CF2E: C9 01
    BNE LCF16                   ; CF30: D0 E4
LCF32:
    LDA $33                     ; CF32: A5 33
    STA $3C                     ; CF34: 85 3C
    LDA $0702,X                 ; CF36: BD 02 07
    CMP #$47                    ; CF39: C9 47
    BCS LCF16                   ; CF3B: B0 D9
    LDA $0702,X                 ; CF3D: BD 02 07
    AND #$7F                    ; CF40: 29 7F
    CMP #$45                    ; CF42: C9 45
    BEQ LCF4D                   ; CF44: F0 07
    CMP #$46                    ; CF46: C9 46
    BNE LCF79                   ; CF48: D0 2F
    SEC                         ; CF4A: 38
    SBC #$01                    ; CF4B: E9 01
LCF4D:
    JSR $BEF8                   ; CF4D: 20 F8 BE  -> Bank0:ObjTypeRemap
    STA $30                     ; CF50: 85 30
    LDA $0705,X                 ; CF52: BD 05 07
    AND #$F0                    ; CF55: 29 F0
    BEQ LCF6E                   ; CF57: F0 15
    BPL LCF16                   ; CF59: 10 BB
    CMP #$80                    ; CF5B: C9 80
    BEQ LCF63                   ; CF5D: F0 04
    LDA #$08                    ; CF5F: A9 08
    BNE LCF73                   ; CF61: D0 10
LCF63:
    LDA $0705,X                 ; CF63: BD 05 07
    AND #$0F                    ; CF66: 29 0F
    CLC                         ; CF68: 18
    ADC #$09                    ; CF69: 69 09
    JMP LCF73                   ; CF6B: 4C 73 CF
LCF6E:
    LDA $0705,X                 ; CF6E: BD 05 07
    AND #$0F                    ; CF71: 29 0F
LCF73:
    CLC                         ; CF73: 18
    ADC $30                     ; CF74: 65 30
    JMP LCF7C                   ; CF76: 4C 7C CF
LCF79:
    JSR $BEF8                   ; CF79: 20 F8 BE  -> Bank0:ObjTypeRemap
LCF7C:
    TAY                         ; CF7C: A8
    LDA ProxClassIdxTab,Y       ; CF7D: B9 C0 D0
    TAY                         ; CF80: A8
    LDA ProxBoxTab,Y            ; CF81: B9 E9 D0
    STA $3A                     ; CF84: 85 3A
    LDA $D0EA,Y                 ; CF86: B9 EA D0
    STA $3B                     ; CF89: 85 3B
    LDA $D0EB,Y                 ; CF8B: B9 EB D0
    STA $38                     ; CF8E: 85 38
    LDA $D0EC,Y                 ; CF90: B9 EC D0
    STA $39                     ; CF93: 85 39
    LDA $0703,X                 ; CF95: BD 03 07
    STA $36                     ; CF98: 85 36
    LDA $0704,X                 ; CF9A: BD 04 07
    STA $35                     ; CF9D: 85 35
    LDA $38                     ; CF9F: A5 38
    CLC                         ; CFA1: 18
    ADC $35                     ; CFA2: 65 35
    STA $35                     ; CFA4: 85 35
    LDA $39                     ; CFA6: A5 39
    CLC                         ; CFA8: 18
    ADC $36                     ; CFA9: 65 36
    STA $36                     ; CFAB: 85 36
    LDA $3B                     ; CFAD: A5 3B
    CLC                         ; CFAF: 18
    ADC $36                     ; CFB0: 65 36
    STA $36                     ; CFB2: 85 36
    LDA $3A                     ; CFB4: A5 3A
    LSR A                       ; CFB6: 4A
    CLC                         ; CFB7: 18
    ADC $35                     ; CFB8: 65 35
    STA $35                     ; CFBA: 85 35
    LDA $3A                     ; CFBC: A5 3A
    CLC                         ; CFBE: 18
    ADC $3C                     ; CFBF: 65 3C
    LSR A                       ; CFC1: 4A
    STA $3C                     ; CFC2: 85 3C
    LDX $37                     ; CFC4: A6 37
    LDA ObjX,X                  ; CFC6: BD 70 04
    CMP $35                     ; CFC9: C5 35
    BCC LCFE6                   ; CFCB: 90 19
    SEC                         ; CFCD: 38
    SBC $35                     ; CFCE: E5 35
    JMP LCFEC                   ; CFD0: 4C EC CF
LCFD3:
    LDA #$FF                    ; CFD3: A9 FF
    STA ProxRec1,X              ; CFD5: 9D 50 01
    STA ProxRec2,X              ; CFD8: 9D 60 01
LCFDB:
    INC $37                     ; CFDB: E6 37
    DEC $033E                   ; CFDD: CE 3E 03
    BEQ LCFE5                   ; CFE0: F0 03
    JMP LCEE7                   ; CFE2: 4C E7 CE
LCFE5:
    RTS                         ; CFE5: 60
LCFE6:
    LDA $35                     ; CFE6: A5 35
    SEC                         ; CFE8: 38
    SBC ObjX,X                  ; CFE9: FD 70 04
LCFEC:
    CMP $3C                     ; CFEC: C5 3C
    BCS LD059                   ; CFEE: B0 69
    LDA ObjY,X                  ; CFF0: BD 60 04
    CMP $36                     ; CFF3: C5 36
    BCC LD000                   ; CFF5: 90 09
    SEC                         ; CFF7: 38
    SBC $36                     ; CFF8: E5 36
    CMP $33                     ; CFFA: C5 33
    BCS LD059                   ; CFFC: B0 5B
    BCC LD00A                   ; CFFE: 90 0A
LD000:
    LDA $36                     ; D000: A5 36
    SEC                         ; D002: 38
    SBC ObjY,X                  ; D003: FD 60 04
    CMP $3B                     ; D006: C5 3B
    BCS LD059                   ; D008: B0 4F
LD00A:
    LDX $37                     ; D00A: A6 37
    LDA ObjType,X               ; D00C: B5 60
    CMP #$00                    ; D00E: C9 00
    BNE LD042                   ; D010: D0 30
    LDX $3E                     ; D012: A6 3E
    LDA $0702,X                 ; D014: BD 02 07
    CMP #$00                    ; D017: C9 00
    BCC LD042                   ; D019: 90 27
    CMP #$18                    ; D01B: C9 18
    BCS LD042                   ; D01D: B0 23
    LDA StageArea               ; D01F: A5 A3
    CMP #$07                    ; D021: C9 07
    BEQ LD075                   ; D023: F0 50
    TAY                         ; D025: A8
    LDA $92                     ; D026: A5 92
    AND #$01                    ; D028: 29 01
    BEQ LD038                   ; D02A: F0 0C
    LDA JoyHeld                 ; D02C: A5 07
    AND $D08C,Y                 ; D02E: 39 8C D0
    CMP $D08C,Y                 ; D031: D9 8C D0
    BNE LD059                   ; D034: D0 23
    BEQ LD042                   ; D036: F0 0A
LD038:
    LDA JoyHeld                 ; D038: A5 07
    AND $D082,Y                 ; D03A: 39 82 D0
    CMP $D082,Y                 ; D03D: D9 82 D0
    BNE LD059                   ; D040: D0 17
LD042:
    LDX $37                     ; D042: A6 37
    LDA $32                     ; D044: A5 32
    BNE LD051                   ; D046: D0 09
    LDA $3E                     ; D048: A5 3E
    STA ProxRec1,X              ; D04A: 9D 50 01
    INC $32                     ; D04D: E6 32
    BNE LD067                   ; D04F: D0 16
LD051:
    LDA $3E                     ; D051: A5 3E
    STA ProxRec2,X              ; D053: 9D 60 01
LD056:
    JMP LCFDB                   ; D056: 4C DB CF
LD059:
    LDX $37                     ; D059: A6 37
    LDA #$FF                    ; D05B: A9 FF
    LDY $32                     ; D05D: A4 32
    BNE LD064                   ; D05F: D0 03
    STA ProxRec1,X              ; D061: 9D 50 01
LD064:
    STA ProxRec2,X              ; D064: 9D 60 01
LD067:
    LDA $3E                     ; D067: A5 3E
    CLC                         ; D069: 18
    ADC #$06                    ; D06A: 69 06
    STA $3E                     ; D06C: 85 3E
    CMP #$60                    ; D06E: C9 60
    BEQ LD056                   ; D070: F0 E4
    JMP LCF0F                   ; D072: 4C 0F CF
LD075:
    LDA SlingAmmo               ; D075: AD F2 05
    BEQ LD059                   ; D078: F0 DF
    LDA JoyHeld                 ; D07A: A5 07
    AND #$40                    ; D07C: 29 40
    BEQ LD059                   ; D07E: F0 D9
    BNE LD042                   ; D080: D0 C0
    BRK                         ; D082: 00
    .byte $40,$04,$01,$08,$44,$02,$00,$04         ; D083: 40 04 01 08 44 02 00 04
    .byte $40,$00,$44,$06,$05,$09,$46,$0A         ; D08B: 40 00 44 06 05 09 46 0A
    .byte $00,$06,$41,$01,$01,$02,$02,$04         ; D093: 00 06 41 01 01 02 02 04
    .byte $02,$06,$02,$08,$15,$10,$16,$10         ; D09B: 02 06 02 08 15 10 16 10
    .byte $16,$08,$10,$0B,$10,$0F,$16,$08         ; D0A3: 16 08 10 0B 10 0F 16 08
    .byte $08,$10,$10,$10,$10,$10,$10,$0F         ; D0AB: 08 10 10 10 10 10 10 0F
    .byte $06,$10,$16,$10,$10,$08,$08,$03         ; D0B3: 06 10 16 10 10 08 08 03
    .byte $03,$08,$03,$10,$03                     ; D0BB: 03 08 03 10 03
ProxClassIdxTab:
    .byte $04,$08,$0C,$0C,$10,$10,$10,$10         ; D0C0: 04 08 0C 0C 10 10 10 10
    .byte $00,$00,$14,$18,$18,$18,$1C,$20         ; D0C8: 00 00 14 18 18 18 1C 20
    .byte $24,$20,$24,$24,$28,$2C,$00,$30         ; D0D0: 24 20 24 24 28 2C 00 30
    .byte $34,$38,$3C,$40,$44,$48,$4C,$50         ; D0D8: 34 38 3C 40 44 48 4C 50
    .byte $54,$58,$5C,$60,$64,$68,$6C,$70         ; D0E0: 54 58 5C 60 64 68 6C 70
    .byte $74                                     ; D0E8: 74
ProxBoxTab:
    .byte $FF,$FF,$FF,$FF,$16,$30,$FD,$00         ; D0E9: FF FF FF FF 16 30 FD 00
    .byte $0C,$20,$08,$00,$16,$30,$FD,$00         ; D0F1: 0C 20 08 00 16 30 FD 00
    .byte $16,$30,$FD,$00,$08,$20,$0A,$00         ; D0F9: 16 30 FD 00 08 20 0A 00
    .byte $10,$20,$02,$08,$04,$A8,$02,$F8         ; D101: 10 20 02 08 04 A8 02 F8
    .byte $04,$70,$02,$F8,$04,$38,$02,$F8         ; D109: 04 70 02 F8 04 38 02 F8
    .byte $04,$20,$02,$F8,$02,$30,$0A,$00         ; D111: 04 20 02 F8 02 30 0A 00
    .byte $10,$18,$FE,$00,$10,$28,$FE,$F0         ; D119: 10 18 FE 00 10 28 FE F0
    .byte $10,$38,$FE,$E0,$10,$48,$FE,$D0         ; D121: 10 38 FE E0 10 48 FE D0
    .byte $10,$58,$FE,$C0,$10,$68,$FE,$B0         ; D129: 10 58 FE C0 10 68 FE B0
    .byte $10,$78,$FE,$A0,$10,$88,$FE,$90         ; D131: 10 78 FE A0 10 88 FE 90
    .byte $10,$98,$FE,$80,$10,$98,$FE,$00         ; D139: 10 98 FE 80 10 98 FE 00
    .byte $10,$88,$FE,$00,$10,$78,$FE,$00         ; D141: 10 88 FE 00 10 78 FE 00
    .byte $10,$68,$FE,$00,$10,$58,$FE,$00         ; D149: 10 68 FE 00 10 58 FE 00
    .byte $10,$48,$FE,$00,$10,$38,$FE,$00         ; D151: 10 48 FE 00 10 38 FE 00
    .byte $10,$28,$FE,$00,$10,$18,$FE,$00         ; D159: 10 28 FE 00 10 18 FE 00
SpawnPageTab:
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; D161: 00 00 00 00 00 00 00 00
    .byte $00,$00,$00,$00,$00,$08,$00,$00         ; D169: 00 00 00 00 00 08 00 00
    .byte $09,$00,$00,$00,$00,$31,$30,$2F         ; D171: 09 00 00 00 00 31 30 2F
    .byte $00,$14,$00,$00,$00,$00,$00,$00         ; D179: 00 14 00 00 00 00 00 00
    .byte $00,$00,$00,$15,$0D,$0E,$00,$00         ; D181: 00 00 00 15 0D 0E 00 00
    .byte $00,$00,$00,$00,$00,$0A,$0B,$0C         ; D189: 00 00 00 00 00 0A 0B 0C
    .byte $0F,$00,$00,$1B,$1A,$00,$00,$13         ; D191: 0F 00 00 1B 1A 00 00 13
    .byte $12,$11,$10,$00,$00,$00,$19,$18         ; D199: 12 11 10 00 00 00 19 18
    .byte $17,$16,$00,$2D,$2C,$00,$00,$00         ; D1A1: 17 16 00 2D 2C 00 00 00
    .byte $1D,$1C,$00,$00,$00,$2E,$00,$00         ; D1A9: 1D 1C 00 00 00 2E 00 00
    .byte $00,$00,$00,$21,$22,$27,$28,$29         ; D1B1: 00 00 00 21 22 27 28 29
    .byte $00,$00,$00,$00,$00,$23,$24,$25         ; D1B9: 00 00 00 00 00 23 24 25
    .byte $26,$1E,$1F,$20,$00,$00,$00,$00         ; D1C1: 26 1E 1F 20 00 00 00 00
    .byte $00,$00,$03,$02,$01,$00,$00,$00         ; D1C9: 00 00 03 02 01 00 00 00
    .byte $00,$07,$06,$05,$04,$00,$00,$00         ; D1D1: 00 07 06 05 04 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; D1D9: 00 00 00 00 00 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; D1E1: 00 00 00 00 00 00 00 00
    .byte $38,$37,$36,$35,$00,$00,$00,$00         ; D1E9: 38 37 36 35 00 00 00 00
    .byte $34,$33,$00,$32,$00,$00,$39,$3A         ; D1F1: 34 33 00 32 00 00 39 3A
    .byte $3B,$3C,$00,$00,$00,$00,$00,$00         ; D1F9: 3B 3C 00 00 00 00 00 00
    .byte $3D,$3E,$00,$3F,$00,$00,$00,$00         ; D201: 3D 3E 00 3F 00 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; D209: 00 00 00 00 00 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; D211: 00 00 00 00 00 00 00 00
    .byte $00,$44,$45,$46,$47,$48,$00,$43         ; D219: 00 44 45 46 47 48 00 43
    .byte $42,$41,$40,$00,$2A,$2B,$00,$00         ; D221: 42 41 40 00 2A 2B 00 00
SpawnBasePtr:
    .byte $2B,$D2                                 ; D229: 2B D2
SpawnStreamData:
    .byte $10,$FF,$20,$FF,$40,$FF,$60,$FF         ; D22B: 10 FF 20 FF 40 FF 60 FF
    .byte $80,$FF,$A0,$FF,$C0,$FF,$E0,$FF         ; D233: 80 FF A0 FF C0 FF E0 FF
    .byte $13,$0B,$43,$00,$53,$01,$70,$FF         ; D23B: 13 0B 43 00 53 01 70 FF
    .byte $91,$40,$B3,$02,$C0,$18,$D2,$41         ; D243: 91 40 B3 02 C0 18 D2 41
    .byte $09,$40,$10,$FF,$21,$19,$A3,$03         ; D24B: 09 40 10 FF 21 19 A3 03
    .byte $B3,$04,$C3,$05,$D2,$41,$E2,$1A         ; D253: B3 04 C3 05 D2 41 E2 1A
    .byte $33,$42,$3B,$06,$40,$1B,$5A,$30         ; D25B: 33 42 3B 06 40 1B 5A 30
    .byte $73,$08,$B2,$41,$D1,$40,$F0,$07         ; D263: 73 08 B2 41 D1 40 F0 07
    .byte $09,$18,$20,$44,$32,$41,$8A,$44         ; D26B: 09 18 20 44 32 41 8A 44
    .byte $A2,$FF,$B1,$40,$C0,$38,$D3,$FF         ; D273: A2 FF B1 40 C0 38 D3 FF
    .byte $12,$41,$1B,$00,$20,$19,$48,$FF         ; D27B: 12 41 1B 00 20 19 48 FF
    .byte $51,$40,$71,$44,$B0,$FF,$E7,$FF         ; D283: 51 40 71 44 B0 FF E7 FF
    .byte $08,$0B,$20,$1A,$50,$FF,$82,$01         ; D28B: 08 0B 20 1A 50 FF 82 01
    .byte $92,$FF,$A0,$FF,$C2,$FF,$F2,$44         ; D293: 92 FF A0 FF C2 FF F2 44
    .byte $20,$38,$42,$1B,$59,$02,$6A,$44         ; D29B: 20 38 42 1B 59 02 6A 44
    .byte $A8,$FF,$B2,$41,$D1,$40,$F7,$FF         ; D2A3: A8 FF B2 41 D1 40 F7 FF
    .byte $20,$38,$33,$42,$58,$FF,$72,$FF         ; D2AB: 20 38 33 42 58 FF 72 FF
    .byte $A8,$03,$B9,$44,$C0,$FF,$D2,$41         ; D2B3: A8 03 B9 44 C0 FF D2 41
    .byte $2F,$04,$31,$3F,$71,$40,$A2,$31         ; D2BB: 2F 04 31 3F 71 40 A2 31
    .byte $B1,$40,$C0,$38,$D3,$42,$E3,$FF         ; D2C3: B1 40 C0 38 D3 42 E3 FF
    .byte $22,$38,$43,$00,$49,$51,$59,$51         ; D2CB: 22 38 43 00 49 51 59 51
    .byte $72,$41,$82,$FF,$88,$47,$91,$40         ; D2D3: 72 41 82 FF 88 47 91 40
    .byte $10,$FF,$20,$FF,$44,$11,$60,$FF         ; D2DB: 10 FF 20 FF 44 11 60 FF
    .byte $80,$FF,$B0,$3E,$D0,$FF,$F3,$FF         ; D2E3: 80 FF B0 3E D0 FF F3 FF
    .byte $09,$51,$19,$52,$70,$3D,$82,$18         ; D2EB: 09 51 19 52 70 3D 82 18
    .byte $A8,$47,$B2,$41,$C2,$4C,$D0,$3E         ; D2F3: A8 47 B2 41 C2 4C D0 3E
    .byte $19,$48,$27,$FF,$32,$41,$78,$4F         ; D2FB: 19 48 27 FF 32 41 78 4F
    .byte $81,$19,$B3,$42,$B8,$4F,$D8,$4F         ; D303: 81 19 B3 42 B8 4F D8 4F
    .byte $18,$47,$48,$01,$51,$3F,$73,$42         ; D30B: 18 47 48 01 51 3F 73 42
    .byte $A0,$38,$C0,$FF,$D3,$42,$E2,$4C         ; D313: A0 38 C0 FF D3 42 E2 4C
    .byte $28,$FF,$31,$40,$48,$FF,$72,$41         ; D31B: 28 FF 31 40 48 FF 72 41
    .byte $82,$FF,$A0,$02,$D3,$42,$E2,$4C         ; D323: 82 FF A0 02 D3 42 E2 4C
    .byte $41,$40,$5A,$49,$72,$41,$78,$4E         ; D32B: 41 40 5A 49 72 41 78 4E
    .byte $80,$1A,$B3,$42,$D0,$3C,$E1,$4B         ; D333: 80 1A B3 42 D0 3C E1 4B
    .byte $32,$41,$4E,$0E,$62,$4C,$78,$4E         ; D33B: 32 41 4E 0E 62 4C 78 4E
    .byte $A8,$4E,$B1,$40,$D0,$4A,$E3,$FF         ; D343: A8 4E B1 40 D0 4A E3 FF
    .byte $22,$FF,$5A,$49,$6E,$03,$80,$FF         ; D34B: 22 FF 5A 49 6E 03 80 FF
    .byte $92,$41,$A7,$FF,$B0,$FF,$F0,$FF         ; D353: 92 41 A7 FF B0 FF F0 FF
    .byte $33,$42,$40,$1B,$62,$30,$92,$41         ; D35B: 33 42 40 1B 62 30 92 41
    .byte $A0,$FF,$A8,$4E,$B8,$4E,$F8,$4E         ; D363: A0 FF A8 4E B8 4E F8 4E
    .byte $28,$FF,$33,$42,$38,$00,$47,$12         ; D36B: 28 FF 33 42 38 00 47 12
    .byte $48,$01,$58,$02,$68,$03,$D0,$FF         ; D373: 48 01 58 02 68 03 D0 FF
    .byte $30,$FF,$43,$04,$53,$05,$63,$06         ; D37B: 30 FF 43 04 53 05 63 06
    .byte $73,$07,$A9,$51,$B9,$51,$D3,$42         ; D383: 73 07 A9 51 B9 51 D3 42
    .byte $08,$39,$48,$39,$72,$FF,$78,$FF         ; D38B: 08 39 48 39 72 FF 78 FF
    .byte $88,$FF,$A8,$FF,$B8,$55,$C0,$18         ; D393: 88 FF A8 FF B8 55 C0 18
    .byte $08,$51,$38,$51,$40,$55,$69,$3A         ; D39B: 08 51 38 51 40 55 69 3A
    .byte $A0,$00,$B2,$41,$D1,$40,$F8,$4F         ; D3A3: A0 00 B2 41 D1 40 F8 4F
    .byte $08,$4E,$33,$42,$51,$40,$60,$38         ; D3AB: 08 4E 33 42 51 40 60 38
    .byte $89,$3A,$B8,$4E,$D2,$01,$F8,$4F         ; D3B3: 89 3A B8 4E D2 01 F8 4F
    .byte $21,$19,$33,$42,$50,$55,$71,$3F         ; D3BB: 21 19 33 42 50 55 71 3F
    .byte $78,$4E,$90,$FF,$D0,$3E,$E2,$FF         ; D3C3: 78 4E 90 FF D0 3E E2 FF
    .byte $0C,$10,$18,$39,$51,$40,$60,$54         ; D3CB: 0C 10 18 39 51 40 60 54
    .byte $80,$38,$89,$3A,$C0,$02,$D3,$42         ; D3D3: 80 38 89 3A C0 02 D3 42
    .byte $20,$1A,$36,$FF,$41,$FF,$60,$FF         ; D3DB: 20 1A 36 FF 41 FF 60 FF
    .byte $68,$3B,$A8,$FF,$B8,$4F,$F1,$3F         ; D3E3: 68 3B A8 FF B8 4F F1 3F
    .byte $11,$FF,$30,$3D,$48,$4F,$68,$39         ; D3EB: 11 FF 30 3D 48 4F 68 39
    .byte $A0,$55,$AA,$31,$C8,$0C,$D3,$42         ; D3F3: A0 55 AA 31 C8 0C D3 42
    .byte $30,$3D,$40,$56,$60,$1B,$6A,$3A         ; D3FB: 30 3D 40 56 60 1B 6A 3A
    .byte $91,$40,$B8,$50,$C8,$3B,$F3,$03         ; D403: 91 40 B8 50 C8 3B F3 03
    .byte $10,$FF,$20,$FF,$6B,$00,$8E,$01         ; D40B: 10 FF 20 FF 6B 00 8E 01
    .byte $91,$40,$A1,$19,$D2,$41,$E1,$FF         ; D413: 91 40 A1 19 D2 41 E1 FF
    .byte $0B,$16,$20,$02,$40,$FF,$51,$18         ; D41B: 0B 16 20 02 40 FF 51 18
    .byte $91,$40,$AE,$03,$D2,$41,$E3,$04         ; D423: 91 40 AE 03 D2 41 E3 04
    .byte $00,$1A,$12,$41,$43,$05,$56,$06         ; D42B: 00 1A 12 41 43 05 56 06
    .byte $83,$07,$91,$40,$A0,$1B,$F0,$FF         ; D433: 83 07 91 40 A0 1B F0 FF
    .byte $2B,$14,$38,$50,$71,$3F,$83,$00         ; D43B: 2B 14 38 50 71 3F 83 00
    .byte $93,$01,$A3,$02,$B3,$03,$B8,$55         ; D443: 93 01 A3 02 B3 03 B8 55
    .byte $11,$FF,$38,$50,$62,$04,$72,$05         ; D44B: 11 FF 38 50 62 04 72 05
    .byte $82,$06,$92,$07,$B8,$4E,$D3,$42         ; D453: 82 06 92 07 B8 4E D3 42
    .byte $21,$FF,$71,$3F,$78,$54,$82,$38         ; D45B: 21 FF 71 3F 78 54 82 38
    .byte $A8,$45,$C2,$18,$C8,$54,$F8,$FF         ; D463: A8 45 C2 18 C8 54 F8 FF
    .byte $12,$FF,$38,$4E,$51,$40,$6B,$00         ; D46B: 12 FF 38 4E 51 40 6B 00
    .byte $78,$54,$88,$45,$B8,$4E,$F0,$FF         ; D473: 78 54 88 45 B8 4E F0 FF
    .byte $38,$4F,$51,$40,$78,$4E,$88,$45         ; D47B: 38 4F 51 40 78 4E 88 45
    .byte $A8,$09,$B8,$54,$C0,$FF,$D0,$3E         ; D483: A8 09 B8 54 C0 FF D0 3E
    .byte $08,$56,$30,$3C,$42,$01,$60,$FF         ; D48B: 08 56 30 3C 42 01 60 FF
    .byte $82,$19,$90,$31,$B8,$FF,$C0,$38         ; D493: 82 19 90 31 B8 FF C0 38
    .byte $31,$40,$38,$54,$40,$38,$60,$56         ; D49B: 31 40 38 54 40 38 60 56
    .byte $8D,$02,$A8,$45,$D3,$42,$F8,$54         ; D4A3: 8D 02 A8 45 D3 42 F8 54
    .byte $11,$40,$21,$1A,$33,$42,$40,$55         ; D4AB: 11 40 21 1A 33 42 40 55
    .byte $52,$41,$88,$46,$B8,$4F,$F0,$54         ; D4B3: 52 41 88 46 B8 4F F0 54
    .byte $08,$54,$38,$4F,$48,$46,$78,$56         ; D4BB: 08 54 38 4F 48 46 78 56
    .byte $82,$13,$A8,$46,$D1,$1B,$F0,$FF         ; D4C3: 82 13 A8 46 D1 1B F0 FF
    .byte $20,$FF,$40,$FF,$53,$00,$72,$01         ; D4CB: 20 FF 40 FF 53 00 72 01
    .byte $91,$02,$C0,$03,$D0,$FF,$F0,$FF         ; D4D3: 91 02 C0 03 D0 FF F0 FF
    .byte $33,$04,$43,$05,$53,$06,$63,$07         ; D4DB: 33 04 43 05 53 06 63 07
    .byte $91,$3F,$A0,$FF,$C0,$38,$D0,$FF         ; D4E3: 91 3F A0 FF C0 38 D0 FF
    .byte $20,$FF,$30,$FF,$40,$FF,$60,$FF         ; D4EB: 20 FF 30 FF 40 FF 60 FF
    .byte $90,$FF,$B0,$3C,$D8,$FF,$E1,$4B         ; D4F3: 90 FF B0 3C D8 FF E1 4B
    .byte $18,$47,$20,$FF,$33,$FF,$48,$FF         ; D4FB: 18 47 20 FF 33 FF 48 FF
    .byte $50,$FF,$60,$FF,$90,$FF,$CB,$42         ; D503: 50 FF 60 FF 90 FF CB 42
    .byte $20,$FF,$30,$FF,$40,$FF,$90,$FF         ; D50B: 20 FF 30 FF 40 FF 90 FF
    .byte $70,$FF,$A0,$18,$C0,$FF,$D3,$42         ; D513: 70 FF A0 18 C0 FF D3 42
    .byte $0B,$05,$2A,$41,$30,$3E,$8A,$44         ; D51B: 0B 05 2A 41 30 3E 8A 44
    .byte $90,$FF,$B1,$40,$C2,$1C,$D3,$15         ; D523: 90 FF B1 40 C2 1C D3 15
    .byte $12,$41,$1B,$FF,$20,$1D,$51,$40         ; D52B: 12 41 1B FF 20 1D 51 40
    .byte $63,$06,$71,$44,$B0,$FF,$E7,$FF         ; D533: 63 06 71 44 B0 FF E7 FF
    .byte $20,$1E,$40,$44,$57,$07,$6A,$44         ; D53B: 20 1E 40 44 57 07 6A 44
    .byte $A0,$09,$A8,$44,$B2,$41,$D1,$40         ; D543: A0 09 A8 44 B2 41 D1 40
    .byte $10,$FF,$5A,$49,$76,$04,$78,$4E         ; D54B: 10 FF 5A 49 76 04 78 4E
    .byte $80,$1C,$A8,$4E,$D1,$3F,$E1,$4B         ; D553: 80 1C A8 4E D1 3F E1 4B
    .byte $10,$FF,$22,$38,$52,$41,$62,$FF         ; D55B: 10 FF 22 38 52 41 62 FF
    .byte $80,$FF,$A0,$FF,$C0,$FF,$E0,$FF         ; D563: 80 FF A0 FF C0 FF E0 FF
    .byte $28,$47,$4E,$05,$51,$3F,$60,$FF         ; D56B: 28 47 4E 05 51 3F 60 FF
    .byte $80,$1D,$A0,$FF,$C0,$FF,$E0,$FF         ; D573: 80 1D A0 FF C0 FF E0 FF
    .byte $11,$40,$38,$4E,$58,$4E,$72,$41         ; D57B: 11 40 38 4E 58 4E 72 41
    .byte $78,$4E,$A2,$1E,$C8,$06,$E2,$4C         ; D583: 78 4E A2 1E C8 06 E2 4C
    .byte $00,$1F,$32,$41,$47,$07,$62,$4C         ; D58B: 00 1F 32 41 47 07 62 4C
    .byte $78,$4E,$B1,$40,$D0,$4A,$E3,$FF         ; D593: 78 4E B1 40 D0 4A E3 FF
    .byte $19,$40,$20,$FF,$40,$FF,$60,$FF         ; D59B: 19 40 20 FF 40 FF 60 FF
    .byte $80,$FF,$90,$FF,$A0,$38,$F3,$FF         ; D5A3: 80 FF 90 FF A0 38 F3 FF
    .byte $10,$FF,$37,$0A,$78,$FF,$92,$41         ; D5AB: 10 FF 37 0A 78 FF 92 41
    .byte $A2,$4C,$A8,$4E,$B8,$4E,$D8,$4E         ; D5B3: A2 4C A8 4E B8 4E D8 4E
    .byte $2B,$06,$33,$FF,$41,$39,$71,$3F         ; D5BB: 2B 06 33 FF 41 39 71 3F
    .byte $78,$4E,$82,$1C,$90,$54,$E2,$FF         ; D5C3: 78 4E 82 1C 90 54 E2 FF
    .byte $10,$FF,$33,$FF,$51,$40,$6B,$07         ; D5CB: 10 FF 33 FF 51 40 6B 07
    .byte $89,$3A,$B8,$4E,$C7,$FF,$F8,$4F         ; D5D3: 89 3A B8 4E C7 FF F8 4F
    .byte $08,$4E,$33,$FF,$70,$3A,$80,$38         ; D5DB: 08 4E 33 FF 70 3A 80 38
    .byte $89,$3A,$A8,$4E,$B1,$40,$D2,$41         ; D5E3: 89 3A A8 4E B1 40 D2 41
    .byte $08,$4F,$33,$FF,$50,$39,$71,$FF         ; D5EB: 08 4F 33 FF 50 39 71 FF
    .byte $78,$55,$90,$FF,$B8,$4E,$C0,$1D         ; D5F3: 78 55 90 FF B8 4E C0 1D
    .byte $31,$0D,$50,$56,$60,$FF,$78,$4F         ; D5FB: 31 0D 50 56 60 FF 78 4F
    .byte $80,$FF,$A8,$56,$C1,$1E,$E0,$55         ; D603: 80 FF A8 56 C1 1E E0 55
    .byte $08,$FF,$18,$55,$40,$FF,$78,$55         ; D60B: 08 FF 18 55 40 FF 78 55
    .byte $83,$04,$B0,$FF,$D0,$55,$E0,$FF         ; D613: 83 04 B0 FF D0 55 E0 FF
    .byte $10,$FF,$30,$39,$50,$56,$60,$38         ; D61B: 10 FF 30 39 50 56 60 38
    .byte $77,$05,$91,$40,$B2,$41,$C2,$1F         ; D623: 77 05 91 40 B2 41 C2 1F
    .byte $08,$55,$38,$4F,$4A,$55,$6B,$03         ; D62B: 08 55 38 4F 4A 55 6B 03
    .byte $70,$1C,$91,$3F,$C0,$FF,$E0,$FF         ; D633: 70 1C 91 3F C0 FF E0 FF
    .byte $10,$FF,$28,$56,$38,$50,$60,$FF         ; D63B: 10 FF 28 56 38 50 60 FF
    .byte $82,$38,$A0,$04,$D2,$59,$E0,$FF         ; D643: 82 38 A0 04 D2 59 E0 FF
    .byte $10,$FF,$38,$4F,$48,$55,$60,$FF         ; D64B: 10 FF 38 4F 48 55 60 FF
    .byte $88,$45,$A0,$05,$C8,$55,$E0,$FF         ; D653: 88 45 A0 05 C8 55 E0 FF
    .byte $21,$1D,$40,$FF,$58,$55,$71,$3F         ; D65B: 21 1D 40 FF 58 55 71 3F
    .byte $80,$FF,$A8,$45,$C0,$FF,$C8,$54         ; D663: 80 FF A8 45 C0 FF C8 54
    .byte $31,$40,$38,$54,$40,$38,$78,$54         ; D66B: 31 40 38 54 40 38 78 54
    .byte $8F,$FF,$A8,$45,$D7,$0D,$E0,$FF         ; D673: 8F FF A8 45 D7 0D E0 FF
    .byte $38,$4F,$51,$40,$68,$54,$88,$45         ; D67B: 38 4F 51 40 68 54 88 45
    .byte $A0,$1E,$B0,$FF,$BB,$FF,$D0,$FF         ; D683: A0 1E B0 FF BB FF D0 FF
    .byte $10,$FF,$28,$55,$38,$4F,$60,$FF         ; D68B: 10 FF 28 55 38 4F 60 FF
    .byte $88,$45,$A8,$06,$C3,$FF,$F8,$55         ; D693: 88 45 A8 06 C3 FF F8 55
    .byte $18,$55,$28,$56,$38,$50,$48,$4F         ; D69B: 18 55 28 56 38 50 48 4F
    .byte $87,$07,$A0,$FF,$CA,$59,$E0,$FF         ; D6A3: 87 07 A0 FF CA 59 E0 FF
    .byte $10,$FF,$38,$55,$48,$4F,$52,$59         ; D6AB: 10 FF 38 55 48 4F 52 59
    .byte $62,$1F,$91,$3F,$C0,$FF,$C8,$56         ; D6B3: 62 1F 91 3F C0 FF C8 56
LayoutPageTab:
    .byte $24,$24,$24,$24,$24,$24,$24,$24         ; D6BB: 24 24 24 24 24 24 24 24
    .byte $24,$24,$24,$24,$3A,$07,$24,$24         ; D6C3: 24 24 24 24 3A 07 24 24
    .byte $08,$24,$24,$24,$3A,$03,$05,$06         ; D6CB: 08 24 24 24 3A 03 05 06
    .byte $24,$17,$16,$24,$24,$24,$24,$24         ; D6D3: 24 17 16 24 24 24 24 24
    .byte $24,$24,$24,$18,$0C,$0D,$24,$24         ; D6DB: 24 24 24 18 0C 0D 24 24
    .byte $24,$24,$24,$24,$24,$09,$0A,$0B         ; D6E3: 24 24 24 24 24 09 0A 0B
    .byte $0E,$24,$24,$1E,$1D,$24,$24,$12         ; D6EB: 0E 24 24 1E 1D 24 24 12
    .byte $11,$10,$0F,$24,$24,$24,$1C,$1B         ; D6F3: 11 10 0F 24 24 24 1C 1B
    .byte $1A,$19,$24,$14,$13,$24,$24,$24         ; D6FB: 1A 19 24 14 13 24 24 24
    .byte $20,$1F,$24,$24,$24,$15,$24,$24         ; D703: 20 1F 24 24 24 15 24 24
    .byte $24,$24,$24,$2C,$2D,$2B,$2A,$29         ; D70B: 24 24 24 2C 2D 2B 2A 29
    .byte $24,$24,$24,$24,$24,$28,$27,$26         ; D713: 24 24 24 24 24 28 27 26
    .byte $25,$21,$22,$23,$24,$24,$24,$24         ; D71B: 25 21 22 23 24 24 24 24
    .byte $24,$24,$00,$01,$02,$24,$24,$24         ; D723: 24 24 00 01 02 24 24 24
    .byte $3A,$03,$04,$05,$06,$24,$24,$24         ; D72B: 3A 03 04 05 06 24 24 24
    .byte $24,$24,$24,$24,$24,$24,$24,$24         ; D733: 24 24 24 24 24 24 24 24
    .byte $24,$24,$24,$24,$24,$24,$24,$24         ; D73B: 24 24 24 24 24 24 24 24
    .byte $12,$0A,$10,$0E,$24,$24,$24,$24         ; D743: 12 0A 10 0E 24 24 24 24
    .byte $33,$32,$31,$30,$24,$24,$1C,$1B         ; D74B: 33 32 31 30 24 24 1C 1B
    .byte $1A,$19,$24,$24,$24,$24,$24,$24         ; D753: 1A 19 24 24 24 24 24 24
    .byte $39,$31,$31,$38,$24,$24,$24,$24         ; D75B: 39 31 31 38 24 24 24 24
    .byte $24,$24,$24,$24,$24,$24,$24,$24         ; D763: 24 24 24 24 24 24 24 24
    .byte $24,$24,$24,$24,$24,$24,$24,$24         ; D76B: 24 24 24 24 24 24 24 24
    .byte $24,$2B,$27,$36,$35,$34,$24,$37         ; D773: 24 2B 27 36 35 34 24 37
    .byte $36,$35,$34,$24,$2E,$2F,$24,$24         ; D77B: 36 35 34 24 2E 2F 24 24
ScrollLockRtTab:
    .byte $0D,$10,$17,$1A,$23,$25,$30,$34         ; D783: 0D 10 17 1A 23 25 30 34
    .byte $3A,$41,$44,$49,$4D,$54,$58,$60         ; D78B: 3A 41 44 49 4D 54 58 60
    .byte $63,$6C,$74,$8B,$93,$99,$A3,$BD         ; D793: 63 6C 74 8B 93 99 A3 BD
    .byte $C2,$C5,$FF                             ; D79B: C2 C5 FF
ScrollLockLtTab:
    .byte $0D,$10,$15,$19,$23,$24,$2D,$33         ; D79E: 0D 10 15 19 23 24 2D 33
    .byte $37,$3E,$43,$48,$4D,$53,$55,$5D         ; D7A6: 37 3E 43 48 4D 53 55 5D
    .byte $61,$6A,$71,$88,$90,$96,$A0,$B9         ; D7AE: 61 6A 71 88 90 96 A0 B9
    .byte $BF,$C4,$FF                             ; D7B6: BF C4 FF
AltQuadRangeTab:
    .byte $14,$19,$6A,$6D,$6F,$75,$0C,$11         ; D7B9: 14 19 6A 6D 6F 75 0C 11
    .byte $55,$58,$5D,$61,$BF,$C3,$B9,$BE         ; D7C1: 55 58 5D 61 BF C3 B9 BE
    .byte $61,$64,$FF                             ; D7C9: 61 64 FF
StageAreaMapTab:
    .byte $00,$00,$FE,$6A,$6D,$FE,$0D,$11         ; D7CC: 00 00 FE 6A 6D FE 0D 11
    .byte $15,$18,$71,$75,$FE,$19,$1B,$23         ; D7D4: 15 18 71 75 FE 19 1B 23
    .byte $24,$FE,$24,$27,$2D,$31,$37,$3C         ; D7DC: 24 FE 24 27 2D 31 37 3C
    .byte $43,$45,$4D,$4E,$88,$8C,$90,$94         ; D7E4: 43 45 4D 4E 88 8C 90 94
    .byte $FE,$33,$35,$3E,$42,$48,$4A,$96         ; D7EC: FE 33 35 3E 42 48 4A 96
    .byte $9A,$A0,$A4,$FE,$53,$55,$FE,$55         ; D7F4: 9A A0 A4 FE 53 55 FE 55
    .byte $58,$5D,$61,$B9,$BE,$BF,$C3,$FE         ; D7FC: 58 5D 61 B9 BE BF C3 FE
    .byte $C4,$C6,$FE,$61,$64,$FE,$FF             ; D804: C4 C6 FE 61 64 FE FF
StageNameStrTab:
    .byte $0E,$0E,$0E,$0E,$13,$0F,$11,$14         ; D80B: 0E 0E 0E 0E 13 0F 11 14
    .byte $10,$12,$11,$14,$11,$14,$11,$14         ; D813: 10 12 11 14 11 14 11 14
    .byte $11,$14,$11,$11                         ; D81B: 11 14 11 11
QuadBaseDef:
    .byte $21,$D8                                 ; D81F: 21 D8
QuadRecDef:
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; D821: 00 00 00 00 00 00 00 00
    .byte $00,$00,$00,$00,$68,$1D,$68,$BB         ; D829: 00 00 00 00 68 1D 68 BB
    .byte $68,$68,$70,$70,$12,$0B,$8F,$30         ; D831: 68 68 70 70 12 0B 8F 30
    .byte $B6,$B5,$B4,$B3,$30,$7B,$B2,$7B         ; D839: B6 B5 B4 B3 30 7B B2 7B
    .byte $BD,$8E,$69,$72,$30,$30,$30,$E1         ; D841: BD 8E 69 72 30 30 30 E1
    .byte $30,$30,$E2,$30,$8D,$8F,$D8,$D8         ; D849: 30 30 E2 30 8D 8F D8 D8
    .byte $30,$30,$D8,$D8,$30,$30,$7A,$A1         ; D851: 30 30 D8 D8 30 30 7A A1
    .byte $79,$68,$68,$68,$94,$96,$30,$30         ; D859: 79 68 68 68 94 96 30 30
    .byte $30,$30,$30,$82,$72,$68,$B0,$70         ; D861: 30 30 30 82 72 68 B0 70
    .byte $68,$68,$A0,$30,$68,$68,$9C,$91         ; D869: 68 68 A0 30 68 68 9C 91
    .byte $69,$69,$69,$69,$69,$6D,$6A,$6E         ; D871: 69 69 69 69 69 6D 6A 6E
    .byte $6B,$68,$6C,$6F,$12,$13,$69,$72         ; D879: 6B 68 6C 6F 12 13 69 72
    .byte $71,$73,$6E,$6E,$68,$68,$6F,$6F         ; D881: 71 73 6E 6E 68 68 6F 6F
    .byte $14,$0A,$74,$68,$75,$79,$76,$7A         ; D889: 14 0A 74 68 75 79 76 7A
    .byte $77,$7B,$78,$7C,$0A,$11,$68,$68         ; D891: 77 7B 78 7C 0A 11 68 68
    .byte $68,$7E,$7D,$7D,$11,$11,$68,$68         ; D899: 68 7E 7D 7D 11 11 68 68
    .byte $7F,$7F,$80,$6E,$6B,$68,$6B,$68         ; D8A1: 7F 7F 80 6E 6B 68 6B 68
    .byte $7F,$7F,$81,$68,$68,$68,$68,$68         ; D8A9: 7F 7F 81 68 68 68 68 68
    .byte $7F,$7F,$82,$6E,$10,$1D,$83,$7B         ; D8B1: 7F 7F 82 6E 10 1D 83 7B
    .byte $84,$85,$6E,$6E,$71,$73,$6E,$86         ; D8B9: 84 85 6E 6E 71 73 6E 86
    .byte $0E,$11,$74,$68,$68,$68,$68,$82         ; D8C1: 0E 11 74 68 68 68 68 82
    .byte $68,$68,$68,$87,$11,$0F,$68,$74         ; D8C9: 68 68 68 87 11 0F 68 74
    .byte $68,$75,$6E,$6E,$7F,$7F,$76,$7A         ; D8D1: 68 75 6E 6E 7F 7F 76 7A
    .byte $0B,$0B,$6B,$68,$6B,$68,$88,$6E         ; D8D9: 0B 0B 6B 68 6B 68 88 6E
    .byte $89,$68,$8A,$90,$0B,$0C,$68,$68         ; D8E1: 89 68 8A 90 0B 0C 68 68
    .byte $68,$68,$6E,$7A,$68,$8C,$90,$90         ; D8E9: 68 68 6E 7A 68 8C 90 90
    .byte $68,$68,$A1,$8E,$8D,$8F,$90,$90         ; D8F1: 68 68 A1 8E 8D 8F 90 90
    .byte $68,$68,$68,$7A,$68,$7B,$91,$7B         ; D8F9: 68 68 68 7A 68 7B 91 7B
    .byte $0B,$0B,$92,$68,$93,$8B,$7D,$8E         ; D901: 0B 0B 92 68 93 8B 7D 8E
    .byte $69,$72,$69,$72,$7E,$7F,$68,$82         ; D909: 69 72 69 72 7E 7F 68 82
    .byte $68,$68,$90,$90,$94,$95,$6E,$6E         ; D911: 68 68 90 90 94 95 6E 6E
    .byte $0B,$0D,$68,$97,$96,$97,$6E,$98         ; D919: 0B 0D 68 97 96 97 6E 98
    .byte $68,$9F,$9C,$9A,$7F,$7F,$7D,$8E         ; D921: 68 9F 9C 9A 7F 7F 7D 8E
    .byte $68,$68,$68,$87,$68,$68,$6F,$A0         ; D929: 68 68 68 87 68 68 6F A0
    .byte $68,$9F,$91,$F3,$68,$7E,$7D,$7D         ; D931: 68 9F 91 F3 68 7E 7D 7D
    .byte $0A,$0C,$68,$68,$7F,$7F,$80,$6E         ; D939: 0A 0C 68 68 7F 7F 80 6E
    .byte $94,$96,$81,$68,$0A,$0D,$68,$9F         ; D941: 94 96 81 68 0A 0D 68 9F
    .byte $68,$9F,$68,$9B,$7F,$7F,$6E,$6E         ; D949: 68 9F 68 9B 7F 7F 6E 6E
    .byte $68,$68,$68,$87,$7F,$7F,$6E,$76         ; D951: 68 68 68 87 7F 7F 6E 76
    .byte $68,$77,$6F,$78,$7F,$7F,$7A,$7D         ; D959: 68 77 6F 78 7F 7F 7A 7D
    .byte $7B,$69,$7C,$69,$0B,$0B,$83,$68         ; D961: 7B 69 7C 69 0B 0B 83 68
    .byte $84,$68,$7D,$7D,$8A,$68,$68,$68         ; D969: 84 68 7D 7D 8A 68 68 68
    .byte $7F,$79,$7D,$7D,$68,$7E,$80,$6E         ; D971: 7F 79 7D 7D 68 7E 80 6E
    .byte $6B,$68,$6B,$9C,$79,$68,$81,$68         ; D979: 6B 68 6B 9C 79 68 81 68
    .byte $12,$0B,$72,$30,$7E,$7F,$82,$6E         ; D981: 12 0B 72 30 7E 7F 82 6E
    .byte $68,$68,$91,$68,$6B,$68,$9D,$90         ; D989: 68 68 91 68 6B 68 9D 90
    .byte $95,$96,$6E,$6E,$68,$30,$87,$70         ; D991: 95 96 6E 6E 68 30 87 70
    .byte $69,$95,$6A,$6E,$68,$7B,$6F,$7C         ; D999: 69 95 6A 6E 68 7B 6F 7C
    .byte $12,$12,$69,$69,$0A,$0A,$68,$68         ; D9A1: 12 12 69 69 0A 0A 68 68
    .byte $68,$68,$90,$99,$13,$0A,$72,$30         ; D9A9: 68 68 90 99 13 0A 72 30
    .byte $69,$A2,$69,$69,$C3,$30,$A1,$8E         ; D9B1: 69 A2 69 69 C3 30 A1 8E
    .byte $0C,$0B,$30,$30,$A2,$A3,$69,$69         ; D9B9: 0C 0B 30 30 A2 A3 69 69
    .byte $30,$30,$30,$BA,$0B,$12,$30,$8D         ; D9C1: 30 30 30 BA 0B 12 30 8D
    .byte $8E,$30,$A5,$A4,$8D,$8D,$70,$70         ; D9C9: 8E 30 A5 A4 8D 8D 70 70
    .byte $6D,$6D,$A1,$A1,$6D,$6D,$8E,$30         ; D9D1: 6D 6D A1 A1 6D 6D 8E 30
    .byte $8F,$30,$70,$70,$12,$12,$69,$8F         ; D9D9: 8F 30 70 70 12 12 69 8F
    .byte $6D,$30,$A8,$A9,$AB,$8D,$70,$70         ; D9E1: 6D 30 A8 A9 AB 8D 70 70
    .byte $0B,$0C,$30,$30,$7A,$B1,$AA,$69         ; D9E9: 0B 0C 30 30 7A B1 AA 69
    .byte $0B,$12,$30,$7B,$A2,$A7,$69,$69         ; D9F1: 0B 12 30 7B A2 A7 69 69
    .byte $8D,$AC,$AD,$AE,$72,$6D,$B0,$AD         ; D9F9: 8D AC AD AE 72 6D B0 AD
    .byte $6D,$6D,$30,$7A,$30,$7B,$70,$7C         ; DA01: 6D 6D 30 7A 30 7B 70 7C
    .byte $0A,$1D,$30,$7B,$30,$7B,$A1,$AF         ; DA09: 0A 1D 30 7B 30 7B A1 AF
    .byte $73,$30,$7A,$A9,$7B,$69,$7C,$69         ; DA11: 73 30 7A A9 7B 69 7C 69
    .byte $72,$30,$72,$A1,$1D,$12,$7B,$69         ; DA19: 72 30 72 A1 1D 12 7B 69
    .byte $85,$6D,$A1,$A1,$6D,$71,$A1,$A1         ; DA21: 85 6D A1 A1 6D 71 A1 A1
    .byte $69,$72,$69,$B0,$6D,$7B,$30,$7B         ; DA29: 69 72 69 B0 6D 7B 30 7B
    .byte $30,$7B,$AD,$AF,$17,$0A,$30,$30         ; DA31: 30 7B AD AF 17 0A 30 30
    .byte $30,$30,$B2,$30,$30,$30,$70,$70         ; DA39: 30 30 B2 30 30 30 70 70
    .byte $30,$30,$7A,$A9,$30,$30,$70,$70         ; DA41: 30 30 7A A9 30 30 70 70
    .byte $30,$B7,$8E,$30,$B6,$B6,$30,$B4         ; DA49: 30 B7 8E 30 B6 B6 30 B4
    .byte $B6,$B5,$B3,$B3,$B6,$B6,$B9,$A4         ; DA51: B6 B5 B3 B3 B6 B6 B9 A4
    .byte $B6,$B6,$A1,$D7,$B6,$B8,$30,$BA         ; DA59: B6 B6 A1 D7 B6 B8 30 BA
    .byte $30,$7A,$B9,$AA,$BC,$8D,$B0,$AD         ; DA61: 30 7A B9 AA BC 8D B0 AD
    .byte $8D,$8F,$70,$70,$30,$BB,$70,$70         ; DA69: 8D 8F 70 70 30 BB 70 70
    .byte $12,$12,$69,$72,$0A,$18,$30,$30         ; DA71: 12 12 69 72 0A 18 30 30
    .byte $72,$73,$BD,$A1,$30,$B7,$F2,$30         ; DA79: 72 73 BD A1 30 B7 F2 30
    .byte $B8,$30,$30,$BA,$B7,$B6,$B9,$B9         ; DA81: B8 30 30 BA B7 B6 B9 B9
    .byte $30,$7B,$70,$7C,$B5,$30,$7A,$A1         ; DA89: 30 7B 70 7C B5 30 7A A1
    .byte $B7,$B6,$A1,$8E,$B6,$BE,$30,$7B         ; DA91: B7 B6 A1 8E B6 BE 30 7B
    .byte $BB,$8D,$70,$70,$8D,$BF,$AD,$AE         ; DA99: BB 8D 70 70 8D BF AD AE
    .byte $69,$C2,$72,$6D,$8E,$30,$73,$30         ; DAA1: 69 C2 72 6D 8E 30 73 30
    .byte $30,$30,$C0,$A1,$30,$B7,$8E,$30         ; DAA9: 30 30 C0 A1 30 B7 8E 30
    .byte $A6,$70,$69,$69,$C1,$30,$B0,$70         ; DAB1: A6 70 69 69 C1 30 B0 70
    .byte $BB,$8D,$70,$70,$C3,$30,$A1,$A1         ; DAB9: BB 8D 70 70 C3 30 A1 A1
    .byte $30,$30,$A1,$A1,$30,$7A,$A9,$AA         ; DAC1: 30 30 A1 A1 30 7A A9 AA
    .byte $B1,$A7,$69,$69,$6D,$7B,$AD,$AE         ; DAC9: B1 A7 69 69 6D 7B AD AE
    .byte $72,$30,$BD,$8E,$69,$72,$72,$73         ; DAD1: 72 30 BD 8E 69 72 72 73
    .byte $30,$B7,$30,$30,$B6,$B5,$7A,$8E         ; DAD9: 30 B7 30 30 B6 B5 7A 8E
    .byte $30,$C6,$30,$7A,$69,$B0,$69,$69         ; DAE1: 30 C6 30 7A 69 B0 69 69
    .byte $C4,$30,$C5,$70,$BB,$8F,$70,$70         ; DAE9: C4 30 C5 70 BB 8F 70 70
    .byte $30,$BB,$70,$70,$8F,$6D,$70,$70         ; DAF1: 30 BB 70 70 8F 6D 70 70
    .byte $72,$30,$B0,$70,$A2,$E9,$69,$72         ; DAF9: 72 30 B0 70 A2 E9 69 72
    .byte $30,$30,$A1,$F2,$30,$EA,$30,$7B         ; DB01: 30 30 A1 F2 30 EA 30 7B
    .byte $E8,$E8,$E8,$E8,$30,$30,$30,$EB         ; DB09: E8 E8 E8 E8 30 30 30 EB
    .byte $17,$0A,$E8,$E8,$12,$12,$8D,$8D         ; DB11: 17 0A E8 E8 12 12 8D 8D
    .byte $0B,$0D,$68,$9F,$68,$94,$80,$6E         ; DB19: 0B 0D 68 9F 68 94 80 6E
    .byte $96,$7F,$81,$68,$79,$9F,$68,$9B         ; DB21: 96 7F 81 68 79 9F 68 9B
    .byte $68,$68,$68,$A8,$68,$68,$8E,$68         ; DB29: 68 68 68 A8 68 68 8E 68
    .byte $68,$68,$A8,$A1,$68,$2F,$68,$2F         ; DB31: 68 68 A8 A1 68 2F 68 2F
    .byte $72,$68,$72,$68,$2F,$69,$2F,$69         ; DB39: 72 68 72 68 2F 69 2F 69
    .byte $30,$30,$30,$30,$68,$68,$6E,$6E         ; DB41: 30 30 30 30 68 68 6E 6E
    .byte $68,$68,$6E,$76,$68,$68,$7A,$A1         ; DB49: 68 68 6E 76 68 68 7A A1
    .byte $12,$14,$72,$74,$0A,$0A,$30,$30         ; DB51: 12 14 72 74 0A 0A 30 30
    .byte $0A,$1D,$30,$8C,$72,$75,$72,$30         ; DB59: 0A 1D 30 8C 72 75 72 30
QuadBaseAlt:
    .byte $63,$DB                                 ; DB61: 63 DB
QuadRecAlt:
    .byte $17,$0A,$30,$30,$18,$0C,$30,$30         ; DB63: 17 0A 30 30 18 0C 30 30
    .byte $0B,$0C,$30,$30,$0B,$12,$30,$7B         ; DB6B: 0B 0C 30 30 0B 12 30 7B
    .byte $30,$30,$B2,$30,$30,$7A,$BA,$AA         ; DB73: 30 30 B2 30 30 7A BA AA
    .byte $B1,$A2,$69,$69,$A2,$A7,$69,$69         ; DB7B: B1 A2 69 69 A2 A7 69 69
    .byte $30,$30,$D8,$D9,$85,$6D,$70,$70         ; DB83: 30 30 D8 D9 85 6D 70 70
    .byte $6D,$7B,$70,$7C,$69,$69,$69,$69         ; DB8B: 6D 7B 70 7C 69 69 69 69
    .byte $1C,$0C,$DA,$30,$0A,$18,$30,$30         ; DB93: 1C 0C DA 30 0A 18 30 30
    .byte $8E,$30,$A5,$A4,$B7,$B8,$A1,$D7         ; DB9B: 8E 30 A5 A4 B7 B8 A1 D7
    .byte $DB,$B7,$DC,$B4,$B6,$B5,$B3,$B3         ; DBA3: DB B7 DC B4 B6 B5 B3 B3
    .byte $8D,$8D,$D8,$D8,$8D,$8F,$D8,$D8         ; DBAB: 8D 8D D8 D8 8D 8F D8 D8
    .byte $DC,$30,$D8,$D8,$30,$DC,$D8,$D8         ; DBB3: DC 30 D8 D8 30 DC D8 D8
    .byte $B6,$B6,$B9,$A4,$B6,$B8,$A1,$D7         ; DBBB: B6 B6 B9 A4 B6 B8 A1 D7
    .byte $DB,$DE,$DC,$7A,$30,$7A,$A9,$AA         ; DBC3: DB DE DC 7A 30 7A A9 AA
    .byte $BC,$8D,$DD,$D8,$DC,$BB,$D8,$D8         ; DBCB: BC 8D DD D8 DC BB D8 D8
    .byte $12,$12,$69,$72,$0B,$1C,$30,$DA         ; DBD3: 12 12 69 72 0B 1C 30 DA
    .byte $72,$73,$BD,$A1,$30,$B7,$8E,$30         ; DBDB: 72 73 BD A1 30 B7 8E 30
    .byte $B8,$DB,$30,$DC,$B7,$B6,$30,$BA         ; DBE3: B8 DB 30 DC B7 B6 30 BA
    .byte $8F,$30,$D8,$D9,$30,$DC,$DF,$D8         ; DBEB: 8F 30 D8 D9 30 DC DF D8
    .byte $30,$7B,$D9,$7C,$C2,$8E,$69,$72         ; DBF3: 30 7B D9 7C C2 8E 69 72
    .byte $DC,$30,$DC,$E1,$30,$DC,$E2,$DC         ; DBFB: DC 30 DC E1 30 DC E2 DC
    .byte $30,$30,$7A,$A1,$7B,$69,$E0,$69         ; DC03: 30 30 7A A1 7B 69 E0 69
    .byte $B6,$B5,$A1,$A1,$30,$30,$B3,$B2         ; DC0B: B6 B5 A1 A1 30 30 B3 B2
    .byte $DC,$30,$DC,$BA,$7A,$B1,$AA,$69         ; DC13: DC 30 DC BA 7A B1 AA 69
    .byte $BC,$8F,$B0,$AD,$30,$30,$70,$DF         ; DC1B: BC 8F B0 AD 30 30 70 DF
    .byte $12,$0C,$72,$30,$E3,$B6,$BD,$8E         ; DC23: 12 0C 72 30 E3 B6 BD 8E
    .byte $B6,$B6,$30,$30,$B8,$DB,$30,$DC         ; DC2B: B6 B6 30 30 B8 DB 30 DC
    .byte $DB,$B7,$30,$7A,$69,$B0,$E4,$E4         ; DC33: DB B7 30 7A 69 B0 E4 E4
    .byte $C1,$30,$E5,$D8,$30,$DC,$E6,$D8         ; DC3B: C1 30 E5 D8 30 DC E6 D8
    .byte $30,$7B,$E7,$AE,$12,$12,$69,$69         ; DC43: 30 7B E7 AE 12 12 69 69
    .byte $0A,$0A,$30,$C7,$30,$C8,$30,$C9         ; DC4B: 0A 0A 30 C7 30 C8 30 C9
    .byte $30,$30,$D8,$D8,$0A,$0A,$C7,$C7         ; DC53: 30 30 D8 D8 0A 0A C7 C7
    .byte $CA,$CD,$CB,$D3,$CC,$CE,$D8,$CF         ; DC5B: CA CD CB D3 CC CE D8 CF
    .byte $0A,$0A,$30,$30,$CD,$D1,$D3,$D3         ; DC63: 0A 0A 30 30 CD D1 D3 D3
    .byte $30,$30,$D0,$D2,$0A,$1E,$30,$D4         ; DC6B: 30 30 D0 D2 0A 1E 30 D4
    .byte $30,$D5,$D3,$D6,$30,$30,$EC,$EC         ; DC73: 30 D5 D3 D6 30 30 EC EC
    .byte $0A,$0A,$30,$30,$CD,$F1,$EF,$D6         ; DC7B: 0A 0A 30 30 CD F1 EF D6
    .byte $30,$30,$2C,$2D,$CD,$CD,$D3,$D3         ; DC83: 30 30 2C 2D CD CD D3 D3
    .byte $30,$22,$EC,$23,$CD,$CD,$D3,$EE         ; DC8B: 30 22 EC 23 CD CD D3 EE
    .byte $0A,$1F,$24,$25,$CD,$CD,$30,$EF         ; DC93: 0A 1F 24 25 CD CD 30 EF
    .byte $20,$20,$30,$30,$CD,$D5,$D3,$28         ; DC9B: 20 20 30 30 CD D5 D3 28
    .byte $26,$29,$27,$D8,$21,$0A,$2A,$30         ; DCA3: 26 29 27 D8 21 0A 2A 30
    .byte $2B,$30,$2E,$30,$ED,$CD,$EE,$30         ; DCAB: 2B 30 2E 30 ED CD EE 30
    .byte $30,$B7,$A1,$8E,$B6,$B5,$30,$30         ; DCB3: 30 B7 A1 8E B6 B5 30 30
    .byte $30,$7B,$30,$7B,$6D,$6D,$70,$DF         ; DCBB: 30 7B 30 7B 6D 6D 70 DF
    .byte $6D,$6D,$D8,$D9,$30,$30,$DF,$D8         ; DCC3: 6D 6D D8 D9 30 30 DF D8
    .byte $A2,$C2,$69,$69,$30,$30,$A1,$A1         ; DCCB: A2 C2 69 69 30 30 A1 A1
    .byte $DE,$7A,$30,$7B,$00,$00,$00,$00         ; DCD3: DE 7A 30 7B 00 00 00 00
    .byte $00,$00,$00,$00,$30,$30,$30,$EB         ; DCDB: 00 00 00 00 30 30 30 EB
    .byte $00,$01,$31,$36,$32,$37,$33,$38         ; DCE3: 00 01 31 36 32 37 33 38
    .byte $34,$39,$35,$3A,$02,$02,$3B,$3B         ; DCEB: 34 39 35 3A 02 02 3B 3B
    .byte $3C,$3C,$3D,$3D,$30,$30,$64,$64         ; DCF3: 3C 3C 3D 3D 30 30 64 64
    .byte $02,$02,$3B,$3B,$3C,$3B,$3D,$3D         ; DCFB: 02 02 3B 3B 3C 3B 3D 3D
    .byte $3C,$3F,$3D,$40,$41,$41,$64,$64         ; DD03: 3C 3F 3D 40 41 41 64 64
    .byte $02,$02,$67,$42,$3C,$3B,$3D,$3D         ; DD0B: 02 02 67 42 3C 3B 3D 3D
    .byte $41,$30,$64,$64,$30,$30,$64,$64         ; DD13: 41 30 64 64 30 30 64 64
    .byte $02,$02,$42,$42,$3B,$3B,$3D,$3B         ; DD1B: 02 02 42 42 3B 3B 3D 3B
    .byte $3B,$3B,$3D,$3D,$43,$43,$44,$44         ; DD23: 3B 3B 3D 3D 43 43 44 44
    .byte $3B,$65,$3D,$40,$02,$02,$42,$3B         ; DD2B: 3B 65 3D 40 02 02 42 3B
    .byte $3B,$3B,$3D,$3B,$45,$45,$64,$64         ; DD33: 3B 3B 3D 3B 45 45 64 64
    .byte $45,$30,$64,$64,$02,$04,$3B,$46         ; DD3B: 45 30 64 64 02 04 3B 46
    .byte $3C,$47,$3D,$48,$30,$49,$64,$4A         ; DD43: 3C 47 3D 48 30 49 64 4A
    .byte $05,$06,$4B,$30,$4C,$4C,$4C,$4C         ; DD4B: 05 06 4B 30 4C 4C 4C 4C
    .byte $4D,$30,$4E,$63,$06,$06,$30,$30         ; DD53: 4D 30 4E 63 06 06 30 30
    .byte $50,$30,$4C,$51,$30,$30,$63,$63         ; DD5B: 50 30 4C 51 30 30 63 63
    .byte $30,$53,$52,$52,$53,$30,$52,$52         ; DD63: 30 53 52 52 53 30 52 52
    .byte $54,$54,$63,$63,$50,$30,$4C,$30         ; DD6B: 54 54 63 63 50 30 4C 30
    .byte $55,$30,$63,$63,$07,$08,$56,$4C         ; DD73: 55 30 63 63 07 08 56 4C
    .byte $30,$53,$57,$57,$4C,$4D,$58,$4E         ; DD7B: 30 53 57 57 4C 4D 58 4E
    .byte $08,$08,$4C,$4C,$53,$53,$57,$52         ; DD83: 08 08 4C 4C 53 53 57 52
    .byte $53,$53,$63,$63,$53,$53,$52,$30         ; DD8B: 53 53 63 63 53 53 52 30
    .byte $53,$53,$52,$52,$30,$30,$30,$57         ; DD93: 53 53 52 52 30 30 30 57
    .byte $02,$02,$42,$66,$52,$4C,$4C,$59         ; DD9B: 02 02 42 66 52 4C 4C 59
    .byte $53,$5A,$63,$63,$55,$55,$52,$52         ; DDA3: 53 5A 63 63 55 55 52 52
    .byte $54,$30,$63,$63,$5B,$5D,$5C,$5E         ; DDAB: 54 30 63 63 5B 5D 5C 5E
    .byte $30,$53,$57,$52,$06,$09,$30,$5F         ; DDB3: 30 53 57 52 06 09 30 5F
    .byte $53,$60,$52,$61,$30,$5F,$63,$62         ; DDBB: 53 60 52 61 30 5F 63 62
    .byte $5F,$4C,$4C,$4C,$4D,$54,$4E,$4F         ; DDC3: 5F 4C 4C 4C 4D 54 4E 4F
    .byte $52,$52,$4C,$4C,$30,$53,$57,$52         ; DDCB: 52 52 4C 4C 30 53 57 52
    .byte $30,$60,$63,$62,$08,$08,$4D,$30         ; DDD3: 30 60 63 62 08 08 4D 30
    .byte $4C,$53,$4C,$30,$5B,$53,$5C,$52         ; DDDB: 4C 53 4C 30 5B 53 5C 52
    .byte $05,$06,$4B,$30,$30,$5F,$4F,$62         ; DDE3: 05 06 4B 30 30 5F 4F 62
    .byte $08,$08,$4D,$30,$08,$06,$30,$30         ; DDEB: 08 08 4D 30 08 06 30 30
PageDescPtr:
    .byte $F5,$DD                                 ; DDF3: F5 DD
PageDescTab:
    .byte $60,$63,$66,$63,$61,$64,$67,$68         ; DDF5: 60 63 66 63 61 64 67 68
    .byte $62,$65,$6D,$69,$6A,$6E,$6E,$8E         ; DDFD: 62 65 6D 69 6A 6E 6E 8E
    .byte $6B,$6F,$70,$72,$6C,$6D,$71,$6D         ; DE05: 6B 6F 70 72 6C 6D 71 6D
    .byte $73,$63,$63,$77,$74,$68,$64,$78         ; DE0D: 73 63 63 77 74 68 64 78
    .byte $6D,$75,$76,$79,$7A,$7D,$7D,$7D         ; DE15: 6D 75 76 79 7A 7D 7D 7D
    .byte $7B,$7E,$80,$81,$7C,$7F,$5F,$82         ; DE1D: 7B 7E 80 81 7C 7F 5F 82
    .byte $7D,$7D,$85,$88,$7B,$83,$86,$89         ; DE25: 7D 7D 85 88 7B 83 86 89
    .byte $82,$84,$87,$8A,$7A,$7D,$7D,$7D         ; DE2D: 82 84 87 8A 7A 7D 7D 7D
    .byte $8B,$8C,$8D,$8F,$7F,$7F,$5F,$90         ; DE35: 8B 8C 8D 8F 7F 7F 5F 90
    .byte $7D,$7D,$7D,$95,$91,$93,$94,$96         ; DE3D: 7D 7D 7D 95 91 93 94 96
    .byte $92,$8A,$7F,$97,$A2,$A3,$7D,$95         ; DE45: 92 8A 7F 97 A2 A3 7D 95
    .byte $98,$9A,$9B,$96,$99,$92,$7F,$9C         ; DE4D: 98 9A 9B 96 99 92 7F 9C
    .byte $9D,$7D,$A0,$95,$9E,$9F,$8C,$96         ; DE55: 9D 7D A0 95 9E 9F 8C 96
    .byte $7C,$82,$7F,$A1,$60,$17,$1A,$1D         ; DE5D: 7C 82 7F A1 60 17 1A 1D
    .byte $15,$18,$1B,$1E,$16,$19,$1C,$14         ; DE65: 15 18 1B 1E 16 19 1C 14
    .byte $1F,$1F,$1F,$25,$20,$22,$24,$26         ; DE6D: 1F 1F 1F 25 20 22 24 26
    .byte $21,$23,$23,$23,$17,$28,$2B,$61         ; DE75: 21 23 23 23 17 28 2B 61
    .byte $27,$29,$2C,$2D,$23,$2A,$19,$1C         ; DE7D: 27 29 2C 2D 23 2A 19 1C
    .byte $2E,$31,$31,$31,$2F,$32,$34,$36         ; DE85: 2E 31 31 31 2F 32 34 36
    .byte $30,$33,$35,$37,$38,$31,$31,$3E         ; DE8D: 30 33 35 37 38 31 31 3E
    .byte $39,$3B,$3D,$3F,$3A,$3C,$62,$40         ; DE95: 39 3B 3D 3F 3A 3C 62 40
    .byte $31,$31,$31,$3E,$41,$3B,$3D,$3F         ; DE9D: 31 31 31 3E 41 3B 3D 3F
    .byte $3A,$42,$43,$44,$31,$46,$31,$49         ; DEA5: 3A 42 43 44 31 46 31 49
    .byte $45,$47,$48,$4A,$14,$16,$3C,$5F         ; DEAD: 45 47 48 4A 14 16 3C 5F
    .byte $61,$46,$31,$51,$4B,$4D,$4F,$52         ; DEB5: 61 46 31 51 4B 4D 4F 52
    .byte $4C,$4E,$50,$14,$61,$61,$61,$61         ; DEBD: 4C 4E 50 14 61 61 61 61
    .byte $54,$55,$57,$59,$14,$56,$3C,$5A         ; DEC5: 54 55 57 59 14 56 3C 5A
    .byte $58,$31,$31,$31,$5E,$5C,$4D,$4F         ; DECD: 58 31 31 31 5E 5C 4D 4F
    .byte $5B,$5D,$4E,$50,$31,$31,$BC,$49         ; DED5: 5B 5D 4E 50 31 31 BC 49
    .byte $B7,$B8,$BA,$4A,$14,$3A,$2A,$5F         ; DEDD: B7 B8 BA 4A 14 3A 2A 5F
    .byte $2E,$31,$31,$31,$2F,$32,$9C,$9D         ; DEE5: 2E 31 31 31 2F 32 9C 9D
    .byte $30,$33,$35,$37,$28,$1F,$1F,$25         ; DEED: 30 33 35 37 28 1F 1F 25
    .byte $B7,$BA,$B9,$75,$3A,$3C,$33,$35         ; DEF5: B7 BA B9 75 3A 3C 33 35
    .byte $60,$6F,$72,$7A,$6D,$7C,$73,$75         ; DEFD: 60 6F 72 7A 6D 7C 73 75
    .byte $6E,$7D,$14,$14,$58,$66,$69,$60         ; DF05: 6E 7D 14 14 58 66 69 60
    .byte $64,$67,$6A,$6C,$77,$6B,$6B,$6B         ; DF0D: 64 67 6A 6C 77 6B 6B 6B
    .byte $63,$7F,$60,$60,$7E,$80,$81,$83         ; DF15: 63 7F 60 60 7E 80 81 83
    .byte $14,$14,$82,$84,$85,$66,$72,$74         ; DF1D: 14 14 82 84 85 66 72 74
    .byte $86,$88,$73,$75,$87,$7D,$14,$14         ; DF25: 86 88 73 75 87 7D 14 14
    .byte $72,$72,$72,$72,$6A,$8A,$8B,$8C         ; DF2D: 72 72 72 72 6A 8A 8B 8C
    .byte $6B,$6E,$89,$89,$72,$72,$72,$72         ; DF35: 6B 6E 89 89 72 72 72 72
    .byte $8D,$8E,$8F,$90,$91,$92,$93,$6B         ; DF3D: 8D 8E 8F 90 91 92 93 6B
    .byte $94,$72,$85,$95,$96,$97,$98,$99         ; DF45: 94 72 85 95 96 97 98 99
    .byte $91,$6E,$9A,$14,$72,$72,$72,$74         ; DF4D: 91 6E 9A 14 72 72 72 74
    .byte $9B,$9C,$9D,$75,$9E,$92,$93,$9F         ; DF55: 9B 9C 9D 75 9E 92 93 9F
    .byte $58,$72,$72,$72,$A0,$A1,$A2,$A3         ; DF5D: 58 72 72 72 A0 A1 A2 A3
    .byte $A4,$A5,$A6,$6E,$63,$66,$72,$74         ; DF65: A4 A5 A6 6E 63 66 72 74
    .byte $A7,$A8,$A9,$AA,$6B,$6B,$B5,$AB         ; DF6D: A7 A8 A9 AA 6B 6B B5 AB
    .byte $63,$66,$72,$74,$AC,$AE,$AF,$B0         ; DF75: 63 66 72 74 AC AE AF B0
    .byte $B1,$B2,$B3,$B4,$3A,$3D,$40,$43         ; DF7D: B1 B2 B3 B4 3A 3D 40 43
    .byte $3B,$3E,$41,$44,$3C,$3F,$42,$45         ; DF85: 3B 3E 41 44 3C 3F 42 45
    .byte $40,$46,$3A,$3D,$53,$47,$49,$49         ; DF8D: 40 46 3A 3D 53 47 49 49
    .byte $45,$48,$42,$4A,$43,$4C,$4E,$51         ; DF95: 45 48 42 4A 43 4C 4E 51
    .byte $4B,$4D,$4F,$52,$45,$48,$50,$3C         ; DF9D: 4B 4D 4F 52 45 48 50 3C
    .byte $60,$60,$60,$60,$14,$14,$14,$14         ; DFA5: 60 60 60 60 14 14 14 14
    .byte $14,$14,$14,$14,$00,$01,$02,$03         ; DFAD: 14 14 14 14 00 01 02 03
    .byte $04,$05,$06,$07,$08,$09,$0A,$0B         ; DFB5: 04 05 06 07 08 09 0A 0B
    .byte $02,$02,$0C,$0D,$0E,$0F,$10,$11         ; DFBD: 02 02 0C 0D 0E 0F 10 11
    .byte $12,$13,$14,$15,$02,$02,$0C,$0D         ; DFC5: 12 13 14 15 02 02 0C 0D
    .byte $16,$17,$18,$19,$1A,$13,$1B,$12         ; DFCD: 16 17 18 19 1A 13 1B 12
    .byte $1C,$02,$1D,$02,$1E,$1F,$20,$21         ; DFD5: 1C 02 1D 02 1E 1F 20 21
    .byte $12,$22,$23,$24,$02,$0C,$1D,$02         ; DFDD: 12 22 23 24 02 0C 1D 02
    .byte $25,$26,$27,$28,$13,$14,$15,$29         ; DFE5: 25 26 27 28 13 14 15 29
    .byte $02,$02,$0C,$02,$2A,$2B,$2C,$2D         ; DFED: 02 02 0C 02 2A 2B 2C 2D
    .byte $2E,$2F,$1B,$12,$30,$02,$1D,$02         ; DFF5: 2E 2F 1B 12 30 02 1D 02
    .byte $31,$32,$33,$34,$35,$36,$37,$38         ; DFFD: 31 32 33 34 35 36 37 38
    .byte $58,$66,$72,$7A,$AC,$AE,$AF,$B0         ; E005: 58 66 72 7A AC AE AF B0
    .byte $B1,$B2,$B3,$B4,$58,$66,$72,$74         ; E00D: B1 B2 B3 B4 58 66 72 74
    .byte $65,$68,$90,$AA,$6B,$93,$B5,$AB         ; E015: 65 68 90 AA 6B 93 B5 AB
    .byte $60,$6F,$72,$74,$AD,$70,$73,$75         ; E01D: 60 6F 72 74 AD 70 73 75
    .byte $B6,$71,$6B,$6B,$58,$72,$72,$74         ; E025: B6 71 6B 6B 58 72 72 74
    .byte $7E,$9C,$9D,$75,$6B,$92,$93,$9F         ; E02D: 7E 9C 9D 75 6B 92 93 9F
    .byte $BD,$31,$31,$BE,$A8,$BF,$C0,$C1         ; E035: BD 31 31 BE A8 BF C0 C1
    .byte $14,$16,$04,$5F,$BD,$BD,$BD,$BD         ; E03D: 14 16 04 5F BD BD BD BD
    .byte $B8,$C2,$C3,$C4,$3A,$C5,$C6,$C7         ; E045: B8 C2 C3 C4 3A C5 C6 C7
    .byte $BD,$BD,$BD,$BD,$C9,$CA,$CB,$A8         ; E04D: BD BD BD BD C9 CA CB A8
    .byte $4C,$4E,$50,$14,$CC,$CD,$CD,$03         ; E055: 4C 4E 50 14 CC CD CD 03
    .byte $CF,$0E,$0F,$10,$11,$12,$13,$C8         ; E05D: CF 0E 0F 10 11 12 13 C8
    .byte $02,$02,$02,$03,$0E,$54,$55,$56         ; E065: 02 02 02 03 0E 54 55 56
    .byte $57,$58,$59,$1B,$02,$02,$02,$02         ; E06D: 57 58 59 1B 02 02 02 02
    .byte $04,$05,$06,$5A,$08,$09,$57,$58         ; E075: 04 05 06 5A 08 09 57 58
    .byte $02,$02,$0C,$02,$0E,$0F,$18,$5B         ; E07D: 02 02 0C 02 0E 0F 18 5B
    .byte $1A,$13,$1B,$12,$1C,$02,$1D,$02         ; E085: 1A 13 1B 12 1C 02 1D 02
    .byte $1E,$1F,$20,$5C,$12,$22,$23,$24         ; E08D: 1E 1F 20 5C 12 22 23 24
    .byte $05,$72,$72,$74,$B8,$AE,$06,$07         ; E095: 05 72 72 74 B8 AE 06 07
    .byte $B1,$B2,$19,$9A,$58,$72,$72,$72         ; E09D: B1 B2 19 9A 58 72 72 72
    .byte $08,$09,$0A,$CB,$0B,$0C,$0C,$7D         ; E0A5: 08 09 0A CB 0B 0C 0C 7D
    .byte $88,$88,$88,$88,$7B,$7B,$7B,$7B         ; E0AD: 88 88 88 88 7B 7B 7B 7B
    .byte $7B,$7B,$7B,$7B                         ; E0B5: 7B 7B 7B 7B
MetaAttrTab:
    .byte $F5,$35,$05,$05,$C5,$05,$05,$C5         ; E0B9: F5 35 05 05 C5 05 05 C5
    .byte $05,$35,$A5,$05,$05,$05,$A5,$A5         ; E0C1: 05 35 A5 05 05 05 A5 A5
    .byte $A5,$A5,$05,$05,$A5,$05,$05,$05         ; E0C9: A5 A5 05 05 A5 05 05 05
    .byte $05,$A5,$A5,$A5,$05,$05,$05,$05         ; E0D1: 05 A5 A5 A5 05 05 05 05
    .byte $05,$05,$00,$F0,$00,$00,$00,$F0         ; E0D9: 05 05 00 F0 00 00 00 F0
    .byte $00,$00,$00,$00,$F0,$F0,$00,$00         ; E0E1: 00 00 00 00 F0 F0 00 00
    .byte $00,$FF,$FF,$FF,$AA,$22,$00,$00         ; E0E9: 00 FF FF FF AA 22 00 00
    .byte $00,$0A,$00,$20,$00,$00,$00,$00         ; E0F1: 00 0A 00 20 00 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$CC,$CC         ; E0F9: 00 00 00 00 00 00 CC CC
    .byte $CC,$AA,$88,$33,$00,$FC,$0F,$00         ; E101: CC AA 88 33 00 FC 0F 00
    .byte $00,$00,$00,$00,$00,$00,$F3,$00         ; E109: 00 00 00 00 00 00 F3 00
    .byte $00,$C3,$0F,$30,$03,$00,$00,$F3         ; E111: 00 C3 0F 30 03 00 00 F3
    .byte $CC,$00,$00,$00,$00,$00,$00,$00         ; E119: CC 00 00 00 00 00 00 00
    .byte $AA,$00,$80,$88,$08,$00,$AA,$0A         ; E121: AA 00 80 88 08 00 AA 0A
    .byte $00,$A0,$00,$A0,$AA,$AA,$AA,$AA         ; E129: 00 A0 00 A0 AA AA AA AA
    .byte $0A,$AA,$00,$00,$00,$0A,$AA,$AA         ; E131: 0A AA 00 00 00 0A AA AA
    .byte $8A,$AA,$AA,$AA,$0A,$A0,$AA,$0A         ; E139: 8A AA AA AA 0A A0 AA 0A
    .byte $88,$00,$A0,$AA,$00,$00,$0A,$00         ; E141: 88 00 A0 AA 00 00 0A 00
    .byte $AA,$AA,$AA,$AA,$00,$00,$00,$22         ; E149: AA AA AA AA 00 00 00 22
    .byte $22,$AA,$AA,$A2,$AA,$08,$00,$22         ; E151: 22 AA AA A2 AA 08 00 22
    .byte $08,$00,$00,$00,$00,$00,$00,$00         ; E159: 08 00 00 00 00 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; E161: 00 00 00 00 00 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; E169: 00 00 00 00 00 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; E171: 00 00 00 00 00 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$00,$00         ; E179: 00 00 00 00 00 00 00 00
    .byte $00,$00,$00,$00,$00,$00,$00,$F0         ; E181: 00 00 00 00 00 00 00 F0
    .byte $F0,$F0,$F0,$00,$00,$00,$00,$00         ; E189: F0 F0 F0 00 00 00 00 00
    .byte $FF,$00,$FF,$FF,$FF,$00,$00,$00         ; E191: FF 00 FF FF FF 00 00 00
    .byte $00,$00,$00,$00,$F0,$F0,$F0,$00         ; E199: 00 00 00 00 F0 F0 F0 00
    .byte $AA,$00,$00,$00,$F0,$00,$00,$00         ; E1A1: AA 00 00 00 F0 00 00 00
    .byte $00,$00,$00,$A2                         ; E1A9: 00 00 00 A2
MetaStreamPtrPtr:
    .byte $AF,$E1                                 ; E1AD: AF E1
MetaStreamPtrTab:
    .byte $97,$E3,$9C,$E3,$A4,$E3,$A9,$E3         ; E1AF: 97 E3 9C E3 A4 E3 A9 E3
    .byte $AB,$E3,$B1,$E3,$B7,$E3,$B9,$E3         ; E1B7: AB E3 B1 E3 B7 E3 B9 E3
    .byte $C1,$E3,$C3,$E3,$C9,$E3,$CB,$E3         ; E1BF: C1 E3 C3 E3 C9 E3 CB E3
    .byte $D3,$E3,$DB,$E3,$E3,$E3,$E9,$E3         ; E1C7: D3 E3 DB E3 E3 E3 E9 E3
    .byte $ED,$E3,$F5,$E3,$FA,$E3,$02,$E4         ; E1CF: ED E3 F5 E3 FA E3 02 E4
    .byte $0A,$E4,$0E,$E4,$16,$E4,$1C,$E4         ; E1D7: 0A E4 0E E4 16 E4 1C E4
    .byte $24,$E4,$2C,$E4,$31,$E4,$33,$E4         ; E1DF: 24 E4 2C E4 31 E4 33 E4
    .byte $3B,$E4,$43,$E4,$83,$E7,$4B,$E4         ; E1E7: 3B E4 43 E4 83 E7 4B E4
    .byte $53,$E4,$58,$E4,$3D,$EB,$45,$EB         ; E1EF: 53 E4 58 E4 3D EB 45 EB
    .byte $50,$EB,$60,$EB,$6A,$EB,$7A,$EB         ; E1F7: 50 EB 60 EB 6A EB 7A EB
    .byte $8A,$EB,$9A,$EB,$A5,$EB,$B5,$EB         ; E1FF: 8A EB 9A EB A5 EB B5 EB
    .byte $C5,$EB,$C9,$EB,$D9,$EB,$E1,$EB         ; E207: C5 EB C9 EB D9 EB E1 EB
    .byte $60,$E4,$64,$E4,$70,$E4,$78,$E4         ; E20F: 60 E4 64 E4 70 E4 78 E4
    .byte $87,$E4,$8F,$E4,$9C,$E4,$A8,$E4         ; E217: 87 E4 8F E4 9C E4 A8 E4
    .byte $AE,$E4,$B8,$E4,$BD,$E4,$C7,$E4         ; E21F: AE E4 B8 E4 BD E4 C7 E4
    .byte $C2,$E4,$C9,$E4,$D0,$E4,$D5,$E4         ; E227: C2 E4 C9 E4 D0 E4 D5 E4
    .byte $E1,$E4,$EE,$E4,$F8,$E4,$FF,$E4         ; E22F: E1 E4 EE E4 F8 E4 FF E4
    .byte $FF,$E4,$07,$E5,$1A,$E5,$14,$E5         ; E237: FF E4 07 E5 1A E5 14 E5
    .byte $20,$E5,$2C,$E5,$34,$E5,$44,$E5         ; E23F: 20 E5 2C E5 34 E5 44 E5
    .byte $98,$E5,$50,$E5,$60,$E5,$70,$E5         ; E247: 98 E5 50 E5 60 E5 70 E5
    .byte $77,$E5,$7D,$E5,$85,$E5,$84,$E5         ; E24F: 77 E5 7D E5 85 E5 84 E5
    .byte $99,$E5,$CA,$E5,$89,$E5,$97,$E5         ; E257: 99 E5 CA E5 89 E5 97 E5
    .byte $B9,$E5,$9D,$E5,$6B,$E5,$AB,$E5         ; E25F: B9 E5 9D E5 6B E5 AB E5
    .byte $B3,$E5,$C3,$E5,$C6,$E5,$CE,$E5         ; E267: B3 E5 C3 E5 C6 E5 CE E5
    .byte $DC,$E5,$EC,$E5,$F6,$E5,$FF,$E5         ; E26F: DC E5 EC E5 F6 E5 FF E5
    .byte $09,$E6,$DD,$E4,$13,$E6,$1D,$E6         ; E277: 09 E6 DD E4 13 E6 1D E6
    .byte $60,$E4,$27,$E6,$2F,$E6,$3D,$E6         ; E27F: 60 E4 27 E6 2F E6 3D E6
    .byte $4D,$E6,$5D,$E6,$61,$E6,$70,$E6         ; E287: 4D E6 5D E6 61 E6 70 E6
    .byte $70,$E6,$68,$E6,$7A,$E6,$85,$E6         ; E28F: 70 E6 68 E6 7A E6 85 E6
    .byte $90,$E6,$98,$E6,$9C,$E6,$A3,$E6         ; E297: 90 E6 98 E6 9C E6 A3 E6
    .byte $AB,$E6,$BB,$E6,$BF,$E6,$C6,$E6         ; E29F: AB E6 BB E6 BF E6 C6 E6
    .byte $D6,$E6,$89,$E6,$E6,$E6,$F1,$E6         ; E2A7: D6 E6 89 E6 E6 E6 F1 E6
    .byte $F5,$E6,$EA,$E6,$00,$E7,$82,$E7         ; E2AF: F5 E6 EA E6 00 E7 82 E7
    .byte $FC,$E6,$07,$E7,$0B,$E7,$12,$E7         ; E2B7: FC E6 07 E7 0B E7 12 E7
    .byte $1C,$E7,$2C,$E7,$38,$E7,$43,$E7         ; E2BF: 1C E7 2C E7 38 E7 43 E7
    .byte $4C,$E7,$59,$E7,$45,$E7,$66,$E7         ; E2C7: 4C E7 59 E7 45 E7 66 E7
    .byte $72,$E7,$78,$E7,$83,$E7,$93,$E7         ; E2CF: 72 E7 78 E7 83 E7 93 E7
    .byte $9E,$E7,$AE,$E7,$BE,$E7,$CE,$E7         ; E2D7: 9E E7 AE E7 BE E7 CE E7
    .byte $DE,$E7,$EE,$E7,$F4,$E7,$10,$E8         ; E2DF: DE E7 EE E7 F4 E7 10 E8
    .byte $00,$E8,$1E,$E8,$2E,$E8,$32,$E8         ; E2E7: 00 E8 1E E8 2E E8 32 E8
    .byte $06,$E8,$97,$E7,$42,$E8,$4D,$E8         ; E2EF: 06 E8 97 E7 42 E8 4D E8
    .byte $58,$E8,$65,$E8,$70,$E8,$7B,$E8         ; E2F7: 58 E8 65 E8 70 E8 7B E8
    .byte $83,$E8,$8A,$E8,$92,$E8,$9D,$E8         ; E2FF: 83 E8 8A E8 92 E8 9D E8
    .byte $B1,$E8,$A9,$E8,$BD,$E8,$CD,$E8         ; E307: B1 E8 A9 E8 BD E8 CD E8
    .byte $D9,$E8,$E0,$E8,$F0,$E8,$F7,$E8         ; E30F: D9 E8 E0 E8 F0 E8 F7 E8
    .byte $FE,$E8,$10,$E9,$FA,$E8,$01,$E9         ; E317: FE E8 10 E9 FA E8 01 E9
    .byte $F3,$E8,$15,$E9,$22,$E9,$2A,$E9         ; E31F: F3 E8 15 E9 22 E9 2A E9
    .byte $37,$E9,$47,$E9,$57,$E9,$67,$E9         ; E327: 37 E9 47 E9 57 E9 67 E9
    .byte $77,$E9,$84,$E9,$8E,$E9,$9E,$E9         ; E32F: 77 E9 84 E9 8E E9 9E E9
    .byte $A6,$E9,$AE,$E9,$BE,$E9,$C6,$E9         ; E337: A6 E9 AE E9 BE E9 C6 E9
    .byte $D0,$E9,$E0,$E9,$ED,$E9,$F5,$E9         ; E33F: D0 E9 E0 E9 ED E9 F5 E9
    .byte $05,$EA,$12,$EA,$21,$EA,$31,$EA         ; E347: 05 EA 12 EA 21 EA 31 EA
    .byte $40,$EA,$4B,$EA,$56,$EA,$4F,$EA         ; E34F: 40 EA 4B EA 56 EA 4F EA
    .byte $65,$EA,$61,$EA,$6D,$EA,$81,$EA         ; E357: 65 EA 61 EA 6D EA 81 EA
    .byte $88,$EA,$06,$E9,$7D,$EA,$8C,$EA         ; E35F: 88 EA 06 E9 7D EA 8C EA
    .byte $90,$EA,$98,$EA,$A8,$EA,$AD,$EA         ; E367: 90 EA 98 EA A8 EA AD EA
    .byte $B7,$EA,$C7,$EA,$CD,$EA,$DC,$EA         ; E36F: B7 EA C7 EA CD EA DC EA
    .byte $E3,$EA,$EA,$EA,$F1,$EA,$FE,$EA         ; E377: E3 EA EA EA F1 EA FE EA
    .byte $60,$E4,$06,$EB,$16,$EB,$D2,$EA         ; E37F: 60 E4 06 EB 16 EB D2 EA
    .byte $26,$EB,$2B,$EB,$2F,$EB,$91,$EA         ; E387: 26 EB 2B EB 2F EB 91 EA
    .byte $17,$EA,$36,$EB,$F1,$EB,$F8,$EB         ; E38F: 17 EA 36 EB F1 EB F8 EB
MetaTileStreams:
    .byte $31,$01,$01,$01,$60,$72,$62,$62         ; E397: 31 01 01 01 60 72 62 62
    .byte $62,$74,$62,$62,$70,$62,$62,$62         ; E39F: 62 74 62 62 70 62 62 62
    .byte $62,$33,$32,$33,$62,$62,$31,$03         ; E3A7: 62 33 32 33 62 62 31 03
    .byte $73,$31,$41,$41,$34,$41,$41,$30         ; E3AF: 73 31 41 41 34 41 41 30
    .byte $34,$30,$04,$04,$54,$54,$04,$04         ; E3B7: 34 30 04 04 54 54 04 04
    .byte $25,$25,$34,$39,$25,$25,$39,$54         ; E3BF: 25 25 34 39 25 25 39 54
    .byte $54,$39,$30,$30,$5E,$5F,$5C,$5D         ; E3C7: 54 39 30 30 5E 5F 5C 5D
    .byte $8E,$8F,$8C,$8D,$5E,$DD,$5C,$DD         ; E3CF: 8E 8F 8C 8D 5E DD 5C DD
    .byte $8E,$ED,$8D,$ED,$5C,$5D,$5E,$2F         ; E3D7: 8E ED 8D ED 5C 5D 5E 2F
    .byte $8C,$8D,$5E,$5F,$69,$58,$47,$48         ; E3DF: 8C 8D 5E 5F 69 58 47 48
    .byte $F8,$30,$49,$30,$F8,$30,$47,$47         ; E3E7: F8 30 49 30 F8 30 47 47
    .byte $48,$49,$00,$00,$00,$F8,$47,$47         ; E3EF: 48 49 00 00 00 F8 47 47
    .byte $47,$48,$30,$4E,$2F,$4C,$4D,$5E         ; E3F7: 47 48 30 4E 2F 4C 4D 5E
    .byte $5F,$5C,$5D,$4E,$2F,$4C,$4D,$5E         ; E3FF: 5F 5C 5D 4E 2F 4C 4D 5E
    .byte $5F,$5C,$7C,$59,$30,$B7,$30,$8C         ; E407: 5F 5C 7C 59 30 B7 30 8C
    .byte $8D,$8E,$4E,$00,$00,$00,$7D,$4D         ; E40F: 8D 8E 4E 00 00 00 7D 4D
    .byte $8D,$8E,$8F,$6C,$30,$5E,$5F,$5C         ; E417: 8D 8E 8F 6C 30 5E 5F 5C
    .byte $6C,$8E,$8F,$8C,$9C,$6D,$5F,$5C         ; E41F: 6C 8E 8F 8C 9C 6D 5F 5C
    .byte $5D,$7D,$8F,$8C,$8D,$BE,$AE,$BE         ; E427: 5D 7D 8F 8C 8D BE AE BE
    .byte $AE,$00,$BE,$AE,$BE,$AE,$BE,$AE         ; E42F: AE 00 BE AE BE AE BE AE
    .byte $AE,$BE,$AE,$00,$80,$80,$80,$80         ; E437: AE BE AE 00 80 80 80 80
    .byte $80,$00,$00,$80,$6D,$2F,$4C,$4D         ; E43F: 80 00 00 80 6D 2F 4C 4D
    .byte $7D,$5F,$5C,$5D,$00,$BE,$DE,$93         ; E447: 7D 5F 5C 5D 00 BE DE 93
    .byte $BE,$3E,$85,$00,$93,$93,$93,$93         ; E44F: BE 3E 85 00 93 93 93 93
    .byte $30,$B6,$B6,$B6,$B6,$CE,$83,$63         ; E457: 30 B6 B6 B6 B6 CE 83 63
    .byte $AE,$30,$30,$30,$30,$01,$01,$60         ; E45F: AE 30 30 30 30 01 01 60
    .byte $74,$01,$60,$74,$62,$60,$74,$62         ; E467: 74 01 60 74 62 60 74 62
    .byte $62,$01,$01,$65,$01,$01,$01,$65         ; E46F: 62 01 01 65 01 01 01 65
    .byte $01,$01,$01,$65,$01,$01,$01,$65         ; E477: 01 01 01 65 01 01 01 65
    .byte $01,$01,$75,$78,$78,$01,$65,$31         ; E47F: 01 01 75 78 78 01 65 31
    .byte $67,$67,$67,$67,$69,$7B,$7A,$79         ; E487: 67 67 67 67 69 7B 7A 79
    .byte $69,$6C,$30,$69,$7B,$30,$69,$6C         ; E48F: 69 6C 30 69 7B 30 69 6C
    .byte $63,$64,$69,$7B,$30,$62,$62,$70         ; E497: 63 64 69 7B 30 62 62 70
    .byte $04,$62,$70,$34,$62,$70,$34,$73         ; E49F: 04 62 70 34 62 70 34 73
    .byte $34,$73,$66,$66,$66,$73,$33,$73         ; E4A7: 34 73 66 66 66 73 33 73
    .byte $34,$73,$34,$73,$35,$73,$63,$64         ; E4AF: 34 73 34 73 35 73 63 64
    .byte $63,$6A,$6B,$30,$7A,$30,$30,$30         ; E4B7: 63 6A 6B 30 7A 30 30 30
    .byte $38,$0F,$E5,$66,$66,$66,$66,$33         ; E4BF: 38 0F E5 66 66 66 66 33
    .byte $34,$34,$34,$34,$35,$64,$63,$64         ; E4C7: 34 34 34 34 35 64 63 64
    .byte $63,$30,$30,$38,$FF,$E4,$66,$66         ; E4CF: 63 30 30 38 FF E4 66 66
    .byte $66,$66,$71,$71,$71,$03,$71,$71         ; E4D7: 66 66 71 71 71 03 71 71
    .byte $71,$04,$71,$71,$71,$04,$71,$71         ; E4DF: 71 04 71 71 71 04 71 71
    .byte $71,$04,$71,$71,$71,$04,$64,$63         ; E4E7: 71 04 71 71 71 04 64 63
    .byte $64,$63,$64,$64,$63,$64,$63,$30         ; E4EF: 64 63 64 64 63 64 63 30
    .byte $30,$34,$34,$66,$66,$66,$66,$33         ; E4F7: 30 34 34 66 66 66 66 33
    .byte $63,$64,$63,$64,$64,$63,$64,$64         ; E4FF: 63 64 63 64 64 63 64 64
    .byte $63,$64,$63,$64,$64,$63,$64,$63         ; E507: 63 64 63 64 64 63 64 63
    .byte $63,$64,$63,$64,$30,$66,$73,$31         ; E50F: 63 64 63 64 30 66 73 31
    .byte $03,$73,$31,$04,$73,$31,$04,$73         ; E517: 03 73 31 04 73 31 04 73
    .byte $31,$04,$73,$31,$04,$73,$31,$05         ; E51F: 31 04 73 31 04 73 31 05
    .byte $73,$31,$64,$73,$31,$7D,$6A,$67         ; E527: 73 31 64 73 31 7D 6A 67
    .byte $68,$00,$7A,$7D,$6A,$00,$00,$6D         ; E52F: 68 00 7A 7D 6A 00 00 6D
    .byte $6A,$00,$00,$7D,$69,$63,$64,$7C         ; E537: 6A 00 00 7D 69 63 64 7C
    .byte $69,$64,$63,$00,$79,$54,$54,$30         ; E53F: 69 64 63 00 79 54 54 30
    .byte $25,$25,$30,$25,$25,$30,$44,$44         ; E547: 25 25 30 25 25 30 44 44
    .byte $30,$41,$41,$54,$54,$41,$41,$25         ; E54F: 30 41 41 54 54 41 41 25
    .byte $25,$25,$25,$25,$54,$56,$46,$25         ; E557: 25 25 25 25 54 56 46 25
    .byte $24,$54,$54,$54,$00,$25,$25,$24         ; E55F: 24 54 54 54 00 25 25 24
    .byte $00,$38,$BB,$E5,$46,$46,$56,$24         ; E567: 00 38 BB E5 46 46 56 24
    .byte $30,$30,$30,$50,$51,$50,$51,$30         ; E56F: 30 30 30 50 51 50 51 30
    .byte $41,$41,$30,$38,$7E,$E5,$30,$41         ; E577: 41 41 30 38 7E E5 30 41
    .byte $41,$30,$41,$41,$30,$39,$30,$30         ; E57F: 41 30 41 41 30 39 30 30
    .byte $30,$39,$25,$54,$39,$54,$22,$39         ; E587: 30 39 25 54 39 54 22 39
    .byte $22,$55,$46,$54,$00,$00,$00,$22         ; E58F: 22 55 46 54 00 00 00 22
    .byte $30,$39,$39,$39,$39,$30,$42,$55         ; E597: 30 39 39 39 39 30 42 55
    .byte $39,$44,$46,$39,$41,$41,$54,$25         ; E59F: 39 44 46 39 41 41 54 25
    .byte $41,$41,$22,$54,$39,$39,$25,$25         ; E5A7: 41 41 22 54 39 39 25 25
    .byte $39,$44,$44,$39,$25,$54,$39,$25         ; E5AF: 39 44 44 39 25 54 39 25
    .byte $22,$39,$39,$39,$50,$51,$50,$51         ; E5B7: 22 39 39 39 50 51 50 51
    .byte $51,$50,$51,$50,$30,$30,$30,$41         ; E5BF: 51 50 51 50 30 30 30 41
    .byte $41,$30,$39,$39,$39,$30,$30,$25         ; E5C7: 41 30 39 39 39 30 30 25
    .byte $25,$39,$25,$54,$39,$54,$22,$55         ; E5CF: 25 39 25 54 39 54 22 55
    .byte $54,$22,$55,$46,$25,$41,$41,$25         ; E5D7: 54 22 55 46 25 41 41 25
    .byte $25,$00,$00,$54,$54,$00,$00,$25         ; E5DF: 25 00 00 54 54 00 00 25
    .byte $25,$00,$00,$25,$25,$00,$00,$39         ; E5E7: 25 00 00 25 25 00 00 39
    .byte $00,$00,$39,$00,$00,$39,$39,$00         ; E5EF: 00 00 39 00 00 39 39 00
    .byte $00,$39,$00,$00,$39,$38,$01,$E6         ; E5F7: 00 39 00 00 39 38 01 E6
    .byte $30,$30,$50,$51,$50,$51,$51,$50         ; E5FF: 30 30 50 51 50 51 51 50
    .byte $51,$50,$30,$30,$63,$64,$63,$64         ; E607: 51 50 30 30 63 64 63 64
    .byte $64,$63,$64,$63,$34,$34,$66,$66         ; E60F: 64 63 64 63 34 34 66 66
    .byte $66,$66,$71,$71,$71,$03,$34,$34         ; E617: 66 66 71 71 71 03 34 34
    .byte $04,$04,$04,$66,$04,$04,$04,$66         ; E61F: 04 04 04 66 04 04 04 66
    .byte $4C,$4D,$4E,$2F,$5C,$38,$97,$E8         ; E627: 4C 4D 4E 2F 5C 38 97 E8
    .byte $4C,$6C,$8C,$9C,$4E,$7C,$30,$4C         ; E62F: 4C 6C 8C 9C 4E 7C 30 4C
    .byte $6C,$30,$5E,$7C,$69,$58,$4C,$6C         ; E637: 6C 30 5E 7C 69 58 4C 6C
    .byte $F8,$00,$5C,$7C,$59,$00,$4E,$6C         ; E63F: F8 00 5C 7C 59 00 4E 6C
    .byte $59,$00,$5E,$7C,$59,$00,$4C,$6C         ; E647: 59 00 5E 7C 59 00 4C 6C
    .byte $F8,$00,$5C,$7C,$59,$00,$4E,$2F         ; E64F: F8 00 5C 7C 59 00 4E 2F
    .byte $A4,$A5,$5E,$5F,$B4,$B5,$8E,$8F         ; E657: A4 A5 5E 5F B4 B5 8E 8F
    .byte $8C,$8D,$30,$30,$30,$47,$47,$47         ; E65F: 8C 8D 30 30 30 47 47 47
    .byte $48,$8E,$DD,$8C,$DD,$00,$ED,$00         ; E667: 48 8E DD 8C DD 00 ED 00
    .byte $ED,$30,$30,$A4,$A5,$A4,$A5,$B4         ; E66F: ED 30 30 A4 A5 A4 A5 B4
    .byte $B5,$B4,$B5,$4C,$4D,$4E,$6C,$5C         ; E677: B5 B4 B5 4C 4D 4E 6C 5C
    .byte $5D,$5E,$7C,$38,$0E,$EB,$8E,$8F         ; E67F: 5D 5E 7C 38 0E EB 8E 8F
    .byte $8C,$9C,$30,$30,$30,$6E,$6F,$7E         ; E687: 8C 9C 30 30 30 6E 6F 7E
    .byte $7F,$59,$30,$59,$30,$59,$30,$B7         ; E68F: 7F 59 30 59 30 59 30 B7
    .byte $30,$BB,$58,$47,$48,$30,$30,$30         ; E697: 30 BB 58 47 48 30 30 30
    .byte $47,$47,$48,$49,$00,$00,$00,$F8         ; E69F: 47 47 48 49 00 00 00 F8
    .byte $00,$69,$58,$59,$00,$F8,$00,$F8         ; E6A7: 00 69 58 59 00 F8 00 F8
    .byte $00,$59,$00,$59,$A4,$A5,$A4,$A5         ; E6AF: 00 59 00 59 A4 A5 A4 A5
    .byte $B4,$B5,$B4,$B5,$47,$47,$47,$57         ; E6B7: B4 B5 B4 B5 47 47 47 57
    .byte $30,$30,$30,$9F,$6F,$7E,$7F,$6D         ; E6BF: 30 30 30 9F 6F 7E 7F 6D
    .byte $4D,$4E,$2F,$7D,$5D,$5E,$5F,$6D         ; E6C7: 4D 4E 2F 7D 5D 5E 5F 6D
    .byte $2F,$4C,$4D,$7D,$5F,$5C,$5D,$6D         ; E6CF: 2F 4C 4D 7D 5F 5C 5D 6D
    .byte $4D,$4E,$2F,$7D,$5D,$5E,$5F,$4E         ; E6D7: 4D 4E 2F 7D 5D 5E 5F 4E
    .byte $2F,$4C,$4D,$5E,$5F,$5C,$5D,$E8         ; E6DF: 2F 4C 4D 5E 5F 5C 5D E8
    .byte $47,$47,$48,$30,$30,$30,$47,$47         ; E6E7: 47 47 48 30 30 30 47 47
    .byte $47,$57,$47,$47,$47,$48,$30,$30         ; E6EF: 47 57 47 47 47 48 30 30
    .byte $30,$6E,$9E,$69,$58,$47,$47,$48         ; E6F7: 30 6E 9E 69 58 47 47 48
    .byte $BA,$30,$30,$30,$E8,$47,$47,$48         ; E6FF: BA 30 30 30 E8 47 47 48
    .byte $9D,$8D,$8E,$8F,$30,$30,$30,$47         ; E707: 9D 8D 8E 8F 30 30 30 47
    .byte $47,$57,$00,$30,$30,$9F,$A5,$A4         ; E70F: 47 57 00 30 30 9F A5 A4
    .byte $A5,$6D,$B5,$B4,$B5,$4C,$6C,$59         ; E717: A5 6D B5 B4 B5 4C 6C 59
    .byte $00,$5C,$7C,$59,$00,$5E,$6C,$B7         ; E71F: 00 5C 7C 59 00 5E 6C B7
    .byte $00,$5E,$7C,$BB,$58,$4C,$6C,$30         ; E727: 00 5E 7C BB 58 4C 6C 30
    .byte $5C,$7C,$30,$4E,$6C,$30,$5E,$7C         ; E72F: 5C 7C 30 4E 6C 30 5E 7C
    .byte $30,$4C,$6C,$30,$8E,$9C,$30,$47         ; E737: 30 4C 6C 30 8E 9C 30 47
    .byte $47,$47,$48,$30,$57,$30,$30,$30         ; E73F: 47 47 48 30 57 30 30 30
    .byte $30,$6E,$6F,$7E,$9E,$6D,$4D,$4E         ; E747: 30 6E 6F 7E 9E 6D 4D 4E
    .byte $2F,$7D,$5D,$5E,$5F,$9D,$8D,$8E         ; E74F: 2F 7D 5D 5E 5F 9D 8D 8E
    .byte $8F,$30,$4C,$4D,$4E,$2F,$5C,$5D         ; E757: 8F 30 4C 4D 4E 2F 5C 5D
    .byte $5E,$5F,$8C,$8D,$8E,$8F,$30,$4C         ; E75F: 5E 5F 8C 8D 8E 8F 30 4C
    .byte $4D,$4E,$6C,$5C,$5D,$5E,$7C,$8C         ; E767: 4D 4E 6C 5C 5D 5E 7C 8C
    .byte $8D,$8E,$9C,$30,$30,$47,$47,$47         ; E76F: 8D 8E 9C 30 30 47 47 47
    .byte $48,$30,$30,$47,$47,$48,$49,$00         ; E777: 48 30 30 47 47 48 49 00
    .byte $00,$00,$F8,$00,$00,$00,$59,$00         ; E77F: 00 00 F8 00 00 00 59 00
    .byte $00,$00,$59,$00,$00,$00,$59,$00         ; E787: 00 00 59 00 00 00 59 00
    .byte $00,$00,$B7,$00,$00,$00,$BB,$58         ; E78F: 00 00 B7 00 00 00 BB 58
    .byte $30,$30,$30,$6E,$6F,$7E,$7F,$9F         ; E797: 30 30 30 6E 6F 7E 7F 9F
    .byte $6F,$7E,$7F,$6D,$5D,$5E,$5F,$7D         ; E79F: 6F 7E 7F 6D 5D 5E 5F 7D
    .byte $2F,$4C,$4D,$9D,$8D,$8E,$8F,$6E         ; E7A7: 2F 4C 4D 9D 8D 8E 8F 6E
    .byte $6F,$7E,$7F,$5C,$5D,$5E,$5F,$4E         ; E7AF: 6F 7E 7F 5C 5D 5E 5F 4E
    .byte $2F,$4C,$4D,$8C,$8D,$8E,$8F,$6E         ; E7B7: 2F 4C 4D 8C 8D 8E 8F 6E
    .byte $6F,$7E,$9E,$5C,$5D,$5E,$6C,$4E         ; E7BF: 6F 7E 9E 5C 5D 5E 6C 4E
    .byte $2F,$4C,$7C,$8C,$8D,$8E,$9C,$00         ; E7C7: 2F 4C 7C 8C 8D 8E 9C 00
    .byte $00,$6D,$4D,$00,$00,$7D,$5D,$00         ; E7CF: 00 6D 4D 00 00 7D 5D 00
    .byte $00,$6D,$2F,$00,$00,$7D,$5F,$00         ; E7D7: 00 6D 2F 00 00 7D 5F 00
    .byte $00,$6D,$4D,$00,$00,$7D,$5D,$00         ; E7DF: 00 6D 4D 00 00 7D 5D 00
    .byte $00,$6D,$2F,$48,$49,$7D,$5F,$30         ; E7E7: 00 6D 2F 48 49 7D 5F 30
    .byte $30,$49,$30,$F8,$30,$00,$B7,$F8         ; E7EF: 30 49 30 F8 30 00 B7 F8
    .byte $F8,$00,$BB,$58,$47,$47,$47,$47         ; E7F7: F8 00 BB 58 47 47 47 47
    .byte $47,$30,$30,$E8,$47,$47,$48,$30         ; E7FF: 47 30 30 E8 47 47 48 30
    .byte $30,$A4,$A5,$A4,$9E,$B4,$B5,$B4         ; E807: 30 A4 A5 A4 9E B4 B5 B4
    .byte $6C,$00,$B7,$6D,$4D,$69,$BA,$9D         ; E80F: 6C 00 B7 6D 4D 69 BA 9D
    .byte $8F,$59,$30,$BB,$58,$47,$47,$4C         ; E817: 8F 59 30 BB 58 47 47 4C
    .byte $6C,$F8,$00,$5C,$7C,$59,$00,$4E         ; E81F: 6C F8 00 5C 7C 59 00 4E
    .byte $A4,$A4,$9E,$5E,$5F,$B4,$6C,$35         ; E827: A4 A4 9E 5E 5F B4 6C 35
    .byte $35,$35,$35,$00,$F8,$6D,$4D,$00         ; E82F: 35 35 35 00 F8 6D 4D 00
    .byte $59,$7D,$5D,$00,$59,$6D,$2F,$00         ; E837: 59 7D 5D 00 59 6D 2F 00
    .byte $59,$7D,$5F,$6E,$6F,$7E,$7F,$5C         ; E83F: 59 7D 5F 6E 6F 7E 7F 5C
    .byte $5D,$5E,$5F,$38,$1A,$E9,$6E,$6F         ; E847: 5D 5E 5F 38 1A E9 6E 6F
    .byte $7E,$9E,$5C,$5D,$5E,$7C,$38,$4F         ; E84F: 7E 9E 5C 5D 5E 7C 38 4F
    .byte $E9,$30,$7E,$7F,$6E,$9E,$4E,$2F         ; E857: E9 30 7E 7F 6E 9E 4E 2F
    .byte $4C,$7C,$5E,$5F,$5C,$5D,$4C,$4D         ; E85F: 4C 7C 5E 5F 5C 5D 4C 4D
    .byte $4E,$6C,$5C,$5D,$5E,$66,$38,$97         ; E867: 4E 6C 5C 5D 5E 66 38 97
    .byte $E8,$4C,$4D,$4E,$6C,$5C,$5D,$5E         ; E86F: E8 4C 4D 4E 6C 5C 5D 5E
    .byte $7C,$38,$B6,$E9,$76,$4D,$4E,$2F         ; E877: 7C 38 B6 E9 76 4D 4E 2F
    .byte $5C,$38,$97,$E8,$30,$30,$30,$00         ; E87F: 5C 38 97 E8 30 30 30 00
    .byte $9F,$7E,$7F,$30,$9F,$6F,$7E,$7F         ; E887: 9F 7E 7F 30 9F 6F 7E 7F
    .byte $38,$E8,$E8,$6D,$4D,$4E,$2F,$76         ; E88F: 38 E8 E8 6D 4D 4E 2F 76
    .byte $5D,$5E,$5F,$38,$1A,$E9,$00,$6D         ; E897: 5D 5E 5F 38 1A E9 00 6D
    .byte $4E,$2F,$00,$7D,$5E,$5F,$00,$9D         ; E89F: 4E 2F 00 7D 5E 5F 00 9D
    .byte $8E,$8F,$30,$30,$A4,$EE,$EF,$EE         ; E8A7: 8E 8F 30 30 A4 EE EF EE
    .byte $6C,$30,$4C,$4D,$4E,$2F,$5C,$5D         ; E8AF: 6C 30 4C 4D 4E 2F 5C 5D
    .byte $5E,$5F,$6D,$38,$C6,$E8,$6D,$4D         ; E8B7: 5E 5F 6D 38 C6 E8 6D 4D
    .byte $4E,$2F,$7D,$5D,$5E,$5F,$76,$2F         ; E8BF: 4E 2F 7D 5D 5E 5F 76 2F
    .byte $4C,$4D,$7D,$5F,$5C,$5D,$6D,$4D         ; E8C7: 4C 4D 7D 5F 5C 5D 6D 4D
    .byte $4E,$2F,$7D,$5D,$5E,$5F,$6D,$38         ; E8CF: 4E 2F 7D 5D 5E 5F 6D 38
    .byte $E9,$E8,$4C,$4D,$4E,$6C,$38,$74         ; E8D7: E9 E8 4C 4D 4E 6C 38 74
    .byte $E8,$9F,$6F,$7E,$7F,$7D,$5D,$5E         ; E8DF: E8 9F 6F 7E 7F 7D 5D 5E
    .byte $5F,$6D,$2F,$4C,$4D,$76,$5F,$5C         ; E8E7: 5F 6D 2F 4C 4D 76 5F 5C
    .byte $5D,$30,$30,$30,$B0,$B1,$B2,$A1         ; E8EF: 5D 30 30 30 B0 B1 B2 A1
    .byte $30,$30,$30,$B0,$B1,$B2,$B3,$30         ; E8F7: 30 30 30 B0 B1 B2 B3 30
    .byte $30,$30,$A0,$B1,$B2,$B3,$30,$30         ; E8FF: 30 30 A0 B1 B2 B3 30 30
    .byte $30,$DF,$A5,$A4,$A5,$E6,$B5,$B4         ; E907: 30 DF A5 A4 A5 E6 B5 B4
    .byte $B5,$B0,$A1,$30,$30,$30,$30,$6E         ; E90F: B5 B0 A1 30 30 30 30 6E
    .byte $6F,$7E,$7F,$4E,$2F,$4C,$4D,$5E         ; E917: 6F 7E 7F 4E 2F 4C 4D 5E
    .byte $5F,$5C,$5D,$30,$9F,$6F,$7E,$7F         ; E91F: 5F 5C 5D 30 9F 6F 7E 7F
    .byte $38,$5F,$E9,$6D,$4D,$4E,$2F,$7D         ; E927: 38 5F E9 6D 4D 4E 2F 7D
    .byte $5D,$5E,$5F,$9D,$8D,$8E,$8F,$30         ; E92F: 5D 5E 5F 9D 8D 8E 8F 30
    .byte $4C,$4D,$4E,$2F,$5C,$5D,$5E,$5F         ; E937: 4C 4D 4E 2F 5C 5D 5E 5F
    .byte $4E,$2F,$4C,$6C,$5E,$5F,$5C,$7C         ; E93F: 4E 2F 4C 6C 5E 5F 5C 7C
    .byte $4C,$4D,$4E,$6C,$5C,$5D,$5E,$7C         ; E947: 4C 4D 4E 6C 5C 5D 5E 7C
    .byte $4E,$2F,$4C,$6C,$5E,$5F,$5C,$66         ; E94F: 4E 2F 4C 6C 5E 5F 5C 66
    .byte $A4,$6F,$7E,$7F,$7D,$5D,$5E,$5F         ; E957: A4 6F 7E 7F 7D 5D 5E 5F
    .byte $6D,$2F,$4C,$4D,$7D,$5F,$5C,$5D         ; E95F: 6D 2F 4C 4D 7D 5F 5C 5D
    .byte $4C,$4D,$4E,$2F,$5C,$5D,$5E,$5F         ; E967: 4C 4D 4E 2F 5C 5D 5E 5F
    .byte $4D,$2F,$4C,$4D,$7D,$5F,$5C,$5D         ; E96F: 4D 2F 4C 4D 7D 5F 5C 5D
    .byte $30,$9F,$7F,$6E,$9E,$6D,$2F,$4C         ; E977: 30 9F 7F 6E 9E 6D 2F 4C
    .byte $6C,$7D,$5F,$5C,$66,$30,$30,$A4         ; E97F: 6C 7D 5F 5C 66 30 30 A4
    .byte $A5,$A4,$9E,$B4,$B5,$B4,$7C,$7E         ; E987: A5 A4 9E B4 B5 B4 7C 7E
    .byte $7F,$6E,$9E,$5C,$5D,$5E,$6C,$4E         ; E98F: 7F 6E 9E 5C 5D 5E 6C 4E
    .byte $2F,$4C,$7C,$5E,$5F,$5C,$66,$4C         ; E997: 2F 4C 7C 5E 5F 5C 66 4C
    .byte $4D,$4E,$6C,$8E,$8F,$8C,$9C,$30         ; E99F: 4D 4E 6C 8E 8F 8C 9C 30
    .byte $30,$7E,$9E,$30,$5E,$6C,$30,$4C         ; E9A7: 30 7E 9E 30 5E 6C 30 4C
    .byte $66,$7E,$9E,$5C,$5D,$5E,$6C,$4E         ; E9AF: 66 7E 9E 5C 5D 5E 6C 4E
    .byte $2F,$4C,$66,$5E,$5F,$5C,$5D,$6D         ; E9B7: 2F 4C 66 5E 5F 5C 5D 6D
    .byte $4D,$4E,$2F,$9D,$8F,$8C,$8D,$30         ; E9BF: 4D 4E 2F 9D 8F 8C 8D 30
    .byte $30,$79,$79,$79,$88,$87,$89,$87         ; E9C7: 30 79 79 79 88 87 89 87
    .byte $89,$00,$00,$95,$83,$00,$94,$83         ; E9CF: 89 00 00 95 83 00 94 83
    .byte $85,$00,$78,$63,$83,$00,$00,$68         ; E9D7: 85 00 78 63 83 00 00 68
    .byte $96,$00,$00,$78,$63,$00,$00,$00         ; E9DF: 96 00 00 78 63 00 00 00
    .byte $68,$00,$00,$00,$78,$30,$85,$93         ; E9E7: 68 00 00 00 78 30 85 93
    .byte $93,$93,$00,$00,$00,$70,$83,$85         ; E9EF: 93 93 00 00 00 70 83 85
    .byte $00,$70,$96,$83,$85,$70,$63,$85         ; E9F7: 00 70 96 83 85 70 63 85
    .byte $00,$70,$68,$96,$85,$93,$78,$63         ; E9FF: 00 70 68 96 85 93 78 63
    .byte $83,$83,$00,$60,$73,$96,$00,$00         ; EA07: 83 83 00 60 73 96 00 00
    .byte $61,$62,$30,$93,$92,$93,$93,$30         ; EA0F: 61 62 30 93 92 93 93 30
    .byte $30,$30,$00,$00,$3D,$00,$00,$00         ; EA17: 30 30 00 00 3D 00 00 00
    .byte $59,$00,$85,$00,$00,$70,$83,$83         ; EA1F: 59 00 85 00 00 70 83 83
    .byte $85,$70,$73,$85,$00,$70,$61,$62         ; EA27: 85 70 73 85 00 70 61 62
    .byte $85,$70,$00,$00,$71,$72,$00,$00         ; EA2F: 85 70 00 00 71 72 00 00
    .byte $00,$82,$01,$02,$31,$03,$05,$03         ; EA37: 00 82 01 02 31 03 05 03
    .byte $05,$84,$97,$93,$93,$77,$84,$84         ; EA3F: 05 84 97 93 93 77 84 84
    .byte $84,$38,$D1,$EB,$93,$92,$93,$5A         ; EA47: 84 38 D1 EB 93 92 93 5A
    .byte $30,$30,$30,$93,$92,$93,$93,$93         ; EA4F: 30 30 30 93 92 93 93 93
    .byte $93,$93,$5A,$77,$84,$84,$97,$38         ; EA57: 93 93 5A 77 84 84 97 38
    .byte $D1,$EB,$3C,$93,$93,$93,$00,$00         ; EA5F: D1 EB 3C 93 93 93 00 00
    .byte $59,$00,$00,$00,$59,$00,$00,$00         ; EA67: 59 00 00 00 59 00 00 00
    .byte $59,$00,$00,$00,$59,$00,$00,$00         ; EA6F: 59 00 00 00 59 00 00 00
    .byte $B7,$00,$93,$93,$93,$93,$64,$74         ; EA77: B7 00 93 93 93 93 64 74
    .byte $75,$65,$30,$30,$30,$6E,$6F,$7E         ; EA7F: 75 65 30 30 30 6E 6F 7E
    .byte $9E,$30,$38,$F5,$EA,$86,$86,$86         ; EA87: 9E 30 38 F5 EA 86 86 86
    .byte $86,$30,$30,$30,$30,$3C,$92,$93         ; EA8F: 86 30 30 30 30 3C 92 93
    .byte $93,$4C,$4D,$4E,$6C,$5C,$5D,$5E         ; EA97: 93 4C 4D 4E 6C 5C 5D 5E
    .byte $5F,$4C,$2F,$4C,$76,$5E,$5F,$5C         ; EA9F: 5F 4C 2F 4C 76 5E 5F 5C
    .byte $B4,$A0,$B1,$B2,$A1,$30,$30,$30         ; EAA7: B4 A0 B1 B2 A1 30 30 30
    .byte $A4,$A5,$A4,$CB,$B4,$B5,$B4,$E6         ; EAAF: A4 A5 A4 CB B4 B5 B4 E6
    .byte $7D,$4D,$4E,$2F,$6D,$5D,$5E,$5F         ; EAB7: 7D 4D 4E 2F 6D 5D 5E 5F
    .byte $AF,$2F,$4C,$4D,$5E,$5F,$5C,$5D         ; EABF: AF 2F 4C 4D 5E 5F 5C 5D
    .byte $30,$A0,$B1,$B2,$B3,$30,$30,$B0         ; EAC7: 30 A0 B1 B2 B3 30 30 B0
    .byte $B1,$B2,$A1,$30,$30,$00,$51,$50         ; EACF: B1 B2 A1 30 30 00 51 50
    .byte $51,$00,$50,$51,$50,$4C,$4D,$4E         ; EAD7: 51 00 50 51 50 4C 4D 4E
    .byte $66,$38,$0A,$EB,$8E,$8F,$8C,$8D         ; EADF: 66 38 0A EB 8E 8F 8C 8D
    .byte $38,$F5,$EA,$8E,$8F,$8D,$9C,$38         ; EAE7: 38 F5 EA 8E 8F 8D 9C 38
    .byte $F5,$EA,$A0,$B1,$B2,$A1,$30,$01         ; EAEF: F5 EA A0 B1 B2 A1 30 01
    .byte $02,$01,$02,$03,$05,$03,$05,$30         ; EAF7: 02 01 02 03 05 03 05 30
    .byte $30,$DF,$B1,$EE,$EE,$E6,$30,$7E         ; EAFF: 30 DF B1 EE EE E6 30 7E
    .byte $7F,$6E,$9E,$5C,$5D,$5E,$6C,$4E         ; EB07: 7F 6E 9E 5C 5D 5E 6C 4E
    .byte $2F,$4C,$7C,$5E,$5F,$5C,$6C,$9F         ; EB0F: 2F 4C 7C 5E 5F 5C 6C 9F
    .byte $6F,$7E,$7F,$6D,$5D,$5E,$5F,$7D         ; EB17: 6F 7E 7F 6D 5D 5E 5F 7D
    .byte $2F,$4C,$4D,$6D,$5F,$5C,$5D,$30         ; EB1F: 2F 4C 4D 6D 5F 5C 5D 30
    .byte $30,$38,$D1,$EB,$5A,$00,$00,$3C         ; EB27: 30 38 D1 EB 5A 00 00 3C
    .byte $30,$30,$30,$93,$93,$5A,$00,$93         ; EB2F: 30 30 30 93 93 5A 00 93
    .byte $92,$93,$93,$38,$65,$EA,$00,$00         ; EB37: 92 93 93 38 65 EA 00 00
    .byte $00,$70,$00,$00,$00,$70,$00,$00         ; EB3F: 00 70 00 00 00 70 00 00
    .byte $00,$70,$00,$00,$00,$70,$38,$D1         ; EB47: 00 70 00 00 00 70 38 D1
    .byte $EB,$00,$00,$00,$BE,$00,$00,$BE         ; EB4F: EB 00 00 00 BE 00 00 BE
    .byte $3E,$00,$BE,$3E,$83,$BE,$3E,$85         ; EB57: 3E 00 BE 3E 83 BE 3E 85
    .byte $00,$3E,$85,$30,$85,$00,$30,$83         ; EB5F: 00 3E 85 30 85 00 30 83
    .byte $85,$30,$30,$00,$94,$83,$83,$00         ; EB67: 85 30 30 00 94 83 83 00
    .byte $00,$94,$63,$94,$83,$73,$83,$00         ; EB6F: 00 94 63 94 83 73 83 00
    .byte $94,$83,$BD,$93,$CE,$63,$BC,$84         ; EB77: 94 83 BD 93 CE 63 BC 84
    .byte $84,$84,$CC,$91,$91,$91,$02,$03         ; EB7F: 84 84 CC 91 91 91 02 03
    .byte $05,$03,$05,$00,$00,$B7,$94,$00         ; EB87: 05 03 05 00 00 B7 94 00
    .byte $CE,$83,$83,$00,$CE,$83,$AD,$93         ; EB8F: CE 83 83 00 CE 83 AD 93
    .byte $CE,$BD,$00,$73,$83,$BC,$00,$83         ; EB97: CE BD 00 73 83 BC 00 83
    .byte $83,$CC,$00,$AD,$30,$30,$00,$CE         ; EB9F: 83 CC 00 AD 30 30 00 CE
    .byte $73,$AE,$00,$00,$CE,$AE,$00,$00         ; EBA7: 73 AE 00 00 CE AE 00 00
    .byte $CE,$73,$00,$00,$94,$AE,$93,$DE         ; EBAF: CE 73 00 00 94 AE 93 DE
    .byte $83,$AD,$00,$CE,$BD,$00,$CE,$83         ; EBB7: 83 AD 00 CE BD 00 CE 83
    .byte $BC,$00,$94,$63,$CC,$00,$3C,$38         ; EBBF: BC 00 94 63 CC 00 3C 38
    .byte $CA,$EB,$93,$93,$93,$93,$AC,$84         ; EBC7: CA EB 93 93 93 93 AC 84
    .byte $84,$84,$91,$91,$91,$91,$03,$05         ; EBCF: 84 84 91 91 91 91 03 05
    .byte $03,$05,$63,$BD,$30,$CD,$BC,$30         ; EBD7: 03 05 63 BD 30 CD BC 30
    .byte $30,$30,$00,$6D,$4E,$2F,$00,$7D         ; EBDF: 30 30 00 6D 4E 2F 00 7D
    .byte $5E,$5F,$00,$6D,$4C,$4D,$00,$7D         ; EBE7: 5E 5F 00 6D 4C 4D 00 7D
    .byte $5C,$5D,$30,$30,$30,$7F,$6E,$7F         ; EBEF: 5C 5D 30 30 30 7F 6E 7F
    .byte $9E,$00,$F8,$6D,$4D,$00,$59,$9D         ; EBF7: 9E 00 F8 6D 4D 00 59 9D
    .byte $8F,$00,$B7,$30,$00,$BB,$58,$47         ; EBFF: 8F 00 B7 30 00 BB 58 47
DrawHudItem:
    ; HUD 道具绘制：STX $3E/STY $3F 保存，$35/$36=$2042+A*2 为 PPU 地址，$EC84[A*4] 取 4 tile 经 PpuBuf 写入；A&$0F==9 时另把 $05F2 转两位 BCD 写入
    STX $3E                     ; EC07: 86 3E
    STY $3F                     ; EC09: 84 3F
    STA TmpPtr                  ; EC0B: 85 20
    TAX                         ; EC0D: AA
    ASL A                       ; EC0E: 0A
    CLC                         ; EC0F: 18
    ADC #$42                    ; EC10: 69 42
    STA $35                     ; EC12: 85 35
    LDA #$20                    ; EC14: A9 20
    STA $36                     ; EC16: 85 36
    LDY #$28                    ; EC18: A0 28
    LDA TmpPtr                  ; EC1A: A5 20
    BMI LEC21                   ; EC1C: 30 03
    ASL A                       ; EC1E: 0A
    ASL A                       ; EC1F: 0A
    TAY                         ; EC20: A8
LEC21:
    LDA #$01                    ; EC21: A9 01
    STA $21                     ; EC23: 85 21
LEC25:
    JSR $BFA4                   ; EC25: 20 A4 BF  -> Bank0:PpuBufPutAddr
    INX                         ; EC28: E8
    JSR LEC7B                   ; EC29: 20 7B EC
    JSR LEC7B                   ; EC2C: 20 7B EC
    LDA $21                     ; EC2F: A5 21
    BNE LEC68                   ; EC31: D0 35
    LDA TmpPtr                  ; EC33: A5 20
    AND #$0F                    ; EC35: 29 0F
    CMP #$09                    ; EC37: C9 09
    BNE LEC68                   ; EC39: D0 2D
    STX PpuBufIdx               ; EC3B: 86 11
    LDY #$30                    ; EC3D: A0 30
    LDA SlingAmmo               ; EC3F: AD F2 05
LEC42:
    CMP #$0A                    ; EC42: C9 0A
    BCC LEC4B                   ; EC44: 90 05
    SBC #$0A                    ; EC46: E9 0A
    INY                         ; EC48: C8
    BNE LEC42                   ; EC49: D0 F7
LEC4B:
    CPY #$30                    ; EC4B: C0 30
    BEQ LEC51                   ; EC4D: F0 02
    ORA #$30                    ; EC4F: 09 30
LEC51:
    CMP #$00                    ; EC51: C9 00
    BEQ LEC57                   ; EC53: F0 02
    ORA #$30                    ; EC55: 09 30
LEC57:
    STA TmpPtr                  ; EC57: 85 20
    TYA                         ; EC59: 98
    CMP #$30                    ; EC5A: C9 30
    BNE LEC60                   ; EC5C: D0 02
    LDA #$00                    ; EC5E: A9 00
LEC60:
    JSR $870A                   ; EC60: 20 0A 87  -> Bank0:PpuBufPut
    LDA TmpPtr                  ; EC63: A5 20
    JSR $870A                   ; EC65: 20 0A 87  -> Bank0:PpuBufPut
LEC68:
    JSR $8714                   ; EC68: 20 14 87  -> Bank0:PpuBufPutFFAtX
    LDA #$20                    ; EC6B: A9 20
    CLC                         ; EC6D: 18
    ADC $35                     ; EC6E: 65 35
    STA $35                     ; EC70: 85 35
    DEC $21                     ; EC72: C6 21
    BPL LEC25                   ; EC74: 10 AF
    LDX $3E                     ; EC76: A6 3E
    LDY $3F                     ; EC78: A4 3F
    RTS                         ; EC7A: 60
LEC7B:
    LDA $EC84,Y                 ; EC7B: B9 84 EC
    INY                         ; EC7E: C8
    STA PpuBuf,X                ; EC7F: 9D 00 06
    INX                         ; EC82: E8
    RTS                         ; EC83: 60
    .byte $B4,$B5,$B6,$B7,$B4,$B5,$B6,$B7         ; EC84: B4 B5 B6 B7 B4 B5 B6 B7
    .byte $94,$95,$96,$97,$90,$91,$92,$93         ; EC8C: 94 95 96 97 90 91 92 93
    .byte $A4,$A5,$A6,$A7,$80,$81,$82,$83         ; EC94: A4 A5 A6 A7 80 81 82 83
    .byte $84,$85,$86,$87,$6E,$6F,$7E,$7F         ; EC9C: 84 85 86 87 6E 6F 7E 7F
    .byte $A8,$A9,$AA,$AB,$B8,$B9,$BA,$BB         ; ECA4: A8 A9 AA AB B8 B9 BA BB
    .byte $00,$00,$00,$00                         ; ECAC: 00 00 00 00
LoadScreen0:
    ; A=0 选 $ED34[0] 流（BEQ 恒跳越过 $ECB6，不写 $1E），PpuOff 后 RLE 解压填 nametable $2000；尾 JMP $8136(bank0 窗口)
    LDA #$00                    ; ECB0: A9 00
    BEQ LECB8                   ; ECB2: F0 04
LoadScreen2:
    ; 同上，A=2 在 $ECB6 写 MapperShadow（仅本路径写影子寄存器），取 $ED34[2] 流；L925C 建屏路径调用
    LDA #$02                    ; ECB4: A9 02
    STA MapperShadow            ; ECB6: 85 1E
LECB8:
    JSR LECC2                   ; ECB8: 20 C2 EC
    JMP $8136                   ; ECBB: 4C 36 81  -> Bank0:RenderDelay5NmiOn
LECBE:
    LDA #$04                    ; ECBE: A9 04
    BNE LECB8                   ; ECC0: D0 F6
LECC2:
    TAX                         ; ECC2: AA
    LDA $ED34,X                 ; ECC3: BD 34 ED
    STA $23                     ; ECC6: 85 23
    LDA $ED35,X                 ; ECC8: BD 35 ED
    STA JoyBits                 ; ECCB: 85 24
    JSR $8115                   ; ECCD: 20 15 81  -> Bank0:PpuOff
    STA PpuBufIdx               ; ECD0: 85 11
    LDX #$20                    ; ECD2: A2 20
    LDY #$00                    ; ECD4: A0 00
    LDA PPU_STATUS              ; ECD6: AD 02 20
    STX PPU_ADDR                ; ECD9: 8E 06 20
    STY PPU_ADDR                ; ECDC: 8C 06 20
    STY TmpPtr                  ; ECDF: 84 20
LECE1:
    LDY TmpPtr                  ; ECE1: A4 20
    CPY #$08                    ; ECE3: C0 08
    BEQ LECF9                   ; ECE5: F0 12
    LDA ($23),Y                 ; ECE7: B1 23
    STA $21                     ; ECE9: 85 21
    INY                         ; ECEB: C8
    LDA ($23),Y                 ; ECEC: B1 23
    STA $22                     ; ECEE: 85 22
    INY                         ; ECF0: C8
    STY TmpPtr                  ; ECF1: 84 20
    JSR LECFA                   ; ECF3: 20 FA EC
    JMP LECE1                   ; ECF6: 4C E1 EC
LECF9:
    RTS                         ; ECF9: 60
LECFA:
    LDY #$00                    ; ECFA: A0 00
LECFC:
    LDA ($21),Y                 ; ECFC: B1 21
    CMP #$34                    ; ECFE: C9 34
    BEQ LED15                   ; ED00: F0 13
    CMP #$39                    ; ED02: C9 39
    BEQ LED14                   ; ED04: F0 0E
    CMP #$35                    ; ED06: C9 35
    BEQ LED24                   ; ED08: F0 1A
    CMP #$36                    ; ED0A: C9 36
    BEQ LED2C                   ; ED0C: F0 1E
    STA PPU_DATA                ; ED0E: 8D 07 20
LED11:
    INY                         ; ED11: C8
    BNE LECFC                   ; ED12: D0 E8
LED14:
    RTS                         ; ED14: 60
LED15:
    INY                         ; ED15: C8
    LDA ($21),Y                 ; ED16: B1 21
    INY                         ; ED18: C8
    TAX                         ; ED19: AA
    LDA ($21),Y                 ; ED1A: B1 21
LED1C:
    STA PPU_DATA                ; ED1C: 8D 07 20
    DEX                         ; ED1F: CA
    BNE LED1C                   ; ED20: D0 FA
    BEQ LED11                   ; ED22: F0 ED
LED24:
    INY                         ; ED24: C8
    LDA ($21),Y                 ; ED25: B1 21
    TAX                         ; ED27: AA
    LDA #$00                    ; ED28: A9 00
    BEQ LED1C                   ; ED2A: F0 F0
LED2C:
    INY                         ; ED2C: C8
    LDA ($21),Y                 ; ED2D: B1 21
    TAX                         ; ED2F: AA
    LDA #$D8                    ; ED30: A9 D8
    BNE LED1C                   ; ED32: D0 E8
    .byte $3C,$ED,$53,$ED,$A0,$EE,$3C,$ED         ; ED34: 3C ED 53 ED A0 EE 3C ED
    .byte $44,$ED,$4D,$ED,$44,$ED,$4D,$ED         ; ED3C: 44 ED 4D ED 44 ED 4D ED
    .byte $35,$E0,$35,$E0,$35,$E0,$35,$60         ; ED44: 35 E0 35 E0 35 E0 35 60
    .byte $39,$35,$C0,$34,$40,$55,$39,$5B         ; ED4C: 39 35 C0 34 40 55 39 5B
    .byte $ED,$A0,$ED,$2E,$EE,$5F,$EE,$36         ; ED54: ED A0 ED 2E EE 5F EE 36
    .byte $64,$E2,$BE,$BE,$E2,$BE,$BE,$E2         ; ED5C: 64 E2 BE BE E2 BE BE E2
    .byte $E2,$BE,$BE,$BE,$E2,$BE,$E2,$34         ; ED64: E2 BE BE BE E2 BE E2 34
    .byte $04,$BE,$E2,$BE,$E2,$BE,$BE,$E2         ; ED6C: 04 BE E2 BE E2 BE BE E2
    .byte $36,$07,$E0,$35,$18,$E1,$36,$06         ; ED74: 36 07 E0 35 18 E1 36 06
    .byte $BC,$35,$08,$E3,$E4,$35,$04,$F4         ; ED7C: BC 35 08 E3 E4 35 04 F4
    .byte $35,$09,$E1,$36,$06,$BC,$35,$08         ; ED84: 35 09 E1 36 06 BC 35 08
    .byte $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7         ; ED8C: D0 D1 D2 D3 D4 D5 D6 D7
    .byte $35,$08,$BD,$36,$06,$E0,$35,$18         ; ED94: 35 08 BD 36 06 E0 35 18
    .byte $BD,$36,$06,$39,$BC,$35,$03,$D0         ; ED9C: BD 36 06 39 BC 35 03 D0
    .byte $D1,$D2,$D3,$D4,$D5,$D7,$D6,$D7         ; EDA4: D1 D2 D3 D4 D5 D7 D6 D7
    .byte $D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF         ; EDAC: D8 D9 DA DB DC DD DE DF
    .byte $35,$04,$E1,$36,$06,$BC,$35,$03         ; EDB4: 35 04 E1 36 06 BC 35 03
    .byte $E0,$E1,$E2,$E3,$E4,$E5,$E7,$E6         ; EDBC: E0 E1 E2 E3 E4 E5 E7 E6
    .byte $E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE         ; EDC4: E7 E8 E9 EA EB EC ED EE
    .byte $EF,$35,$04,$E1,$36,$06,$BC,$35         ; EDCC: EF 35 04 E1 36 06 BC 35
    .byte $06,$F3,$F4,$F5,$F7,$F6,$F7,$F8         ; EDD4: 06 F3 F4 F5 F7 F6 F7 F8
    .byte $F9,$FA,$FB,$FC,$FD,$FE,$FF,$F0         ; EDDC: F9 FA FB FC FD FE FF F0
    .byte $35,$03,$BD,$36,$06,$E0,$35,$18         ; EDE4: 35 03 BD 36 06 E0 35 18
    .byte $BD,$36,$06,$BC,$35,$10,$DA,$35         ; EDEC: BD 36 06 BC 35 10 DA 35
    .byte $07,$BD,$36,$06,$BC,$35,$0F,$DB         ; EDF4: 07 BD 36 06 BC 35 0F DB
    .byte $DC,$DD,$DE,$DF,$35,$04,$E1,$36         ; EDFC: DC DD DE DF 35 04 E1 36
    .byte $06,$BC,$35,$08,$E5,$E6,$00,$E7         ; EE04: 06 BC 35 08 E5 E6 00 E7
    .byte $E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF         ; EE0C: E8 E9 EA EB EC ED EE EF
    .byte $35,$04,$BD,$36,$06,$BC,$35,$08         ; EE14: 35 04 BD 36 06 BC 35 08
    .byte $F5,$F6,$D9,$F7,$F8,$F9,$FA,$FB         ; EE1C: F5 F6 D9 F7 F8 F9 FA FB
    .byte $FC,$FD,$FE,$FF,$35,$04,$BD,$36         ; EE24: FC FD FE FF 35 04 BD 36
    .byte $06,$39,$E0,$35,$18,$BD,$36,$06         ; EE2C: 06 39 E0 35 18 BD 36 06
    .byte $BC,$35,$18,$BD,$36,$06,$E0,$35         ; EE34: BC 35 18 BD 36 06 E0 35
    .byte $18,$E1,$36,$06,$BC,$35,$18,$BD         ; EE3C: 18 E1 36 06 BC 35 18 BD
    .byte $36,$06,$BC,$35,$18,$E1,$36,$06         ; EE44: 36 06 BC 35 18 E1 36 06
    .byte $E0,$35,$18,$BD,$36,$06,$BC,$35         ; EE4C: E0 35 18 BD 36 06 BC 35
    .byte $18,$BD,$36,$06,$E0,$35,$18,$E1         ; EE54: 18 BD 36 06 E0 35 18 E1
    .byte $36,$07,$39,$F0,$BF,$BF,$BF,$F0         ; EE5C: 36 07 39 F0 BF BF BF F0
    .byte $BF,$F0,$BF,$BF,$BF,$F0,$BF,$BF         ; EE64: BF F0 BF BF BF F0 BF BF
    .byte $F0,$BF,$BF,$F0,$34,$04,$BF,$F0         ; EE6C: F0 BF BF F0 34 04 BF F0
    .byte $BF,$F0,$34,$A4,$D8,$34,$09,$55         ; EE74: BF F0 34 A4 D8 34 09 55
    .byte $34,$06,$AA,$55,$55,$34,$06,$00         ; EE7C: 34 06 AA 55 55 34 06 00
    .byte $34,$0A,$55,$34,$06,$5A,$55,$55         ; EE84: 34 0A 55 34 06 5A 55 55
    .byte $34,$06,$AA,$34,$11,$55,$36,$E0         ; EE8C: 34 06 AA 34 11 55 36 E0
    .byte $36,$E0,$36,$E0,$36,$60,$36,$C0         ; EE94: 36 E0 36 E0 36 60 36 C0
    .byte $34,$40,$55,$39,$A8,$EE,$BA,$EE         ; EE9C: 34 40 55 39 A8 EE BA EE
    .byte $D3,$EE,$30,$EF,$35,$60,$34,$20         ; EEA4: D3 EE 30 EF 35 60 34 20
    .byte $AE,$34,$20,$AD,$34,$20,$AC,$34         ; EEAC: AE 34 20 AD 34 20 AC 34
    .byte $20,$AB,$34,$20,$AA,$39,$34,$20         ; EEB4: 20 AB 34 20 AA 39 34 20
    .byte $A9,$34,$20,$A8,$34,$20,$A7,$34         ; EEBC: A9 34 20 A8 34 20 A7 34
    .byte $20,$A6,$34,$20,$A5,$34,$20,$A4         ; EEC4: 20 A6 34 20 A5 34 20 A4
    .byte $34,$20,$A3,$34,$20,$A2,$39,$34         ; EECC: 34 20 A3 34 20 A2 39 34
    .byte $20,$A1,$34,$0A,$A0,$AF,$BF,$34         ; EED4: 20 A1 34 0A A0 AF BF 34
    .byte $14,$A0,$C6,$C7,$34,$07,$B0,$D0         ; EEDC: 14 A0 C6 C7 34 07 B0 D0
    .byte $B2,$B3,$D0,$34,$10,$B0,$B7,$B8         ; EEE4: B2 B3 D0 34 10 B0 B7 B8
    .byte $B9,$C4,$C9,$35,$08,$C0,$C1,$35         ; EEEC: B9 C4 C9 35 08 C0 C1 35
    .byte $10,$BA,$BB,$BB,$BB,$CB,$CA,$CB         ; EEF4: 10 BA BB BB BB CB CA CB
    .byte $CA,$CB,$CC,$CD,$B1,$EC,$B1,$EC         ; EEFC: CA CB CC CD B1 EC B1 EC
    .byte $B1,$EC,$B1,$EC,$B1,$EC,$B1,$EC         ; EF04: B1 EC B1 EC B1 EC B1 EC
    .byte $B1,$EC,$B1,$EC,$B1,$EC,$B1,$EC         ; EF0C: B1 EC B1 EC B1 EC B1 EC
    .byte $B1,$BC,$34,$08,$BB,$D1,$D2,$35         ; EF14: B1 BC 34 08 BB D1 D2 35
    .byte $14,$BE,$34,$04,$BB,$D4,$D1,$D4         ; EF1C: 14 BE 34 04 BB D4 D1 D4
    .byte $D3,$D4,$D2,$35,$16,$C2,$C3,$C4         ; EF24: D3 D4 D2 35 16 C2 C3 C4
    .byte $C5,$35,$20,$39,$B4,$B5,$B4,$B5         ; EF2C: C5 35 20 39 B4 B5 B4 B5
    .byte $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5         ; EF34: B4 B5 B4 B5 B4 B5 B4 B5
    .byte $B4,$B5,$B4,$B5,$DD,$DE,$B4,$B5         ; EF3C: B4 B5 B4 B5 DD DE B4 B5
    .byte $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5         ; EF44: B4 B5 B4 B5 B4 B5 B4 B5
    .byte $B4,$B5,$B4,$B5,$34,$0B,$B6,$D8         ; EF4C: B4 B5 B4 B5 34 0B B6 D8
    .byte $B6,$D8,$B6,$D8,$CE,$CF,$ED,$B6         ; EF54: B6 D8 B6 D8 CE CF ED B6
    .byte $D8,$B6,$D8,$D6,$34,$12,$B6,$D5         ; EF5C: D8 B6 D8 D6 34 12 B6 D5
    .byte $DA,$D9,$DA,$D9,$DA,$DF,$E0,$EE         ; EF64: DA D9 DA D9 DA DF E0 EE
    .byte $F0,$DA,$D9,$DA,$D7,$34,$13,$B6         ; EF6C: F0 DA D9 DA D7 34 13 B6
    .byte $DB,$B6,$DC,$B6,$EB,$E1,$E2,$EF         ; EF74: DB B6 DC B6 EB E1 E2 EF
    .byte $B6,$BD,$B6,$DB,$34,$14,$B6,$E3         ; EF7C: B6 BD B6 DB 34 14 B6 E3
    .byte $E4,$E3,$E4,$E3,$E7,$E8,$E3,$E4         ; EF84: E4 E3 E4 E3 E7 E8 E3 E4
    .byte $F1,$E4,$E3,$E4,$34,$13,$B6,$E5         ; EF8C: F1 E4 E3 E4 34 13 B6 E5
    .byte $E6,$E5,$E6,$E5,$E9,$EA,$E5,$E6         ; EF94: E6 E5 E6 E5 E9 EA E5 E6
    .byte $E5,$E6,$E5,$E6,$34,$08,$B6,$35         ; EF9C: E5 E6 E5 E6 34 08 B6 35
    .byte $10,$34,$08,$F0,$34,$08,$FF,$34         ; EFA4: 10 34 08 F0 34 08 FF 34
    .byte $08,$5F,$34,$08,$55,$34,$08,$AA         ; EFAC: 08 5F 34 08 55 34 08 AA
    .byte $34,$08,$0A,$39                         ; EFB4: 34 08 0A 39
TitleSeq:
    ; 标题/演示序列分发：LDA TitlePhase($0110) 经 DispatchJump 走 $EFBE 表（5 阶段：建屏/置标题物体/延时/上移卷动/收尾转 GameStart）
    LDA TitlePhase              ; EFB8: AD 10 01
    JSR $859A                   ; EFBB: 20 9A 85  -> Bank0:DispatchJump
    .byte $C8,$EF,$E7,$EF,$13,$F0,$20,$F0         ; EFBE: C8 EF E7 EF 13 F0 20 F0
    .byte $72,$F0                                 ; EFC6: 72 F0
LEFC8:
    JSR $8956                   ; EFC8: 20 56 89  -> Bank0:ClearLoadScreen0
    LDA #$02                    ; EFCB: A9 02
    STA MapperShadow            ; EFCD: 85 1E
    LDA #$00                    ; EFCF: A9 00
    STA StageId                 ; EFD1: 85 80
    STA ScrollX                 ; EFD3: 85 18
    LDA #$05                    ; EFD5: A9 05
    JSR $86AD                   ; EFD7: 20 AD 86  -> Bank0:PpuBufPutStr
    LDA #$1B                    ; EFDA: A9 1B
    JSR $86AD                   ; EFDC: 20 AD 86  -> Bank0:PpuBufPutStr
    INC TitlePhase              ; EFDF: EE 10 01
    LDY #$13                    ; EFE2: A0 13
    JMP $861C                   ; EFE4: 4C 1C 86  -> Bank0:SoundCmdC0
LEFE7:
    JSR LECBE                   ; EFE7: 20 BE EC
    LDA #$00                    ; EFEA: A9 00
    STA ObjXPage                ; EFEC: 8D 10 04
    STA ObjXFrac                ; EFEF: 8D 90 04
    LDA #$80                    ; EFF2: A9 80
    STA ObjY                    ; EFF4: 8D 60 04
    LDA #$C0                    ; EFF7: A9 C0
    STA ObjX                    ; EFF9: 8D 70 04
    LDA #$6E                    ; EFFC: A9 6E
    STA ObjSprite               ; EFFE: 85 70
    LDA #$20                    ; F000: A9 20
    STA ObjSpeedX               ; F002: 8D C0 04
    LDA #$02                    ; F005: A9 02
    STA ObjSpeedY               ; F007: 8D D0 04
    LDA #$00                    ; F00A: A9 00
    STA ObjTimer                ; F00C: 8D 30 04
    INC TitlePhase              ; F00F: EE 10 01
    RTS                         ; F012: 60
LF013:
    LDA #$90                    ; F013: A9 90
    STA PpuCtrlShadow           ; F015: 85 0E
    DEC ObjTimer                ; F017: CE 30 04
    BNE $F01E                   ; F01A: D0 02
    INC TitlePhase              ; F01C: EE 10 01
    RTS                         ; F01F: 60
LF020:
    JSR $99DC                   ; F020: 20 DC 99  -> Bank0:PauseCheck
    LDA PauseFlag               ; F023: A5 1A
    BNE LF071                   ; F025: D0 4A
    LDA ObjYFrac                ; F027: AD 80 04
    SEC                         ; F02A: 38
    SBC ObjSpeedY               ; F02B: ED D0 04
    STA ObjYFrac                ; F02E: 8D 80 04
    LDA ObjY                    ; F031: AD 60 04
    SBC #$00                    ; F034: E9 00
    STA ObjY                    ; F036: 8D 60 04
    LDA ObjXFrac                ; F039: AD 90 04
    SEC                         ; F03C: 38
    SBC ObjSpeedX               ; F03D: ED C0 04
    STA ObjXFrac                ; F040: 8D 90 04
    LDA ObjX                    ; F043: AD 70 04
    SBC #$00                    ; F046: E9 00
    STA ObjX                    ; F048: 8D 70 04
    CMP #$10                    ; F04B: C9 10
    BCS LF071                   ; F04D: B0 22
    JSR $8956                   ; F04F: 20 56 89  -> Bank0:ClearLoadScreen0
    INC TitlePhase              ; F052: EE 10 01
    LDX #$0F                    ; F055: A2 0F
    LDA #$19                    ; F057: A9 19
    JSR $8718                   ; F059: 20 18 87  -> Bank0:PpuBufPutStrChain
    JSR $83EB                   ; F05C: 20 EB 83  -> Bank0:ModeTimerSet256
    LDA #$02                    ; F05F: A9 02
    STA MapperShadow            ; F061: 85 1E
    LDA #$88                    ; F063: A9 88
    STA PpuCtrlShadow           ; F065: 85 0E
    LDA #$09                    ; F067: A9 09
    JSR $86AD                   ; F069: 20 AD 86  -> Bank0:PpuBufPutStr
    LDA #$05                    ; F06C: A9 05
    JSR $84E5                   ; F06E: 20 E5 84  -> Bank0:L84E5
LF071:
    RTS                         ; F071: 60
LF072:
    JSR $836D                   ; F072: 20 6D 83  -> Bank0:ModeTimerTick
    BNE LF071                   ; F075: D0 FA
    LDA #$00                    ; F077: A9 00
    STA $23                     ; F079: 85 23
    STA $22                     ; F07B: 85 22
    STA TitlePhase              ; F07D: 8D 10 01
    STA $A5                     ; F080: 85 A5
    STA $05DE                   ; F082: 8D DE 05
    STA KeyCount                ; F085: 8D DF 05
    STA $05D6                   ; F088: 8D D6 05
    JMP $8337                   ; F08B: 4C 37 83  -> Bank0:GameStart
SoundCmd:
    ; 声音命令入口：A=命令号，高半字节查 $F177 选通道组，特定 ID 映射 $40-$46→$DF；体内写 $4000-$4008
    STX $EF                     ; F08E: 86 EF
    STY $EE                     ; F090: 84 EE
    STA $ED                     ; F092: 85 ED
    LSR A                       ; F094: 4A
    LSR A                       ; F095: 4A
    LSR A                       ; F096: 4A
    LSR A                       ; F097: 4A
    AND #$0C                    ; F098: 29 0C
    STA $E8                     ; F09A: 85 E8
    LSR A                       ; F09C: 4A
    LSR A                       ; F09D: 4A
    TAY                         ; F09E: A8
    LDX $F177,Y                 ; F09F: BE 77 F1
    LDA $ED                     ; F0A2: A5 ED
    CMP #$31                    ; F0A4: C9 31
    BEQ LF0C4                   ; F0A6: F0 1C
    CMP #$3B                    ; F0A8: C9 3B
    BEQ LF0C8                   ; F0AA: F0 1C
    CMP #$7A                    ; F0AC: C9 7A
    BEQ LF0CC                   ; F0AE: F0 1C
    CMP #$BD                    ; F0B0: C9 BD
    BEQ LF0D0                   ; F0B2: F0 1C
    CMP #$29                    ; F0B4: C9 29
    BEQ LF0D4                   ; F0B6: F0 1C
    CMP #$4F                    ; F0B8: C9 4F
    BEQ LF0D8                   ; F0BA: F0 1C
    CMP #$8F                    ; F0BC: C9 8F
    BNE LF0DE                   ; F0BE: D0 1E
    LDA #$46                    ; F0C0: A9 46
    BNE LF0DA                   ; F0C2: D0 16
LF0C4:
    LDA #$40                    ; F0C4: A9 40
    BNE LF0DA                   ; F0C6: D0 12
LF0C8:
    LDA #$41                    ; F0C8: A9 41
    BNE LF0DA                   ; F0CA: D0 0E
LF0CC:
    LDA #$42                    ; F0CC: A9 42
    BNE LF0DA                   ; F0CE: D0 0A
LF0D0:
    LDA #$43                    ; F0D0: A9 43
    BNE LF0DA                   ; F0D2: D0 06
LF0D4:
    LDA #$44                    ; F0D4: A9 44
    BNE LF0DA                   ; F0D6: D0 02
LF0D8:
    LDA #$45                    ; F0D8: A9 45
LF0DA:
    STA $DF                     ; F0DA: 85 DF
    BNE LF0E2                   ; F0DC: D0 04
LF0DE:
    AND #$3F                    ; F0DE: 29 3F
    BEQ LF151                   ; F0E0: F0 6F
LF0E2:
    CMP $02,X                   ; F0E2: D5 02
    BCC LF110                   ; F0E4: 90 2A
    BNE LF0F0                   ; F0E6: D0 08
    CMP #$14                    ; F0E8: C9 14
    BEQ LF110                   ; F0EA: F0 24
    CMP #$07                    ; F0EC: C9 07
    BEQ LF110                   ; F0EE: F0 20
LF0F0:
    STA $ED                     ; F0F0: 85 ED
    CMP #$32                    ; F0F2: C9 32
    BEQ LF106                   ; F0F4: F0 10
    CMP #$30                    ; F0F6: C9 30
    BEQ LF106                   ; F0F8: F0 0C
    CMP #$3A                    ; F0FA: C9 3A
    BEQ LF106                   ; F0FC: F0 08
    CMP #$1B                    ; F0FE: C9 1B
    BEQ LF106                   ; F100: F0 04
    CMP #$21                    ; F102: C9 21
    BNE LF113                   ; F104: D0 0D
LF106:
    LDY $03                     ; F106: A4 03
    BNE LF11B                   ; F108: D0 11
    LDY #$01                    ; F10A: A0 01
    STY $DE                     ; F10C: 84 DE
    BNE LF11B                   ; F10E: D0 0B
LF110:
    JMP LF171                   ; F110: 4C 71 F1
LF113:
    CMP #$3D                    ; F113: C9 3D
    BNE LF11B                   ; F115: D0 04
    LDY #$00                    ; F117: A0 00
    STY $DE                     ; F119: 84 DE
LF11B:
    LDY #$00                    ; F11B: A0 00
    STY $02,X                   ; F11D: 94 02
    ASL A                       ; F11F: 0A
    TAY                         ; F120: A8
    LDA $F4CF,Y                 ; F121: B9 CF F4
    STA $03,X                   ; F124: 95 03
    STA $F2                     ; F126: 85 F2
    LDA $F4D0,Y                 ; F128: B9 D0 F4
    STA NmiBusy,X               ; F12B: 95 04
    STA $F3                     ; F12D: 85 F3
    LDY #$01                    ; F12F: A0 01
    STY GameMode,X              ; F131: 94 00
    STY SubMode,X               ; F133: 94 01
    DEY                         ; F135: 88
    STY $06,X                   ; F136: 94 06
    CPX #$D2                    ; F138: E0 D2
    BEQ LF146                   ; F13A: F0 0A
    STY JoyHeld,X               ; F13C: 94 07
    CPX #$E3                    ; F13E: E0 E3
    BEQ LF146                   ; F140: F0 04
    STY RenderDelay,X           ; F142: 94 0C
    STY $0B,X                   ; F144: 94 0B
LF146:
    LDA ($F2),Y                 ; F146: B1 F2
    AND #$F0                    ; F148: 29 F0
    CMP #$20                    ; F14A: C9 20
    BEQ LF14F                   ; F14C: F0 01
    INY                         ; F14E: C8
LF14F:
    STY FrameCnt,X              ; F14F: 94 09
LF151:
    LDA #$00                    ; F151: A9 00
    LDY $E8                     ; F153: A4 E8
    CPY #$08                    ; F155: C0 08
    BEQ LF15B                   ; F157: F0 02
    LDA #$30                    ; F159: A9 30
LF15B:
    STA $4000,Y                 ; F15B: 99 00 40
    STA $4001,Y                 ; F15E: 99 01 40
    LDA $DF                     ; F161: A5 DF
    BNE LF169                   ; F163: D0 04
    LDA $ED                     ; F165: A5 ED
    AND #$3F                    ; F167: 29 3F
LF169:
    STA $02,X                   ; F169: 95 02
    LDA #$00                    ; F16B: A9 00
    STA $DF                     ; F16D: 85 DF
    LDA $02,X                   ; F16F: B5 02
LF171:
    LDX $EF                     ; F171: A6 EF
    LDY $EE                     ; F173: A4 EE
    SEC                         ; F175: 38
    RTS                         ; F176: 60
    .byte $B0,$C1,$D2,$E3                         ; F177: B0 C1 D2 E3
LF17B:
    LDA $02,X                   ; F17B: B5 02
    CMP #$33                    ; F17D: C9 33
    BEQ LF189                   ; F17F: F0 08
    CMP #$1C                    ; F181: C9 1C
    BEQ LF189                   ; F183: F0 04
    CMP #$22                    ; F185: C9 22
    BNE LF1B3                   ; F187: D0 2A
LF189:
    LDA GameMode                ; F189: A5 00
    CMP #$05                    ; F18B: C9 05
    BNE LF1B3                   ; F18D: D0 24
    LDA SceneId                 ; F18F: A5 1F
    CMP #$83                    ; F191: C9 83
    BEQ LF1B3                   ; F193: F0 1E
    LDA #$00                    ; F195: A9 00
    STA $02,X                   ; F197: 95 02
    STA RenderDelay,X           ; F199: 95 0C
    LDA #$30                    ; F19B: A9 30
    LDX $F5                     ; F19D: A6 F5
    STA $4000,X                 ; F19F: 9D 00 40
    LDA DeathSeqCnt             ; F1A2: AD DD 05
    BEQ LF1B0                   ; F1A5: F0 09
    JSR $8614                   ; F1A7: 20 14 86  -> Bank0:InitSound
    LDY #$16                    ; F1AA: A0 16
    JSR $8622                   ; F1AC: 20 22 86  -> Bank0:SoundCmd80
    RTS                         ; F1AF: 60
LF1B0:
    JMP BgmByStage              ; F1B0: 4C 90 CB
LF1B3:
    TYA                         ; F1B3: 98
    STY $02,X                   ; F1B4: 94 02
    CPX #$D2                    ; F1B6: E0 D2
    BEQ LF1C0                   ; F1B8: F0 06
    BPL LF1BE                   ; F1BA: 10 02
    STY RenderDelay,X           ; F1BC: 94 0C
LF1BE:
    LDA #$30                    ; F1BE: A9 30
LF1C0:
    LDX $F5                     ; F1C0: A6 F5
    STA $4000,X                 ; F1C2: 9D 00 40
    RTS                         ; F1C5: 60
LF1C6:
    INY                         ; F1C6: C8
    LDA ($F6),Y                 ; F1C7: B1 F6
    STA $03,X                   ; F1C9: 95 03
    INY                         ; F1CB: C8
    LDA ($F6),Y                 ; F1CC: B1 F6
    STA NmiBusy,X               ; F1CE: 95 04
    RTS                         ; F1D0: 60
LF1D1:
    LDA $06,X                   ; F1D1: B5 06
    CLC                         ; F1D3: 18
    ADC #$01                    ; F1D4: 69 01
    INY                         ; F1D6: C8
    CMP ($F6),Y                 ; F1D7: D1 F6
    BEQ LF1E8                   ; F1D9: F0 0D
    BMI LF1E0                   ; F1DB: 30 03
    SEC                         ; F1DD: 38
    SBC #$01                    ; F1DE: E9 01
LF1E0:
    STA $06,X                   ; F1E0: 95 06
    JSR LF1C6                   ; F1E2: 20 C6 F1
    JMP LF1FB                   ; F1E5: 4C FB F1
LF1E8:
    LDA #$00                    ; F1E8: A9 00
    STA $06,X                   ; F1EA: 95 06
    INY                         ; F1EC: C8
    INY                         ; F1ED: C8
    INY                         ; F1EE: C8
    TYA                         ; F1EF: 98
    CLC                         ; F1F0: 18
    ADC $F6                     ; F1F1: 65 F6
    STA $03,X                   ; F1F3: 95 03
    LDA #$00                    ; F1F5: A9 00
    ADC $F7                     ; F1F7: 65 F7
    STA NmiBusy,X               ; F1F9: 95 04
LF1FB:
    LDA #$01                    ; F1FB: A9 01
    STA GameMode,X              ; F1FD: 95 00
    BNE LF223                   ; F1FF: D0 22
SoundUpdate:
    ; 声音驱动帧更新：NMI 每帧末调用，通道状态步进并写 $4000-$4008
    LDX #$B0                    ; F201: A2 B0
    LDY #$00                    ; F203: A0 00
LF205:
    STX $F4                     ; F205: 86 F4
    STY $F5                     ; F207: 84 F5
    LDA $02,X                   ; F209: B5 02
    BEQ LF210                   ; F20B: F0 03
    JSR LF223                   ; F20D: 20 23 F2
LF210:
    LDA $F4                     ; F210: A5 F4
    CLC                         ; F212: 18
    ADC #$11                    ; F213: 69 11
    CMP #$F4                    ; F215: C9 F4
    BNE LF21A                   ; F217: D0 01
    RTS                         ; F219: 60
LF21A:
    TAX                         ; F21A: AA
    LDA $F5                     ; F21B: A5 F5
    CLC                         ; F21D: 18
    ADC #$04                    ; F21E: 69 04
    TAY                         ; F220: A8
    BCC LF205                   ; F221: 90 E2
LF223:
    LDY #$00                    ; F223: A0 00
    LDA $03,X                   ; F225: B5 03
    STA $F6                     ; F227: 85 F6
    LDA NmiBusy,X               ; F229: B5 04
    STA $F7                     ; F22B: 85 F7
    DEC GameMode,X              ; F22D: D6 00
    BEQ LF265                   ; F22F: F0 34
    LDA PauseFlag               ; F231: A5 1A
    BEQ LF25F                   ; F233: F0 2A
    LDA $02,X                   ; F235: B5 02
    CMP #$40                    ; F237: C9 40
    BEQ LF25F                   ; F239: F0 24
LF23B:
    INC GameMode,X              ; F23B: F6 00
    CPX #$E3                    ; F23D: E0 E3
    BEQ LF245                   ; F23F: F0 04
    LDA #$00                    ; F241: A9 00
    STA JoyHeld,X               ; F243: 95 07
LF245:
    LDX $F5                     ; F245: A6 F5
    CPX #$0C                    ; F247: E0 0C
    BEQ LF24E                   ; F249: F0 03
    JMP LF253                   ; F24B: 4C 53 F2
LF24E:
    LDA #$30                    ; F24E: A9 30
    STA $4000,X                 ; F250: 9D 00 40
LF253:
    LDA #$00                    ; F253: A9 00
    STA $4002,X                 ; F255: 9D 02 40
    STA $4003,X                 ; F258: 9D 03 40
    STA $4008                   ; F25B: 8D 08 40
    RTS                         ; F25E: 60
LF25F:
    JMP LF329                   ; F25F: 4C 29 F3
LF262:
    JMP LF1D1                   ; F262: 4C D1 F1
LF265:
    LDA ($F6),Y                 ; F265: B1 F6
    CMP #$FD                    ; F267: C9 FD
    BCC LF2A5                   ; F269: 90 3A
    BNE LF288                   ; F26B: D0 1B
    LDX $F4                     ; F26D: A6 F4
    LDA FrameCnt,X              ; F26F: B5 09
    ORA #$80                    ; F271: 09 80
    STA FrameCnt,X              ; F273: 95 09
    JSR LF1C6                   ; F275: 20 C6 F1
    INY                         ; F278: C8
    TYA                         ; F279: 98
    CLC                         ; F27A: 18
    ADC $F6                     ; F27B: 65 F6
    STA $E0                     ; F27D: 85 E0
    LDA #$00                    ; F27F: A9 00
    ADC $F7                     ; F281: 65 F7
    STA $E1                     ; F283: 85 E1
    JMP LF1FB                   ; F285: 4C FB F1
LF288:
    CMP #$FE                    ; F288: C9 FE
    BNE LF28F                   ; F28A: D0 03
    JMP LF1D1                   ; F28C: 4C D1 F1
LF28F:
    LDA FrameCnt,X              ; F28F: B5 09
    BMI LF296                   ; F291: 30 03
    JMP LF17B                   ; F293: 4C 7B F1
LF296:
    AND #$7F                    ; F296: 29 7F
    STA FrameCnt,X              ; F298: 95 09
    LDA $E0                     ; F29A: A5 E0
    STA $03,X                   ; F29C: 95 03
    LDA $E1                     ; F29E: A5 E1
    STA NmiBusy,X               ; F2A0: 95 04
    JMP LF1FB                   ; F2A2: 4C FB F1
LF2A5:
    LDX $F4                     ; F2A5: A6 F4
    LDA FrameCnt,X              ; F2A7: B5 09
    AND #$7F                    ; F2A9: 29 7F
    BEQ LF2B0                   ; F2AB: F0 03
    JMP LF37B                   ; F2AD: 4C 7B F3
LF2B0:
    LDA ($F6),Y                 ; F2B0: B1 F6
    AND #$F0                    ; F2B2: 29 F0
    CMP #$20                    ; F2B4: C9 20
    BNE LF2CF                   ; F2B6: D0 17
    LDA ($F6),Y                 ; F2B8: B1 F6
    AND #$0F                    ; F2BA: 29 0F
    STA SubMode,X               ; F2BC: 95 01
    INY                         ; F2BE: C8
    LDA ($F6),Y                 ; F2BF: B1 F6
    LDX $F5                     ; F2C1: A6 F5
    STA $4000,X                 ; F2C3: 9D 00 40
    LDX $F4                     ; F2C6: A6 F4
    CPX #$D2                    ; F2C8: E0 D2
    BEQ LF2CE                   ; F2CA: F0 02
    STA $08,X                   ; F2CC: 95 08
LF2CE:
    INY                         ; F2CE: C8
LF2CF:
    LDA SubMode,X               ; F2CF: B5 01
    STA GameMode,X              ; F2D1: 95 00
    CPX #$D2                    ; F2D3: E0 D2
    BEQ LF316                   ; F2D5: F0 3F
    LDA ($F6),Y                 ; F2D7: B1 F6
    CMP #$11                    ; F2D9: C9 11
    BNE LF2E3                   ; F2DB: D0 06
    STA RenderDelay,X           ; F2DD: 95 0C
    INY                         ; F2DF: C8
    JMP LF2B0                   ; F2E0: 4C B0 F2
LF2E3:
    CMP #$10                    ; F2E3: C9 10
    BNE LF2F4                   ; F2E5: D0 0D
    INY                         ; F2E7: C8
    LDA ($F6),Y                 ; F2E8: B1 F6
    INY                         ; F2EA: C8
    LDX $F5                     ; F2EB: A6 F5
    STA $4001,X                 ; F2ED: 9D 01 40
    LDX $F4                     ; F2F0: A6 F4
    STA $0B,X                   ; F2F2: 95 0B
LF2F4:
    LDA $08,X                   ; F2F4: B5 08
    AND #$10                    ; F2F6: 29 10
    BEQ LF316                   ; F2F8: F0 1C
    LDA $08,X                   ; F2FA: B5 08
    AND #$F0                    ; F2FC: 29 F0
    STA $08,X                   ; F2FE: 95 08
    LDA ($F6),Y                 ; F300: B1 F6
    CMP #$F8                    ; F302: C9 F8
    BNE LF309                   ; F304: D0 03
    INY                         ; F306: C8
    LDA ($F6),Y                 ; F307: B1 F6
LF309:
    LSR A                       ; F309: 4A
    LSR A                       ; F30A: 4A
    LSR A                       ; F30B: 4A
    LSR A                       ; F30C: 4A
    ORA $08,X                   ; F30D: 15 08
    STA $08,X                   ; F30F: 95 08
    LDX $F5                     ; F311: A6 F5
    STA $4000,X                 ; F313: 9D 00 40
LF316:
    LDA ($F6),Y                 ; F316: B1 F6
    AND #$07                    ; F318: 29 07
    STA $F0                     ; F31A: 85 F0
    INY                         ; F31C: C8
    LDA ($F6),Y                 ; F31D: B1 F6
    STA $F1                     ; F31F: 85 F1
    LDX $F4                     ; F321: A6 F4
    JSR LF46A                   ; F323: 20 6A F4
    JMP LF4A7                   ; F326: 4C A7 F4
LF329:
    LDA FrameCnt,X              ; F329: B5 09
    BNE LF32E                   ; F32B: D0 01
    RTS                         ; F32D: 60
LF32E:
    CPX #$D2                    ; F32E: E0 D2
    BNE LF333                   ; F330: D0 01
    RTS                         ; F332: 60
LF333:
    LDA $F6                     ; F333: A5 F6
    BNE LF339                   ; F335: D0 02
    DEC $F7                     ; F337: C6 F7
LF339:
    DEC $F6                     ; F339: C6 F6
    LDY #$00                    ; F33B: A0 00
    LDA ($F6),Y                 ; F33D: B1 F6
    AND #$F0                    ; F33F: 29 F0
    CMP #$C0                    ; F341: C9 C0
    BNE LF346                   ; F343: D0 01
    RTS                         ; F345: 60
LF346:
    LDA $08,X                   ; F346: B5 08
    AND #$10                    ; F348: 29 10
    BNE LF34D                   ; F34A: D0 01
    RTS                         ; F34C: 60
LF34D:
    LDA $0D,X                   ; F34D: B5 0D
    SEC                         ; F34F: 38
    SBC #$01                    ; F350: E9 01
    STA $0D,X                   ; F352: 95 0D
    CMP GameMode,X              ; F354: D5 00
    BNE LF360                   ; F356: D0 08
    SEC                         ; F358: 38
    SBC PpuMaskShadow,X         ; F359: F5 0F
    BCC LF365                   ; F35B: 90 08
    BEQ LF365                   ; F35D: F0 06
    RTS                         ; F35F: 60
LF360:
    SEC                         ; F360: 38
    SBC #$01                    ; F361: E9 01
    STA $0D,X                   ; F363: 95 0D
LF365:
    LDA $08,X                   ; F365: B5 08
    AND #$0F                    ; F367: 29 0F
    SEC                         ; F369: 38
    SBC #$01                    ; F36A: E9 01
    BPL LF36F                   ; F36C: 10 01
    RTS                         ; F36E: 60
LF36F:
    LDA $08,X                   ; F36F: B5 08
    SBC #$01                    ; F371: E9 01
    STA $08,X                   ; F373: 95 08
    LDX $F5                     ; F375: A6 F5
    STA $4000,X                 ; F377: 9D 00 40
    RTS                         ; F37A: 60
LF37B:
    LDA PauseFlag               ; F37B: A5 1A
    BEQ LF382                   ; F37D: F0 03
    JMP LF23B                   ; F37F: 4C 3B F2
LF382:
    LDA ($F6),Y                 ; F382: B1 F6
    AND #$F0                    ; F384: 29 F0
    CMP #$D0                    ; F386: C9 D0
    BNE LF3A9                   ; F388: D0 1F
    LDA ($F6),Y                 ; F38A: B1 F6
    AND #$0F                    ; F38C: 29 0F
    STA $0A,X                   ; F38E: 95 0A
    INY                         ; F390: C8
    LDA ($F6),Y                 ; F391: B1 F6
    STA JoyPressed,X            ; F393: 95 05
    INY                         ; F395: C8
    CPX #$D2                    ; F396: E0 D2
    BEQ LF3C0                   ; F398: F0 26
    LDA ($F6),Y                 ; F39A: B1 F6
    LSR A                       ; F39C: 4A
    LSR A                       ; F39D: 4A
    LSR A                       ; F39E: 4A
    LSR A                       ; F39F: 4A
    STA PpuCtrlShadow,X         ; F3A0: 95 0E
    LDA ($F6),Y                 ; F3A2: B1 F6
    AND #$0F                    ; F3A4: 29 0F
    STA PpuMaskShadow,X         ; F3A6: 95 0F
    INY                         ; F3A8: C8
LF3A9:
    CPX #$D2                    ; F3A9: E0 D2
    BEQ LF3C0                   ; F3AB: F0 13
    LDA ($F6),Y                 ; F3AD: B1 F6
    CMP #$F0                    ; F3AF: C9 F0
    BNE LF3C0                   ; F3B1: D0 0D
    INY                         ; F3B3: C8
    LDA ($F6),Y                 ; F3B4: B1 F6
    LDX $F5                     ; F3B6: A6 F5
    STA $4001,X                 ; F3B8: 9D 01 40
    LDX $F4                     ; F3BB: A6 F4
    STA $0B,X                   ; F3BD: 95 0B
    INY                         ; F3BF: C8
LF3C0:
    LDA ($F6),Y                 ; F3C0: B1 F6
    AND #$F0                    ; F3C2: 29 F0
    CMP #$E0                    ; F3C4: C9 E0
    BNE LF405                   ; F3C6: D0 3D
    LDA ($F6),Y                 ; F3C8: B1 F6
    AND #$0F                    ; F3CA: 29 0F
    CMP #$08                    ; F3CC: C9 08
    BEQ LF3F5                   ; F3CE: F0 25
    CMP #$0E                    ; F3D0: C9 0E
    BNE LF3D8                   ; F3D2: D0 04
    LDA #$C1                    ; F3D4: A9 C1
    BNE LF3EE                   ; F3D6: D0 16
LF3D8:
    CMP #$0F                    ; F3D8: C9 0F
    BNE LF3E0                   ; F3DA: D0 04
    LDA #$C2                    ; F3DC: A9 C2
    BNE LF3EE                   ; F3DE: D0 0E
LF3E0:
    CMP #$0A                    ; F3E0: C9 0A
    BNE LF3E8                   ; F3E2: D0 04
    LDA #$43                    ; F3E4: A9 43
    BNE LF3EE                   ; F3E6: D0 06
LF3E8:
    CMP #$0B                    ; F3E8: C9 0B
    BNE LF3FD                   ; F3EA: D0 11
    LDA #$44                    ; F3EC: A9 44
LF3EE:
    JSR SoundCmd                ; F3EE: 20 8E F0
    INY                         ; F3F1: C8
    JMP LF265                   ; F3F2: 4C 65 F2
LF3F5:
    LDX $F4                     ; F3F5: A6 F4
    STA RenderDelay,X           ; F3F7: 95 0C
    INY                         ; F3F9: C8
    JMP LF37B                   ; F3FA: 4C 7B F3
LF3FD:
    LDX $F4                     ; F3FD: A6 F4
    STA $10,X                   ; F3FF: 95 10
    INY                         ; F401: C8
    JMP LF265                   ; F402: 4C 65 F2
LF405:
    JSR LF4A7                   ; F405: 20 A7 F4
    DEY                         ; F408: 88
    LDA ($F6),Y                 ; F409: B1 F6
    AND #$0F                    ; F40B: 29 0F
    STA $F0                     ; F40D: 85 F0
    BEQ LF41C                   ; F40F: F0 0B
    LDA $0A,X                   ; F411: B5 0A
    CLC                         ; F413: 18
LF414:
    ADC $0A,X                   ; F414: 75 0A
    DEC $F0                     ; F416: C6 F0
    BNE LF414                   ; F418: D0 FA
    BEQ LF41E                   ; F41A: F0 02
LF41C:
    LDA $0A,X                   ; F41C: B5 0A
LF41E:
    STA GameMode,X              ; F41E: 95 00
    CPX #$D2                    ; F420: E0 D2
    BEQ LF429                   ; F422: F0 05
    CLC                         ; F424: 18
    ADC PpuCtrlShadow,X         ; F425: 75 0E
    STA $0D,X                   ; F427: 95 0D
LF429:
    LDA JoyPressed,X            ; F429: B5 05
    CPX #$D2                    ; F42B: E0 D2
    BEQ LF431                   ; F42D: F0 02
    STA $08,X                   ; F42F: 95 08
LF431:
    LDX $F5                     ; F431: A6 F5
    STA $4000,X                 ; F433: 9D 00 40
    LDA ($F6),Y                 ; F436: B1 F6
    LSR A                       ; F438: 4A
    LSR A                       ; F439: 4A
    LSR A                       ; F43A: 4A
    LSR A                       ; F43B: 4A
    CMP #$0C                    ; F43C: C9 0C
    BNE LF44C                   ; F43E: D0 0C
    LDA #$00                    ; F440: A9 00
    CPX #$08                    ; F442: E0 08
    BEQ LF448                   ; F444: F0 02
    LDA #$30                    ; F446: A9 30
LF448:
    STA $4000,X                 ; F448: 9D 00 40
    RTS                         ; F44B: 60
LF44C:
    LDX $F4                     ; F44C: A6 F4
    ASL A                       ; F44E: 0A
    TAY                         ; F44F: A8
    LDA $F4B9,Y                 ; F450: B9 B9 F4
    STA $F0                     ; F453: 85 F0
    INY                         ; F455: C8
    LDA $F4B9,Y                 ; F456: B9 B9 F4
    STA $F1                     ; F459: 85 F1
    LDY $10,X                   ; F45B: B4 10
LF45D:
    TYA                         ; F45D: 98
    CMP #$04                    ; F45E: C9 04
    BEQ LF46A                   ; F460: F0 08
    LSR $F0                     ; F462: 46 F0
    ROR $F1                     ; F464: 66 F1
    INY                         ; F466: C8
    JMP LF45D                   ; F467: 4C 5D F4
LF46A:
    CPX #$D2                    ; F46A: E0 D2
    BCS LF478                   ; F46C: B0 0A
    LDA RenderDelay,X           ; F46E: B5 0C
    BEQ LF478                   ; F470: F0 06
    INC $F1                     ; F472: E6 F1
    BNE LF478                   ; F474: D0 02
    INC $F0                     ; F476: E6 F0
LF478:
    LDA $F0                     ; F478: A5 F0
    ORA #$08                    ; F47A: 09 08
    STA $F0                     ; F47C: 85 F0
    CPX #$D2                    ; F47E: E0 D2
    BEQ LF498                   ; F480: F0 16
    CMP JoyHeld,X               ; F482: D5 07
    BNE LF496                   ; F484: D0 10
    CPX #$E3                    ; F486: E0 E3
    BEQ LF49F                   ; F488: F0 15
    LDA $08,X                   ; F48A: B5 08
    AND #$10                    ; F48C: 29 10
    BEQ LF498                   ; F48E: F0 08
    LDA $0B,X                   ; F490: B5 0B
    BNE LF498                   ; F492: D0 04
    BEQ LF49F                   ; F494: F0 09
LF496:
    STA JoyHeld,X               ; F496: 95 07
LF498:
    LDA $F0                     ; F498: A5 F0
    LDX $F5                     ; F49A: A6 F5
    STA $4003,X                 ; F49C: 9D 03 40
LF49F:
    LDX $F5                     ; F49F: A6 F5
    LDA $F1                     ; F4A1: A5 F1
    STA $4002,X                 ; F4A3: 9D 02 40
    RTS                         ; F4A6: 60
LF4A7:
    INY                         ; F4A7: C8
    TYA                         ; F4A8: 98
    CLC                         ; F4A9: 18
    ADC $F6                     ; F4AA: 65 F6
    LDX $F4                     ; F4AC: A6 F4
    STA $03,X                   ; F4AE: 95 03
    BCC LF4B8                   ; F4B0: 90 06
    LDA $F7                     ; F4B2: A5 F7
    ADC #$00                    ; F4B4: 69 00
    STA NmiBusy,X               ; F4B6: 95 04
LF4B8:
    RTS                         ; F4B8: 60
    .byte $06,$AE,$06,$4E,$05,$F4,$05,$9E         ; F4B9: 06 AE 06 4E 05 F4 05 9E
    .byte $05,$4E,$05,$01,$04,$B9,$04,$76         ; F4C1: 05 4E 05 01 04 B9 04 76
    .byte $04,$36,$03,$F9,$03,$C0,$03,$8A         ; F4C9: 04 36 03 F9 03 C0 03 8A
    .byte $E9,$F6,$F6,$F6,$23,$F6,$35,$F6         ; F4D1: E9 F6 F6 F6 23 F6 35 F6
    .byte $47,$F6,$4F,$F6,$CE,$F5,$50,$F8         ; F4D9: 47 F6 4F F6 CE F5 50 F8
    .byte $7F,$F7,$90,$F7,$EE,$F8,$EB,$F7         ; F4E1: 7F F7 90 F7 EE F8 EB F7
    .byte $57,$F8,$B2,$F7,$BE,$F7,$8B,$F6         ; F4E9: 57 F8 B2 F7 BE F7 8B F6
    .byte $92,$F6,$10,$F7,$1F,$F7,$B4,$F5         ; F4F1: 92 F6 10 F7 1F F7 B4 F5
    .byte $6E,$F8,$C9,$F8,$7F,$F6,$1C,$F8         ; F4F9: 6E F8 C9 F8 7F F6 1C F8
    .byte $B7,$F6,$FB,$F6,$6B,$F5,$7F,$F5         ; F501: B7 F6 FB F6 6B F5 7F F5
    .byte $50,$F7,$45,$F8,$5D,$F5,$2A,$F7         ; F509: 50 F7 45 F8 5D F5 2A F7
    .byte $37,$F7,$3C,$F7,$92,$F5,$57,$FC         ; F511: 37 F7 3C F7 92 F5 57 FC
    .byte $0A,$F8,$12,$F8,$C5,$FC,$C6,$FC         ; F519: 0A F8 12 F8 C5 FC C6 FC
    .byte $CA,$FD,$0A,$FD,$03,$FE,$09,$F9         ; F521: CA FD 0A FD 03 FE 09 F9
    .byte $57,$F9,$E7,$F9,$70,$FA,$B3,$FF         ; F529: 57 F9 E7 F9 70 FA B3 FF
    .byte $CB,$FF,$58,$F6,$5D,$F6,$6F,$F6         ; F531: CB FF 58 F6 5D F6 6F F6
    .byte $9C,$F5,$A1,$F5,$61,$FF,$77,$FF         ; F539: 9C F5 A1 F5 61 FF 77 FF
    .byte $93,$FF,$9A,$F6,$9B,$F6,$AC,$F6         ; F541: 93 FF 9A F6 9B F6 AC F6
    .byte $46,$FB,$64,$FB,$80,$FB,$97,$F7         ; F549: 46 FB 64 FB 80 FB 97 F7
    .byte $A7,$FB,$AC,$FB,$0C,$FC,$D0,$F6         ; F551: A7 FB AC FB 0C FC D0 F6
    .byte $D1,$F6,$E0,$F6,$DA,$A0,$00,$E0         ; F559: D1 F6 E0 F6 DA A0 00 E0
    .byte $B2,$DC,$B0,$00,$C0,$FE,$05,$5D         ; F561: B2 DC B0 00 C0 FE 05 5D
    .byte $F5,$FF,$D5,$FE,$11,$E1,$C1,$50         ; F569: F5 FF D5 FE 11 E1 C1 50
    .byte $40,$20,$00,$50,$40,$20,$00,$90         ; F571: 40 20 00 50 40 20 00 90
    .byte $50,$90,$E0,$01,$C2,$FF,$D5,$BE         ; F579: 50 90 E0 01 C2 FF D5 BE
    .byte $22,$E1,$C1,$90,$70,$50,$40,$90         ; F581: 22 E1 C1 90 70 50 40 90
    .byte $70,$50,$40,$50,$00,$50,$91,$C2         ; F589: 70 50 40 50 00 50 91 C2
    .byte $FF,$D1,$BF,$00,$E1,$B0,$C2,$FE         ; F591: FF D1 BF 00 E1 B0 C2 FE
    .byte $FF,$96,$F5,$E8,$D5,$B0,$00,$C0         ; F599: FF 96 F5 E8 D5 B0 00 C0
    .byte $D7,$89,$00,$E2,$50,$E1,$00,$50         ; F5A1: D7 89 00 E2 50 E1 00 50
    .byte $70,$B0,$E0,$20,$50,$92,$D7,$88         ; F5A9: 70 B0 E0 20 50 92 D7 88
    .byte $00,$74,$FF,$2A,$30,$60,$0A,$80         ; F5B1: 00 74 FF 2A 30 60 0A 80
    .byte $0A,$A0,$0A,$B0,$0A,$C0,$0A,$A0         ; F5B9: 0A A0 0A B0 0A C0 0A A0
    .byte $0A,$B0,$0A,$70,$0A,$40,$0A,$30         ; F5C1: 0A B0 0A 70 0A 40 0A 30
    .byte $0A,$F8,$20,$0A,$FF,$21,$F0,$43         ; F5C9: 0A F8 20 0A FF 21 F0 43
    .byte $0F,$62,$B0,$83,$F0,$72,$80,$82         ; F5D1: 0F 62 B0 83 F0 72 80 82
    .byte $00,$21,$80,$43,$F0,$32,$80,$42         ; F5D9: 00 21 80 43 F0 32 80 42
    .byte $00,$33,$FF,$52,$80,$63,$F0,$51         ; F5E1: 00 33 FF 52 80 63 F0 51
    .byte $80,$43,$F0,$21,$B0,$63,$FF,$52         ; F5E9: 80 43 F0 21 B0 63 FF 52
    .byte $80,$62,$80,$53,$00,$61,$80,$52         ; F5F1: 80 62 80 53 00 61 80 52
    .byte $80,$32,$00,$52,$80,$33,$F0,$52         ; F5F9: 80 32 00 52 80 33 F0 52
    .byte $00,$32,$80,$51,$80,$32,$80,$53         ; F601: 00 32 80 51 80 32 80 53
    .byte $00,$33,$00,$33,$FF,$F8,$22,$80         ; F609: 00 33 00 33 FF F8 22 80
    .byte $32,$00,$F8,$23,$F0,$31,$80,$F8         ; F611: 32 00 F8 23 F0 31 80 F8
    .byte $23,$FF,$F8,$22,$80,$2F,$B0,$00         ; F619: 23 FF F8 22 80 2F B0 00
    .byte $00,$FF,$25,$B0,$90,$BE,$90,$B3         ; F621: 00 FF 25 B0 90 BE 90 B3
    .byte $60,$BE,$60,$B3,$40,$BE,$40,$B3         ; F629: 60 BE 60 B3 40 BE 40 B3
    .byte $F8,$20,$BE,$FF,$25,$B0,$90,$8E         ; F631: F8 20 BE FF 25 B0 90 8E
    .byte $90,$86,$60,$8E,$60,$86,$40,$8E         ; F639: 90 86 60 8E 60 86 40 8E
    .byte $40,$86,$F8,$20,$8E,$FF,$D1,$BF         ; F641: 40 86 F8 20 8E FF D1 BF
    .byte $00,$E3,$70,$C0,$00,$FF,$21,$30         ; F649: 00 E3 70 C0 00 FF 21 30
    .byte $B0,$0C,$00,$00,$B0,$08,$FF,$D2         ; F651: B0 0C 00 00 B0 08 FF D2
    .byte $B0,$00,$C0,$E8,$D5,$BF,$33,$E1         ; F659: B0 00 C0 E8 D5 BF 33 E1
    .byte $00,$20,$40,$50,$40,$50,$70,$90         ; F661: 00 20 40 50 40 50 70 90
    .byte $D5,$86,$00,$94,$C3,$FF,$D5,$18         ; F669: D5 86 00 94 C3 FF D5 18
    .byte $E1,$50,$70,$90,$E0,$00,$00,$20         ; F671: E1 50 70 90 E0 00 00 20
    .byte $40,$D5,$48,$54,$C3,$FF,$D5,$81         ; F679: 40 D5 48 54 C3 FF D5 81
    .byte $33,$E1,$70,$60,$71,$E0,$70,$60         ; F681: 33 E1 70 60 71 E0 70 60
    .byte $71,$FF,$28,$B0,$10,$82,$F0,$88         ; F689: 71 FF 28 B0 10 82 F0 88
    .byte $FF,$D5,$05,$00,$F0,$83,$E0,$B0         ; F691: FF D5 05 00 F0 83 E0 B0
    .byte $FF,$E8,$D8,$BF,$74,$E2,$90,$50         ; F699: FF E8 D8 BF 74 E2 90 50
    .byte $20,$50,$20,$E3,$B0,$D8,$A0,$00         ; F6A1: 20 50 20 E3 B0 D8 A0 00
    .byte $85,$CA,$FF,$D6,$1A,$E2,$23,$E3         ; F6A9: 85 CA FF D6 1A E2 23 E3
    .byte $B3,$D6,$3A,$57,$CA,$FF,$25,$82         ; F6B1: B3 D6 3A 57 CA FF 25 82
    .byte $00,$6A,$00,$47,$23,$B0,$E0,$54         ; F6B9: 00 6A 00 47 23 B0 E0 54
    .byte $D0,$54,$B0,$54,$A0,$54,$80,$54         ; F6C1: D0 54 B0 54 A0 54 80 54
    .byte $60,$54,$40,$54,$30,$54,$FF,$E8         ; F6C9: 60 54 40 54 30 54 FF E8
    .byte $D6,$BA,$22,$E2,$20,$E1,$20,$E2         ; F6D1: D6 BA 22 E2 20 E1 20 E2
    .byte $20,$70,$D6,$BA,$67,$92,$FF,$D6         ; F6D9: 20 70 D6 BA 67 92 FF D6
    .byte $0F,$E1,$20,$20,$20,$20,$22,$FF         ; F6E1: 0F E1 20 20 20 20 22 FF
    .byte $21,$30,$B0,$06,$90,$06,$70,$06         ; F6E9: 21 30 B0 06 90 06 70 06
    .byte $50,$04,$30,$06,$FF,$21,$30,$F0         ; F6F1: 50 04 30 06 FF 21 30 F0
    .byte $02,$FF,$24,$82,$00,$5F,$00,$47         ; F6F9: 02 FF 24 82 00 5F 00 47
    .byte $00,$2F,$00,$38,$00,$47,$00,$2F         ; F701: 00 2F 00 38 00 47 00 2F
    .byte $00,$38,$2F,$82,$00,$47,$FF,$22         ; F709: 00 38 2F 82 00 47 FF 22
    .byte $B0,$10,$81,$F1,$49,$F2,$52,$A1         ; F711: B0 10 81 F1 49 F2 52 A1
    .byte $15,$C1,$13,$C1,$25,$FF,$22,$30         ; F719: 15 C1 13 C1 25 FF 22 30
    .byte $F0,$0F,$B0,$0E,$B0,$0D,$D0,$0C         ; F721: F0 0F B0 0E B0 0D D0 0C
    .byte $FF,$D5,$81,$00,$F0,$8C,$E1,$00         ; F729: FF D5 81 00 F0 8C E1 00
    .byte $20,$40,$50,$70,$90,$FF,$E8,$D2         ; F731: 20 40 50 70 90 FF E8 D2
    .byte $B0,$00,$C0,$D3,$82,$00,$E2,$00         ; F739: B0 00 C0 D3 82 00 E2 00
    .byte $70,$E1,$00,$00,$40,$70,$00,$40         ; F741: 70 E1 00 00 40 70 00 40
    .byte $70,$70,$E0,$00,$40,$73,$FF,$22         ; F749: 70 70 E0 00 40 73 FF 22
    .byte $30,$F1,$D0,$F1,$F0,$F1,$D0,$D1         ; F751: 30 F1 D0 F1 F0 F1 D0 D1
    .byte $F0,$22,$70,$D1,$D0,$D1,$F0,$C1         ; F759: F0 22 70 D1 D0 D1 F0 C1
    .byte $D0,$C1,$F0,$22,$30,$B1,$D0,$B1         ; F761: D0 C1 F0 22 30 B1 D0 B1
    .byte $F0,$A1,$D0,$A1,$F0,$22,$70,$91         ; F769: F0 A1 D0 A1 F0 22 70 91
    .byte $D0,$81,$F0,$71,$D0,$61,$F0,$51         ; F771: D0 81 F0 71 D0 61 F0 51
    .byte $D0,$41,$F0,$31,$D0,$FF,$25,$B0         ; F779: D0 41 F0 31 D0 FF 25 B0
    .byte $10,$8C,$F3,$57,$E2,$A7,$A2,$3B         ; F781: 10 8C F3 57 E2 A7 A2 3B
    .byte $83,$57,$62,$A7,$42,$3B,$FF,$25         ; F789: 83 57 62 A7 42 3B FF 25
    .byte $70,$10,$8A,$F1,$AF,$FF,$25,$82         ; F791: 70 10 8A F1 AF FF 25 82
    .byte $00,$D5,$00,$8E,$00,$A9,$22,$B0         ; F799: 00 D5 00 8E 00 A9 22 B0
    .byte $E0,$6A,$D0,$6A,$B0,$6A,$A0,$6A         ; F7A1: E0 6A D0 6A B0 6A A0 6A
    .byte $90,$6A,$70,$6A,$50,$6A,$40,$6A         ; F7A9: 90 6A 70 6A 50 6A 40 6A
    .byte $FF,$D4,$66,$00,$F0,$83,$E1,$00         ; F7B1: FF D4 66 00 F0 83 E1 00
    .byte $E2,$40,$E3,$70,$FF,$21,$30,$10         ; F7B9: E2 40 E3 70 FF 21 30 10
    .byte $89,$F1,$A0,$E1,$90,$E1,$80,$E1         ; F7C1: 89 F1 A0 E1 90 E1 80 E1
    .byte $70,$E1,$60,$E1,$50,$D1,$40,$C1         ; F7C9: 70 E1 60 E1 50 D1 40 C1
    .byte $30,$B1,$20,$A1,$10,$91,$00,$2B         ; F7D1: 30 B1 20 A1 10 91 00 2B
    .byte $F0,$00,$00,$00,$00,$26,$F0,$00         ; F7D9: F0 00 00 00 00 26 F0 00
    .byte $00,$2C,$B0,$10,$83,$F2,$28,$F1         ; F7E1: 00 2C B0 10 83 F2 28 F1
    .byte $98,$FF,$21,$70,$C1,$8F,$22,$B0         ; F7E9: 98 FF 21 70 C1 8F 22 B0
    .byte $00,$00,$21,$70,$D0,$30,$C0,$38         ; F7F1: 00 00 21 70 D0 30 C0 38
    .byte $B0,$40,$A0,$48,$90,$50,$80,$58         ; F7F9: B0 40 A0 48 90 50 80 58
    .byte $70,$60,$60,$68,$50,$70,$40,$78         ; F801: 70 60 60 68 50 70 40 78
    .byte $FF,$D4,$8F,$00,$F0,$AB,$E2,$0F         ; F809: FF D4 8F 00 F0 AB E2 0F
    .byte $FF,$E8,$D4,$8F,$00,$F0,$AB,$E2         ; F811: FF E8 D4 8F 00 F0 AB E2
    .byte $C0,$4F,$FF,$21,$B0,$F0,$35,$F0         ; F819: C0 4F FF 21 B0 F0 35 F0
    .byte $35,$F0,$35,$F0,$2C,$D0,$2C,$A0         ; F821: 35 F0 35 F0 2C D0 2C A0
    .byte $2C,$F0,$25,$F0,$25,$E0,$25,$F0         ; F829: 2C F0 25 F0 25 E0 25 F0
    .byte $21,$F0,$21,$E0,$21,$D0,$21,$B0         ; F831: 21 F0 21 E0 21 D0 21 B0
    .byte $21,$A0,$21,$80,$21,$50,$21,$40         ; F839: 21 A0 21 80 21 50 21 40
    .byte $21,$30,$21,$FF,$22,$80,$E0,$70         ; F841: 21 30 21 FF 22 80 E0 70
    .byte $C0,$58,$FE,$13,$47,$F8,$FF,$27         ; F849: C0 58 FE 13 47 F8 FF 27
    .byte $83,$10,$9B,$00,$B7,$FF,$21,$F0         ; F851: 83 10 9B 00 B7 FF 21 F0
    .byte $F1,$40,$F1,$60,$F1,$80,$F1,$60         ; F859: F1 40 F1 60 F1 80 F1 60
    .byte $E1,$40,$D1,$20,$C1,$00,$A1,$20         ; F861: E1 40 D1 20 C1 00 A1 20
    .byte $FE,$06,$59,$F8,$FF,$21,$B0,$F3         ; F869: FE 06 59 F8 FF 21 B0 F3
    .byte $00,$F1,$48,$F1,$C8,$F2,$10,$F2         ; F871: 00 F1 48 F1 C8 F2 10 F2
    .byte $30,$B2,$50,$A1,$00,$F1,$48,$F3         ; F879: 30 B2 50 A1 00 F1 48 F3
    .byte $88,$F3,$50,$F2,$F0,$F2,$00,$F2         ; F881: 88 F3 50 F2 F0 F2 00 F2
    .byte $C8,$F3,$10,$21,$F0,$F1,$00,$F1         ; F889: C8 F3 10 21 F0 F1 00 F1
    .byte $48,$F1,$C8,$F2,$10,$F3,$58,$F3         ; F891: 48 F1 C8 F2 10 F3 58 F3
    .byte $20,$F3,$68,$F2,$30,$F3,$78,$F3         ; F899: 20 F3 68 F2 30 F3 78 F3
    .byte $40,$F3,$88,$F2,$50,$31,$00,$81         ; F8A1: 40 F3 88 F2 50 31 00 81
    .byte $48,$81,$C8,$B2,$10,$B3,$58,$B3         ; F8A9: 48 81 C8 B2 10 B3 58 B3
    .byte $FF,$A3,$FF,$92,$30,$83,$78,$73         ; F8B1: FF A3 FF 92 30 83 78 73
    .byte $40,$63,$88,$53,$50,$22,$F0,$32         ; F8B9: 40 63 88 53 50 22 F0 32
    .byte $00,$42,$48,$42,$C8,$32,$10,$FF         ; F8C1: 00 42 48 42 C8 32 10 FF
    .byte $23,$30,$F0,$0D,$E0,$0E,$B0,$0F         ; F8C9: 23 30 F0 0D E0 0E B0 0F
    .byte $F0,$06,$E0,$08,$F0,$08,$E0,$08         ; F8D1: F0 06 E0 08 F0 08 E0 08
    .byte $F0,$08,$B0,$08,$A0,$08,$90,$08         ; F8D9: F0 08 B0 08 A0 08 90 08
    .byte $80,$08,$70,$08,$60,$0C,$50,$08         ; F8E1: 80 08 70 08 60 0C 50 08
    .byte $40,$08,$30,$06,$FF,$21,$30,$10         ; F8E9: 40 08 30 06 FF 21 30 10
    .byte $8A,$F2,$5B,$E2,$03,$81,$CD,$00         ; F8F1: 8A F2 5B E2 03 81 CD 00
    .byte $00,$25,$B0,$10,$83,$F1,$5B,$C1         ; F8F9: 00 25 B0 10 83 F1 5B C1
    .byte $03,$70,$CD,$51,$5B,$31,$03,$FF         ; F901: 03 70 CD 51 5B 31 03 FF
    .byte $D7,$B6,$FF,$E3,$90,$C0,$90,$E2         ; F909: D7 B6 FF E3 90 C0 90 E2
    .byte $20,$40,$90,$E3,$90,$90,$C0,$E2         ; F911: 20 40 90 E3 90 90 C0 E2
    .byte $50,$E3,$50,$70,$70,$E2,$70,$E3         ; F919: 50 E3 50 70 70 E2 70 E3
    .byte $70,$90,$FE,$02,$09,$F9,$D7,$F5         ; F921: 70 90 FE 02 09 F9 D7 F5
    .byte $41,$E1,$43,$23,$03,$E2,$B3,$E1         ; F929: 41 E1 43 23 03 E2 B3 E1
    .byte $03,$E2,$B3,$93,$73,$FE,$02,$2A         ; F931: 03 E2 B3 93 73 FE 02 2A
    .byte $F9,$E1,$73,$53,$43,$23,$43,$23         ; F939: F9 E1 73 53 43 23 43 23
    .byte $43,$53,$FE,$02,$3B,$F9,$53,$33         ; F941: 43 53 FE 02 3B F9 53 33
    .byte $23,$03,$73,$53,$03,$20,$00,$E2         ; F949: 23 03 73 53 03 20 00 E2
    .byte $70,$90,$FE,$FF,$09,$F9,$D7,$0A         ; F951: 70 90 FE FF 09 F9 D7 0A
    .byte $EF,$E3,$90,$C0,$EF,$90,$EF,$E2         ; F959: EF E3 90 C0 EF 90 EF E2
    .byte $20,$EE,$40,$90,$EF,$E3,$90,$EF         ; F961: 20 EE 40 90 EF E3 90 EF
    .byte $90,$C0,$EF,$E2,$50,$EF,$E3,$50         ; F969: 90 C0 EF E2 50 EF E3 50
    .byte $EF,$70,$EE,$70,$E2,$70,$EE,$E3         ; F971: EF 70 EE 70 E2 70 EE E3
    .byte $70,$90,$FE,$06,$5B,$F9,$EF,$E2         ; F979: 70 90 FE 06 5B F9 EF E2
    .byte $00,$C0,$EF,$00,$EF,$00,$EE,$E3         ; F981: 00 C0 EF 00 EF 00 EE E3
    .byte $70,$EF,$E2,$00,$EF,$70,$EF,$00         ; F989: 70 EF E2 00 EF 70 EF 00
    .byte $C0,$EF,$00,$EE,$E3,$70,$EF,$E2         ; F991: C0 EF 00 EE E3 70 EF E2
    .byte $00,$EF,$00,$EE,$70,$EE,$00,$EE         ; F999: 00 EF 00 EE 70 EE 00 EE
    .byte $00,$FE,$04,$7F,$F9,$EF,$E3,$80         ; F9A1: 00 FE 04 7F F9 EF E3 80
    .byte $C0,$EF,$80,$EF,$80,$EE,$E2,$80         ; F9A9: C0 EF 80 EF 80 EE E2 80
    .byte $EF,$E3,$81,$EF,$80,$C0,$EF,$80         ; F9B1: EF E3 81 EF 80 C0 EF 80
    .byte $EE,$E2,$80,$EF,$E3,$80,$EE,$81         ; F9B9: EE E2 80 EF E3 80 EE 81
    .byte $EE,$81,$EF,$A0,$C0,$EF,$A0,$EF         ; F9C1: EE 81 EF A0 C0 EF A0 EF
    .byte $A0,$EE,$E2,$A0,$EF,$E3,$A1,$EF         ; F9C9: A0 EE E2 A0 EF E3 A1 EF
    .byte $A0,$C0,$EF,$A0,$EE,$E2,$A0,$EF         ; F9D1: A0 C0 EF A0 EE E2 A0 EF
    .byte $E3,$A0,$EF,$A0,$EE,$A0,$EE,$A0         ; F9D9: E3 A0 EF A0 EE A0 EE A0
    .byte $EE,$A0,$FE,$FF,$57,$F9,$D5,$B8         ; F9E1: EE A0 FE FF 57 F9 D5 B8
    .byte $51,$E2,$C1,$B1,$B1,$B1,$91,$B3         ; F9E9: 51 E2 C1 B1 B1 B1 91 B3
    .byte $E1,$03,$01,$E2,$B3,$91,$B5,$C1         ; F9F1: E1 03 01 E2 B3 91 B5 C1
    .byte $B1,$B1,$B1,$91,$B3,$E1,$23,$21         ; F9F9: B1 B1 B1 91 B3 E1 23 21
    .byte $03,$E2,$71,$95,$C1,$B1,$B1,$B1         ; FA01: 03 E2 71 95 C1 B1 B1 B1
    .byte $91,$B3,$E1,$43,$41,$23,$01,$E2         ; FA09: 91 B3 E1 43 41 23 01 E2
    .byte $B5,$C1,$71,$71,$71,$91,$73,$93         ; FA11: B5 C1 71 71 71 91 73 93
    .byte $B1,$91,$71,$C1,$01,$11,$21,$C1         ; FA19: B1 91 71 C1 01 11 21 C1
    .byte $D5,$78,$61,$91,$91,$91,$91,$23         ; FA21: D5 78 61 91 91 91 91 23
    .byte $E1,$03,$01,$E2,$B3,$91,$75,$C1         ; FA29: E1 03 01 E2 B3 91 75 C1
    .byte $91,$91,$91,$91,$23,$E1,$23,$21         ; FA31: 91 91 91 91 23 E1 23 21
    .byte $21,$43,$25,$C1,$E2,$91,$91,$91         ; FA39: 21 43 25 C1 E2 91 91 91
    .byte $91,$23,$E1,$23,$03,$E2,$B3,$91         ; FA41: 91 23 E1 23 03 E2 B3 91
    .byte $93,$C1,$21,$21,$21,$41,$41,$21         ; FA49: 93 C1 21 21 21 41 41 21
    .byte $21,$E1,$21,$21,$21,$43,$25,$D5         ; FA51: 21 E1 21 21 21 43 25 D5
    .byte $B7,$32,$E2,$C3,$B3,$B1,$E1,$01         ; FA59: B7 32 E2 C3 B3 B1 E1 01
    .byte $C1,$E2,$B0,$90,$C1,$71,$7B,$FE         ; FA61: C1 E2 B0 90 C1 71 7B FE
    .byte $02,$58,$FA,$FE,$FF,$E7,$F9,$D5         ; FA69: 02 58 FA FE FF E7 F9 D5
    .byte $0E,$EF,$E2,$71,$EF,$71,$EE,$71         ; FA71: 0E EF E2 71 EF 71 EE 71
    .byte $EF,$71,$EF,$71,$EF,$21,$EE,$41         ; FA79: EF 71 EF 71 EF 21 EE 41
    .byte $EF,$71,$FE,$02,$70,$FA,$EF,$51         ; FA81: EF 71 FE 02 70 FA EF 51
    .byte $EF,$51,$EE,$51,$EF,$FD,$37,$FB         ; FA89: EF 51 EE 51 EF FD 37 FB
    .byte $01,$EF,$01,$EF,$01,$EF,$E3,$71         ; FA91: 01 EF 01 EF 01 EF E3 71
    .byte $EE,$91,$EF,$E2,$01,$EF,$71,$EF         ; FA99: EE 91 EF E2 01 EF 71 EF
    .byte $71,$EE,$E1,$21,$EF,$E2,$71,$EF         ; FAA1: 71 EE E1 21 EF E2 71 EF
    .byte $71,$EF,$21,$EE,$41,$EF,$71,$FE         ; FAA9: 71 EF 21 EE 41 EF 71 FE
    .byte $02,$9E,$FA,$51,$EF,$51,$EE,$E1         ; FAB1: 02 9E FA 51 EF 51 EE E1
    .byte $01,$EF,$E2,$FD,$37,$FB,$71,$EF         ; FAB9: 01 EF E2 FD 37 FB 71 EF
    .byte $01,$EF,$01,$EE,$E3,$71,$EE,$81         ; FAC1: 01 EF 01 EE E3 71 EE 81
    .byte $EE,$91,$D5,$0C,$EF,$E2,$21,$FE         ; FAC9: EE 91 D5 0C EF E2 21 FE
    .byte $0D,$CD,$FA,$EE,$01,$EE,$11,$EF         ; FAD1: 0D CD FA EE 01 EE 11 EF
    .byte $E2,$21,$FE,$0A,$D8,$FA,$EE,$01         ; FAD9: E2 21 FE 0A D8 FA EE 01
    .byte $EE,$01,$EF,$21,$EF,$21,$EE,$01         ; FAE1: EE 01 EF 21 EF 21 EE 01
    .byte $EE,$01,$EE,$21,$D5,$0C,$EF,$E2         ; FAE9: EE 01 EE 21 D5 0C EF E2
    .byte $21,$FE,$0D,$EF,$FA,$EE,$01,$EE         ; FAF1: 21 FE 0D EF FA EE 01 EE
    .byte $11,$EF,$E2,$21,$FE,$0A,$FA,$FA         ; FAF9: 11 EF E2 21 FE 0A FA FA
    .byte $EE,$01,$EE,$01,$EF,$21,$EF,$21         ; FB01: EE 01 EE 01 EF 21 EF 21
    .byte $EE,$01,$EE,$01,$EE,$21,$EF,$71         ; FB09: EE 01 EE 01 EE 21 EF 71
    .byte $EF,$71,$EF,$71,$EF,$71,$EF,$71         ; FB11: EF 71 EF 71 EF 71 EF 71
    .byte $EF,$71,$EF,$71,$EF,$71,$EF,$51         ; FB19: EF 71 EF 71 EF 71 EF 51
    .byte $EF,$01,$EF,$01,$EF,$01,$EF,$01         ; FB21: EF 01 EF 01 EF 01 EF 01
    .byte $EE,$01,$EE,$01,$EE,$01,$FE,$02         ; FB29: EE 01 EE 01 EE 01 FE 02
    .byte $0F,$FB,$FE,$FF,$70,$FA,$51,$EF         ; FB31: 0F FB FE FF 70 FA 51 EF
    .byte $51,$EF,$01,$EE,$21,$EF,$51,$EF         ; FB39: 51 EF 01 EE 21 EF 51 EF
    .byte $01,$EF,$01,$EE,$FF,$D8,$BA,$51         ; FB41: 01 EF 01 EE FF D8 BA 51
    .byte $E1,$90,$50,$E0,$00,$E1,$90,$A0         ; FB49: E1 90 50 E0 00 E1 90 A0
    .byte $90,$70,$90,$C0,$90,$91,$70,$50         ; FB51: 90 70 90 C0 90 91 70 50
    .byte $40,$50,$C0,$50,$51,$20,$00,$E2         ; FB59: 40 50 C0 50 51 20 00 E2
    .byte $A0,$95,$FF,$D8,$F8,$24,$E2,$50         ; FB61: A0 95 FF D8 F8 24 E2 50
    .byte $20,$90,$40,$70,$50,$40,$50,$C0         ; FB69: 20 90 40 70 50 40 50 C0
    .byte $50,$51,$40,$20,$00,$20,$C0,$20         ; FB71: 50 51 40 20 00 20 C0 20
    .byte $21,$E2,$A0,$90,$70,$55,$FF,$D8         ; FB79: 21 E2 A0 90 70 55 FF D8
    .byte $2E,$E2,$51,$E1,$51,$E2,$41,$E1         ; FB81: 2E E2 51 E1 51 E2 41 E1
    .byte $40,$D8,$0E,$E2,$20,$C0,$20,$D8         ; FB89: 40 D8 0E E2 20 C0 20 D8
    .byte $2E,$21,$01,$00,$D8,$0E,$E3,$A0         ; FB91: 2E 21 01 00 D8 0E E3 A0
    .byte $C0,$A0,$D8,$2E,$A1,$E2,$00,$01         ; FB99: C0 A0 D8 2E A1 E2 00 01
    .byte $51,$01,$E3,$90,$54,$FF,$E8,$D2         ; FBA1: 51 01 E3 90 54 FF E8 D2
    .byte $B9,$22,$C0,$D5,$B9,$22,$E1,$51         ; FBA9: B9 22 C0 D5 B9 22 E1 51
    .byte $43,$01,$E2,$93,$E1,$51,$43,$09         ; FBB1: 43 01 E2 93 E1 51 43 09
    .byte $E2,$93,$E1,$03,$DA,$BA,$22,$E1         ; FBB9: E2 93 E1 03 DA BA 22 E1
    .byte $2B,$D5,$B9,$22,$E1,$71,$53,$51         ; FBC1: 2B D5 B9 22 E1 71 53 51
    .byte $43,$51,$43,$01,$E2,$93,$E1,$51         ; FBC9: 43 51 43 01 E2 93 E1 51
    .byte $43,$09,$E2,$93,$E1,$03,$DA,$B9         ; FBD1: 43 09 E2 93 E1 03 DA B9
    .byte $22,$E1,$9B,$D5,$B9,$22,$E1,$71         ; FBD9: 22 E1 9B D5 B9 22 E1 71
    .byte $93,$91,$A3,$DA,$B9,$34,$E0,$0B         ; FBE1: 93 91 A3 DA B9 34 E0 0B
    .byte $D5,$B9,$34,$E1,$31,$83,$81,$A3         ; FBE9: D5 B9 34 E1 31 83 81 A3
    .byte $DA,$B9,$34,$E0,$0B,$D5,$B9,$34         ; FBF1: DA B9 34 E0 0B D5 B9 34
    .byte $E1,$31,$83,$81,$A3,$E0,$03,$E1         ; FBF9: E1 31 83 81 A3 E0 03 E1
    .byte $73,$53,$E0,$05,$E1,$71,$53,$71         ; FC01: 73 53 E0 05 E1 71 53 71
    .byte $51,$4F,$FF,$D5,$3E,$E2,$53,$E1         ; FC09: 51 4F FF D5 3E E2 53 E1
    .byte $03,$53,$E2,$53,$E1,$03,$53,$E2         ; FC11: 03 53 E2 53 E1 03 53 E2
    .byte $53,$E1,$03,$53,$E2,$53,$E1,$23         ; FC19: 53 E1 03 53 E2 53 E1 23
    .byte $73,$E2,$53,$E1,$23,$73,$E2,$53         ; FC21: 73 E2 53 E1 23 73 E2 53
    .byte $E1,$23,$73,$FE,$02,$0C,$FC,$E2         ; FC29: E1 23 73 FE 02 0C FC E2
    .byte $83,$E1,$33,$83,$FE,$03,$30,$FC         ; FC31: 83 E1 33 83 FE 03 30 FC
    .byte $E2,$A3,$E1,$53,$A3,$FE,$03,$39         ; FC39: E2 A3 E1 53 A3 FE 03 39
    .byte $FC,$E2,$03,$73,$E1,$03,$FE,$02         ; FC41: FC E2 03 73 E1 03 FE 02
    .byte $42,$FC,$01,$E2,$71,$51,$71,$21         ; FC49: 42 FC 01 E2 71 51 71 21
    .byte $71,$D5,$7E,$E2,$07,$FF,$FD,$A9         ; FC51: 71 D5 7E E2 07 FF FD A9
    .byte $FC,$E2,$50,$D7,$30,$C3,$EA,$D5         ; FC59: FC E2 50 D7 30 C3 EA D5
    .byte $30,$CC,$EA,$CC,$EA,$C6,$FD,$A9         ; FC61: 30 CC EA CC EA C6 FD A9
    .byte $FC,$50,$C3,$D5,$30,$EA,$CC,$EA         ; FC69: FC 50 C3 D5 30 EA CC EA
    .byte $CC,$EA,$C6,$FD,$B7,$FC,$E2,$A0         ; FC71: CC EA C6 FD B7 FC E2 A0
    .byte $C3,$D5,$30,$EB,$CC,$EB,$CC,$EB         ; FC79: C3 D5 30 EB CC EB CC EB
    .byte $C6,$FD,$B7,$FC,$A0,$D7,$30,$C3         ; FC81: C6 FD B7 FC A0 D7 30 C3
    .byte $EB,$D5,$30,$CC,$EB,$C6,$D7,$09         ; FC89: EB D5 30 CC EB C6 D7 09
    .byte $E1,$A0,$E2,$A1,$E1,$90,$E2,$91         ; FC91: E1 A0 E2 A1 E1 90 E2 91
    .byte $E1,$80,$E2,$81,$E1,$70,$E2,$71         ; FC99: E1 80 E2 81 E1 70 E2 71
    .byte $60,$50,$40,$30,$FE,$FF,$57,$FC         ; FCA1: 60 50 40 30 FE FF 57 FC
    .byte $D7,$09,$E2,$20,$20,$E1,$20,$E2         ; FCA9: D7 09 E2 20 20 E1 20 E2
    .byte $20,$70,$90,$E1,$00,$FF,$D7,$09         ; FCB1: 20 70 90 E1 00 FF D7 09
    .byte $E2,$70,$70,$E1,$70,$E2,$70,$E1         ; FCB9: E2 70 70 E1 70 E2 70 E1
    .byte $00,$20,$50,$FF,$FF,$D6,$78,$FF         ; FCC1: 00 20 50 FF FF D6 78 FF
    .byte $E2,$21,$C1,$E1,$21,$E2,$21,$71         ; FCC9: E2 21 C1 E1 21 E2 21 71
    .byte $91,$E1,$01,$21,$C1,$E2,$20,$20         ; FCD1: 91 E1 01 21 C1 E2 20 20
    .byte $E1,$21,$E2,$21,$71,$91,$E1,$01         ; FCD9: E1 21 E2 21 71 91 E1 01
    .byte $21,$E2,$21,$C1,$E1,$21,$E2,$21         ; FCE1: 21 E2 21 C1 E1 21 E2 21
    .byte $71,$91,$E1,$01,$21,$C1,$D6,$B5         ; FCE9: 71 91 E1 01 21 C1 D6 B5
    .byte $11,$E2,$20,$20,$E1,$21,$E2,$21         ; FCF1: 11 E2 20 20 E1 21 E2 21
    .byte $71,$91,$E1,$71,$51,$95,$B0,$E0         ; FCF9: 71 91 E1 71 51 95 B0 E0
    .byte $10,$DC,$B7,$22,$2B,$E1,$62,$42         ; FD01: 10 DC B7 22 2B E1 62 42
    .byte $69,$D6,$F8,$61,$E2,$C3,$93,$51         ; FD09: 69 D6 F8 61 E2 C3 93 51
    .byte $93,$51,$A3,$93,$73,$51,$70,$9C         ; FD11: 93 51 A3 93 73 51 70 9C
    .byte $01,$21,$C1,$E3,$21,$21,$21,$41         ; FD19: 01 21 C1 E3 21 21 21 41
    .byte $51,$71,$51,$E2,$C3,$91,$91,$93         ; FD21: 51 71 51 E2 C3 91 91 93
    .byte $93,$A3,$93,$73,$53,$C1,$51,$51         ; FD29: 93 A3 93 73 53 C1 51 51
    .byte $51,$71,$93,$43,$41,$53,$73,$93         ; FD31: 51 71 93 43 41 53 73 93
    .byte $C3,$D6,$B6,$41,$E1,$03,$E2,$A3         ; FD39: C3 D6 B6 41 E1 03 E2 A3
    .byte $93,$73,$53,$41,$55,$C3,$93,$73         ; FD41: 93 73 53 41 55 C3 93 73
    .byte $53,$43,$23,$11,$25,$C3,$E1,$03         ; FD49: 53 43 23 11 25 C3 E1 03
    .byte $E2,$A3,$93,$73,$51,$93,$91,$71         ; FD51: E2 A3 93 73 51 93 91 71
    .byte $51,$C3,$D6,$F8,$51,$E2,$92,$90         ; FD59: 51 C3 D6 F8 51 E2 92 90
    .byte $93,$E3,$92,$90,$93,$E2,$93,$93         ; FD61: 93 E3 92 90 93 E2 93 93
    .byte $93,$C3,$92,$90,$91,$71,$51,$E3         ; FD69: 93 C3 92 90 91 71 51 E3
    .byte $90,$70,$51,$C1,$E2,$A3,$A5,$E1         ; FD71: 90 70 51 C1 E2 A3 A5 E1
    .byte $00,$26,$01,$0F,$E2,$91,$E1,$01         ; FD79: 00 26 01 0F E2 91 E1 01
    .byte $01,$03,$03,$21,$C1,$E3,$51,$91         ; FD81: 01 03 03 21 C1 E3 51 91
    .byte $E2,$01,$E1,$52,$42,$21,$03,$00         ; FD89: E2 01 E1 52 42 21 03 00
    .byte $22,$D6,$F9,$FF,$E2,$21,$C1,$E1         ; FD91: 22 D6 F9 FF E2 21 C1 E1
    .byte $21,$E2,$21,$71,$91,$E1,$01,$21         ; FD99: 21 E2 21 71 91 E1 01 21
    .byte $C1,$E2,$20,$20,$E1,$21,$E2,$21         ; FDA1: C1 E2 20 20 E1 21 E2 21
    .byte $71,$91,$E1,$01,$21,$E2,$21,$C1         ; FDA9: 71 91 E1 01 21 E2 21 C1
    .byte $E1,$21,$E2,$21,$71,$91,$E1,$01         ; FDB1: E1 21 E2 21 71 91 E1 01
    .byte $21,$C1,$E2,$20,$20,$E1,$21,$E2         ; FDB9: 21 C1 E2 20 20 E1 21 E2
    .byte $21,$41,$51,$71,$51,$FE,$FF,$0A         ; FDC1: 21 41 51 71 51 FE FF 0A
    .byte $FD,$D6,$0E,$E1,$21,$FE,$10,$CD         ; FDC9: FD D6 0E E1 21 FE 10 CD
    .byte $FD,$E2,$EF,$21,$FE,$0E,$D3,$FD         ; FDD1: FD E2 EF 21 FE 0E D3 FD
    .byte $EE,$50,$EE,$10,$EE,$E3,$71,$EE         ; FDD9: EE 50 EE 10 EE E3 71 EE
    .byte $E2,$21,$C1,$E1,$21,$EE,$E2,$21         ; FDE1: E2 21 C1 E1 21 EE E2 21
    .byte $EE,$71,$91,$E1,$01,$EE,$21,$C1         ; FDE9: EE 71 91 E1 01 EE 21 C1
    .byte $E2,$20,$20,$E1,$21,$E2,$21,$EE         ; FDF1: E2 20 20 E1 21 E2 21 EE
    .byte $71,$91,$EE,$E1,$01,$21,$FE,$02         ; FDF9: 71 91 EE E1 01 21 FE 02
    .byte $E0,$FD,$D6,$0E,$E2,$FD,$20,$FF         ; FE01: E0 FD D6 0E E2 FD 20 FF
    .byte $E2,$FD,$20,$FF,$FD,$2F,$FF,$EF         ; FE09: E2 FD 20 FF FD 2F FF EF
    .byte $21,$EF,$21,$EE,$91,$EF,$21,$EF         ; FE11: 21 EF 21 EE 91 EF 21 EF
    .byte $41,$EF,$51,$EE,$71,$EF,$51,$EF         ; FE19: 41 EF 51 EE 71 EF 51 EF
    .byte $51,$EF,$51,$EE,$E1,$01,$EF,$E2         ; FE21: 51 EF 51 EE E1 01 EF E2
    .byte $51,$FE,$04,$20,$FE,$FD,$2F,$FF         ; FE29: 51 FE 04 20 FE FD 2F FF
    .byte $FD,$2F,$FF,$E3,$FD,$3C,$FF,$EF         ; FE31: FD 2F FF E3 FD 3C FF EF
    .byte $A1,$EF,$51,$EE,$71,$EF,$A1,$FD         ; FE39: A1 EF 51 EE 71 EF A1 FD
    .byte $55,$FF,$EF,$E3,$71,$EE,$91,$EF         ; FE41: 55 FF EF E3 71 EE 91 EF
    .byte $E2,$01,$EF,$51,$EF,$51,$EE,$91         ; FE49: E2 01 EF 51 EF 51 EE 91
    .byte $EF,$51,$EF,$51,$EF,$51,$EE,$E1         ; FE51: EF 51 EF 51 EF 51 EE E1
    .byte $01,$EF,$E2,$51,$EF,$71,$EF,$E3         ; FE59: 01 EF E2 51 EF 71 EF E3
    .byte $71,$EE,$71,$EF,$71,$EF,$91,$EE         ; FE61: 71 EE 71 EF 71 EF 91 EE
    .byte $91,$EE,$A1,$EE,$E2,$01,$EF,$E3         ; FE69: 91 EE A1 EE E2 01 EF E3
    .byte $A1,$EF,$A1,$EE,$E2,$51,$EF,$E3         ; FE71: A1 EF A1 EE E2 51 EF E3
    .byte $A1,$FD,$3C,$FF,$FD,$55,$FF,$EE         ; FE79: A1 FD 3C FF FD 55 FF EE
    .byte $01,$EE,$21,$EE,$41,$EF,$E2,$51         ; FE81: 01 EE 21 EE 41 EF E2 51
    .byte $EF,$E1,$50,$50,$EE,$E2,$51,$EF         ; FE89: EF E1 50 50 EE E2 51 EF
    .byte $E1,$50,$50,$FE,$04,$86,$FE,$EF         ; FE91: E1 50 50 FE 04 86 FE EF
    .byte $FD,$47,$FF,$EE,$FD,$47,$FF,$EF         ; FE99: FD 47 FF EE FD 47 FF EF
    .byte $FD,$47,$FF,$EE,$FD,$47,$FF,$EF         ; FEA1: FD 47 FF EE FD 47 FF EF
    .byte $E3,$A1,$EF,$E2,$A0,$A0,$EE,$E3         ; FEA9: E3 A1 EF E2 A0 A0 EE E3
    .byte $A1,$EF,$E2,$A0,$A0,$FE,$02,$A8         ; FEB1: A1 EF E2 A0 A0 FE 02 A8
    .byte $FE,$E2,$EF,$01,$EF,$E1,$00,$00         ; FEB9: FE E2 EF 01 EF E1 00 00
    .byte $EE,$E2,$01,$EF,$E1,$00,$00,$FE         ; FEC1: EE E2 01 EF E1 00 00 FE
    .byte $03,$BA,$FE,$EF,$FD,$4E,$FF,$EE         ; FEC9: 03 BA FE EF FD 4E FF EE
    .byte $FD,$4E,$FF,$D6,$1E,$EF,$E3,$92         ; FED1: FD 4E FF D6 1E EF E3 92
    .byte $EF,$90,$EE,$E2,$41,$EF,$93,$EE         ; FED9: EF 90 EE E2 41 EF 93 EE
    .byte $E3,$91,$EE,$E2,$41,$EE,$91,$EF         ; FEE1: E3 91 EE E2 41 EE 91 EF
    .byte $E3,$A2,$EF,$A0,$EE,$E2,$21,$EF         ; FEE9: E3 A2 EF A0 EE E2 21 EF
    .byte $51,$EF,$01,$EE,$01,$EE,$21,$EE         ; FEF1: 51 EF 01 EE 01 EE 21 EE
    .byte $41,$23,$C1,$EE,$21,$EE,$23,$C1         ; FEF9: 41 23 C1 EE 21 EE 23 C1
    .byte $EE,$21,$C7,$EE,$E3,$93,$EE,$E2         ; FF01: EE 21 C7 EE E3 93 EE E2
    .byte $03,$EE,$23,$C1,$EE,$21,$EE,$23         ; FF09: 03 EE 23 C1 EE 21 EE 23
    .byte $C1,$EE,$21,$C7,$EF,$03,$EE,$E2         ; FF11: C1 EE 21 C7 EF 03 EE E2
    .byte $21,$EE,$41,$FE,$FF,$03,$FE,$EF         ; FF19: 21 EE 41 FE FF 03 FE EF
    .byte $51,$EF,$51,$EE,$E1,$01,$EF,$E2         ; FF21: 51 EF 51 EE E1 01 EF E2
    .byte $51,$FE,$02,$20,$FF,$FF,$EF,$21         ; FF29: 51 FE 02 20 FF FF EF 21
    .byte $EF,$21,$EE,$91,$EF,$21,$FE,$02         ; FF31: EF 21 EE 91 EF 21 FE 02
    .byte $2F,$FF,$FF,$EF,$A1,$EF,$A1,$EE         ; FF39: 2F FF FF EF A1 EF A1 EE
    .byte $E2,$51,$EF,$E3,$A1,$FF,$E2,$21         ; FF41: E2 51 EF E3 A1 FF E2 21
    .byte $EF,$E1,$20,$20,$FF,$E2,$01,$EE         ; FF49: EF E1 20 20 FF E2 01 EE
    .byte $E1,$00,$00,$FF,$EF,$E2,$01,$EF         ; FF51: E1 00 00 FF EF E2 01 EF
    .byte $01,$EE,$71,$EF,$01,$EF,$01,$FF         ; FF59: 01 EE 71 EF 01 EF 01 FF
    .byte $D6,$BA,$22,$E1,$C2,$52,$42,$21         ; FF61: D6 BA 22 E1 C2 52 42 21
    .byte $00,$90,$C0,$52,$01,$20,$A0,$C0         ; FF69: 00 90 C0 52 01 20 A0 C0
    .byte $71,$40,$50,$70,$51,$FF,$D6,$BA         ; FF71: 71 40 50 70 51 FF D6 BA
    .byte $22,$E1,$C2,$02,$02,$E2,$A1,$90         ; FF79: 22 E1 C2 02 02 E2 A1 90
    .byte $E1,$00,$C0,$02,$E2,$91,$A0,$E1         ; FF81: E1 00 C0 02 E2 91 A0 E1
    .byte $70,$C0,$40,$00,$00,$20,$40,$E2         ; FF89: 70 C0 40 00 00 20 40 E2
    .byte $91,$FF,$D6,$0E,$E3,$C2,$51,$E2         ; FF91: 91 FF D6 0E E3 C2 51 E2
    .byte $50,$50,$E3,$51,$E2,$50,$50,$E3         ; FF99: 50 50 E3 51 E2 50 50 E3
    .byte $91,$E2,$90,$90,$E3,$91,$E2,$90         ; FFA1: 91 E2 90 90 E3 91 E2 90
    .byte $90,$D6,$1E,$E3,$A1,$A1,$E2,$03         ; FFA9: 90 D6 1E E3 A1 A1 E2 03
    .byte $51,$FF,$D6,$BA,$22,$E1,$90,$50         ; FFB1: 51 FF D6 BA 22 E1 90 50
    .byte $90,$50,$A0,$70,$A0,$70,$C0,$00         ; FFB9: 90 50 A0 70 A0 70 C0 00
    .byte $C0,$00,$20,$40,$50,$70,$FE,$FF         ; FFC1: C0 00 20 40 50 70 FE FF
    .byte $B7,$FF,$D6,$0E,$E1,$51,$51,$71         ; FFC9: B7 FF D6 0E E1 51 51 71
    .byte $71,$01,$01,$20,$40,$50,$70,$FE         ; FFD1: 71 01 01 20 40 50 70 FE
    .byte $FF,$CE,$FF,$FF,$FF,$FF,$FF,$FF         ; FFD9: FF CE FF FF FF FF FF FF
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; FFE1: FF FF FF FF FF FF FF FF
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; FFE9: FF FF FF FF FF FF FF FF
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; FFF1: FF FF FF FF FF FF FF FF
    .byte $FF,$8F,$80,$11,$80,$14,$81             ; FFF9: FF 8F 80 11 80 14 81
