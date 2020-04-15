***********************************************************************
* Title: PWM Light Text Interface
* Objective: CSE472 Homework 56
* Revision: V1                                      
* Date: Feb 25 2019
* Programmer: Aidan Jones
* Company: Penn State University Computer Science
* Algorithm: Loop system that takes text input to determine
*            LED light levels
* Register Use: A,B: Light on/off state and Counters for PWM
*               X,Y: Delay loop counters
* Memory use: RAM locations from  $3000 for data,
*                                 $3100 for program
* Input: Parameters hard coded in program
*        Input from serial connection
* Output: LED 1,2,3,4 at PORTB bit 4,5,6,7
* Observation: This is a program that varies LED brightness using
*              PWM. A delay subroutine is used that lasts 10 micro
*              seconds. The LED dimms to level determined by input
* Comments: This program is developed and simulated using
* CopdeWarrior development software and targeted for Axion
* Manufacturing's APS12C128 board running at 24MHz bus clock
***********************************************************************
;export symbols
              XDEF      Entry          ; export 'Entry' symbol
              ABSENTRY  Entry          ; for assembly entry point

;include derivative specific macros
PORTB         EQU     $0001
DDRB          EQU     $0003
;add more for the ones you need

SCISR1        EQU     $00cc            ; Serial port (SCI) Status Register 1
SCIDRL        EQU     $00cf            ; Serial port (SCI) Data Register

;following is for the TestTerm debugger simulation only
;SCISR1        EQU     $0203            ; Serial port (SCI) Status Register 1
;SCIDRL        EQU     $0204            ; Serial port (SCI) Data Register

CR            equ     $0d              ; carriage return, ASCII 'Return' key
LF            equ     $0a              ; line feed, ASCII 'next line' character

;variable/data section below
              ORG     $3000            ; RAMStart defined as $3000
                                       ; in MC9S12C128 chip ($3000 - $3FFF)

dimmTimer     DC.W    $001E            ; PWM dimm amount
charAmount    DC.B    $00              ; input char decimal amount
totlAmount    DC.B    $00              ; total of all input amounts
fullAmount    DC.B    $65              ; full onn time for LED 4
onnAmount     DC.B    $64              ; initial onn time for LED 4
offAmount     DC.B    $01              ; initial off time for LED 4
buff          
; Each message ends with $00 (NULL ASCII character) for your program.
;
; There are 256 bytes from $3000 to $3100.  If you need more bytes for
; your messages, you can put more messages 'msg3' and 'msg4' at the end of 
; the program.
                                  
StackSP                                ; Stack space reserved from here to
                                       ; StackST

              ORG  $3100
;code section below
Entry
              LDS   #Entry             ; initialize the stack pointer

; add PORTB initialization code here

              LDAA       #%11110000    ; set PORTB bit 7,6,5,4 as output, 3,2,1,0 as input
              STAA       DDRB          ; LED 1,2,3,4 on PORTB bit 4,5,6,7
                                       ; DIP switch 1,2,3,4 on PORTB bit 0,1,2,3.
              LDAA       #%01010000    ; Turn off LED 1,2,3,4 at PORTB bit 4,5,6,7
              STAA       PORTB         ; Note: LED numbers and PORTB bit numbers are different
              
              ldx   #msg5              ; Print out program menu
              jsr   printmsg
              
ledProg       ldy   #buff               ; initialize buffer
              ldx   #msg3
              jsr   printmsg
                                  
charLoop      jsr   dimm30ms

              jsr   getchar            ; get character from serial
              cmpa  #$00               ; if null get next char
              beq   charLoop
              
              jsr   putchar
              staa  1,Y+               ; store character into buffer
              
              cmpa  #CR                ; check for return character
              bne   charLoop
              
              ldaa  #LF                ; cursor to next line
              jsr   putchar
              
              ldy   #buff              ; reset y to buff initial
              
              ldaa  1,Y+               ; load first character
              
              jsr   checkchar01        ; check if char is between 0-1 and load into data
              ldab  charAmount         ; load the decimal value
              cmpb  #$FF
              beq   ledProg
              cmpb  #$01
              beq   is100
              jsr   mult10             ; multiply it by 10
              jsr   mult10             ; multiply it by 10 again (mult by 100)
              ldab  charAmount         ; load updated decimal value
              stab  totlAmount         ; store new value into total
              
              ldaa  1,Y+               ; load second character
              
              jsr   checkchar          ; check if char is between 0-9 and load into data
              ldab  charAmount         ; load the decimal value
              cmpb  #$FF
              beq   ledProg
              jsr   mult10             ; multiply it by 10
              ldab  charAmount         ; load updated decimal value
              ldaa  totlAmount         ; load current total
              aba                      ; add new amount to total
              staa  totlAmount         ; store new value into total
              
              ldaa  1,Y+               ; load third character
              
              jsr   checkchar          ; check if char is between 0-9 and load into data
              ldab  charAmount         ; load the decimal value
              cmpb  #$FF
              beq   ledProg
              ldab  charAmount
              ldaa  totlAmount         ; load current total
              aba                      ; add new amount to total
              staa  totlAmount         ; store new value into total
              
              ldaa  1,Y+               ; load fourth character
              cmpa  #CR                ; check if it is return char
              beq   valid
              jsr   invalid
back          bra   ledProg

