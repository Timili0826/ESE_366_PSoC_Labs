Project:      output/Lab8D28
Build Number: 0
Date:         Wed Oct 28 14:42:27 2026
Compiler:     ICCM8C
Version:      7.05.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             lit   0190   0120 =    288. bytes (rel,con,rom,lit)

       Addr  Global Symbol
      -----  --------------------------------
       0190  LoadConfigTBL_lab7d28_Bank0
       0219  LoadConfigTBL_lab7d28_Bank1
       02B0  __lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                        func_lit   02B0   0002 =      2. bytes (rel,con,rom,proclab)

       Addr  Global Symbol
      -----  --------------------------------
       02B0  __func_lit_start
       02B2  __func_lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     psoc_config   02B2   0127 =    295. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       02B2  LoadConfigTBL_lab7d28_Ordered
       0377  _LoadConfigInit
       0377  LoadConfigInit
       037E  _LoadConfig_lab7d28
       037E  LoadConfig_lab7d28
       03D9  __psoc_config_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     UserModules   03D9   01AF =    431. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       03D9  _EzI2C_ISR
       04AF  EzI2C_Start
       04AF  _EzI2C_Start
       04E0  _EzI2C_SetAddr
       04E0  EzI2C_SetAddr
       04F6  EzI2C_GetActivity
       04F6  _EzI2C_GetActivity
       0501  _EzI2C_GetAddr
       0501  EzI2C_GetAddr
       050A  _EzI2C_ResumeInt
       050A  EzI2C_ResumeInt
       050C  _EzI2C_EnableInt
       050C  EzI2C_EnableInt
       0517  EzI2C_Stop
       0517  _EzI2C_Stop
       051E  EzI2C_DisableInt
       051E  _EzI2C_DisableInt
       0522  _EzI2C_DisableSlave
       0522  EzI2C_DisableSlave
       0526  _EzI2C_SetRamBuffer
       0526  EzI2C_SetRamBuffer
       053F  _DigBuf_ISR
       0540  Buffer_SetPower
       0540  Buffer_Start
       0540  _Buffer_SetPower
       0540  _Buffer_Start
       0552  _Buffer_SetGain
       0552  Buffer_SetGain
       057C  Buffer_Stop
       057C  _Buffer_Stop
       0580  _Buffer_EnableAGNDBuffer
       0580  Buffer_EnableAGNDBuffer
       0584  _Buffer_DisableAGNDBuffer
       0584  Buffer_DisableAGNDBuffer
       0588  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   0588   01DF =    479. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       0588  __text_start
       0588  _main
       064E  _VC3Handler
       0767  __xidata_start
       0767  __text_end
       076D  __xidata_end

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
               virtual_registers   000F   0003 =      3. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       000F  __r2
       0010  __r1
       0011  __r0

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            data   0000   0007 =      7. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  __data_start
       0008  _MyI2C_Regs

Files Linked      [ module(s) ]

./obj/boot.o	[ boot.asm ]
obj/main.o	[ main.c ]
obj/vc3handler.o	[ vc3handler.asm ]
<library>	[ psocconfigtbl.asm, psocconfig.asm, ezi2cint.asm, ezi2c.asm, digbufint.asm, buffer.asm, r2.asm ]
[ r1.asm, r0.asm ]

Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0xf
-Blab7d28_RAM
-rwh:SSCParmBlk:0xf7.0xff

