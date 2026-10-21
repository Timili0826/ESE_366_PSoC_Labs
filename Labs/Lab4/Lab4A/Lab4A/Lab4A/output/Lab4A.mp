Project:      output/Lab4A
Build Number: 0
Date:         Tue Oct 13 21:16:45 2026
Compiler:     ICCM8C
Version:      7.05.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             lit   0190   010E =    270. bytes (rel,con,rom,lit)

       Addr  Global Symbol
      -----  --------------------------------
       019E  LoadConfigTBL_lab4a_Bank0
       0207  LoadConfigTBL_lab4a_Bank1
       029E  __lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                        func_lit   029E   0002 =      2. bytes (rel,con,rom,proclab)

       Addr  Global Symbol
      -----  --------------------------------
       029E  __func_lit_start
       02A0  __func_lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     psoc_config   02A0   0127 =    295. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       02A0  LoadConfigTBL_lab4a_Ordered
       0365  LoadConfigInit
       0365  _LoadConfigInit
       036C  LoadConfig_lab4a
       036C  _LoadConfig_lab4a
       03C7  __psoc_config_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     UserModules   03C7   02D6 =    726. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       03C7  _LCD_PrCString
       03C7  LCD_PrCString
       03D9  LCD_HEX_STR
       03E9  _LCD_PrHexByte
       03E9  LCD_PrHexByte
       03FC  _LCD_PrHexInt
       03FC  LCD_PrHexInt
       0403  LCD_PrString
       0403  _LCD_PrString
       0415  LCD_Write_Data
       0415  _LCD_WriteData
       0415  LCD_WriteData
       0415  _LCD_Write_Data
       0429  _LCD_Control
       0429  LCD_Control
       04D9  LCD_Start
       04D9  _LCD_Start
       04D9  LCD_Init
       04D9  _LCD_Init
       0548  LCD_ROW_OFFSET
       054C  _LCD_Position
       054C  LCD_Position
       055C  _LCD_Delay50uTimes
       055C  LCD_Delay50uTimes
       0562  LCD_Delay50u_Table
       056A  _LCD_Delay50u
       056A  LCD_Delay50u
       057E  _LCD_DrawBG
       05AF  _LCD_DrawVBG
       05E3  LCD_InitVBG
       05E3  _LCD_InitVBG
       0614  LCD_BG_TYPE1
       061B  LCD_BG_TYPE2
       0622  LCD_InitBG
       0622  _LCD_InitBG
       0656  _FanPWM_ISR
       0657  FanPWM_EnableInt
       0657  _FanPWM_EnableInt
       065B  _FanPWM_DisableInt
       065B  FanPWM_DisableInt
       065F  _FanPWM_Start
       065F  FanPWM_Start
       0663  _FanPWM_Stop
       0663  FanPWM_Stop
       0667  FanPWM_WritePeriod
       0667  _FanPWM_WritePeriod
       066A  FanPWM_WritePulseWidth
       066A  _FanPWM_WritePulseWidth
       066D  _bFanPWM_ReadPulseWidth
       066D  _FanPWM_bReadPulseWidth
       066D  bFanPWM_ReadPulseWidth
       066D  FanPWM_bReadPulseWidth
       0670  _bFanPWM_ReadCounter
       0670  _FanPWM_bReadCounter
       0670  FanPWM_bReadCounter
       0670  bFanPWM_ReadCounter
       069D  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   069D   0351 =    849. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       069D  _main
       069D  __text_start
       06F4  _SleepTimerISR
       0815  _itoa
       09EE  __text_end
       09EE  __xidata_start
       09FB  __xidata_end

Area                               Start  End    Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             TOP   0000   0151 =    337. bytes (abs,ovr,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       0080  __Start
       014E  _bGetPowerSetting
       014E  bGetPowerSetting

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
               virtual_registers   0020   000F =     15. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0020  __rZ
       0021  __rY
       0022  __rX
       0023  __r11
       0024  __r10
       0025  __r9
       0026  __r8
       0027  __r7
       0028  __r6
       0029  __r5
       002A  __r4
       002B  __r3
       002C  __r2
       002D  __r1
       002E  __r0

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            data   0000   0024 =     36. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  __data_start
       0000  _string
       002F  _pulse_read
       0031  _pulse_width

Files Linked      [ module(s) ]

./obj/boot.o	[ boot.asm ]
obj/main.o	[ main.c ]
<library>	[ psocconfigtbl.asm, psocconfig.asm, lcd.asm, fanpwmint.asm, fanpwm.asm, rZ.asm, rY.asm, rX.asm, r11.asm ]
[ r10.asm, r9.asm, r8.asm, r7.asm, r6.asm, r5.asm, r4.asm, r3.asm, r2.asm, r1.asm, r0.asm, divmodu_16x16_16_util.asm ]
[ i_div16_block_util.asm, itoa.s ]

Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0x20
-Blab4a_RAM	allocated at: 0
-rwh:SSCParmBlk:0xf7.0xff

