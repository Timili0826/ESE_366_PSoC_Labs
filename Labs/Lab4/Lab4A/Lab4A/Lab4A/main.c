//----------------------------------------------------------------------------
// C main line
//----------------------------------------------------------------------------

#include <m8c.h>        // part specific constants and macros
#include "PSoCAPI.h"    // PSoC API definitions for all User Modules
#include <stdlib.h>

char string[32];
int pulse_width = 255;
int pulse_read;

void main(void)
{
	
	M8C_EnableGInt ; // Uncomment this line to enable Global Interrupts
	
	LCD_Start();
	FanPWM_WritePulseWidth(pulse_width);
	pulse_read = (int)FanPWM_bReadPulseWidth();
	itoa(string, pulse_read, 10);
	LCD_Position(0, 0);
	LCD_PrCString("Pulse Width: ");
	LCD_PrString(string);
	
	while (1)
	{
		
	}
}

#pragma interrupt_handler SleepTimerISR

void SleepTimerISR(void)
{
	M8C_ClearIntFlag(INT_CLR0, INT_MSK0_SLEEP);
	
	if (PRT1DR & 0x01)
	{
		pulse_width--;
		FanPWM_WritePulseWidth(pulse_width);
		pulse_read = (int)FanPWM_bReadPulseWidth();
		itoa(string, pulse_read, 10);
		LCD_Position(0, 0);
		LCD_PrCString("Pulse Width: ");
		LCD_PrString(string);
	}
}
