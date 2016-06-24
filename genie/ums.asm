#include "[%INC%]einsdein.inc"
#include "[%INC%]commandIDs.h"

CHAROUT 	.equ $033a
STRZOUT		.equ $28a7
RET2BAS		.equ $06cc
WAITKEY		.equ $0049
INPSTR      .equ $0361
GOSYS		.equ $02b5
RESET       .equ 0

	.org	$41e2

    jp      start
    nop
    nop

start:
    ld      a,CMD_BUFFER_PTR_RESET
	out		(IOP_WRITECMD),a

    ld      a,'>'
    call    CHAROUT

    ; input filename string. assume < 32 chars, incl. terminator. [PATH][\0]
    ld      hl,_ctlblock+6
    ld      ($40a7),hl
    call    INPSTR
	rst		10h
	ld		bc,$2000+IOP_WRITEDAT
	otir

	; opens .GNE file, leaves 3 words in xfer buffer: LOAD, LEN and EXEC
    ld      a,CMD_FILE_OPEN_READ
    call    sdSendCommand

    ld      hl,_ctlblock
    ld      bc,$0600+IOP_READ
    inir

    ld      ix,_loadLength
    ld      hl,(_loadAddress)
    jr      wholeBlocksDoneTest

loadWhole:
	ld		a,CMD_FILE_READ_256
	call	sdSendCommand

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
    jp      (hl)

    nop

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
	jp      nz,RESET
    ret

_ctlblock:
_loadAddress	.equ _ctlblock
_loadLength	    .equ _ctlblock+2
_execAddress	.equ _ctlblock+4
_inputbuf       .equ _ctlblock+6
	.end
