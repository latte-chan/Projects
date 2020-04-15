***********************************************************************
* Title: LED Light Blinking
* Objective: CSE472 Homework 2
* Revision: V3.1                                       
* Date: Jan 21 2019
* Programmer: Aidan Jones
* Company: Penn State University Computer Science
* Algorithm: SImple Parallel I/O in a nested delay-loop
* Register Use: A: Light on/off state and Switch SW1 on/off state
*               X,Y: Delay loop counters
* Memory use: RAM locations from $3000 for data,
*                                 $3100 for program
* Input: Parameters hard coded in program
*        Switch SW1 at PORTP bit 0
* Output: LED 1,2,3,4 at PORTB bit 4,5,6,7
* Observation: This is a program that blinks LEDs and blinking period
*              can be hanged with the delay loop counter value.
* Note: This is a good example of program comments
* All Homework programs must have comments similar
* to this Homework 1 program. So, please use this
* comment format for all subsequent homework programs
* Adding more explanations and comments help you and others
* to understand your program later.
* Comments: This program is developed and simulated using
* CopdeWarrior development software and targeted for Axion
* Manufacturing's APS12C128 board running at 24MHz bus clock
***********************************************************************
* Parameter Declearation Section
* Export Symbols

        XDEF       pgstart ; export 'pgstart' symbol
        ABSENTRY   pgstart ; for assembly entry point
                         
PORTA   EQU    $0000       ; i/o port addresses
DDRA    EQU    $0002
                                                 
PORTB   EQU    $0001       ; PORT B is conneced with LEDs
DDRB    EQU    $0003
PUCR    EQU    $000C       ; to enable oull-up mode for PORT A,B,E,K

PTP     EQU    $0258       ; PORTP data register, used for Push Switch
PTIP    EQU    $0259       ; PORTP input data register 
DDRP    EQU    $025A       ; PORTP data direction register
PERP    EQU    $025C       ; PORTP pull up/down enable
PPSP    EQU    $025D       ; PORTP pull up/down selection

***********************************************************************
* Data Section
            ORG     $3000      ; reserved memory starting address
            
Counter1    DC.W    $4fff      ; initial X register count number
Counter2    DC.W    $0020      ; initial Y register count number

StackSpace                     ; remaining memory space for stack data
                               ; initial stack pointer position set     \
                               ; to $3100 (pgstart)

***********************************************************************
* Program Section

            ORG     $3100              ; Program start address, in RAM
pgstart     LDS     #pgstart           ; initalize the stack pointer
                               
            LDAA    #%11110000         ; set PORTB bit 7,6,5,4 as output, 3,2,1,0 as input
            STAA    DDRB               ; LED 1,2,3,4 on PORTB bit 4,5,6,7
                                       ; DIP switch 1,2,3,4 on PORTB bit 0,1,2,3.
            BSET    PUCR,%00000010     ; enable PORTB pull up/down feature for the
                                       ; DIP switch 1,2,3,4 on the bits 0,1,2,3
            
            BCLR    DDRP,%00000011     ; Push Button Switch 1 and 2 at PORTP bit 0 and 1
                                       ; set PORTP bit 0 and 1 as input
            BSET    PERP,%00000011     ; endable the pull up/down feature at PORTP bit 0 and 1
            BCLR    PPSP,%00000011     ; select pull up feature at PORTP bit 0 and 1 fopr the
                                       ; Push Button Switch 1 and 2.
                               
            LDAA    #%11110000         ; Turn off LED 1,2,3,4 at PORTB bit 4,5,6,7
            STAA    PORTB              ; Note: LED nubmers and PORTB bit numbers are different
                               
mainLoop                               
            BSET    PORTB,%10000000    ; Turn off LED 4 at PORTB7
            BCLR    PORTB,%00010000    ; Turn on LED 1 at PORTB4
            JSR     delay1sec          ; Wait for 1 second
            BCLR    PORTB,%10000000    ; Turn on LED 4 at PORTB7
            BSET    PORTB,%00010000    ; Turn off LED 1at PORTB4
            JSR     delay1sec          ; Wait for 1 second
            BRA     endLoop
            
scndLoop
            BSET    PORTB,%00010000    ; Turn off LED 1 at PORTB4    
            BCLR    PORTB,%10000000    ; Turn on LED 4 at PORTB7
            JSR     delay1sec          ; Wait for 1 second
            BSET    PORTB,%10000000    ; Turn off LED 4 at PORTB7
            BCLR    PORTB,%01000000    ; Turn on LED 3 at PORTB6
            JSR     delay1sec          ; Wait for 1 second
            BSET    PORTB,%01000000    ; Turn off LED 3 at PORTB6
            BCLR    PORTB,%00100000    ; Turn on LED 2 at PORTB5
            JSR     delay1sec          ; Wait for 1 second
            BSET    PORTB,%00100000    ; Turn off LED 2 at PORTB5
            BCLR    PORTB,%00010000    ; Turn on LED 1 at PORTB4
            JSR     delay1sec          ; Wait for 1 second
            BRA     endLoop
            
endLoop                                    
            LDAA    PTIP               ; read push button SW1 at PORTP0
            ANDA    #%00000001         ; check bit 0 only
            BNE     sw1pushed
              
sw1notpsh   
            BRA     mainLoop           ; loop forever!
                                      
sw1pushed   
            BRA     scndLoop           ; loop forever!

            
***********************************************************************
* Subroutine Section

;**********************************************************************
; delay1sec subroutine
;
; Input: a 16 bit count number in Counter2
; Output: time delay, cpu cycles wasted
; Registers: Y register, as counter
; Memory locations: a 16 bit input number
; Comments: can add more time by calling delay1ms more

delay1sec
            PSHY
            
            LDY     Counter2           ; long delay
dly1sLoop   JSR     delay1ms           ; Y * delay1ms (Y * X * NOP)
            DEY
            BNE     dly1sLoop
            
            PULY
            RTS
            
;**********************************************************************
; delay1ms subroutine
;
; This subroutine cause a few msec. delay
; Input: a 16bit count number in Counter1
; Output: time delay, cpu cycle wasted
; Registers: X register, as counter
; Memory locations: a 16 bit input number
; Comments: can add more NOP instructions to lengthen the delay time

delay1ms
            PSHX
            
            LDX     Counter1           ; short delay
dlymsLoop   NOP                        ; X * NOP
            DEX
            BNE     dlymsLoop
            
            PULX
            RTS      
            
***********************************************************************

            end                        ; last line of a file      
