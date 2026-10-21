#include <m8c.h>
#include "PSoCAPI.h"

/* Shared memory for EzI2C */
struct I2C_Regs
{
    unsigned int  wPhase;
    unsigned int  wPhaseRate;
    unsigned char bGainValue;
};

struct I2C_Regs MyI2C_Regs;

void main(void)
{
    /* ---------------- Initialization ---------------- */

    MyI2C_Regs.wPhase     = 0;
    MyI2C_Regs.wPhaseRate = 256;     /* 1.0 in 8.8 fixed-point */
    MyI2C_Regs.bGainValue = 0x30;    /* gain = -1 */

    /*
     * Expose all 5 bytes to the I2C master:
     *
     * wPhase      = 2 bytes
     * wPhaseRate  = 2 bytes
     * bGainValue  = 1 byte
     */
    EzI2C_SetRamBuffer(
        5,
        5,
        (BYTE *)&MyI2C_Regs
    );

    /* Start EzI2C */
    EzI2C_Start();
	Buffer_Start(Buffer_HIGHPOWER);
	SquareWave_Start();
	LowpassSpectral_Start(LowpassSpectral_HIGHPOWER);
	LowpassTemporal_Start(LowpassTemporal_HIGHPOWER);
	

    /* Enable VC3 interrupt */
    M8C_EnableIntMask(INT_MSK0, INT_MSK0_VC3);

    /* Enable global interrupts */
    M8C_EnableGInt;

    /* ---------------- Main Control Loop ---------------- */

    while(1)
    {
        /*
         * Update the switched-capacitor gain stage
         * only when the I2C value changes.
         */
        if(SCGain_cr0 != MyI2C_Regs.bGainValue)
        {
            SCGain_cr0 = MyI2C_Regs.bGainValue;
        }
    }
}