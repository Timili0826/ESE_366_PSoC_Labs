Project:      output/Lab7A_another_attempt
Build Number: 0
Date:         Thu Sep 10 12:42:13 2026
Compiler:     ICCM8C
Version:      7.05.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             lit   0190   010A =    266. bytes (rel,con,rom,lit)

       Addr  Global Symbol
      -----  --------------------------------
       0190  LoadConfigTBL_lab7a_another_attempt_Bank0
       020B  LoadConfigTBL_lab7a_another_attempt_Bank1
       029A  __lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                        func_lit   029A   0002 =      2. bytes (rel,con,rom,proclab)

       Addr  Global Symbol
      -----  --------------------------------
       029A  __func_lit_start
       029C  __func_lit_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     psoc_config   029C   0127 =    295. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       029C  LoadConfigTBL_lab7a_another_attempt_Ordered
       0361  _LoadConfigInit
       0361  LoadConfigInit
       0368  _LoadConfig_lab7a_another_attempt
       0368  LoadConfig_lab7a_another_attempt
       03C3  __psoc_config_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     UserModules   03C3   0078 =    120. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       03C3  _RefLoMux_Start
       03C3  _RefLoMux_SetPower
       03C3  RefLoMux_SetPower
       03C3  RefLoMux_Start
       03D5  RefLoMux_Stop
       03D5  _RefLoMux_Stop
       03D9  RefLoMux_RefSelect
       03D9  _RefLoMux_RefSelect
       03EB  RefHiMux_Start
       03EB  _RefHiMux_SetPower
       03EB  RefHiMux_SetPower
       03EB  _RefHiMux_Start
       03FD  _RefHiMux_Stop
       03FD  RefHiMux_Stop
       0401  RefHiMux_RefSelect
       0401  _RefHiMux_RefSelect
       0413  _RefAgndMux_SetPower
       0413  RefAgndMux_Start
       0413  _RefAgndMux_Start
       0413  RefAgndMux_SetPower
       0425  RefAgndMux_Stop
       0425  _RefAgndMux_Stop
       0429  RefAgndMux_RefSelect
       0429  _RefAgndMux_RefSelect
       043B  __UserModules_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   043B   0013 =     19. bytes (rel,con,rom,code)

       Addr  Global Symbol
      -----  --------------------------------
       043B  __text_start
       043B  _main
       044E  __xidata_start
       044E  __text_end
       0450  __xidata_end

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
               virtual_registers   0000   0002 =      2. bytes (rel,con,ram)

       Addr  Global Symbol
      -----  --------------------------------
       0000  __r1
       0001  __r0

Files Linked      [ module(s) ]

./obj/boot.o	[ boot.asm ]
obj/main.o	[ main.c ]
<library>	[ reflomux.asm, refhimux.asm, refagndmux.asm, psocconfigtbl.asm, psocconfig.asm, r1.asm, r0.asm ]


Area Definitions

-blit:0x190.0x3fff
-bdata:0.0x2ff
-BInterruptRAM:0	allocated at: 0
-Bvirtual_registers	allocated at: 0
-Blab7a_another_attempt_RAM
-rwh:SSCParmBlk:0xf7.0xff

