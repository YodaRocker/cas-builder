set inname=test2
set outname=test.bin

set inc=%~dp0

brass %INNAME%.asm -o %OUTNAME%

casbuilder.exe %OUTNAME% /out=test.cas /load=7d00

pause
