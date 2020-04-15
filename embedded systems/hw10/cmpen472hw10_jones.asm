***********************************************************************
* Title: Timer module and interrupt based Analog Signal Acquisition
* Objective: CSE472 Homework 10
* Revision: V1                                      
* Date: Apr 12 2019
* Programmer: Aidan Jones
* Company: Penn State University Computer Science
* Algorithm: waits for button 1 to be pressed to send data over SCI
* Register Use: 
* Memory use: RAM locations from  $3000 for data,
*                                 $3100 for program
* Input: Parameters hard coded in program
*        Input from serial connection
* Output: HyperTerminal and Binary Data
* Observation: This program takes the users input and sends hex
*              or binary data
* Comments: This program is developed and simulated using
* CopdeWarrior development software and targeted for Axion
* Manufacturing's APS12C128 board running at 24MHz bus clock
***********************************************************************
;export symbols
              XDEF      Entry          ; export 'Entry' symbol
              ABSENTRY  Entry          ; for assembly entry point

;include derivative specific macros
PORTB         EQU    $0001
DDRB          EQU    $0003

PTP           EQU    $0258             ; PORTP data register, used for Push Switch
PTIP          EQU    $0259             ; PORTP input data register 
DDRP          EQU    $025A             ; PORTP data direction register
PERP          EQU    $025C             ; PORTP pull up/down enable
PPSP          EQU    $025D             ; PORTP pull up/down selection
                                    
SCISR1        EQU    $00cc             ; Serial port (SCI) Status Register 1
SCIDRL        EQU    $00cf             ; Serial port (SCI) Data Register

CRGFLG        EQU    $0037             ; Clock and Reset Generator Flags
CRGINT        EQU    $0038             ; Clock and Reset Generator Interrupts
RTICTL        EQU    $003B             ; Real Time Interrupt Control
                               
SCIBDH        EQU    $00c8             ; Baud rate register top 5 bits
SCIBDL        EQU    $00c9             ; Baud rate register bottom 8 bits

ATDCTL2       EQU    $0082             ; registers for Analog to Digital conversions
ATDCTL3       EQU    $0083
ATDCTL4       EQU    $0084
ATDCTL5       EQU    $0085
ATDSTAT0      EQU    $0086
ATDDR0H       EQU    $0090
ATDDR0L       EQU    $0091
ATDDR7H       EQU    $009e
ATDDR7L       EQU    $009f

TIOS          EQU    $0040             ; Timer Input Capture (IC) or Output Compare (OC) select
TIE           EQU    $004C             ; Timer interrupt enable register
TCNTH         EQU    $0044             ; Timer free runing main counter
TSCR1         EQU    $0046             ; Timer system control 1
TSCR2         EQU    $004D             ; Timer system control 2
TFLG1         EQU    $004E             ; Timer interrupt flag 1
TC2H          EQU    $0054             ; Timer channel 2 register

CR            EQU    $0d               ; carriage return, ASCII 'Return' key
LF            EQU    $0a               ; line feed, ASCII 'next line' character

;variable/data section below
              ORG     $3000            ; RAMStart defined as $3000
                                       ; in MC9S12C128 chip ($3000 - $3FFF)

ClearScreen     DC.B    $1B, '[2J', $00               ; clear the Hyper Terminal screen
UnSavePosition  DC.B    $1B, '8',  $00                ; restore the saved cursor position
SavePosition    DC.B    $1B, '7',  $00                ; save the current cursor position  
CursorToTop     DC.B    $1B, '[2',  $3B, '30f',  $00   ; move cursor to 2,30  position
CursorToBot     DC.B    $1B, '[15', $3B, '1f',  $00   ; move cursor to 15,1 position
ScrollEnable    DC.B    $1B, '[3',  $3B, '20r', $00   ; enable scrolling

ctr125u       DS.W    1                ; 16bit interrupt counter for 125 uSec. of time

ATDdone       DS.B    1                ; ADC finish indicator, 1 = ATD finished

; interrupt vector section

              ORG     $3FEA            ; Timer channel 2 interrupt vector setup
              DC.W    oc2isr
              
; code section                                  
StackSP                                ; Stack space reserved from here to
                                       ; StackST

              ORG  $3100
;code section below
Entry
              LDS   #Entry             ; initialize the stack pointer
              
              LDAA    #%00000000       ; set PORTB bit 7,6,5,4,3,2,1,0 as input
              STAA    DDRB             
              
              BCLR    DDRP,%00000011   ; Push Button Switch 1 and 2 at PORTP bit 0 and 1
                                       ; set PORTP bit 0 and 1 as input
              BSET    PERP,%00000011   ; endable the pull up/down feature at PORTP bit 0 and 1
              BCLR    PPSP,%00000011   ; select pull up feature at PORTP bit 0 and 1 fopr the
                                       ; Push Button Switch 1 and 2.
              
              LDAA  #%11000000         ; Turn ON ADC, clear flags, Disable ATD interrupt
              STAA  ATDCTL2
              LDAA  #%00001000         ; Single conversion per sequence, no FIFO
              STAA  ATDCTL3
              LDAA  #%01000111         ; 10bit, ADCLK=24MHz/16=1.5MHz, sampling time=8*(1/ADCLK)
              STAA  ATDCTL4              
              
              
              
              ldx   #msg7              ; print messages to user for information
              jsr   printmsg
              
              bclr  SCIBDH,%11111111   ; clear the previous baud rate
              bclr  SCIBDL,%11111111
              
              bset  SCIBDH,%00000000   ; set baud rate register to 13
              bset  SCIBDL,%00001101   
              
