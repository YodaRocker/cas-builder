#include "[%INC%]/def-einsdein.inc"
#include "[%INC%]/commandIDs.h"

CHAROUT .equ    $033a
STRZOUT	.equ	$28a7
RET2BAS	.equ	$06cc
WAITKEY	.equ	$0049

#define DB(x) push af \ ld a,x \ call CHAROUT \ pop af


	.org	$7d00	; 32000


start:
	ld		a,2
	ld		(lineCount),a	; lines on the screen, 2 because of dir root printing

	ld		a,'?'
	call	CHAROUT
	call	WAITKEY
	push	af
	call	CHAROUT
	pop		af
	cp		'R'
	jp		z,read
	cp		'W'
	jp		z,write
	cp		'S'
	jp		z,status
	cp		'C'
	jp		z,command

	in		a,($76)
	call	numOut
	call	newline

	ld		a,CMD_BUFFER_PTR_RESET
	call	sdSendCommand

	; there's no command line, just the terminator
	xor		a
	out		(IOP_WRITEDAT),a

	ld		a,CMD_DIR_READ_BEGIN
	call	sdSendCommand
	call	handleError						; will only return from here if all's well

	; print directory

	in		a,(IOP_READ)					; sink the confusing drive spec '0:'
	in		a,(IOP_READ)

	call	str
	.db		"DIR OF: ", 0

	call	printEntry
	call	newline

	;

nextEntry:
	ld		a,CMD_DIR_READ_NEXT
	call	sdSendCommand
	call	handleError						; will only return from here if all's well

	; there's one in the pipe - is there room to print it tho?

	ld		a,(lineCount)
	cp		15
	jr		nz,theresSpace

	call	str
	.db		"PRESS A KEY", 0

	call	WAITKEY
	cp		'X' ; 27
	jp		z,ret2bas

	xor		a
	ld		(lineCount),a

	; erase the 'press a key' message (11 chars)

	call	str
	.fill	11,8
	.fill	11,' '
	.fill	11,8
	.db		0

theresSpace:
	call	printEntry
	ld		hl,lineCount
	inc		(hl)
	jr		nextEntry

	;
	;
	;

dispStat:
	in		a,(IOP_STATUS)
	push	af
	call	space
	pop		af
	and		7
	add		a,'0'
	jp		CHAROUT

_n:
	.byte	1
	
read:
	call 	dispStat
	in		a,(IOP_READ)
	call	numOut
	jp		status

write:
	call 	dispStat
	ld		hl,_n
	ld		a,(hl)
	inc		(hl)
	out		(IOP_WRITEDAT),a
	call	numOut
	jp		status


command:
	call 	dispStat
	ld		hl,_n
	ld		a,254 ; show bp
	out		(IOP_WRITECMD),a

	; falls through

status:
	call	dispStat
	call	newline
	jp		start

	
	
cmdbittest:
	ld		b,128
	ld		a,CMD_DIR_READ_BEGIN
	out		(IOP_WRITECMD),a
	
cbt_loop:
	in		a,(IOP_STATUS)
	and		4
	add		a,'0'
	call	CHAROUT
	djnz	cbt_loop
	jp		start

	;
	;
	;
	;
	
numOut:
	push	af
	push	hl
	push	bc
	push	de
	
	ld		e,a
	ld		d,0
	ld		c,d
	ld		b,d
	call	$09b4		; BCDE to ACC

	ld		a,2
	ld		($40af),a		; acc contains number type
	
	call	$0fbd		; acc to string
	call	STRZOUT		; print zero terminated string at hl - in this case, the number

	pop		de
	pop		bc
	pop		hl
	pop		af
	ret


	
; print an inline zero terminated string.

str:
    pop     hl

str_loop:
    ld      a,(hl)
	inc		hl
	or      a
    jr		nz,str_printit

	push	hl
	ret

str_printit:	
    call	charout
	jr		str_loop


; send a command in A, return with Z set = success, else error in A
;
sdSendCommand:
	out		(IOP_WRITECMD),a           ; send command

_busy:
	in		a,(IOP_STATUS)             ; wait for interface to become ... not busy
	and		$4
	jr		nz,_busy

	in		a,(IOP_READ)               ; read command status
	and		a                          ; clear carry, set flags for immediate test on return
	ret


; ensure we return to 0
;
handleError:
	and		a
	ret		z

	and		$3f
	ret		z

	call	numOut
	call	newline
	jp		RET2BAS				; return if error or done


; pull an ASCIIZ directory entry from the einSDein
;	
printEntry:
	ld		bc,$2072				; grab $20 characters from input port $72
	ld		hl,buffer
	inir

	ld		hl,buffer
	call	STRZOUT

	; falls through to newline

newline:
	ld		a,$d
	jp		CHAROUT

space:
	ld		a,' '
	jp		CHAROUT



lineCount:
	.byte		2							; accounts for the 'directory of ..' lines

buffer:

	.end
