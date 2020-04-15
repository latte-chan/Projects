***********************************************************************
* Title: Interactive Clock
* Objective: CSE472 Homework 8
* Revision: V1                                      
* Date: Mar 25 2019
* Programmer: Aidan Jones
* Company: Penn State University Computer Science
* Algorithm: Take user input, check for its validity, apply to clock
* Register Use: 
* Memory use: RAM locations from  $3000 for data,
*                                 $3100 for program
* Input: Parameters hard coded in program
*        Input from serial connection
* Output: HyperTerminal
* Observation: This program takes the users input and applies it to an 
*              onscreen clock interface
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

SCISR1        EQU     $00cc            ; Serial port (SCI) Status Register 1
SCIDRL        EQU     $00cf            ; Serial port (SCI) Data Register

CRGFLG        EQU     $0037            ; Clock and Reset Generator Flags
CRGINT        EQU     $0038            ; Clock and Reset Generator Interrupts
RTICTL        EQU     $003B            ; Real Time Interrupt Control

CR            EQU     $0d              ; carriage return, ASCII 'Return' key
LF            EQU     $0a              ; line feed, ASCII 'next line' character

;variable/data section below
              ORG     $3000            ; RAMStart defined as $3000
                                       ; in MC9S12C128 chip ($3000 - $3FFF)

ClearScreen     DC.B    $1B, '[2J', $00               ; clear the Hyper Terminal screen
UnSavePosition  DC.B    $1B, '8',  $00                ; restore the saved cursor position
SavePosition    DC.B    $1B, '7',  $00                ; save the current cursor position  
CursorToTop     DC.B    $1B, '[2',  $3B, '1f',  $00   ; move cursor to 2,1  position
CursorToBot     DC.B    $1B, '[15', $3B, '1f',  $00   ; move cursor to 15,1 position
ScrollEnable    DC.B    $1B, '[3',  $3B, '20r', $00   ; enable scrolling

timeTemp      DS.B    6                ; temporaryTime
time                                                                        
timehTen      DS.B    1                ; houurs  tens time
timehOne      DS.B    1                ; hours   ones time
timemTen      DS.B    1                ; minutes tens time
timemOne      DS.B    1                ; minutes ones time
timesTen      DS.B    1                ; seconds tens time
timesOne      DS.B    1                ; seconds ones time
ctr2p5m       DS.W    1                ; 16b counter for 2.5 ms of time
buff          DS.B    11
buffcount     DS.B    1

; interrupt vector section

            ORG     $3FF0              ; Real Time Interrupt (RTI) interrupt vector setup
            DC.W    rtiisr

; code section                                  
StackSP                                ; Stack space reserved from here to
                                       ; StackST

              ORG  $3100
;code section below
Entry
              LDS   #Entry             ; initialize the stack pointer
              
              ldx   #ScrollEnable
              jsr   printmsg
              
              ldx   #ClearScreen       ; clear the HyperTerminal Screen first
              jsr   printmsg
              
              ldx   #CursorToBot       ; move cursor to bottom
              jsr   printmsg
              
              bset  RTICTL,%00011001   ; set RTI: dev=10*(2**10)=2.555msec for C128 board
                                       ;      4MHz quartz oscillator clock
              bset  CRGINT,%10000000   ; enable RTI interrupt
              bset  CRGFLG,%10000000   ; clear RTI IF (Interrupt Flag)
              
              ldaa  #1                 ; initialize clock to 12:00:00
              staa  timehTen
              ldaa  #2
              staa  timehOne
              ldaa  #0
              staa  timemTen
              staa  timemOne
              staa  timesTen
              staa  timesOne
              staa  buffcount
              ldx   #0                 ; initialize interrupt timer to 0
              stx   ctr2p5m
              
              cli                      ; enable interrupt globally
              
              ldx   #msg5              ; Print out program menu
              jsr   printmsg
              
clockProg     ldx   #msg3              ; Print out prompt
              jsr   printmsg
              ldx   #buff              ; initialize buffer 
              ldy   #timeTemp          ; initialize time
              ldaa  #0
              staa  buffcount    

charLoop      jsr   UpDisplay          ; update display

              jsr   getchar            ; get character from serial
              cmpa  #$00               ; if null get next char
              beq   charLoop  
                            
              inc   buffcount
              ldab  buffcount          ; protect against buffer overflow
              cmpb  #12                ; check if on 12th byte
              beq   charDone           ; if so then skip saving and finish input
              
              jsr   putchar
              staa  1,X+               ; store character into buffer
              
              cmpa  #CR                ; check for return character
              bne   charLoop
              
charDone      ldaa  #LF                ; cursor to next line
              jsr   putchar
              
              ldx   #buff              ; reset x to buff initial
              ldaa  #0
              staa  buffcount          ; reset buff count to 0
              
              ldaa  1,X+
              cmpa  #$71               ; compare first char to 'q'
              beq   qCommand
              cmpa  #$73               ; compare first char to 's'
              beq   sCommand
              
qInvalid              
sInvalid      jsr   invalid            ; if neither q or s then invalid
sValid        bra   clockProg
              
qCommand      ldaa  1,X+               ; checks if next character is return character
              cmpa  #CR                ; if not then its invalid
              bne   qInvalid
              jsr   typeWriter

sCommand      ldaa  1,X+               ; check for space
              cmpa  #$20
              bne   sInvalid
              
sLoop         inc   buffcount
              ldaa  1,X+               ; load character
              cmpa  #$3A               ; check if colon
              beq   sColon
              suba  #$30               ; get decimal form
              ldab  buffcount          ; get number index (0 => hh:mm:ss <= 8)
              cmpb  #1
              beq   isHTens            ; is hours tens place
              cmpb  #2
              beq   isHOnes            ; is hours ones place
              cmpb  #4
              beq   isTens             ; is tens place
              cmpb  #5
              beq   isOnes             ; is ones place
              cmpb  #7
              beq   isTens             ; is tens place
              cmpb  #8
              beq   isOnes             ; is ones place

isHOnes       ldab  timehTen           ; check if hours tens is 0
              cmpb  #0
              beq   isOnes
              cmpa  #2                 ; if higher than 2 its invalid (only for hours ones when tens = 1)
              bhi   sInvalid
              
isOnes        cmpa  #0                 ; if lower than 0 its invalid
              blo   sInvalid
              cmpa  #9                 ; if higher than 9 its invalid
              bhi   sInvalid
              bra   sStore
              
sValidBreak   bra   sValid

isHTens       cmpa  #1                 ; if higher than 1 its invalid (only for hours tens)
              bhi   sInvalid
isTens        cmpa  #0                 ; if lower than 0 its invalid
              blo   sInvalid           
              cmpa  #5                 ; if higher than 5 its invalid
              bhi   sInvalid
              
sStore        staa  1,Y+               ; store into correct place in clock
              ldab  buffcount
              cmpb  #8                 ; stop once 8 characters are read
              beq   sDone
              bra   sLoop

sColon        ldab  buffcount          ; checks if colon is in correct places (hh:mm:ss)
              cmpb  #3                 ; 3rd place
              beq   sLoop
              cmpb  #6                 ; 6th place
              beq   sLoop
              bra   sInvalid

sDone         ldaa  1,X+               ; done checking the hh:mm:ss portion of input
              cmpa  #CR                ; checks if next character is return if not its invalid
              bne   sInvalid
              
              ldx   #timeTemp          ; move the time from temporary storage to actual clock
              ldy   #time
              
              ldaa  #0
validLoop     ldab  1,X+               ; loop through each number to update clock
              stab  1,Y+
              inca
              cmpa  #6
              bne   validLoop              
              
              bra   sValidBreak        

;subroutine section below

;***********RTI interrupt service routine***************
rtiisr      bset  CRGFLG,%10000000   ; clear RTI Interrupt Flag
            ldx   ctr2p5m
            inx
            stx   ctr2p5m            ; every time the RTI occur, increase interrupt count
rtidone     RTI
;***********end of RTI interrupt service routine********

