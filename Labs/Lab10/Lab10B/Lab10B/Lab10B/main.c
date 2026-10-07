#include <m8c.h>
#include <stdlib.h>
#include "PSoCAPI.h"

int iV0;
int iV1;
int iV2;
long lRvalue;

void main(void)
{
    char szBuffer[12];

    Buffer_Start(Buffer_HIGHPOWER);
    InputAtten_Start(InputAtten_HIGHPOWER);
    ADC_Start(ADC_HIGHPOWER);
    LCD_Start();

    Buffer_GAIN_CR2 |= 0x1C;
    InputAtten_GAIN_CR2 |= 0x18;

    M8C_EnableGInt;

    LCD_Position(0, 0);
    LCD_PrCString("R Value (Ohms):");

    while(1)
    {
        ADCMUX_InputSelect(0);
        ADC_GetSamples(1);
        while(!ADC_fIsDataAvailable());
        iV0 = ADC_iClearFlagGetData();

        ADCMUX_InputSelect(1);
        ADC_GetSamples(1);
        while(!ADC_fIsDataAvailable());
        iV1 = ADC_iClearFlagGetData();

        ADCMUX_InputSelect(2);
        ADC_GetSamples(1);
        while(!ADC_fIsDataAvailable());
        iV2 = ADC_iClearFlagGetData();

        if(iV0 <= iV1)
        {
            lRvalue = -1;
        }
        else if(iV1 <= iV2)
        {
            lRvalue = 0;
        }
        else
        {
            lRvalue =
                (10000L *
                ((long)(iV1 - iV2) +
                ((long)(iV0 - iV1) / 2L)))
                /
                (long)(iV0 - iV1);
        }

        LCD_Position(1, 0);

        if(lRvalue == -1)
        {
            LCD_PrCString("OVERLOAD        ");
        }
        else
        {
            ltoa(szBuffer, lRvalue, 10);

            LCD_PrCString("                ");
            LCD_Position(1, 0);

            LCD_PrString(szBuffer);
            LCD_PrCString(" Ohms");
        }
    }
}