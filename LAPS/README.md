## Quick Overview

This is a tempremental solution to managing devices' local administrator passwords in Microsoft Intune. 

## Instructions

* Go to [Microsoft Endpoint Manager](https://endpoint.microsoft.com)
* Navigate to All Services --> Reports --> Endpoint Analytics --> [Proactive remediations](https://endpoint.microsoft.com/#blade/Microsoft_Intune_Enrollment/UXAnalyticsMenu/proactiveRemediations)--> Create Script Package
* Fill out the Basics tab
* Download and configure [LAPS.ps1](https://github.com/rjmurrs/Intune/blob/main/LAPS/LAPS.ps1) | **Use an editor that keeps the file UTF-8 encoded without a BOM**
* Set both the detection and remediation script to LAPS.ps1 and run it in **64 bit**
*  Assign to a device group (user groups won’t work) and deploy. By default it will run every day, but you can also let it run more or less frequently, which determines how often the password is reset 
*  Deploy and then click on the scrpt package
*  Go to device status and add both output column to view the new local administrator password 

## Notes
* If you wish to trigger a quick remediation, delete the correct keys under ``Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies\Scripts\Execution and Reports`` in the client’s registry, then restart the IntuneManagementExtension service and the remediation will re-run within 5 minutes.
* Do not be worried by “with issues” when deploying because that is a good thing in this case. The issues are caused by the script which triggers remediation that outputs the password. 

## Source(s)
https://www.lieben.nu/liebensraum/2021/06/lightweight-laps-solution-for-intune-mde/ 
