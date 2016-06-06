
charout .equ    $33a
ret2bas	.equ	$6cc

    .org    $7f00

	in		a,($76)
	ld		a,42
	ld		e,a
	ld		d,0
	ld		c,d
	ld		b,d
	call	$09b4		; BCDE to ACC

	ld		a,2
	ld		($40af),a	; acc = number
	
	call	$0ab1
	call	$0fbd		; acc to string
	call	$28A7		; print number

    call    str
    .byte   $0d, "GENIUS!"
    .byte   $00

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
