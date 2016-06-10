#include "[%INC%]einsdein.inc"
#include "[%INC%]commandIDs.h"

CHAROUT 	.equ $033a
STRZOUT		.equ $28a7
RET2BAS		.equ $06cc
WAITKEY		.equ $0049
INPSTR      .equ $0361

	.org	$7e80

    ld      a,CMD_BUFFER_PTR_RESET
	out		(IOP_WRITECMD),a

    ; input filename string to _buffer. assume < 32 chars, incl. terminator. [L/D][ ][PATH][\0]
    ld      hl,_buffer
    call    INPSTR

	rst		10h
	ld		bc,$2000+IOP_WRITEDAT
	otir

    ld      a,CMD_FILE_OPEN_READ_GENIE
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

    inir
    dec     (ix)

wholeBlocksDoneTest:
	ld		a,(ix)
    and     a
    jr      nz,loadWhole

    ld      a,(_loadLength+1)
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


_buffer:
_loadAddress	.equ _buffer
_loadLength		.equ _buffer+2
_execAddress	.equ _buffer+4

	.end
