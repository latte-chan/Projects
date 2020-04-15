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
charAmount    DC.B    $00
charOp        DC.B    $00
num1Len       DC.B    $00
num2Len       DC.B    $00
tempLen       DC.B    $00
operator      DC.B    $00
equals        DC.B    $3D
num1digits    DS.B    3
num2digits    DS.B    3
tempAddr      DC.W    $0000
tempNum       DC.W    $0000
digitAmount   DC.W    $0000
num1          DC.W    $0000
num2          DC.W    $0000
total         DC.W    $0000
totalDigits   DS.B    5
totalLen      DC.B    $01
termTot       DC.B    $00
buff          DS.B    50
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
              
ledProg       ldx   #msg3
              jsr   printmsg
              ldy   #buff               ; initialize buffer
              
              ldaa  #$00
              ldx   #num1digits
              staa  1,X+  
              staa  1,X+
              staa  1,X+
              ldx   #num2digits
              staa  1,X+
              staa  1,X+
              staa  1,X+
              ldx   #totalDigits
              staa  1,X+
              staa  1,X+
              staa  1,X+
              staa  1,X+
              staa  1,X+
              staa  num1Len
              staa  num2Len
              staa  charOp
              staa  charAmount
              staa  operator
              ldx   #$0000
              stx   num1
              stx   num2
              stx   total
                   

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
              
              bra   check1

progBack1     bra   ledProg            ; jump backwarding
              
check1        ldx   #num1digits
check1Loop    ldaa  1,Y+               ; load character
              
              staa  tempAddr           
              jsr   checkop            ; check if op is read early
              ldaa  charOp
              cmpa  #$FF
              bne   opRead
              
              ldaa  tempAddr
              
              jsr   checknum           ; check if char is a valid number
              ldaa  charAmount
              cmpa  #$FF               ; print invalid statement if num is invalid
              beq   invForward4
              staa  1,X+               ; store digit for num1
              ldab  num1Len
              incb                     ; update length of num1
              stab  num1Len
              cmpb  #$03
              bne   check1Loop
              bra   Read1

opRead        dey              
Read1         sty   tempAddr
              
              ldx   #num1digits        ; reset x to num1digits initial
              ldy   num1               ; load num1
              ldab  num1Len            ; load length of num1
              decb                     ; decrement by one to find memory offset
              stab  tempLen
              abx                      ; add offset to num1digits
              ldab  1,X-               ; load ones digit
              aby                      ; add ones digit
              sty   num1
              ldaa  tempLen            ; number of remaining digits
              cmpa  #$00
              beq   num1Done           ; if no more digits num1 is done
              ldab  1,X-               ; load tens digit
              jsr   mult10             ; get tens value
              xgdy                     ; exchange y and d
              addd  digitAmount        ; add digitAmount to d (y)
              xgdy                     ; exchange y and d
              sty   num1
              deca
              cmpa  #$00
              beq   num1Done           ; if no more digits num1 is done
              ldab  1,X-               ; load hundreds digit
              jsr   mult10             
              jsr   mult16b10          ; get hundreds value
              xgdy                     ; exchange y and d
              addd  digitAmount        ; add digitAmount to d (y)
              xgdy                     ; exchange y and d
              sty   num1
              bra   num1Done           ; no more digits num1 is done             

progBack2     bra   progBack1          ; jump backwarding
invForward4   bra   invForward3        ; jump forwarding
              
num1Done      ldy   tempAddr
              
              ldaa  1,Y+               ; read next char
              
              staa  operator           ; check is it is valid operator
              jsr   checkop
              ldaa  charOp
              cmpa  #$FF
              beq   invForward3
              
              ldx   #num2digits
check2Loop    ldaa  1,Y+               ; load character
              
              cmpa  #CR
              beq   endRead
              
              jsr   checknum           ; check if char is a valid number
              ldaa  charAmount
              cmpa  #$FF               ; print invalid statement if num is invalid
              beq   invForward3
              staa  1,X+               ; store digit for num1
              ldab  num2Len
              incb                     ; update length of num1
              stab  num2Len
              cmpb  #$03
              bne   check2Loop
              
endRead       sty   tempAddr
              
              ldx   #num2digits        ; reset x to num1digits initial
              ldy   num2               ; load num2
              ldab  num2Len            ; load length of num2
              decb                     ; decrement by one to find memory offset
              stab  tempLen
              abx                      ; add offset to num2digits
              ldab  1,X-               ; load ones digit
              aby                      ; add ones digit
              sty   num2
              ldaa  tempLen            ; number of remaining digits
              cmpa  #$00
              beq   num2Done           ; if no more digits num2 is done
              ldab  1,X-               ; load tens digit
              jsr   mult10             ; get tens value
              xgdy                     ; exchange y and d
              addd  digitAmount        ; add digitAmount to d (y)
              xgdy                     ; exchange y and d
              sty   num2
              deca
              cmpa  #$00
              beq   num2Done           ; if no more digits num2 is done
              ldab  1,X-               ; load hundreds digit
              jsr   mult10             
              jsr   mult16b10          ; get hundreds value
              xgdy                     ; exchange y and d
              addd  digitAmount        ; add digitAmount to d (y)
              xgdy                     ; exchange y and d
              sty   num2
              bra   num2Done           ; no more digits num2 is done
              
