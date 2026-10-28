#include <m8c.h>
#include "PSoCAPI.h"

struct I2C_Regs
{
    unsigned int wPhase;
    unsigned int wPhaseRate;
    unsigned char bGainValue;
} MyI2C_Regs;

void main(void)
{
    /* Lab 7D initialization */
    MyI2C_Regs.wPhase = 0;
    MyI2C_Regs.wPhaseRate = 256;
    MyI2C_Regs.bGainValue = 0x30;

    EzI2C_Start();

    EzI2C_SetRamBuffer(
        5,
        5,
        (BYTE *)&MyI2C_Regs
    );

    /* Start Lab 8A comparator */
    Comp3V_Start(Comp3V_HIGHPOWER);

    /* Enable VC3 interrupt for sine-wave generator */
    M8C_EnableIntMask(INT_MSK0, INT_MSK0_VC3);

    /* Enable global interrupts */
    M8C_EnableGInt;

    while(1)
    {
        if(SCGain_cr0 != MyI2C_Regs.bGainValue)
        {
            SCGain_cr0 = MyI2C_Regs.bGainValue;
        }
    }
}