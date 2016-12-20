/* ==================================================================
	constants and variables for main.asm
===================================================================== */

		.equ 	XTAL = 8000000 			;crystal frequency
		.equ 	baudrate = 9600			;USB port baud rate
		.equ 	bauddivider = XTAL/(16*baudrate)-1			;divider for USART initialization
		.equ 	CS = PB0			;MC pin which will be used as CS
		.equ 	MOSI = PB3			;MC pin which will be used as MOSI
		.equ 	MISO = PB4			;MC pin which will be used as MISO
		.equ 	SCK	= PB5			;MC pin which will be used as SCK
		
		.def	tmp = R16			;temp variable
		.def	tmp2 = R17			;temp variable
		.def 	SPIREG = R23			;a register used for storing the SPI data
		.def	USARTREG = R20			;a register used for storing the USART data
		.def	ADC1_REG1 = R18			;a register used for storing the 1st byte of ADC channel 1
		.def	ADC1_REG2 = R19			;a register used for storing the 2nd byte of ADC channel 1
		.def	ADC2_REG1 = R24			;a register used for storing the 1st byte of ADC channel 2
		.def	ADC2_REG2 = R22			;a register used for storing the 2nd byte of ADC channel 2

