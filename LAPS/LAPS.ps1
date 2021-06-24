<#
    .DESCRIPTION
    Local Admin Password Rotation and Account Management
    Set configuration values, and follow rollout instructions at https://www.lieben.nu/liebensraum/?p=3605
  
    .NOTES
    filename:       leanLAPS.ps1
    created:        09/06/2021
    last updated:   09/06/2021
#>

####CONFIG
$minimumPasswordLength = 12
$localAdminName = "LSAdmin"
$removeOtherLocalAdmins = $True
$onlyRunOnWindows10 = $True #buildin protection in case an admin accidentally assigns this script to e.g. a domain controller
$markerFile = Join-Path $Env:TEMP -ChildPath "leanLAPS.marker"
$markerFileExists = (Test-Path $markerFile)

function Get-NewPassword($passwordLength){
   -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789'.ToCharArray() | Get-Random -Count $passwordLength)
}

Function Write-CustomEventLog($Message){
    $EventSource=".LiebenConsultancy"
    if ([System.Diagnostics.EventLog]::Exists('Application') -eq $False -or [System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False){
        $res = New-EventLog -LogName Application -Source $EventSource  | Out-Null
    }
    $res = Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 1985 -Message $Message
}

Write-CustomEventLog "LeanLAPS starting on $($ENV:COMPUTERNAME) as $($MyInvocation.MyCommand.Name)"

if($onlyRunOnWindows10 -and [Environment]::OSVersion.Version.Major -ne 10){
    Write-CustomEventLog "Unsupported OS!"
    Write-Error "Unsupported OS!"
    Exit 0
}

$mode = $MyInvocation.MyCommand.Name.Split(".")[0]
$pwdSet = $false

#when in remediation mode, always exit successfully as we remediated during the detection phase
if($mode -ne "detect"){
    Exit 0
}else{
    #check if marker file present, which means we're in the 2nd detection run where nothing should happen except posting the new password to Intune
    if($markerFileExists){
        $pwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((Get-Content $markerFile | ConvertTo-SecureString)))
        Remove-Item -Path $markerFile -Force -Confirm:$False
        Write-Host "LeanLAPS current password: $pwd for $($localAdminName), last changed on $(Get-Date)"
        #ensure the password is removed from Intune log files (which are written after a delay):
        $triggers = @((New-ScheduledTaskTrigger -At (get-date).AddMinutes(2) -Once),(New-ScheduledTaskTrigger -At (get-date).AddMinutes(7) -Once))
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ex bypass -EncodedCommand dAByAHkAewAKACAAIAAgACAAJABpAG4AdAB1AG4AZQBMAG8AZwAxACAAPQAgAEoAbwBpAG4ALQBQAGEAdABoACAAJABFAG4AdgA6AFAAcgBvAGcAcgBhAG0ARABhAHQAYQAgAC0AYwBoAGkAbABkAHAAYQB0AGgAIAAiAE0AaQBjAHIAbwBzAG8AZgB0AFwASQBuAHQAdQBuAGUATQBhAG4AYQBnAGUAbQBlAG4AdABFAHgAdABlAG4AcwBpAG8AbgBcAEwAbwBnAHMAXABBAGcAZQBuAHQARQB4AGUAYwB1AHQAbwByAC4AbABvAGcAIgAKACAAIAAgACAAJABpAG4AdAB1AG4AZQBMAG8AZwAyACAAPQAgAEoAbwBpAG4ALQBQAGEAdABoACAAJABFAG4AdgA6AFAAcgBvAGcAcgBhAG0ARABhAHQAYQAgAC0AYwBoAGkAbABkAHAAYQB0AGgAIAAiAE0AaQBjAHIAbwBzAG8AZgB0AFwASQBuAHQAdQBuAGUATQBhAG4AYQBnAGUAbQBlAG4AdABFAHgAdABlAG4AcwBpAG8AbgBcAEwAbwBnAHMAXABJAG4AdAB1AG4AZQBNAGEAbgBhAGcAZQBtAGUAbgB0AEUAeAB0AGUAbgBzAGkAbwBuAC4AbABvAGcAIgAKACAAIAAgACAAUwBlAHQALQBDAG8AbgB0AGUAbgB0ACAALQBGAG8AcgBjAGUAIAAtAEMAbwBuAGYAaQByAG0AOgAkAEYAYQBsAHMAZQAgAC0AUABhAHQAaAAgACQAaQBuAHQAdQBuAGUATABvAGcAMQAgAC0AVgBhAGwAdQBlACAAKABHAGUAdAAtAEMAbwBuAHQAZQBuAHQAIAAtAFAAYQB0AGgAIAAkAGkAbgB0AHUAbgBlAEwAbwBnADEAIAB8ACAAUwBlAGwAZQBjAHQALQBTAHQAcgBpAG4AZwAgAC0AUABhAHQAdABlAHIAbgAgACIAUABhAHMAcwB3AG8AcgBkACIAIAAtAE4AbwB0AE0AYQB0AGMAaAApAAoAIAAgACAAIABTAGUAdAAtAEMAbwBuAHQAZQBuAHQAIAAtAEYAbwByAGMAZQAgAC0AQwBvAG4AZgBpAHIAbQA6ACQARgBhAGwAcwBlACAALQBQAGEAdABoACAAJABpAG4AdAB1AG4AZQBMAG8AZwAyACAALQBWAGEAbAB1AGUAIAAoAEcAZQB0AC0AQwBvAG4AdABlAG4AdAAgAC0AUABhAHQAaAAgACQAaQBuAHQAdQBuAGUATABvAGcAMgAgAHwAIABTAGUAbABlAGMAdAAtAFMAdAByAGkAbgBnACAALQBQAGEAdAB0AGUAcgBuACAAIgBQAGEAcwBzAHcAbwByAGQAIgAgAC0ATgBvAHQATQBhAHQAYwBoACkACgB9AGMAYQB0AGMAaAB7ACQATgB1AGwAbAB9AAoAdAByAHkAewAKACAAIAAgACAAZgBvAHIAZQBhAGMAaAAoACQAVABlAG4AYQBuAHQAIABpAG4AIAAoAEcAZQB0AC0AQwBoAGkAbABkAEkAdABlAG0AIAAiAEgASwBMAE0AOgBcAFMAbwBmAHQAdwBhAHIAZQBcAE0AaQBjAHIAbwBzAG8AZgB0AFwASQBuAHQAdQBuAGUATQBhAG4AYQBnAGUAbQBlAG4AdABFAHgAdABlAG4AcwBpAG8AbgBcAFMAaQBkAGUAQwBhAHIAUABvAGwAaQBjAGkAZQBzAFwAUwBjAHIAaQBwAHQAcwBcAFIAZQBwAG8AcgB0AHMAIgApACkAewAKACAAIAAgACAAIAAgACAAIABmAG8AcgBlAGEAYwBoACgAJABzAGMAcgBpAHAAdAAgAGkAbgAgACgARwBlAHQALQBDAGgAaQBsAGQASQB0AGUAbQAgACQAVABlAG4AYQBuAHQALgBQAFMAUABhAHQAaAApACkAewAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgACQAagBzAG8AbgAgAD0AIAAoACgARwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACgASgBvAGkAbgAtAFAAYQB0AGgAIAAkAHMAYwByAGkAcAB0AC4AUABTAFAAYQB0AGgAIAAtAEMAaABpAGwAZABQAGEAdABoACAAIgBSAGUAcwB1AGwAdAAiACkAIAAtAE4AYQBtAGUAIAAiAFIAZQBzAHUAbAB0ACIAKQAuAFIAZQBzAHUAbAB0ACAAfAAgAGMAbwBuAHYAZQByAHQAZgByAG8AbQAtAGoAcwBvAG4AKQAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgAGkAZgAoACQAagBzAG8AbgAuAFAAbwBzAHQAUgBlAG0AZQBkAGkAYQB0AGkAbwBuAEQAZQB0AGUAYwB0AFMAYwByAGkAcAB0AE8AdQB0AHAAdQB0AC4AUwB0AGEAcgB0AHMAVwBpAHQAaAAoACIATABlAGEAbgBMAEEAUABTACIAKQApAHsACgAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACQAagBzAG8AbgAuAFAAbwBzAHQAUgBlAG0AZQBkAGkAYQB0AGkAbwBuAEQAZQB0AGUAYwB0AFMAYwByAGkAcAB0AE8AdQB0AHAAdQB0ACAAPQAgACIAUgBFAEQAQQBDAFQARQBEACIACgAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgAFMAZQB0AC0ASQB0AGUAbQBQAHIAbwBwAGUAcgB0AHkAIAAtAFAAYQB0AGgAIAAoAEoAbwBpAG4ALQBQAGEAdABoACAAJABzAGMAcgBpAHAAdAAuAFAAUwBQAGEAdABoACAALQBDAGgAaQBsAGQAUABhAHQAaAAgACIAUgBlAHMAdQBsAHQAIgApACAALQBOAGEAbQBlACAAIgBSAGUAcwB1AGwAdAAiACAALQBWAGEAbAB1AGUAIAAoACQAagBzAG8AbgAgAHwAIABDAG8AbgB2AGUAcgB0AFQAbwAtAEoAcwBvAG4AIAAtAEQAZQBwAHQAaAAgADEAMAAgAC0AQwBvAG0AcAByAGUAcwBzACkAIAAtAEYAbwByAGMAZQAgAC0AQwBvAG4AZgBpAHIAbQA6ACQARgBhAGwAcwBlAAoAIAAgACAAIAAgACAAIAAgACAAIAAgACAAfQAKACAAIAAgACAAIAAgACAAIAB9AAoAIAAgACAAIAB9AAoAfQBjAGEAdABjAGgAewAkAE4AdQBsAGwAfQA="
        $Null = Register-ScheduledTask -TaskName "leanLAPS_WL" -Trigger $triggers -User "SYSTEM" -Action $Action -Force
        Exit 0
    }
}