progBack3     bra   progBack2          ; jump backwarding
invForward3   bra   invForward2        ; jump forwarding              
              
num2Done      ldaa  charOp             ; determine what operation to perform
              cmpa  #$00
              beq   doPlus
              cmpa  #$01
              beq   doMinu
              cmpa  #$02
              beq   doMult
              cmpa  #$03
              beq   doDivi
              
doPlus        ldx   num1               ; do addition
              xgdx                     ; exchange x and d
              addd  num2               ; add num2 to d (x)
              xgdx                     ; exchange x and d
              stx   total              ; store into data
              bra   convertTotal
              
doMinu        ldx   num1               ; do subtraction
              xgdx                     ; exchange x and d
              subd  num2               ; sub num2 from d (x)
              xgdx                     ; exchange x and d
              stx   total              ; store into data
              bra   convertTotal         

doMult        ldx   #num1              ; load pointer to num1
              ldy   #num2              ; load pointer to num2
              emacs total              ; mutliple num1 and num2
              bra   convertTotal       ; store into data

doDivi        ldx   num1               ; load num1
              ldy   #$0000             ; load 0
              xgdx                     ; exchange x and d
              ldx   num2               ; load num2 as divisor
              edivs                    ; divide num1 by num2
              sty   total              ; store into data
              bra   convertTotal       

progBack4     bra   progBack3          ; jump backwarding
invForward2   bra   invForward1        ; jump forwarding

convertTotal  ldy   #termTot           ; load address of total ascii terminator
              sty   tempAddr
convertLoop   ldx   total              ; load total into x
              ldy   #$0000             ; load 0 into y
              xgdx                     ; exchange x and d
              ldx   #$000A             ; load 10 into x
              edivs                    ; divide Y:D by X where y contains solution and d remainder
              sty   total              ; store solution into total
              ldx   tempAddr
              stab  1,-X               ; move place to left and store remainder into total ascii              
              stx   tempAddr
              xgdy                     ; exchange y and d
              psha
              ldaa  totalLen           ; increment length of total
              inca
              staa  totalLen
              pula
              cmpa  #$00               ; check if solution is non-zero
              bne   convertLoop        ; if non-zero repeat process
              cmpb  #$00
              bne   convertLoop
              bra   printSol 
              
progBack5     bra   progBack4          ; jump backwarding
invForward1   bra   inv                ; jump forwarding              
              
printSol      ldx   #msg6              ; print out indent
              jsr   printmsg
              ldx   #num1digits
              ldab  num1Len
print1Loop    ldaa  1,X+               ; print the first number
              jsr   convertnum
              jsr   putchar
              decb
              cmpb  #$00
              bne   print1Loop
              ldaa  operator           ; print the operator
              jsr   putchar
              ldx   #num2digits
              ldab  num2Len
print2Loop    ldaa  1,X+               ; print the second number
              jsr   convertnum
              jsr   putchar
              decb
              cmpb  #$00
              bne   print2Loop
              ldaa  equals             ; print the equals sign
              jsr   putchar
              ldx   #totalDigits
              ldab  totalLen
printTLoop    ldaa  1,X+               ; print the total
              jsr   convertnum
              jsr   putchar
              decb
              cmpb  #$00
              bne   printTLoop
              
              ldaa  #CR                ; cursor return to left
              jsr   putchar
              ldaa  #LF                ; cursor to next line
              jsr   putchar
progBack6     bra   progBack5
                          

inv           jsr   invalid
              ldaa  #$00
              staa  1,Y+
              ldx   #buff
              jsr   printmsg
              ldaa  #CR                ; cursor return to left
              jsr   putchar
              ldaa  #LF                ; cursor to next line
              jsr   putchar
              bra   progBack6

;subroutine section below

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

;***************checknum************************
;* Program: check char is between 0-9
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Data at charAmount holds decimal value of input char
;* Registers modified: B
;**********************************************
checknum      pshb
              
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
              ldab  #$FF               ; if not store invalid num
              bra   checkNumEnd
              
is0           ldab  #$00               ; load correct decimal value into b
              bra   checkNumEnd
is1           ldab  #$01
              bra   checkNumEnd
is2           ldab  #$02
              bra   checkNumEnd                            
is3           ldab  #$03
              bra   checkNumEnd              
is4           ldab  #$04
              bra   checkNumEnd              
is5           ldab  #$05
              bra   checkNumEnd              
is6           ldab  #$06
              bra   checkNumEnd
