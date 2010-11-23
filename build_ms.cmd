@echo off
set NETVER=v3.5
c:\windows\microsoft.net\framework\%NETVER%\MSBuild demo\test\code\kri.sln /p:BoocVerbosity=Info /p:BooBinPath="c:\Code\my\boo\build"
pause