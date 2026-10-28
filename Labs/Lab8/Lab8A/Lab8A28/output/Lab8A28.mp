Project:      output/Lab8A28
Build Number: 0
Date:         Wed Oct 28 11:49:46 2026
Compiler:     ICCM8C
Version:      7.05.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             lit   0190   0118 =    280. bytes (rel,con,rom,lit)

       Addr  Global Symbol
      -----  --------------------------------
       0190  LoadConfigTBL_lab7d28_Bank0
       0211  LoadConfigTBL_lab7d28_Bank1
       02A8  __lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                        func_lit   02A8   0002 =      2. bytes (rel,con,rom,proclab)

       Addr  Global Symbol
      -----  --------------------------------
       02A8  __func_lit_start
       02AA  __func_lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     psoc_config   02AA   0127 =    295. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       02AA  LoadConfigTBL_lab7d28_Ordered
       036F  _LoadConfigInit
       036F  LoadConfigInit
       0376  _LoadConfig_lab7d28
       0376  LoadConfig_lab7d28
       03D1  __psoc_config_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     UserModules   03D1   01A7 =    423. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       03D1  _EzI2C_ISR
       04A7  EzI2C_Start
       04A7  _EzI2C_Start
       04D8  _EzI2C_SetAddr
       04D8  EzI2C_SetAddr
       04EE  _EzI2C_GetActivity
       04EE  EzI2C_GetActivity
       04F9  _EzI2C_GetAddr
       04F9  EzI2C_GetAddr
       0502  _EzI2C_ResumeInt
       0502  EzI2C_ResumeInt
       0504  EzI2C_EnableInt
       0504  _EzI2C_EnableInt
       050F  _EzI2C_Stop
       050F  EzI2C_Stop
       0516  _EzI2C_DisableInt
       0516  EzI2C_DisableInt
       051A  EzI2C_DisableSlave
       051A  _EzI2C_DisableSlave
       051E  _EzI2C_SetRamBuffer
       051E  EzI2C_SetRamBuffer
       0537  _DigBuf_ISR
       0538  _Comp3V_SetPower
       0538  Comp3V_Start
       0538  Comp3V_SetPower
       0538  _Comp3V_Start
       054A  _Comp3V_SetRef
       054A  Comp3V_SetRef
       0574  _Comp3V_Stop
       0574  Comp3V_Stop
       0578  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   0578   015C =    348. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       0578  __text_start
       0578  _main
       05BB  _VC3Handler
       06D4  __xidata_start
       06D4  __text_end
       06DA  __xidata_end

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
<library>	[ psocconfigtbl.asm, psocconfig.asm, ezi2cint.asm, ezi2c.asm, digbufint.asm, comp3v.asm, r1.asm ]
[ r0.asm ]

Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0xd
-Blab7d28_RAM
-rwh:SSCParmBlk:0xf7.0xff

