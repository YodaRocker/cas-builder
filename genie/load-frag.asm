INPSTR      .equ $0361

load:
    ld      a,CMD_BUFFER_PTR_RESET
    call    sdSendCommand

    ; input filename string to _buffer. assume < 31 chars + terminator
    ld      hl,_buffer
    ld      ($40a7),hl
    call    INPSTR

    ld      hl,_buffer
    ld      bc,$2000+IOP_WRITEDAT
    otir

    ld      a,CMD_FILE_OPEN_READ
    call    sdSendCommand

    ; read loadAddr, length, exec address
    ld      hl,_buffer
    ld      bc,$0600+IOP_READ
    inir

    ld      b,0
    ld      hl,(_loadAddr)

    ld      a,(_loadLength)
    jr      wholeBlocksDoneTest

loadWhole:
    inir

    dec     a

wholeBlocksDoneTest:
    and     a
    jr      nz,loadWhole

    ld      a,(_loadLength+1)
    and     a
    jr      z,executeIt

    ld      b,a
    inir

executeIt:
    ld      hl,_execAddress
    jp      (hl)


_buffer:
_loadAddr:
    .word   0
_loadLength:
    .word   0
_execAddress:
    .word   0
