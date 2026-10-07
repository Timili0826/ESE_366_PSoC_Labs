Project:      output/Lab6A
Build Number: 0
Date:         Wed Sep 30 12:05:36 2026
Compiler:     ICCM8C
Version:      7.05.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             lit   0190   00F2 =    242. bytes (rel,con,rom,lit)

       Addr  Global Symbol
      -----  --------------------------------
       0190  LoadConfigTBL_lab6a_Bank0
       01F3  LoadConfigTBL_lab6a_Bank1
       0282  __lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                        func_lit   0282   0002 =      2. bytes (rel,con,rom,proclab)

       Addr  Global Symbol
      -----  --------------------------------
       0282  __func_lit_start
       0284  __func_lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     psoc_config   0284   0127 =    295. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       0284  LoadConfigTBL_lab6a_Ordered
       0349  LoadConfigInit
       0349  _LoadConfigInit
       0350  LoadConfig_lab6a
       0350  _LoadConfig_lab6a
       03AB  __psoc_config_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     UserModules   03AB   0111 =    273. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       03AB  I2CHW_Poll
       03AB  _I2CHW_Poll
       03AC  _I2CHW_ISR
       04BC  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   04BC   0002 =      2. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       04BC  __text_start
       04BC  _main
       04BE  __xidata_start
       04BE  __text_end
       04C0  __xidata_end

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
                    InterruptRAM   0000   0008 =      8. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  NO_SHADOW
       0000  _I2CHW_bStatus
       0000  I2CHW_bStatus
       0000  _NO_SHADOW
       0001  I2CHW_RsrcStatus
       0001  _I2CHW_RsrcStatus
       0002  _I2CHW_Write_Count
       0002  I2CHW_Write_Count
       0003  pI2CHW_Write_BufHI
       0003  _pI2CHW_Write_BufHI
       0004  _pI2CHW_Write_Buf
       0004  _pI2CHW_Write_BufLO
       0004  pI2CHW_Write_BufLO
       0004  pI2CHW_Write_Buf
       0005  _pI2CHW_Read_BufHI
       0005  pI2CHW_Read_BufHI
       0006  _pI2CHW_Read_BufLO
       0006  _pI2CHW_Read_Buf
       0006  pI2CHW_Read_BufLO
       0006  pI2CHW_Read_Buf
       0007  _I2CHW_Read_Count
       0007  I2CHW_Read_Count

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
               virtual_registers   0008   0002 =      2. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0008  __r1
       0009  __r0

Files Linked      [ module(s) ]

./obj/boot.o	[ boot.asm ]
obj/main.o	[ main.c ]
<library>	[ psocconfigtbl.asm, psocconfig.asm, i2chwint.asm, r1.asm, r0.asm ]

Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0x8
-Blab6a_RAM
-rwh:SSCParmBlk:0xf7.0xff

