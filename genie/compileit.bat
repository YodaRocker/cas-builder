set inname=test2
set outname=test@7d00!7d00.bin

set inc=%~dp0

brass %INNAME%.asm -o %OUTNAME%

casbuilder.exe %OUTNAME%
pause
