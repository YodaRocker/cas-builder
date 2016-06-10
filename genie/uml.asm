#include "[%INC%]einsdein.inc"
#include "[%INC%]commandIDs.h"

CHAROUT 	.equ $033a
STRZOUT		.equ $28a7
RET2BAS		.equ $06cc
WAITKEY		.equ $0049
INPSTR      .equ $0361
GOSYS		.equ $02b5

	.org	$4400

    ld      a,CMD_BUFFER_PTR_RESET
	out		(IOP_WRITECMD),a

    ; input filename string. assume < 32 chars, incl. terminator. [PATH][\0]
    ld      hl,_buffer
    call    INPSTR

	; find first non-space character then upload to interface as filename
	rst		10h
	ld		bc,$2000+IOP_WRITEDAT
	otir

	; opens .GNE file, leaves 3 words in xfer buffer: LOAD, LEN and EXEC
    ld      a,CMD_FILE_OPEN_READ
    call    sdSendCommand
	jp		nz,GOSYS

    ld      hl,_buffer
    ld      bc,$0600+IOP_READ
    inir

    ld      b,0							; 256 byte xfers
    ld      hl,(_loadAddress)
    ld      ix,_loadLength
    jr      wholeBlocksDoneTest

loadWhole:
	ld		a,CMD_FILE_READ_256
	call	sdSendCommand
	jp		nz,GOSYS

    inir
    dec     (ix+1)

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

_buffer:
_loadAddress	.equ _buffer
_loadLength		.equ _buffer+2
_execAddress	.equ _buffer+4

	.end
