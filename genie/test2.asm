#include "[%INC%]/def-einsdein.inc"
#include "[%INC%]/commandIDs.h"

CHAROUT .equ    $033a
RET2BAS	.equ	$06cc
WAITKEY	.equ	$0049

#define DB(x) push af \ ld a,x \ call CHAROUT \ pop af


	.org	$7d00	; 32000

	
	ld		a,2
	ld		(lineCount),a

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


; print an inline zero terminated string
	
str:
    pop     hl

str_1:
    ld      a,(hl)
	inc		hl
	or      a
    jr		nz,str_2

	push	hl
	ret

str_2:	
    call	charout
	jr		str_1


; send a command in A
; returns with C set if failed
; else A contains result code
;
sdSendCommand:
   out   (IOP_WRITECMD),a           ; send command

_busy:
   in    a,(IOP_STATUS)             ; wait for interface to become ... not busy
   and   $4
   jr    nz,_busy

   in    a,(IOP_READ)               ; read command status
   and   a                          ; clear carry, set flags for immediate test on return
   ret


; ensure we return to 0
;
handleError:
	and		a								; no error, return to caller
	jp		nz,RET2BAS
	ret


; pull an ASCIIZ directory entry from the einSDein
;	
printEntry:
	in		a,(IOP_READ)					; collect the next character
	and		a
	jp		z,newline						; OK/ok - return

	call	CHAROUT
	jr		printEntry


; jus' print a newline
newline:
	ld		a,$d
	jp		CHAROUT


lineCount:
	.byte		2							; accounts for the 'directory of ..' lines


	.end
