***********************************************************************
* Title: PWM Light Looping
* Objective: CSE472 Homework 4
* Revision: V1                                      
* Date: Jan 30 2019
* Programmer: Aidan Jones
* Company: Penn State University Computer Science
* Algorithm: Simple duty cycle loop with no inputs
* Register Use: A,B: Light on/off state and Counters for PWM
*               X,Y: Delay loop counters
* Memory use: RAM locations from  $3000 for data,
*                                 $3100 for program
* Input: Parameters hard coded in program
* Output: LED 1,2,3,4 at PORTB bit 4,5,6,7
* Observation: This is a program that varies LED brightness using
*              PWM. A delay subroutine is used that lasts 10 micro
*              seconds. The LED dimms from 0 to 100% and back again
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
Counter2    DC.W    $0014      ; initial Y register count number
Counter3    DC.W    $0063      ; initial dimming loop duration
LightOnn    DC.B    $01        ; initial onn duration
LightOff    DC.B    $63        ; initial off duration

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
            
            
                                                    
mainLoop    LDX     Counter3           ; Load Dimm loop counter into X
dimUpLoop   LDY     Counter2           ; Load Level loop counter into Y
lightULoop  LDAA    LightOnn           ; Load PWM on length
            LDAB    LightOff           ; Load PWM off length
            BCLR    PORTB,%10000000    ; Turn on LED 4 at PORTB7            
onnULoop    JSR     delay10us          ; Delay 10us
            DECA
            BNE     onnULoop           ; Loop onn
            BSET    PORTB,%10000000    ; Turn off LED 4 at PORTB7
offULoop    JSR     delay10us          ; Delay 10us
            DECB
            BNE     offULoop           ; Loop off
            DEY
            BNE     lightULoop         ; Loop 20 times
            LDAA    LightOnn           ; Load LightOnn into A
            ADDA    #1                 ; Increment A by 1
            STAA    LightOnn           ; Store A into LightOnn
            LDAB    LightOff           ; Load LightOff into B
            SUBB    #1                 ; Decrement B by 1
            STAB    LightOff           ; Store B into LightOff
            DEX
            BNE     dimUpLoop          ; Loop 100 times
            
            LDX     Counter3           ; Load Dimm loop counter into X
dimDnLoop   LDAA    LightOnn           ; Load LightOnn into A
            SUBA    #1                 ; Decrement A by 1
            STAA    LightOnn           ; Store A into LightOnn
            LDAB    LightOff           ; Load LightOff into B
            ADDB    #1                 ; Increment B by 1
            STAB    LightOff           ; Store B into LightOff
            LDY     Counter2           ; Load Level loop counter into Y
lightDLoop  LDAA    LightOnn           ; Load PWM on length
            LDAB    LightOff           ; Load PWM off length
            BCLR    PORTB,%10000000    ; Turn on LED 4 at PORTB7            
onnDLoop    JSR     delay10us          ; Delay 10us
            DECA
            BNE     onnDLoop           ; Loop onn
            BSET    PORTB,%10000000    ; Turn off LED 4 at PORTB7
offDLoop    JSR     delay10us          ; Delay 10us
            DECB
            BNE     offDLoop           ; Loop off
            DEY
            BNE     lightDLoop         ; Loop 20 times     
            DEX
            BNE     dimDnLoop          ; Loop 100 times
            
            BRA     mainLoop 
            

            
***********************************************************************
* Subroutine Section
            
;**********************************************************************
; delay10us subroutine
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
