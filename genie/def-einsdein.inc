;----------------------------------------------------------------------------------------------------------
; einSDein IO port addresses

#define IOP_WRITECMD $70
#define IOP_WRITEDAT $71
#define IOP_READ $72
#define IOP_STATUS $74

; input from this port always returns 42
#define IOP_DETECT $76

; input from this port returns bitfile id
#define IOP_VERSION $77
