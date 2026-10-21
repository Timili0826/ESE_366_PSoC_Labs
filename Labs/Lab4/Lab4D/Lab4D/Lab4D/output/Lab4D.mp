Project:      output/Lab4D
Build Number: 0
Date:         Wed Oct 14 01:27:28 2026
Compiler:     ICCM8C
Version:      7.05.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             lit   0190   013C =    316. bytes (rel,con,rom,lit)

       Addr  Global Symbol
      -----  --------------------------------
       01B0  LoadConfigTBL_lab4a_Bank0
       0225  LoadConfigTBL_lab4a_Bank1
       02CC  __lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                        func_lit   02CC   0002 =      2. bytes (rel,con,rom,proclab)

       Addr  Global Symbol
      -----  --------------------------------
       02CC  __func_lit_start
       02CE  __func_lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     psoc_config   02CE   0127 =    295. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       02CE  LoadConfigTBL_lab4a_Ordered
       0393  LoadConfigInit
       0393  _LoadConfigInit
       039A  LoadConfig_lab4a
       039A  _LoadConfig_lab4a
       03F5  __psoc_config_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     UserModules   03F5   0378 =    888. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       03F5  _FanPWM_ISR
       0437  _TachTimer_ISR
       0438  TachTimer_EnableInt
       0438  _TachTimer_EnableInt
       043C  TachTimer_DisableInt
       043C  _TachTimer_DisableInt
       0440  _TachTimer_Start
       0440  TachTimer_Start
       0444  _TachTimer_Stop
       0444  TachTimer_Stop
       0448  TachTimer_WritePeriod
       0448  _TachTimer_WritePeriod
       044E  TachTimer_WriteCompareValue
       044E  _TachTimer_WriteCompareValue
       0454  wTachTimer_ReadCompareValue
       0454  TachTimer_wReadCompareValue
       0454  _wTachTimer_ReadCompareValue
       0454  _TachTimer_wReadCompareValue
       045A  wTachTimer_ReadTimerSaveCV
       045A  _wTachTimer_ReadTimerSaveCV
       045A  _wTachTimer_ReadCounter
       045A  _TachTimer_wReadTimerSaveCV
       045A  TachTimer_wReadTimerSaveCV
       045A  wTachTimer_ReadCounter
       0490  TachTimer_wReadTimer
       0490  _wTachTimer_ReadTimer
       0490  wTachTimer_ReadTimer
       0490  _TachTimer_wReadTimer
       0490  wTachTimer_CaptureCounter
       0490  _wTachTimer_CaptureCounter
       0498  _LCD_PrCString
       0498  LCD_PrCString
       04AA  LCD_HEX_STR
       04BA  LCD_PrHexByte
       04BA  _LCD_PrHexByte
       04CD  LCD_PrHexInt
       04CD  _LCD_PrHexInt
       04D4  _LCD_PrString
       04D4  LCD_PrString
       04E6  _LCD_Write_Data
       04E6  LCD_Write_Data
       04E6  _LCD_WriteData
       04E6  LCD_WriteData
       04FA  LCD_Control
       04FA  _LCD_Control
       05AA  LCD_Init
       05AA  _LCD_Init
       05AA  LCD_Start
       05AA  _LCD_Start
       0619  LCD_ROW_OFFSET
       061D  LCD_Position
       061D  _LCD_Position
       062D  _LCD_Delay50uTimes
       062D  LCD_Delay50uTimes
       0633  LCD_Delay50u_Table
       063B  LCD_Delay50u
       063B  _LCD_Delay50u
       064F  _LCD_DrawBG
       0680  _LCD_DrawVBG
       06B4  LCD_InitVBG
       06B4  _LCD_InitVBG
       06E5  LCD_BG_TYPE1
       06EC  LCD_BG_TYPE2
       06F3  LCD_InitBG
       06F3  _LCD_InitBG
       0727  FanPWM_EnableInt
       0727  _FanPWM_EnableInt
       072B  _FanPWM_DisableInt
       072B  FanPWM_DisableInt
       072F  FanPWM_Start
       072F  _FanPWM_Start
       0733  FanPWM_Stop
       0733  _FanPWM_Stop
       0737  _FanPWM_WritePeriod
       0737  FanPWM_WritePeriod
       073A  FanPWM_WritePulseWidth
       073A  _FanPWM_WritePulseWidth
       073D  bFanPWM_ReadPulseWidth
       073D  _FanPWM_bReadPulseWidth
       073D  _bFanPWM_ReadPulseWidth
       073D  FanPWM_bReadPulseWidth
       0740  FanPWM_bReadCounter
       0740  _bFanPWM_ReadCounter
       0740  _FanPWM_bReadCounter
       0740  bFanPWM_ReadCounter
       076D  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   076D   0635 =   1589. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       076D  _main
       076D  __text_start
       094D  _SleepTimerISR
       0BC9  _itoa
       0DA2  __text_end
       0DA2  __xidata_start
       0DB3  __xidata_end

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
                            data   0000   002E =     46. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  _string
       0000  __data_start
       002F  _pulse_width
       0031  _wControlState
       0033  _wFirstValue
       0035  _pulse_read
       0037  _wSpeedRPM
       0039  _wLastValue
       003B  _cNumCycles
       003C  _bDataAvailable

Files Linked      [ module(s) ]

./obj/boot.o	[ boot.asm ]
obj/main.o	[ main.c ]
<library>	[ fanpwmint.asm, tachtimerint.asm, tachtimer.asm, psocconfigtbl.asm, psocconfig.asm, lcd.asm ]
[ fanpwm.asm, rZ.asm, rY.asm, rX.asm, r11.asm, r10.asm, r9.asm, r8.asm, r7.asm, r6.asm, r5.asm, r4.asm, r3.asm ]
[ r2.asm, r1.asm, r0.asm, divmod_32x32_32_util.asm, divmodu_16x16_16_util.asm, i_div16_block_util.asm ]
[ i_div32_block_util.asm, i_div32_not_util.asm, i_mulu8_block_util.asm, mul32_util.asm, itoa.s ]


Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0x20
-Blab4a_RAM	allocated at: 0
-rwh:SSCParmBlk:0xf7.0xff

