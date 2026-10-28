#include <m8c.h>
#include "PSoCAPI.h"

struct I2C_Regs
{
    unsigned int wPhase;
    unsigned int wPhaseRate;
    unsigned char bGainValue;

    unsigned char bCompACapValue;
    unsigned char bCompBCapValue;

} MyI2C_Regs;

void main(void)
{
    /* -------------------------
       Lab 7D initial values
       ------------------------- */
    MyI2C_Regs.wPhase = 0;
    MyI2C_Regs.wPhaseRate = 256;
    MyI2C_Regs.bGainValue = 0x30;

    /* -------------------------
       Lab 8D comparator values
       ------------------------- */
    MyI2C_Regs.bCompACapValue = 10;
    MyI2C_Regs.bCompBCapValue = 26;

    /* Start modules */
    EzI2C_Start();
    Buffer_Start(Buffer_HIGHPOWER);

    /* 7 bytes total, all writable */
    EzI2C_SetRamBuffer(
        7,
        7,
        (BYTE *)&MyI2C_Regs
    );

    /*
       Connect Column 2 comparator LUT
       back to SCComp in ASC12
    */
    AMD_CR0 = (AMD_CR0 & 0x0F) | 0x60;

    /* VC3 interrupt for Lab 7D sine generator */
    M8C_EnableIntMask(INT_MSK0, INT_MSK0_VC3);

    /* Global interrupts */
    M8C_EnableGInt;

    while(1)
    {
        /* Update sine-generator gain */
        if(SCGain_cr0 != MyI2C_Regs.bGainValue)
        {
            SCGain_cr0 = MyI2C_Regs.bGainValue;
        }

        /* -------------------------
           Update SCComp ACap
           lower 5 bits only
           ------------------------- */
        if((SCComp_cr0 & 0x1F) !=
           (MyI2C_Regs.bCompACapValue & 0x1F))
        {
            SCComp_cr0 =
                (SCComp_cr0 & 0xE0) |
                (MyI2C_Regs.bCompACapValue & 0x1F);
        }

        /* -------------------------
           Update SCComp BCap
           lower 5 bits only
           ------------------------- */
        if((SCComp_cr1 & 0x1F) !=
           (MyI2C_Regs.bCompBCapValue & 0x1F))
        {
            SCComp_cr1 =
                (SCComp_cr1 & 0xE0) |
                (MyI2C_Regs.bCompBCapValue & 0x1F);
        }
    }
}