try{
    $localAdmin = $Null
    $localAdmin = Get-LocalUser -name $localAdminName -ErrorAction Stop
    if(!$localAdmin){Throw}
}catch{
    Write-CustomEventLog "$localAdminName doesn't exist yet, creating..."
    try{
        $newPwd = Get-NewPassword $minimumPasswordLength
        $pwdSet = $True
        $localAdmin = New-LocalUser -PasswordNeverExpires -AccountNeverExpires -Name $localAdminName -Password ($newPwd | ConvertTo-SecureString -AsPlainText -Force)
        Write-CustomEventLog "$localAdminName created"
    }catch{
        Write-CustomEventLog "Something went wrong while provisioning $localAdminName $($_)"
        Write-Host "Something went wrong while provisioning $localAdminName $($_)"
        Exit 0
    }
}

try{
    $administratorsGroupName = (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")).Translate([System.Security.Principal.NTAccount]).Value.Split("\")[1]
    Write-CustomEventLog "local administrators group is called $administratorsGroupName"
    $group = gwmi win32_group -filter "Name = `"$($administratorsGroupName)`""
    $administrators = $group.GetRelated('Win32_UserAccount')
    Write-CustomEventLog "There are $($administrators.count) readable accounts in $administratorsGroupName"

    if($administrators.SID -notcontains $($localAdmin.SID.Value)){
        Write-CustomEventLog "$($localAdmin.Name) is not a local administrator, adding..."
        $res = Add-LocalGroupMember -Group $administratorsGroupName -Member $localAdmin.SID.Value -Confirm:$False -ErrorAction Stop
        Write-CustomEventLog "Added $($localAdmin.Name) to the local administrators group"
    }
    #remove other local admins if specified, only executes if adding the new local admin succeeded
    if($removeOtherLocalAdmins){
        foreach($administrator in $administrators){
            if($administrator.SID -ne $localAdmin.SID.Value){
                Write-CustomEventLog "removeOtherLocalAdmins set to True, removing $($administrator.Name) from Local Administrators"
                $res = Remove-LocalGroupMember -Group $administratorsGroupName -Member $administrator.SID -Confirm:$False
                Write-CustomEventLog "Removed $($administrator.Name) from Local Administrators"
            }
        }
    }
}catch{
    Write-CustomEventLog "Something went wrong while processing the local administrators group $($_)"
    Write-Host "Something went wrong while processing the local administrators group $($_)"
    Exit 0
}

if(!$pwdSet){
    try{
        Write-CustomEventLog "Setting password for $localAdminName ..."
        $newPwd = Get-NewPassword $minimumPasswordLength
        $pwdSet = $True
        $res = $localAdmin | Set-LocalUser -Password ($newPwd | ConvertTo-SecureString -AsPlainText -Force) -Confirm:$False
        Write-CustomEventLog "Password for $localAdminName set to a new value, see MDE"
    }catch{
        Write-CustomEventLog "Failed to set new password for $localAdminName"
        Write-Host "Failed to set password for $localAdminName because of $($_)"
        Exit 0
    }
}

Write-Host "LAPS ran successfully for $($localAdminName)"
$res = Set-Content -Path $markerFile -Value (ConvertFrom-SecureString (ConvertTo-SecureString $newPwd -asplaintext -force)) -Force -Confirm:$False
Exit 1
