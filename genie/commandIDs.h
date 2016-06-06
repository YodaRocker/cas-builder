;// shared with the transient programs

#define CMD_INTERFACE_DETECT 7
#define CMD_INTERFACE_STATUS 8
#define CMD_INTERFACE_GETBOOTCODE 9
#define CMD_INTERFACE_GETDOS 10
#define CMD_INTERFACE_GETVSN 11

#define CMD_BUFFER_PTR_RESET 16
#define CMD_BUFFER_FLUSH 17
#define CMD_BUFFER_READ 18
#define CMD_BUFFER_CVT_FCB 19

#define CMD_DIR_READ_BEGIN 32
#define CMD_DIR_READ_NEXT 33
#define CMD_DIR_MKDIR 34
#define CMD_DIR_CHDIR 35
#define CMD_DIR_GETCWD 36

#define CMD_FILE_OPEN_READ 48
#define CMD_FILE_OPEN_WRITE 49
#define CMD_FILE_SEEK 50
#define CMD_FILE_READ_512 51
#define CMD_FILE_READ_128 52
#define CMD_FILE_WRITE 53
#define CMD_FILE_CLOSE 54
#define CMD_FILE_RENAME 55
#define CMD_FILE_DELETE 56
#define CMD_FILE_COPY 57

#define CMD_DIMG_OPEN_IMAGE 64
#define CMD_DIMG_SET_LOG_SECT 65
#define CMD_DIMG_READ_128 66
#define CMD_DIMG_WRITE_128 67
#define CMD_DIMG_READ_512 68
#define CMD_DIMG_WRITE_512 69
#define CMD_DIMG_CREATE 70

#define CMD_DBG_HUSH 244
#define CMD_DBG_REGS 245
#define CMD_DBG_DCHAR 246
#define CMD_DBG_PROGRAM_CPLD 247
#define CMD_DBG_LED 248
#define CMD_DBG_STAR 249
#define CMD_DBG_HEX8 250
#define CMD_DBG_HEX16 251
#define CMD_DBG_HEXDUMP 252
#define CMD_DBG_MCAL_REPORT 253
#define CMD_DBG_SHOW_BP 254