baudLoop      jsr   getchar            ; loop to wait for enter key
              cmpa  #$00               ; null
              beq   baudLoop
              cmpa  #CR                ; enter key
              bne   baudLoop  
              
              ldx   #msg8              ; print messages to user for information
              jsr   printmsg
              
audioLoop     jsr   getchar            ; loop to wait for enter key
              cmpa  #$00               ; null
              beq   audioLoop
              cmpa  #CR                ; enter key
              bne   audioLoop      
              
              ldx   #msg5              ; print messages to user for information
              jsr   printmsg         
              
adcLoop       jsr   getchar            ; loop to wait for enter key
              cmpa  #$00               ; null
              beq   adcLoop
              cmpa  #CR                ; enter key
              bne   adcLoop
              
doAdc         jsr   singleADC          ; do single analog to digital conversion
              
              ldx   #msg5              ; print messages to user for information
              jsr   printmsg
              
adcLoop2      jsr   getchar            ; loop to wait for enter or 'a' key
              cmpa  #$00               ; null
              beq   adcLoop2
              cmpa  #CR                ; enter key
              beq   doAdc
              cmpa  #$61               ; 'a' key
              bne   adcLoop2
              
              ldx   #msg9              ; print messages to user for information
              jsr   printmsg
              ldx   #msg10
              jsr   printmsg 
              ldx   #msg11
              jsr   printmsg 
              ldx   #msg12
              jsr   printmsg  
              
buttonLoop    ldaa  PTIP               ; check if button 1 is pressed
              anda  #%00000001
              bne   buttonLoop
              
              jsr   multiADC           ; if so do 1030 single analog to digital conversions
              
              bra   buttonLoop             
              
;subroutine section below

;***********single AD conversiton*********************
; This is a sample, non-interrupt, busy wait method
;
singleADC
            PSHA                   ; Start ATD conversion
            LDAA  #%00000111       ; left justified, unsigned, single conversion,
            STAA  ATDCTL5          ; single channel, CHANNEL 7, start the conversion

adcwait     ldaa  ATDSTAT0         ; Wait until ATD conversion finish
            anda  #%10000000       ; check SCF bit, wait for ATD conversion to finish
            beq   adcwait

            ldaa  #'$'             ; print the ATD result, in hex
            jsr   putchar

            ldaa  ATDDR0H          ; pick up the upper 8bit result
            jsr   printHx          ; print the ATD result
            jsr   nextline

            PULA
            RTS
;***********end of AD conversiton**************  

;***********multi AD conversiton**********************
;
multiADC
            psha                   ; Start multi ATD conversion
            pshx
            
            ldx   #0               ; reset counter
            stx   ctr125u
            
            jsr   StartTimer2oc    ; start interrupts 
            
multiLoop   ldx   ctr125u          ; check if done 1030 times
            cpx   #1029
            blo   multiLoop
            
            sei                    ; stop interrupts
            pulx
            pula
            rts
;***********end of AD conversiton**************  

;***********printHx***************************
; prinHx: print the content of accumulator A in Hex on SCI port
printHx     psha
            lsra
            lsra
            lsra
            lsra
            cmpa   #$09
            bhi    alpha1
            adda   #$30
            jsr    putchar
            bra    low4bits
alpha1      adda   #$37
            jsr    putchar            
low4bits    pula
            anda   #$0f
            cmpa   #$09
            bhi    alpha2
            adda   #$30
            jsr    putchar
            rts
alpha2      adda   #$37
            jsr    putchar
            rts
;***********end of printhx***************************      

;****************nextline**********************
nextline    ldaa  #CR              ; move the cursor to beginning of the line
            jsr   putchar          ;   Cariage Return/Enter key
            ldaa  #LF              ; move the cursor to next line, Line Feed
            jsr   putchar
            rts
;****************end of nextline***************    


;***********printmsg***************************
;* Program: Output character string to SCI port, print message
;* Input:   Register X points to ASCII characters in memory
;* Output:  message printed on the terminal connected to SCI port
;* 
;* Registers modified: CCR
;* Algorithm:
;     Pick up 1 byte from memory where X register is pointing
;     Send it out to SCI port
;     Update X register to point to the next byte
;     Repeat until the byte data $00 is encountered
;       (String is terminated with NULL=$00)
;**********************************************
NULL           equ     $00
printmsg       psha                   ;Save registers
               pshx
