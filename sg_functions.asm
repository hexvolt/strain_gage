/* ==================================================================
		Function to be used in main.asm
===================================================================== */

;======================== F_SPI_INIT ================================
;	Function for SPI Mode 3 initialization (high levels on SPI, CS 
;   pins, read on signal front.
;	SCK frequency: f/64 = 125 kHz
;====================================================================
F_SPI_INIT:
			ldi 	tmp, (1<<SPE) | (1<<MSTR) | (1<<CPOL) | (1<<CPHA) | (1<<SPR1)
			out 	SPCR, tmp
			ldi 	tmp, (1<<SCK) | (1<<MOSI) | (1<<CS) | (1<<PB2)
			out 	DDRB, tmp			;configure SCK, MOSI, CS (PB0), SS (PB2) as outputs
			ser		tmp
			out 	PORTB, tmp			;set 1 on PORTB pins
ret

;======================= F_USART_INIT ===============================
;	USART initialization function
;====================================================================
F_USART_INIT:				
			ldi 	tmp, low(bauddivider)			;configure the data exchange rate
			out  	UBRRL, tmp
			ldi 	tmp, high(bauddivider)
			out 	UBRRH, tmp
			clr		tmp				;clear all USART flags
			out 	UCSRA, tmp
			ldi 	tmp, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<TXCIE)			;enable receiver, transmitter and interrupts
			out  	UCSRB, tmp
			ldi 	tmp, (1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)			;8 bit format
			out 	UCSRC, tmp
ret

;========================== F_WR_SPI ================================
;	Function for sending the SPIREG byte of data to the SPI.
;	After data exchange, SPIREG containts a byte of data received
;   from external device.
;====================================================================
F_WR_SPI:
			out 	SPDR, SPIREG			;start SPI transmitting
WAITSPI:	sbis 	SPSR, SPIF			    ;waiting for the data exchagne process
			rjmp 	WAITSPI
			in 		SPIREG, SPDR			;read the byte from the SPI
ret


;======================= F_USART_SEND ===============================
;	Function for transmitting the USARTREG byte of data via USART.
;====================================================================
F_USART_SEND:
			sbis 	UCSRA, UDRE				;waiting when USART is ready
			rjmp	F_USART_SEND		
			out		UDR, USARTREG			;transmitting
ret

;======================== F_GET_ADC2 ================================
;	Function for measuring the voltage on the input IN2 of ADC.
;	After the measurement, ADC2_REG1 contains the MSB, and
;   ADC2_REG2 - the LSB of the result value.
;====================================================================
F_GET_ADC2:
			clr 	SPIREG			            ;send a command to ADC to start measurements on IN2
			rcall 	F_WR_SPI			
			mov 	ADC2_REG1, SPIREG			;get a MSB of the result
			clr 	SPIREG			            ;send a second arbitrary byte (just to exchange for the result)			
			rcall 	F_WR_SPI			
			mov 	ADC2_REG2, SPIREG			;get a LSB of the result
ret

;======================== F_GET_ADC1 ================================
;	Function for measuring the voltage on the input IN1 of ADC.
;	After the measurement, ADC1_REG1 contains the MSB, and
;   ADC1_REG2 - the LSB of the result value.
;====================================================================
F_GET_ADC1:
			
			ldi 	SPIREG, 0b00001000			;send a command to ADC to start measurements on IN1
			rcall 	F_WR_SPI			
			mov 	ADC1_REG1, SPIREG			;get a MSB of the result
			ldi 	SPIREG, 0b00001000			;send a second arbitrary byte (just to exchange for the result)
			rcall 	F_WR_SPI			
			mov 	ADC1_REG2, SPIREG			;get a LSB of the result
ret

;======================== F_CODE_ADC1 ================================
;	Function encodes the data inside ADC1_REG1 and ADC1_REG2 registers
;   in a way to include there a number of the ADC channel 1. This 
;   function prepares data for sending via USB. The resulting format 
;   of data: 00YYYYYY, 01YYYYYY, where Y - 12 bits of data.
;====================================================================
F_CODE_ADC1:
			lsl 	ADC1_REG1			;left shift by 2 bits
			lsl 	ADC1_REG1
			andi	ADC1_REG1, 0b00111100			;reset the last bits
			mov 	tmp, ADC1_REG2			;move 2 leftmost buts of ADC1_REG2 to the right bits of ADC1_REG1
			andi	tmp, 0b11000000			

			lsr		tmp				;right shift by 6
			lsr		tmp
			lsr		tmp
			lsr		tmp
			lsr		tmp
			lsr		tmp
			or 		ADC1_REG1, tmp			;OR with ADC1_REG1
			andi 	ADC1_REG2, 0b00111111			;clear first 2 bits of ADC1_REG2
			ori 	ADC1_REG2, 0b01000000			;mix the code of the channel
ret

;======================== F_CODE_ADC2 ================================
;	Function encodes the data inside ADC2_REG1 and ADC2_REG2 registers
;   in a way to include there a number of the ADC channel 2. This 
;   function prepares data for sending via USB. The resulting format 
;   of data: 10YYYYYY, 11YYYYYY, where Y - 12 bits of data.
;====================================================================
F_CODE_ADC2:
			lsl 	ADC2_REG1			;left shift by 2 bits
			lsl 	ADC2_REG1
			andi	ADC2_REG1, 0b00111100			;reset the last bits
			mov 	tmp, ADC2_REG2			;move 2 leftmost buts of ADC2_REG2 to the right bits of ADC2_REG1
			andi	tmp, 0b11000000
			lsr		tmp 			;right shift by 6
			lsr		tmp
			lsr		tmp
			lsr		tmp
			lsr		tmp
			lsr		tmp
			or 		ADC2_REG1, tmp			;OR with ADC2_REG1
			andi 	ADC2_REG2, 0b00111111			;clear first 2 bits of ADC1_REG2
			ori 	ADC2_REG1, 0b10000000			;mix the code of the channel
			ori 	ADC2_REG2, 0b11000000			
ret

