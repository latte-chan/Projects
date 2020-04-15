***********************************************************************
* Title: StarFill (in Memory lane)
* Objective: CSE472 Homework 1 in-class-room demonstration program
* Revision: V2.1                                       
* Date: Jan 14 2019
* Programmer: Aidan Jones
* Company: Penn State University Computer Science
* Algorithm: Simple While loop demo of HCS12 assembly program
* Register Use: A accumulator: char data to be filled
*               B accumulator: counter, number of filled positions
*               X register: memory address pointer
* Memory use: RAM locations from $3000 to $3009
* Input: Parameters hard coded in program
* Output: Data filled in memory locations form $3000 to $3009
* Observation: This program is designed for instruction purpose.
* This program can be used as a "loop" template
* Note: This is a good example of program comments
* All Homework programs must have comments similar
* to this Homework 1 program. So, please use this
* comment format for all subsequent homework programs
* Adding more explanations and comments help you and others
* to understand your program later.
* Comments: This program is developed and simulated using
* CopdeWarrior development software.
***********************************************************************
* Parameter Declearation Section
* Export Symbols
        XDEF       pgstart ; export 'pgstart' symbol
        ABSENTRY   pgstart ; for assembly entry point
* Symbols and Macros
PORTA   EQU    $0000       ; i/o port addresses
PORTB   EQU    $0001
DDRA    EQU    $0002
DDRB    EQU    $0003
*
***********************************************************************
* Data Section
        ORG     $3000      ; reserved memory starting address
here    DS.B    $12        ; 18 memory locations reserved
count   DC.B    $12        ; constant, star count = 18
*
***********************************************************************
* Program Section
        ORG     $3100      ; Program start address, in RAM
pgstart ldaa    #'*'       ; load '*' into accumulator A
        ldab    count      ; load star counter into B
        ldx     #here      ; load address pointer into X
loop    staa    0,x        ; put a star
        inx                ; point to next location
        decb               ; decrease counter
        bne     loop       ; if not done, repeat
done    bra     done       ; task finished,
                           ; do nothing
* Add any subroutines here
        END                ; last line of a file