;***************Update Display**********************
;* Program: Update clock timer after 1 second is up
;* Input:   ctr2p5m variable
;* Output:  clock display on the Hyper Terminal
;* Registers modified: CCR, A, X
;* Algorithm:
;    Check for 1 second passed
;      if not 1 second yet, just pass
;      if 1 second has reached, then update display and reset ctr2p5m
;**********************************************
UpDisplay   psha
            pshx
            
            ldx   ctr2p5m          ; check for 1 sec
            cpx   #399             ; 2.5msec * 400 = 1 sec        0 to 399 count is 400
            blo   SkipEnd          ; if interrupt count less than 400, then not 1 sec yet.
                                   ; no need to update display.

            ldx   #0               ; interrupt counter reached 400 count, 1 sec up now
            stx   ctr2p5m          ; clear the interrupt count to 0, for the next 1 sec.

            ldx   #SavePosition    ; save the current cursor posion (user input in
            jsr   printmsg         ; progress at the prompt).
            ldx   #CursorToTop     ; and move the cursor to top
            jsr   printmsg

            ldaa  #$30             ; timer display update, hours tens
            adda  timehTen         
            jsr   putchar

            ldaa  #$30             ; timer display update, hours ones
            adda  timehOne         
            jsr   putchar
            
            ldaa  #$3A             ; print colon ':'
            jsr   putchar
            
            ldaa  #$30             ; timer display update, minutes tens
            adda  timemTen         
            jsr   putchar

            ldaa  #$30             ; timer display update, minutes ones
            adda  timemOne         
            jsr   putchar
            
            ldaa  #$3A             ; print colon ':'
            jsr   putchar
            
            ldaa  #$30             ; timer display update, seconds tens
            adda  timesTen         
            jsr   putchar

            ldaa  #$30             ; timer display update, seconds ones
            adda  timesOne         
            jsr   putchar

            ldx   #UnSavePosition  ; back to the prompt area for continued user input
            jsr   printmsg
            bra   SkipSkip
            
SkipEnd     bra   UpEnd

SkipSkip    inc   timesOne         ; one second has passed so update clock       
            ldaa  timesOne         
            cmpa  #10              ; checks if increment should be carried to next place
            bne   UpDone
            ldaa  #0               ; reset current place
            staa  timesOne
            
            inc   timesTen         ; carry the increment
            ldaa  timesTen
            cmpa  #6               ; checks if increment should be carried to next place
            bne   UpDone
            ldaa  #0               ; reset current place
            staa  timesTen
            
            inc   timemOne         ; carry the increment
            ldaa  timemOne
            cmpa  #10              ; checks if increment should be carried to next place
            bne   UpDone
            ldaa  #0               ; reset current place
            staa  timemOne
            
            inc   timemTen         ; carry the increment
            ldaa  timemTen
            cmpa  #6               ; checks if increment should be carried to next place
            bne   UpDone
            ldaa  #0               ; reset current place
            staa  timemTen
            
            inc   timehOne         ; carry the increment
            ldaa  timehOne
            cmpa  #10              ; checks if increment should be carried to next place
            bne   UpDone
            ldaa  #0               ; reset current place
            staa  timehOne
            
            inc   timehTen         ; carry the increment
            
UpDone      ldaa  timehTen         ; check if clock should wrap from 12:59:59 to 01:00:00
            cmpa  #1
            bne   UpEnd
            ldaa  timehOne
            cmpa  #3               ; checks when clock reads 13:00:00 and sets it to 01:00:00
            bne   UpEnd
            ldaa  #0
            staa  timehTen
            ldaa  #1
            staa  timehOne
            ldaa  #0
            staa  timemTen
            staa  timemOne
            staa  timesTen
            staa  timesOne
            
UpEnd       pulx
            pula
            rts
;***************end of Update Display***************

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
            
looop         jsr   UpDisplay

              jsr   getchar            ; type writer - check the key board
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

;OPTIONAL
;more variable/data section below
; this is after the program code section
; of the RAM.  RAM ends at $3FFF
; in MC9S12C128 chip


msg1           DC.B    'Hello', $00
msg2           DC.B    'You may type below', $00
msg3           DC.B    'Clock> ', $00
msg4           DC.B    'Error: Invalid time format. Correct Example => hh:mm:ss', $0d, $0a, $00
msg5           DC.B    'Clock> ', $0d, $0a, $00
msg6           DC.B    '       ', $00


               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled