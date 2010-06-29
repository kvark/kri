@echo off
set NETVER=v3.5
c:\windows\microsoft.net\framework\%NETVER%\MSBuild demo\code\kri.sln /p:BoocVerbosity=Info /p:BooBinPath="c:\svn\sharpdev\AddIns\AddIns\BackendBindings\BooBinding
pause