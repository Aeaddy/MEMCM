<#This script requires a text file name and path to be provided as a required parameter.  
Example: .\GetCollectionsWithIncrementalUpdatesEnabled.ps1 -FileNameAndPath D:\collections.txt
This script requires the Configuration Manger console to be present.
This script will create a document that will providea  count of how many collections have the "Incremental Update" feature enabled.  The script will also display a list of the colelction names.
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true,Position=0)]
    [string]$FileNameAndPath
)


Function Get-IncrementalUpdates
{
#Connect to CfgMgr site
$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modpath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modpath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"


# list all collections that have RefreshType set to 4 or 6
$devcollnames  = Get-CMDeviceCollection | Select-Object Name, RefreshType | Where-Object {$_.RefreshType -eq 4 -or $_.RefreshType -eq 6} | Format-Table -AutoSize
$devcollcount  = Get-CMDeviceCollection | Select-Object Name, RefreshType | Where-Object {$_.RefreshType -eq 4 -or $_.RefreshType -eq 6} | measure
write-output  "Total Device Collections with incremental updates enabled " $devcollcount.count
 
 
# list all collections that have RefreshType set to 4 or 6
$usercollnames  = Get-CMUserCollection | Select-Object Name, RefreshType | Where-Object {$_.RefreshType -eq 4 -or $_.RefreshType -eq 6} | Format-Table -AutoSize
$usercollcount  = Get-CMUserCollection | Select-Object Name, RefreshType | Where-Object {$_.RefreshType -eq 4 -or $_.RefreshType -eq 6} | measure
write-output  "Total User Collections with incremental updates enabled " $usercollcount.count
$devcollnames

$usercollnames
}

#Run function and output to file
$LOADFUNCTION=Get-IncrementalUpdates
$LOADFUNCTION | Out-File $FileNameAndPath