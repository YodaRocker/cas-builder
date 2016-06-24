setlocal

set props=/property:Configuration=Release

set msbindir=C:\Program Files (x86)\MSBuild\14.0\Bin\

"%msbindir%MSBuild.exe" %props% "%~dp0casbuilder.sln"
