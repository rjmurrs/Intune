$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Source = “$PSScriptRoot\installcelestronmicroscopeimager.iss”
$Destination = “C:\INTUNETEMP”

Copy-Item -Path $Source -Destination $Destination –Recurse -Force