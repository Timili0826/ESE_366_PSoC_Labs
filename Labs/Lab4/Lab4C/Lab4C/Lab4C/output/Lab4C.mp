Project:      output/Lab4C
Build Number: 0
Date:         Tue Oct 13 22:19:57 2026
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
                     UserModules   03C7   02FB =    763. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       03C7  _FanPWM_ISR
       03ED  _LCD_PrCString
       03ED  LCD_PrCString
       03FF  LCD_HEX_STR
       040F  LCD_PrHexByte
       040F  _LCD_PrHexByte
       0422  _LCD_PrHexInt
       0422  LCD_PrHexInt
       0429  LCD_PrString
       0429  _LCD_PrString
       043B  _LCD_Write_Data
       043B  LCD_Write_Data
       043B  _LCD_WriteData
       043B  LCD_WriteData
       044F  LCD_Control
       044F  _LCD_Control
       04FF  LCD_Start
       04FF  _LCD_Start
       04FF  _LCD_Init
       04FF  LCD_Init
       056E  LCD_ROW_OFFSET
       0572  LCD_Position
       0572  _LCD_Position
       0582  LCD_Delay50uTimes
       0582  _LCD_Delay50uTimes
       0588  LCD_Delay50u_Table
       0590  LCD_Delay50u
       0590  _LCD_Delay50u
       05A4  _LCD_DrawBG
       05D5  _LCD_DrawVBG
       0609  LCD_InitVBG
       0609  _LCD_InitVBG
       063A  LCD_BG_TYPE1
       0641  LCD_BG_TYPE2
       0648  LCD_InitBG
       0648  _LCD_InitBG
       067C  FanPWM_EnableInt
       067C  _FanPWM_EnableInt
       0680  _FanPWM_DisableInt
       0680  FanPWM_DisableInt
       0684  FanPWM_Start
       0684  _FanPWM_Start
       0688  FanPWM_Stop
       0688  _FanPWM_Stop
       068C  _FanPWM_WritePeriod
       068C  FanPWM_WritePeriod
       068F  FanPWM_WritePulseWidth
       068F  _FanPWM_WritePulseWidth
       0692  bFanPWM_ReadPulseWidth
       0692  FanPWM_bReadPulseWidth
       0692  _bFanPWM_ReadPulseWidth
       0692  _FanPWM_bReadPulseWidth
       0695  _bFanPWM_ReadCounter
       0695  _FanPWM_bReadCounter
       0695  bFanPWM_ReadCounter
       0695  FanPWM_bReadCounter
       06C2  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   06C2   0356 =    854. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       06C2  _main
       06C2  __text_start
       071E  _SleepTimerISR
       083F  _itoa
       0A18  __text_end
       0A18  __xidata_start
       0A27  __xidata_end

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
                            data   0000   0026 =     38. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  __data_start
       0000  _string
       002F  _wControlState
       0031  _pulse_read
       0033  _pulse_width

Files Linked      [ module(s) ]

./obj/boot.o	[ boot.asm ]
obj/main.o	[ main.c ]
<library>	[ fanpwmint.asm, psocconfigtbl.asm, psocconfig.asm, lcd.asm, fanpwm.asm, rZ.asm, rY.asm, rX.asm, r11.asm ]
[ r10.asm, r9.asm, r8.asm, r7.asm, r6.asm, r5.asm, r4.asm, r3.asm, r2.asm, r1.asm, r0.asm, divmodu_16x16_16_util.asm ]
[ i_div16_block_util.asm, itoa.s ]

Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0x20
-Blab4a_RAM	allocated at: 0
-rwh:SSCParmBlk:0xf7.0xff

