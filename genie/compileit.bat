set inname=sdd
set outname=sdd.bin

set inc=%~dp0

brass %INNAME%.asm -o %OUTNAME% -l %INNAME%.html

casbuilder.exe %OUTNAME% /out=sdd.cas /load=7e80

pause