is7           ldab  #$07
              bra   checkNumEnd              
is8           ldab  #$08
              bra   checkNumEnd
is9           ldab  #$09
              bra   checkNumEnd                            
              
checkNumEnd   stab  charAmount         ; store value into data
              pulb
              rts              
;***************end of checknum*****************

;***************checkop************************
;* Program: check char is +,-,*,/
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Data at charOp holds decimal relating to what op
;* Registers modified: B
;**********************************************
checkop       pshb

              cmpa  #$2B               ; check if char is +,-,*,/
              beq   isPlus
              cmpa  #$2D
              beq   isMinu
              cmpa  #$2A
              beq   isMult
              cmpa  #$2F
              beq   isDivi          
              ldab  #$FF               ; if not store invalid num
              bra   checkOpEnd
              
isPlus        ldab  #$00               ; 0 relates to +
              bra   checkOpEnd
isMinu        ldab  #$01               ; 1 relates to -
              bra   checkOpEnd
isMult        ldab  #$02               ; 2 relates to *
              bra   checkOpEnd                          
isDivi        ldab  #$03               ; 3 relates to /
              bra   checkOpEnd
                            
checkOpEnd    stab  charOp             ; store value into data
              pulb
              rts               
;***************end of checkop*****************

;***************convertnum************************
;* Program: convert 0-9 num to corresponding ascii char
;* Input:   Accumulator A contains a decimal number
;* Output:  Accumulator A contains the corresponding ascii character
;* Registers modified: B
;**********************************************
convertnum    cmpa  #$00               ; check num is between 0-9
              beq   is0d
              cmpa  #$01               
              beq   is1d
              cmpa  #$02               
              beq   is2d
              cmpa  #$03
              beq   is3d
              cmpa  #$04
              beq   is4d
              cmpa  #$05
              beq   is5d
              cmpa  #$06
              beq   is6d
              cmpa  #$07
              beq   is7d
              cmpa  #$08
              beq   is8d
              cmpa  #$09
              beq   is9d
              
is0d          ldaa  #$30               ; load correct ascii char into b
              bra   convertNumEnd
is1d          ldaa  #$31
              bra   convertNumEnd
is2d          ldaa  #$32
              bra   convertNumEnd                            
is3d          ldaa  #$33
              bra   convertNumEnd              
is4d          ldaa  #$34
              bra   convertNumEnd              
is5d          ldaa  #$35
              bra   convertNumEnd              
is6d          ldaa  #$36
              bra   convertNumEnd
is7d          ldaa  #$37
              bra   convertNumEnd              
is8d          ldaa  #$38
              bra   convertNumEnd
is9d          ldaa  #$39
              bra   convertNumEnd                            
              
convertNumEnd rts              
;***************end of convertnum*****************

;***************mult10***************************
;* Program: multiplies 16 bit number by 10
;* Input:   Register b holds decimal value
;* Output:  Data at digitAmount holds 10 * input value
;* Registers modified: D(A,B),X,Y
;************************************************
mult10        pshd
              pshx
              pshy

              ldx   #$0000             ; load input into x
              abx 
              ldy   #$0000             ; load input into y 
              aby
              
              xgdx                     ; exchange x and d        
              asld                     ; multiply d by 8
              asld
              asld      
              xgdx                     ; exchange x and d
              
              xgdy                     ; exchange y and d          
              asld                     ; multiply d by 2  
              xgdy                     ; exchange y and d
              
              sty   tempNum
              
              xgdx                     ; exchange x and d
              addd  tempNum            ; add y to d
              xgdx                     ; exchange x and d
              
              staa  digitAmount        ; store value in data
                      
              puly
              pulx
              puld
              rts         
;***************end of mult10********************

;***************mult16b10***************************
;* Program: multiplies 16 bit number by 10
;* Input:   Data at digitAmount holds input value
;* Output:  Data at digitAmount holds 10 * input value
;* Registers modified: D(A,B),X,Y
;************************************************
mult16b10     pshd
              pshx
              pshy

              ldx   digitAmount        ; load input into x
              ldy   digitAmount        ; load input into y 
              
              xgdx                     ; exchange x and d        
              asld                     ; multiply d by 8
              asld
              asld      
              xgdx                     ; exchange x and d
              
              xgdy                     ; exchange y and d          
              asld                     ; multiply d by 2  
              xgdy                     ; exchange y and d
              
              sty   tempNum
              
              xgdx                     ; exchange x and d
              addd  tempNum            ; add y to d
              xgdx                     ; exchange x and d
              
              staa  digitAmount        ; store value in data
                      
              puly
              pulx
              puld
              rts         
;***************end of mult16b10********************

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

msg3           DC.B    'Ecalc> ', $00
msg4           DC.B    'Error: Invalid command', $0d, $0a, $00
msg5           DC.B    'Ecalc> ', $0d, $0a, $00
msg6           DC.B    '       ', $00


               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled