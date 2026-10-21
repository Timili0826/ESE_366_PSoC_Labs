Project:      output/Lab7D
Build Number: 0
Date:         Wed Oct 07 19:46:01 2026
Compiler:     ICCM8C
Version:      7.05.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             lit   0190   0102 =    258. bytes (rel,con,rom,lit)

       Addr  Global Symbol
      -----  --------------------------------
       0190  LoadConfigTBL_lab7d_Bank0
       0203  LoadConfigTBL_lab7d_Bank1
       0292  __lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                        func_lit   0292   0002 =      2. bytes (rel,con,rom,proclab)

       Addr  Global Symbol
      -----  --------------------------------
       0292  __func_lit_start
       0294  __func_lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     psoc_config   0294   0127 =    295. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       0294  LoadConfigTBL_lab7d_Ordered
       0359  LoadConfigInit
       0359  _LoadConfigInit
       0360  LoadConfig_lab7d
       0360  _LoadConfig_lab7d
       03BB  __psoc_config_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     UserModules   03BB   0166 =    358. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       03BB  _EzI2C_ISR
       0491  EzI2C_Start
       0491  _EzI2C_Start
       04C2  EzI2C_SetAddr
       04C2  _EzI2C_SetAddr
       04D8  EzI2C_GetActivity
       04D8  _EzI2C_GetActivity
       04E3  _EzI2C_GetAddr
       04E3  EzI2C_GetAddr
       04EC  EzI2C_ResumeInt
       04EC  _EzI2C_ResumeInt
       04EE  _EzI2C_EnableInt
       04EE  EzI2C_EnableInt
       04F9  _EzI2C_Stop
       04F9  EzI2C_Stop
       0500  EzI2C_DisableInt
       0500  _EzI2C_DisableInt
       0504  EzI2C_DisableSlave
       0504  _EzI2C_DisableSlave
       0508  _EzI2C_SetRamBuffer
       0508  EzI2C_SetRamBuffer
       0521  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   0521   0157 =    343. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       0521  __text_start
       0521  _main
       055F  _VC3Handler
       0678  __xidata_start
       0678  __text_end
       067E  __xidata_end

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
<library>	[ psocconfigtbl.asm, psocconfig.asm, ezi2cint.asm, ezi2c.asm, r1.asm, r0.asm ]

Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0xd
-Blab7d_RAM
-rwh:SSCParmBlk:0xf7.0xff

