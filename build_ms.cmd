@echo off
set NETVER=v3.5
c:\windows\microsoft.net\framework\%NETVER%\MSBuild demo\kri.sln /p:BoocVerbosity=Info /p:BooBinPath="c:\Program Files\SharpDevelop\3.0\AddIns\AddIns\BackendBindings\BooBinding
pause