is100         jsr   mult10             ; multiply it by 10
              jsr   mult10             ; multiply it by 10 again (mult by 100)
              ldab  charAmount         ; load updated decimal value
              stab  totlAmount         ; store new value into total
              
              ldaa  1,Y+
              
              jsr   checkchar0         ; check if second char is 0
              ldab  charAmount
              cmpb  #$FF
              beq   back               ; if not it is invalid
              
              ldaa  1,Y+
              
              jsr   checkchar0         ; check if thrid char is 0
              ldab  charAmount
              cmpb  #$FF               ; if not it is invalid
              beq   back
              
              ldaa  1,Y+               ; load fourth character
              cmpa  #CR                ; check if it is return char
              beq   valid
              jsr   invalid
              bra   back         
              
valid         ldaa  totlAmount
              ldab  fullAmount
              staa  onnAmount          ; store onn time into data         
              subb  totlAmount         ; subtract from 100 to find off timer
              stab  offAmount          ; store off time into data
              
              ldaa  #$00
              staa  totlAmount                     
                                       
              bra   back
              

;subroutine section below

;***************dimm30ms************************
;* Program: dimms LED 4 for 30 milliseconds
;* Input:   None
;* Output:  LED 4 is dimmed to specific level
;* Registers modified: A,B,X
;**********************************************
dimm30ms      psha
              pshb
              pshx
              
              ldx   dimmTimer
              
pwmLoop       ldaa  onnAmount
              ldab  offAmount          ; check if light level is 0
              cmpa  #$00
              beq   off
              
              bclr  PORTB,#%10000000   ; turn onn LED 4
onnLoop       jsr   delay10us
              deca
              bne   onnLoop            ; loop for total onn amount
              bset  PORTB,#%10000000   ; turn off LED 4
offLoop       jsr   delay10us
              decb
              bne   offLoop            ; loop for total off amount
              
              dex
              bne   pwmLoop            ; loop 300 times (30 milliseconds)
              
off           bset  PORTB,#%10000000   ; turn off LED 4
              
              pulx
              pulb
              pula  
              rts         
;***************end of dimm30ms****************

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

;***************checkchar************************
;* Program: check char is between 0-9
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Data at charAmount holds decimal value of input char
;* Registers modified: B
;**********************************************
checkchar     pshb
              
              cmpa  #$30               ; check char is between 0-9
              beq   is0
              cmpa  #$31               
              beq   is1
              cmpa  #$32               
              beq   is2
              cmpa  #$33
              beq   is3
              cmpa  #$34
              beq   is4
              cmpa  #$35
              beq   is5
              cmpa  #$36
              beq   is6
              cmpa  #$37
              beq   is7
              cmpa  #$38
              beq   is8
              cmpa  #$39
              beq   is9
              jsr   invalid            ; if not print invalid
              ldab  #$FF
              bra   checkEnd
              
checkchar01   pshb
              
              cmpa  #$30               ; check char is between 0-1
              beq   is0
              cmpa  #$31               
              beq   is1
              jsr   invalid            ; if not print invalid
              ldab  #$FF
              bra   checkEnd 
              
checkchar0    pshb
              
              cmpa  #$30               ; check char is 0
              beq   is0
              jsr   invalid            ; if not print invalid
              ldab  #$FF
              bra   checkEnd              
              
is0           ldab  #$00               ; load correct decimal value into b
              bra   checkEnd
is1           ldab  #$01
              bra   checkEnd
is2           ldab  #$02
              bra   checkEnd                            
is3           ldab  #$03
              bra   checkEnd              
is4           ldab  #$04
              bra   checkEnd              
is5           ldab  #$05
              bra   checkEnd              
is6           ldab  #$06
              bra   checkEnd
is7           ldab  #$07
              bra   checkEnd              
is8           ldab  #$08
              bra   checkEnd
is9           ldab  #$09
              bra   checkEnd                            
              
checkEnd      stab  charAmount         ; store value into data
              pulb
              rts              
;***************end of checkchar*****************

;***************mult10***************************
;* Program: multiplies number by 10
;* Input:   Data at charAmount holds decimal value
;* Output:  Data at charAmount holds 10 * input value
;* Registers modified: A,B
;************************************************
mult10        psha
              pshb

              ldab  charAmount         ; load input into b
              ldaa  charAmount         ; load input into a
              
              aslb                     ; multiply b by 8
              aslb
              aslb
              asla                     ; multiply a by 2
              
              aba                      ; add b to a to get multiply by 10
              
              staa  charAmount         ; store value in data
                      
              pulb
              pula
              rts         
;***************end of mult10********************

;****************invalid***********************
;* Program: Print invalid command message
;* Input:   none    
;* Output:  invalid command string to user
;* Registers modified: A, X
;**********************************************
invalid       psha
              pshx
              
              ldx   #msg4              ; print invalid command message
              jsr   printmsg
              
              pulx
              pula
              
              rts
;****************end of invalid****************

;****************delay10us************************
; This subroutine causes a 10us delay
; Input: a 16bit count number in Counter1
; Output: time delay, cpu cycle wasted  (10 + 4 * Counter1)
; Registers: X register, as counter
; Memory locations: a 16 bit input number
; Comments: can change Counter1 to alter the delay
Counter1    DC.W    $002E              ; initial X register count number

delay10us
            PSHX
            
            LDX     Counter1           ; short delay
dlyusLoop   DEX                        
            NOP
            BNE     dlyusLoop
            
            PULX
            RTS
;****************end of delay10us*****************



;OPTIONAL
;more variable/data section below
; this is after the program code section
; of the RAM.  RAM ends at $3FFF
; in MC9S12C128 chip

msg3           DC.B    'Enter your command below:', $0d, $0a, $00
msg4           DC.B    'Error: Invalid command', $0d, $0a, $00
msg5           DC.B    'Welcome', $0d, $0a
msg6           DC.B    'Enter the LED 4 light level', $0d, $0a
msg7           DC.B    '000 to 100 in range (always add leading 0s), and hit ENTER', $0d, $0a, $00


               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled