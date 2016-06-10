set inc=%~dp0..\..\geniestein\
set root=%~dpn1

echo %root%
echo.
brass %1 -o "%root%.bin" -l "%root%.html"

pause
