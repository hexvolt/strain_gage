/* ==================================================================
	MAIN MODULE                          				Strain_Gage
===================================================================== */

.include 	"m8def.inc"			; use ATMega8
.include 	"sg_define.asm"

/* ===================== INTERRUPTS VECTORS TABLE ================ */
			.org 0
			rjmp RESET

			.org URXCaddr
			rjmp ON_USART_RECEIVED

			.org UTXCaddr
			rjmp ON_USART_TRANCIEVED

			.org INT0addr
			rjmp ON_INT0_CHANGED

/* ============================== RESET ============================= */
			.org 0x40
RESET:		ldi 	tmp, low(RAMEND)			;program stack to the end of the memory
			out 	SPL, tmp
			ldi		tmp, high(RAMEND)
			out 	SPH, tmp
			
			cli			        ;disable all interrupts
			ldi 	tmp, 0xFF
			out 	DDRC, tmp			;configure PORTÑ as output
			ldi 	tmp, 0x00
			out 	PORTC, tmp			;set 0 to PORTC (LED is off - process stopped)			
			out 	DDRD, tmp			
			out 	PORTD, tmp			;configure PORTD as high impedance inputs (no pull-up)

			in 		tmp, MCUCR				;configure INT0 
			ori 	tmp, (1<<ISC00) | (1<<ISC01)
			out 	MCUCR, tmp			;any signal changes will trigger INT0
	
			in 		tmp, GICR			;enable external interrupt INT0
			ori 	tmp, (1<<INT0)
			out 	GICR, tmp

			rcall	F_SPI_INIT			;initialize SPI
			rcall	F_USART_INIT		;initialize USART
			
			sei			;enable interrupts

/* ========================= MAIN LOOP ========================= */
MAIN:
			sbis 	PINC, 0				;if LED is on (process started) then
			rjmp	MAIN
			
			clr 	ADC1_REG1			;clear registers which store ADC data
			clr 	ADC1_REG2
			clr 	ADC2_REG1
			clr 	ADC2_REG2

			cbi 	PORTB, CS			;turn on ADC
			rcall 	F_GET_ADC1			;get the voltage from input IN1 of ADC
			rcall 	F_GET_ADC2			;get the voltage from input IN2 of ADC
			sbi 	PORTB, CS			;turn off ADC

			rcall 	F_CODE_ADC1				;prepare 1st channel data for sending
			rcall 	F_CODE_ADC2				;prepare 2nd channel data for sending
			
			mov 	USARTREG, ADC1_REG1			;send 1st byte of the ADC channel 1
			rcall 	F_USART_SEND
			mov 	USARTREG, ADC1_REG2			;send 2nd byte of the ADC channel 1
			rcall 	F_USART_SEND
			mov 	USARTREG, ADC2_REG1			;send 1st byte of the ADC channel 2
			rcall 	F_USART_SEND
			mov 	USARTREG, ADC2_REG2			;send 2nd byte of the ADC channel 2
			rcall 	F_USART_SEND

rjmp MAIN

			.include 	"sg_functions.asm"

/* =========================== INTERRUPT HANDLERS ========================== */
ON_USART_RECEIVED:				;interrupt when getting the byte from USB
			in		R21, UDR			;read the byte of data
			ldi 	tmp2, ' '	
			cpse	R21, tmp2
			rjmp	ELSE
			sbi 	PORTC, 0			;if this is a space-symbol - turn on an LED (process start command)
			rjmp 	EXIT				

ELSE:		ldi		tmp2, 'b'			
			cpse	R21, tmp2
			rjmp	EXIT
			cbi		PORTC, 0			;else if this is 'b' - turn off an LED (process stop command)
EXIT:
reti


ON_USART_TRANCIEVED:			;interrupt for sending byte to USB
								;empty handle just for resetting the microcontrolled flag
reti

ON_INT0_CHANGED:				;external interrupt INT0
								;occurs when toggle the USB cable
			cbi		PORTC, 0	;if the USB cable is being plugged out - stop the process
reti
