//----------------------------------------------------------------------------
// C main line
//----------------------------------------------------------------------------

#include <m8c.h>        // part specific constants and macros
#include "PSoCAPI.h"    // PSoC API definitions for all User Modules
#define MAX 127

void main(void)
{
	int val = 0x80, acap, clockphase, asign;
	char LCD_data[100];
	M8C_EnableGInt ; // Uncomment this line to enable Global Interrupts
	// Insert your main routine code here.
	LCD_1_Init();
	LCD_1_Start();
	
	while (1)
	{
		while (~(INT_CLR0 & 0x40));
		INT_CLR0 &= ~0x40;
		
		if (PRT1DM0 == 1)
		{
			SCDAC_cr0 = val;
			
			if (SCDAC_cr0 & 0x40)
			{
				clockphase = 1;
			}
			else 
			{
				clockphase = 0;
			}
			if (SADC_CR0 & 0x20)
			{
				asign = 1;
			}
			else
			{
				asign = 0;
			}
			acap = SADC_CR0 & 0x1F;
				
			sprintf (LCD_data, "FCAP = 32, CP = %d, \r\nAsign = %d, ACAP = %d", clockphase, asign, acap);
			LCD_1_PrString(LCD_data);
			
			val++;
			
			if (val == 0xFF)
			{
				val = 0;
			}
		}
	}
}
