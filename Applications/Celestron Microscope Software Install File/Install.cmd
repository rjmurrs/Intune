@ECHO OFF
SET ThisScriptsDirectory=%~dp0
SET PowerShellScriptPath=%ThisScriptsDirectory%PSscript.ps1
Powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%PowerShellScriptPath%'"