printmsgloop   ldaa    1,X+           ;pick up an ASCII character from string
                                       ;   pointed by X register
                                       ;then update the X register to point to
                                       ;   the next byte
               cmpa    #NULL
               beq     printmsgdone   ;end of strint yet?
               jsr     putchar        ;if not, print character and do next
               bra     printmsgloop

printmsgdone   pulx 
               pula
               rts
;***********end of printmsg********************


;***************putchar************************
;* Program: Send one character to SCI port, terminal
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Send one character to SCI port, terminal
;* Registers modified: CCR
;* Algorithm:
;    Wait for transmit buffer become empty
;      Transmit buffer empty is indicated by TDRE bit
;      TDRE = 1 : empty - Transmit Data Register Empty, ready to transmit
;      TDRE = 0 : not empty, transmission in progress
;**********************************************
putchar        brclr SCISR1,#%10000000,putchar   ; wait for transmit buffer empty
               staa  SCIDRL                      ; send a character
               rts
;***************end of putchar*****************


;****************getchar***********************
;* Program: Input one character from SCI port (terminal/keyboard)
;*             if a character is received, other wise return NULL
;* Input:   none    
;* Output:  Accumulator A containing the received ASCII character
;*          if a character is received.
;*          Otherwise Accumulator A will contain a NULL character, $00.
;* Registers modified: CCR
;* Algorithm:
;    Check for receive buffer become full
;      Receive buffer full is indicated by RDRF bit
;      RDRF = 1 : full - Receive Data Register Full, 1 byte received
;      RDRF = 0 : not full, 0 byte received
;**********************************************
getchar        brclr SCISR1,#%00100000,getchar7
               ldaa  SCIDRL
               rts
getchar7       clra
               rts
;****************end of getchar****************

;***********Timer OC2 interrupt service routine***************
oc2isr
            ldd   #3000              ; 125usec with (24MHz/1 clock)
            addd  TC2H               ;    for next interrupt
            std   TC2H               ;    + Fast clear timer CH2 interrupt flag  
            
            ldaa  ATDDR0H            ; pick up the upper 8bit result
            jsr   putchar            ; put raw binary to SCI port
            
            ldx   ctr125u            ; 125uSec => 8.000KHz rate
            inx
            stx   ctr125u            ; every time the RTI occur, increase interrupt count  
            
            LDAA  #%00000111         ; left justified, unsigned, single conversion,
            STAA  ATDCTL5            ; single channel, CHANNEL 7, start the conversion
            
oc2done     RTI
;***********end of Timer OC2 interrupt service routine********

;***************StartTimer2oc************************
;* Program: Start the timer interrupt, timer channel 2 output compare
;* Input:   Constants - channel 2 output compare, 125usec at 24MHz
;* Output:  None, only the timer interrupt
;* Registers modified: D used and CCR modified
;* Algorithm:
;             initialize TIOS, TIE, TSCR1, TSCR2, TC2H, and TFLG1
;**********************************************
StartTimer2oc
            PSHD
            LDAA   #%00000100
            STAA   TIOS              ; set CH2 Output Compare
            STAA   TIE               ; set CH2 interrupt Enable
            LDAA   #%10010000        ; enable timer and set Fast Flag Clear
            STAA   TSCR1
            LDAA   #%00000000        ; TOI Off, TCRE Off, TCLK = BCLK/1
            STAA   TSCR2             ;   not needed if started from reset

            LDD     #3000            ; 125usec with (24MHz/1 clock)
            ADDD    TCNTH            ;    for first interrupt
            STD     TC2H             ;    + Fast clear timer CH2 interrupt flag

            PULD
            BSET   TFLG1,%00000100   ; initial Timer CH2 interrupt flag Clear, not needed if fast clear set
            CLI                      ; enable interrupt
            RTS
;***************end of StartTimer2oc*****************

;OPTIONAL
;more variable/data section below
; this is after the program code section
; of the RAM.  RAM ends at $3FFF
; in MC9S12C128 chip


msg1           DC.B    'Hello', $00
msg2           DC.B    'You may type below', $00
msg5           DC.B    'Well> ', $0d, $0a, $00
msg6           DC.B    '       ', $00
msg7           DC.B    'Please change Hyper Termial to 115.2K baud.', $0d, $0a, $00
msg8           DC.B    'Please connect the audio cable to HCS12 board.', $0d, $0a, $00
msg9           DC.B    'Please disconnect the HyperTerminal.', $0d, $0a, $00
msg10          DC.B    'Start NCH Tone Generator program.', $0d, $0a, $00
msg11          DC.B    'Start SB Data Receive program.', $0d, $0a, $00
msg12          DC.B    'Then press the switch SW1, for 1024 point analog to digital conversions.', $0d, $0a, $00


               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled