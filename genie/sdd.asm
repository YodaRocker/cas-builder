#include "[%INC%]einsdein.inc"
#include "[%INC%]commandIDs.h"

CHAROUT 	.equ $033a
STRZOUT		.equ $28a7
RET2BAS		.equ $06cc
WAITKEY		.equ $0049
INPSTR      .equ $0361

#define DBp(x) push af \ ld a,x \ call CHAROUT \ pop af
#define DB(x) ld a,x \ call CHAROUT

	.org	$7e80

	DB('>')
	in		a,(IOP_DETECT)
	call	numOut
	call	newline

	DB('V')
	in		a,(IOP_VERSION)
	call	numOut
	call	newline

start:
    ld      a,CMD_BUFFER_PTR_RESET
    call    sdSendCommand

	call	str
	.db		$0d, "L/D {PATH}? ", 0

    ; input filename string to _buffer. assume < 31 chars + terminator. [L/D][ ][PATH][\0]
    ld      hl,_buffer
    ld      ($40a7),hl
    call    INPSTR

	; find first non-space character in string then send to einSDein
	rst		10h
	ld		bc,$2000+IOP_WRITEDAT
	otir

	ld		a,(_buffer)
	cp		'L'
	jp		z,LOAD
	cp		'D'
	jr		nz,start

DIR:
	ld		a,CMD_DIR_READ_BEGIN
	call	sdSendCommand
	call	handleError

	; sink the confusing drive spec '0:'
	in		a,(IOP_READ)
	in		a,(IOP_READ)

	call	str
	.db		"DIR OF: ", 0

	call	printEntry
	call	newline

	ld		a,2
	ld		(lineCount),a	; #lines of listing already on the screen

nextEntry:
	ld		a,CMD_DIR_READ_NEXT
	call	sdSendCommand
	call	handleError

	; there's one in the pipe - is there room to print it tho?
	ld		a,(lineCount)
	cp		15
	jr		nz,theresSpace

	call	str
	.db		"PRESS A KEY", 0

	; escape key will return us to BASIC at this point
	call	WAITKEY
	cp		27
	jp		z,ret2bas

	xor		a
	ld		(lineCount),a

	; erase the 'press a key' message (11 chars) using 11 backspaces, 11 spaces then another 11 backspaces
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


; pull an ASCIIZ directory entry from the einSDein and print it
printEntry:
	; grab $20 characters from input port $72
	ld		bc,$2072
	ld		hl,_buffer
	push	hl
	inir
	pop		hl
	call	STRZOUT
	; falls through to newline

newline:
	ld		a,$d
	jp		CHAROUT

	;
	;

LOAD:
    ld      a,CMD_FILE_OPEN_READ
    call    sdSendCommand

    ; read loadAddr, length, exec address
    ld      hl,_buffer
    ld      bc,$0600+IOP_READ
    inir

    ld      b,0
    ld      hl,(_loadAddress)
    ld      ix,_loadLength
    jr      wholeBlocksDoneTest

loadWhole:
	ld		a,CMD_FILE_READ_256
	call	sdSendCommand
	call	handleError

    inir
	dec		(ix+1)

wholeBlocksDoneTest:
	ld		a,(ix+1)
    and     a
    jr      nz,loadWhole

    ld      a,(ix)
    and     a
    jr      z,executeIt

    ld      b,a
    inir

executeIt:
    ld      hl,(_execAddress)
	push	hl
	ret


	; -------------------------UTILS------------------------------


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


; returns if a = 0 (no error) else return to BASIC. print error number if a != 0x40 (done)
;
handleError:
	and		a
	ret		z
	cp		$40
	jr		z,he_done

	push	af
	call	str
	.byte	"ERROR ",0
	pop		af
	call	numOut
	call	newline

he_done:	
	jp		RET2BAS				; return if error or done


; print the number in a as decimal
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
	ld		($40af),a	; flag indicating acc contains number type
	
	call	$0fbd		; acc to string
	call	STRZOUT		; print zero terminated string at hl - in this case, the number

	pop		de
	pop		bc
	pop		hl
	pop		af
	ret


; print an inline zero terminated string.
;
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


; print a space
;
space:
	ld		a,' '
	jp		CHAROUT


lineCount:
	.byte		0

_buffer:
_loadAddress	.equ _buffer
_loadLength		.equ _buffer+2
_execAddress	.equ _buffer+4

	.end
