charout .equ    $33a
ret2bas	.equ	$6cc

    .org    $7f00

	push	hl
	push	af
	
    call    str
    .byte   "GENIUS!"
    .byte   0

	pop		af
	pop		hl
    jp		ret2bas


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
