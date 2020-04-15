***********************************************************************
* Title: PWM Light Looping
* Objective: CSE472 Homework 5
* Revision: V1                                      
* Date: Jan 30 2019
* Programmer: Aidan Jones
* Company: Penn State University Computer Science
* Algorithm: Simple loop that takes input to determine
*            LED light levels
* Register Use: A,B: Light on/off state and Counters for PWM
*               X,Y: Delay loop counters
* Memory use: RAM locations from  $3000 for data,
*                                 $3100 for program
* Input: Parameters hard coded in program
*        Input from connection
* Output: LED 1,2,3,4 at PORTB bit 4,5,6,7
* Observation: This is a program that varies LED brightness using
*              PWM. A delay subroutine is used that lasts 10 micro
*              seconds. The LED dimms from 0 to 100% and back again
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

Counter2      DC.W    $0014              ; initial Y register count number
Counter3      DC.W    $0063              ; initial dimming loop duration
LightOnn      DC.B    $01                ; initial onn duration
LightOff      DC.B    $63                ; initial off duration
msg1          DC.B    'Hello', $00
msg2          DC.B    'You may type below', $00
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
              LDAA       #%11110000    ; Turn off LED 1,2,3,4 at PORTB bit 4,5,6,7
              STAA       PORTB         ; Note: LED numbers and PORTB bit numbers are different
              
              ldx   #msg5              ; Print out program menu
              jsr   printmsg
              
ledProg       ldy   #buff               ; initialize buffer
              ldx   #msg3
              jsr   printmsg
                                  
charLoop      jsr   getchar            ; get character from serial
              cmpa  #$00               ; if null get next char
              beq   charLoop
              
              jsr   putchar
              staa  1,Y+               ; store character into buffer
              
              cmpa  #CR                ; check for return character
              bne   charLoop
              
              ldaa  #LF                ; cursor to next line
              jsr   putchar
              
              ldy   #buff              ; reset y to buff initial
              
              ldaa  1,Y+               ; load character
                                       
              cmpa  #$46               ; if F go check second character
              beq   isF    
              
              cmpa  #$4C               ; if L go check second character
              beq   isL
              
              jsr   quitCheck          ; check for quit command
              bra   ledProg
              
isF           ldaa  1,Y+               ; check second character after F
              cmpa  #$31               ; 1 
              beq   isF1               
              cmpa  #$32               ; 2
              beq   isF2               
              cmpa  #$33               ; 3
              beq   isF3               
              cmpa  #$34               ; 4
              beq   isF4               
              jsr   invalid            ; invalid command
              bra   back
              
isF1          ldaa  Y
              cmpa  #CR                ; check for return
              bne   badback
              bset  PORTB,%00010000    ; turn LED 1 off
              bra   back

isF2          ldaa  Y
              cmpa  #CR                ; check for return
              bne   badback
              bset  PORTB,%00100000    ; turn LED 2 off
              bra   back

isF3          ldaa  Y
              cmpa  #CR                ; check for return
              bne   badback
              bset  PORTB,%01000000    ; turn LED 3 off
              bra   back

isF4          ldaa  Y
              cmpa  #CR                ; check for return
              bne   badback
              jsr   F4                 ; dimm LED 4 down
              bra   back
              
badback       jsr   invalid            ; print if invalid F/L command 
back          bra   ledProg            ; return to top of program
                

isL           ldaa  1,Y+               ; check second character after L
              cmpa  #$31               ; 1
              beq   isL1
              cmpa  #$32               ; 2
              beq   isL2
              cmpa  #$33               ; 3
              beq   isL3
              cmpa  #$34               ; 4
              beq   isL4
              jsr   invalid            ; invalid command
              bra   back

isL1          ldaa  Y
              cmpa  #CR                ; check for return
              bne   badback
              bclr  PORTB,%00010000    ; turn LED 1 on
              bra   back

isL2          ldaa  Y
              cmpa  #CR                ; check for return
              bne   badback
              bclr  PORTB,%00100000    ; turn LED 2 on
              bra   back

isL3          ldaa  Y
              cmpa  #CR                ; check for return
              bne   badback
              bclr  PORTB,%01000000    ; turn LED 3 on
              bra   back

