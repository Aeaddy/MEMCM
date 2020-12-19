<#
Script: AddServerToBoundaryGroups.ps1
Author: Adam Eaddy
Date: 12/19/2018
Purpose: This script will cycle through the Boundary Groups and set the provided site server for the entire provided region.
Usage Examples:
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateSet('AMER','EMEA','APAC')]
    [string]$REGION,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$SERVER,

    [Parameter(Mandatory=$false,Position=2)]
    [string]$LOGPATH = "$env:SystemRoot\temp"
)

$DateStr = get-date -Format "yyyyMMdd"
$FullDate = Get-Date
$LOGFILE = "$DateStr-$SERVER.log"
$LOGLOCATION = "$LOGPATH\$LOGFILE"

 "-"*80 | Write-Output | out-file $LOGLOCATION -Append
Write-Output $FullDate | out-file $LOGLOCATION -Append
"$env:userdomain\$env:username" | out-file $LOGLOCATION -append
Write-Output $FullDate
Write-Output "$SERVER is being added to the $REGION boundary groups." | out-file $LOGLOCATION -Append
Write-Output "$SERVER is being added to the $REGION boundary groups." 

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1" 
$SiteCode = Get-PSDrive -PSProvider CMSite

$OLDLOCATION = Get-Location | select -ExpandProperty Path
Set-Location "$($SiteCode.Name):\"

$VALIDSITESERVER = Get-CMSiteSystemServer -SiteSystemServerName $SERVER
$SERVERCOUNT = $VALIDSITESERVER.Count

IF ($SERVERCOUNT -eq 1) {

    $BG = Get-CMBoundaryGroup

    foreach ($BOUNDARY in $BG) {
        $BDESC = $BOUNDARY.description
        IF ($BDESC -like $REGION){
            $BOUNDNAME = $BOUNDARY.Name

            $WMISERVERLIST = Get-WmiObject -Namespace root\sms\site_$SiteCode -Class SMS_BoundaryGroupSiteSystems | where {$_.groupid -eq $BOUNDARY.GroupID} | select -ExpandProperty servernalpath
            $SERVERNAMES = @()
                foreach ($WMISERVER in $WMISERVERLIST){
                $TEST = $WMISERVER.Split('\')[2]
                $SERVERNAMES += $TEST
                }

            $VALUE = $SERVER -match ($SERVERNAMES -join '|' )
        
            IF ($VALUE -eq $false){

                Set-CMBoundaryGroup -Name $BOUNDARY.Name -AddSiteSystemServerName $SERVER -Verbose

                Write-Output "$SERVER was successfully added to the $REGION boundary group $BOUNDNAME." | out-file $LOGLOCATION -Append
                Write-Output "$SERVER was successfully added to the $REGION boundary group $BOUNDNAME."

            }ELSE{

                Write-Output "$SERVER already existed in the $REGION boundary group $BOUNDNAME." | out-file $LOGLOCATION -Append
                Write-Output "$SERVER already existed in the $REGION boundary group $BOUNDNAME."
         
            }   
        }
    }

}ELSE{

Write-Output "$SERVER is not a valid Site System Server in Configuration Manager.  Please provide a valid Site System Server Name." | out-file $LOGLOCATION -Append
Write-Output "$SERVER is not a valid Site System Server in Configuration Manager.  Please provide a valid Site System Server Name."
}

notepad $LOGLOCATION
Set-Location $OLDLOCATION