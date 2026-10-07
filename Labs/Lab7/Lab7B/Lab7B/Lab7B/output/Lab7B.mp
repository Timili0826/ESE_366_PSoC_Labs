Project:      output/Lab7B
Build Number: 0
Date:         Wed Sep 23 18:07:51 2026
Compiler:     ICCM8C
Version:      7.05.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             lit   0190   029B =    667. bytes (rel,con,rom,lit)

       Addr  Global Symbol
      -----  --------------------------------
       01BC  LoadConfigTBL_lab7b_Bank0
       0227  LoadConfigTBL_lab7b_Bank1
       02B6  __ctype
       042B  __lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                        func_lit   042B   0004 =      4. bytes (rel,con,rom,proclab)

       Addr  Global Symbol
      -----  --------------------------------
       042B  __func_lit_start
       042F  __func_lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     psoc_config   042F   0130 =    304. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       042F  LoadConfigTBL_lab7b_Ordered
       04F4  LoadConfigInit
       04F4  _LoadConfigInit
       0504  LoadConfig_lab7b
       0504  _LoadConfig_lab7b
       055F  __psoc_config_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     UserModules   055F   01B7 =    439. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       055F  _LCD_1_PrCString
       055F  LCD_1_PrCString
       0571  LCD_1_HEX_STR
       0581  _LCD_1_PrHexByte
       0581  LCD_1_PrHexByte
       0594  LCD_1_PrHexInt
       0594  _LCD_1_PrHexInt
       059B  _LCD_1_PrString
       059B  LCD_1_PrString
       05AD  LCD_1_Write_Data
       05AD  LCD_1_WriteData
       05AD  _LCD_1_WriteData
       05AD  _LCD_1_Write_Data
       05C1  _LCD_1_Control
       05C1  LCD_1_Control
       0671  _LCD_1_Init
       0671  _LCD_1_Start
       0671  LCD_1_Init
       0671  LCD_1_Start
       06E0  LCD_1_ROW_OFFSET
       06E4  _LCD_1_Position
       06E4  LCD_1_Position
       06F4  _LCD_1_Delay50uTimes
       06F4  LCD_1_Delay50uTimes
       06FA  LCD_1_Delay50u_Table
       0702  LCD_1_Delay50u
       0702  _LCD_1_Delay50u
       0716  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   0716   091F =   2335. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       0716  _main
       0716  __text_start
       082C  __plcall
       0838  _itoa
       0A11  _utoa
       0B54  _islower
       0B75  _toupper
       0BB3  __print
       0F9A  __sdepi
       0FCC  _sprintf
       1035  __text_end
       1035  __xidata_start
       1040  __xidata_end

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
                    InterruptRAM   0000   0003 =      3. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  _NO_SHADOW
       0000  Port_2_Data_SHADE
       0000  NO_SHADOW
       0000  _Port_2_Data_SHADE
       0001  _Port_2_DriveMode_0_SHADE
       0001  Port_2_DriveMode_0_SHADE
       0002  _Port_2_DriveMode_1_SHADE
       0002  Port_2_DriveMode_1_SHADE

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
               virtual_registers   001C   0007 =      7. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       001C  __rZ
       001D  __rY
       001E  __rX
       001F  __r3
       0020  __r2
       0021  __r1
       0022  __r0

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            data   0000   001B =     27. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  __data_start

Files Linked      [ module(s) ]

./obj/boot.o	[ boot.asm ]
obj/main.o	[ main.c ]
<library>	[ psocconfigtbl.asm, psocconfig.asm, lcd_1.asm, rZ.asm, rY.asm, rX.asm, r3.asm, r2.asm, r1.asm, r0.asm ]
[ divmodu_16x16_16_util.asm, i_div16_block_util.asm, plcall.s, itoa.s, utoa.s, islower.s, ctype.s ]
[ toupper.s, _printf.s, sprintf.s ]

Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0x1c
-Blab7b_RAM
-rwh:SSCParmBlk:0xf7.0xff

