***********************************************************************
* Title: PWM LED Test
* Objective: CSE472 Homework 3
* Revision: V1                                      
* Date: Jan 30 2019
* Programmer: Aidan Jones
* Company: Penn State University Computer Science
* Algorithm: Simple duty cycle loop determined by Switch SW1
* Register Use: A,B: Light on/off state and Switch SW1 on/off state
*                    Counters for PWM
*               X: Delay loop counters
* Memory use: RAM locations from  $3000 for data,
*                                 $3100 for program
* Input: Parameters hard coded in program
*        Switch SW1 at PORTP bit 0
* Output: LED 1,2,3,4 at PORTB bit 4,5,6,7
* Observation: This is a program that varies LED brightness using
*              PWM. A delay subroutine is used that lasts 10 micro
*              seconds
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
PUCR    EQU    $000C       ; to enable pull-up mode for PORT A,B,E,K

PTP     EQU    $0258       ; PORTP data register, used for Push Switch
PTIP    EQU    $0259       ; PORTP input data register 
DDRP    EQU    $025A       ; PORTP data direction register
PERP    EQU    $025C       ; PORTP pull up/down enable
PPSP    EQU    $025D       ; PORTP pull up/down selection

***********************************************************************
* Data Section
            ORG     $3000      ; reserved memory starting address
            
Counter1    DC.W    $002E      ; initial X register count number

StackSpace                     ; remaining memory space for stack data
                               ; initial stack pointer position set
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
                               
            LDAA    #%11010000         ; Turn off LED 1,3,4 at PORTB bit 4,6,7
                                       ; Turn on LED 2 at PORTB bit 5
            STAA    PORTB              ; Note: LED nubmers and PORTB bit numbers are different
                               
mainLoop    
            LDAA    PTIP               ; Read push button SW1 at PORTP0
            ANDA    #%00000001         ; Check bit 0 only
            BEQ     sw1pushed          ; Branch if pushed
                                       
            LDAA    #%00001001         ; Load 9  into A
            LDAB    #%01011011         ; Load 91 into B
            BCLR    PORTB,%10000000    ; Turn on LED 4 at PORTB7
snonLoop    JSR     delay10us          ; Delay 10us
            DECA           
            BNE     snonLoop           ; Loop for 9 times
            BSET    PORTB,%10000000    ; Turn off LED 4 at PORTB7
snoffLoop   JSR     delay10us          ; Delay 10us
            DECB
            BNE     snoffLoop          ; Loop for 91 times            
            BRA     mainLoop           ; Loop forever!
            
sw1pushed   
            LDAA    #%00010011         ; Load 19 into A
            LDAB    #%01010001         ; Load 81 into B
            BCLR    PORTB,%10000000    ; Turn on LED 4 at PORTB7
sponLoop    JSR     delay10us          ; Delay 10us
            DECA
            BNE     sponLoop           ; Loop 19 times
            BSET    PORTB,%10000000    ; Turn off LED 4 at PORTB7
spoffLoop   JSR     delay10us          ; Delay 10us
            DECB
            BNE     spoffLoop          ; Loop 81 times        
            BRA     mainLoop

            
***********************************************************************
* Subroutine Section
            
;**********************************************************************
; delay1us subroutine
;
; This subroutine causes a 10us delay
; Input: a 16bit count number in Counter1
; Output: time delay, cpu cycle wasted  (10 + 4 * Counter1)
; Registers: X register, as counter
; Memory locations: a 16 bit input number
; Comments: can change Counter1 to alter the delay

delay10us
            PSHX
            
            LDX     Counter1           ; short delay
dlyusLoop   DEX                        
            NOP
            BNE     dlyusLoop
            
            PULX
            RTS      
            
***********************************************************************

            end                        ; last line of a file      
