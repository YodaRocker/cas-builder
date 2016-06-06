;----------------------------------------------------------------------------------------------------------
; einSDein IO port addresses

#define IOP_READ $72
#define IOP_WRITECMD $70
#define IOP_WRITEDAT $71
#define IOP_STATUS $74

; input from this port always returns 42
#define IOP_DETECT $76


#define SD_COMMAND $E0
#define SD_SEND_DATA $E1
#define SD_RECV_DATA $E2
#define SD_SEND_DATA_EXEC_CMD $E3
#define SD_EXEC_CMD_RECV_DATA $E4
#define SD_LOAD_DOS_COLD $E5
#define SD_LOAD_DOS_WARM $E6
#define SD_LOAD_FILE $E8
#define SD_SAVE_FILE $E9

#define SD_GET_VERSION $EF
