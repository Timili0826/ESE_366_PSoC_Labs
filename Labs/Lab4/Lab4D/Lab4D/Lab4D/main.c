//----------------------------------------------------------------------------
// C main line
//----------------------------------------------------------------------------

#include <m8c.h>        // part specific constants and macros
#include "PSoCAPI.h"    // PSoC API definitions for all User Modules
#include <stdlib.h>

char string[32];
int pulse_width = 255;
int pulse_read;
int wControlState = 1000;
unsigned int wFirstValue, wLastValue, wSpeedRPM;
signed char cNumCycles;
unsigned char bDataAvailable;

void main(void)
{
	FanPWM_EnableInt();
	M8C_EnableGInt ; // Uncomment this line to enable Global Interrupts
	
	LCD_Start();
	FanPWM_WritePulseWidth(pulse_width);
	pulse_read = (int)FanPWM_bReadPulseWidth();
	itoa(string, pulse_read, 10);
	LCD_Position(0, 0);
	LCD_PrCString("Pulse Width: ");
	LCD_PrString(string);
	TachTimer_Start();
	
	while (1)
	{
		if (bDataAvailable)
		{
			bDataAvailable = ~bDataAvailable;
			wSpeedRPM = (((45 * 10000000) * cNumCycles) + ((wFirstValue - wLastValue)/2))/(wFirstValue - wLastValue);
			LCD_Position(1, 0);
			itoa(string, wSpeedRPM, 10);
			LCD_PrCString("Speed: ");
			LCD_PrString(string);
			LCD_PrCString(" Cycles: ");
			itoa(string, (int)cNumCycles, 10);
			LCD_PrString(string);
		}
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
