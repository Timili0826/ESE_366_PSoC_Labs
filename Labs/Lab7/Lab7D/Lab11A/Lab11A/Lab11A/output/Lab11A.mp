Project:      output/Lab11A
Build Number: 0
Date:         Wed Oct 07 20:33:10 2026
Compiler:     ICCM8C
Version:      7.05.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             lit   0190   0146 =    326. bytes (rel,con,rom,lit)

       Addr  Global Symbol
      -----  --------------------------------
       0190  LoadConfigTBL_lab7d_Bank0
       0237  LoadConfigTBL_lab7d_Bank1
       02D6  __lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                        func_lit   02D6   0002 =      2. bytes (rel,con,rom,proclab)

       Addr  Global Symbol
      -----  --------------------------------
       02D6  __func_lit_start
       02D8  __func_lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     psoc_config   02D8   0127 =    295. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       02D8  LoadConfigTBL_lab7d_Ordered
       039D  LoadConfigInit
       039D  _LoadConfigInit
       03A4  LoadConfig_lab7d
       03A4  _LoadConfig_lab7d
       03FF  __psoc_config_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     UserModules   03FF   0167 =    359. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       03FF  _SquareWave_ISR
       0400  _EzI2C_ISR
       04D6  _EzI2C_Start
       04D6  EzI2C_Start
       0507  EzI2C_SetAddr
       0507  _EzI2C_SetAddr
       051D  EzI2C_GetActivity
       051D  _EzI2C_GetActivity
       0528  _EzI2C_GetAddr
       0528  EzI2C_GetAddr
       0531  _EzI2C_ResumeInt
       0531  EzI2C_ResumeInt
       0533  _EzI2C_EnableInt
       0533  EzI2C_EnableInt
       053E  _EzI2C_Stop
       053E  EzI2C_Stop
       0545  EzI2C_DisableInt
       0545  _EzI2C_DisableInt
       0549  _EzI2C_DisableSlave
       0549  EzI2C_DisableSlave
       054D  _EzI2C_SetRamBuffer
       054D  EzI2C_SetRamBuffer
       0566  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   0566   0157 =    343. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       0566  __text_start
       0566  _main
       05A4  _VC3Handler
       06BD  __xidata_start
       06BD  __text_end
       06C3  __xidata_end

Area                               Start  End    Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             TOP   0000   0154 =    340. bytes (abs,ovr,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       0080  __Start
       0151  _bGetPowerSetting
       0151  bGetPowerSetting

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                    InterruptRAM   0000   0008 =      8. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  NO_SHADOW
       0000  _NO_SHADOW
       0000  EzI2C_varPage
       0000  _EzI2C_bState
       0000  EzI2C_bState
       0000  _EzI2C_varPage
       0001  _EzI2C_bRAM_RWoffset
       0001  EzI2C_bRAM_RWoffset
       0002  _EzI2C_bRAM_RWcntr
       0002  EzI2C_bRAM_RWcntr
       0003  EzI2C_pRAM_Buf_Addr_MSB
       0003  _EzI2C_pRAM_Buf_Addr_MSB
       0004  _EzI2C_pRAM_Buf_Addr_LSB
       0004  EzI2C_pRAM_Buf_Addr_LSB
       0005  EzI2C_bRAM_Buf_Size
       0005  _EzI2C_bRAM_Buf_Size
       0006  _EzI2C_bRAM_Buf_WSize
       0006  EzI2C_bRAM_Buf_WSize
       0007  _EzI2C_bBusy_Flag
       0007  EzI2C_bBusy_Flag

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
               virtual_registers   000D   0002 =      2. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       000D  __r1
       000E  __r0

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            data   0000   0005 =      5. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  __data_start
       0008  _MyI2C_Regs

Files Linked      [ module(s) ]

./obj/boot.o	[ boot.asm ]
obj/main.o	[ main.c ]
obj/vc3handler.o	[ vc3handler.asm ]
<library>	[ squarewaveint.asm, psocconfigtbl.asm, psocconfig.asm, ezi2cint.asm, ezi2c.asm, r1.asm, r0.asm ]


Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0xd
-Blab7d_RAM
-rwh:SSCParmBlk:0xf7.0xff