isL4          ldaa  Y
              cmpa  #CR                ; check for return
              bne   badback
              jsr   L4                 ; dimm LED 4 up
              bra   back


;subroutine section below

;****************typeWriter***********************
;* Program: Typewriter program what you type 
;*          is what you see
;* Input:   characters from keyboard    
;* Output:  same characters from keyboard
;* Registers modified: A, X
;**********************************************
typeWriter    psha
              pshx
              
              ldx   #msg1              ; print the first message, 'Hello'
              jsr   printmsg
            
              ldaa  #CR                ; move the cursor to beginning of the line
              jsr   putchar            ;   Cariage Return/Enter key
              ldaa  #LF                ; move the cursor to next line, Line Feed
              jsr   putchar
            
              ldx   #msg2              ; print the second message
              jsr   printmsg
              
              ldaa  #CR                ; move the cursor to beginning of the line
              jsr   putchar            ;   Cariage Return/Enter key
              ldaa  #LF                ; move the cursor to next line, Line Feed
              jsr   putchar
            
looop         jsr   getchar            ; type writer - check the key board
              cmpa  #$00               ;  if nothing typed, keep checking
              beq   looop
                                       ;  otherwise - what is typed on key board
              jsr   putchar            ; is displayed on the terminal window
              cmpa  #CR
              bne   looop              ; if Enter/Return key is pressed, move the
              ldaa  #LF                ; cursor to next line
              jsr   putchar
              bra   looop
              
              pulx
              pula
              
              rts
;****************end of typeWriter****************

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

;****************quitCheck***********************
;* Program: Print invalid command message
;* Input:   characters from buffer    
;* Output:  none
;* Registers modified: A, Y
;**********************************************
quitCheck      PSHA
               PSHY

               ldy   #buff
               ldaa  1,Y+
               cmpa  #$51                ; Q
               bne   invalidExit   
               ldaa  1,Y+
               cmpa  #$55                ; U
               bne   invalidExit                                                                  
               ldaa  1,Y+
               cmpa  #$49                ; I
               bne   invalidExit
               ldaa  1,Y+
               cmpa  #$54                ; T
               bne   invalidExit
               ldaa  Y
               cmpa  #CR                 ; return character
               bne   invalidExit
               
               jsr   typeWriter          ; if QUIT go to type writer program
               
               bra   exit
               
invalidExit    jsr   invalid             ; else go to invalid message
exit           PULY
               PULA
               
               RTS
;****************end of quitCheck****************

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

;****************F4****************************
;* Program: Dimm LED 4 from 100% to 0% over 2 seconds         
;* Input:   none    
;* Output:  LED 4 is dimmed down
;* Registers modified: A, B, X, Y
;**********************************************
F4          PSHA
            PSHB
            PSHX
            PSHY

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
            
            BSET    PORTB,%10000000    ; stay at 0%
            
            PULY
            PULX
            PULB
            PULA
            
            RTS
;****************end of F4****************

;****************L4****************************
;* Program: Dimm LED 4 from 0% to 100% over 2 seconds         
;* Input:   none    
;* Output:  LED 4 is dimmed up
;* Registers modified: A, B, X, Y
;**********************************************
L4          PSHA
            PSHB
            PSHX
            PSHY

            LDX     Counter3           ; Load Dimm loop counter into X
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
            
            BCLR    PORTB,%10000000    ; Stay at 100%
            
            PULY
            PULX
            PULB
            PULA
            
            RTS
;****************end of L4****************

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
msg5           DC.B    'L1: Turn on LED1', $0d, $0a
msg6           DC.B    'F1: Turn on LED1', $0d, $0a
msg7           DC.B    'L2: Turn on LED2', $0d, $0a
msg8           DC.B    'F2: Turn on LED2', $0d, $0a
msg9           DC.B    'L3: Turn on LED3', $0d, $0a
msg10          DC.B    'F3: Turn on LED3', $0d, $0a
msg11          DC.B    'L4: LED 4 goes from 0% light level to 100% light level in 2 seconds', $0d, $0a
msg12          DC.B    'L4: LED 4 goes from 100% light level to 0% light level in 2 seconds', $0d, $0a
msg13          DC.B    'QUIT: Quit menu program run, Typewriter program.', $0d, $0a, $00


               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled