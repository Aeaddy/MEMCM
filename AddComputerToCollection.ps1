[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true,Position=0)]
    [string]$SiteServer,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$CollName
)

$CompName=(Get-WmiObject Win32_ComputerSystem).Name

$Scriptblock = { param($SCompName, $SCollName)

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modpath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modpath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite

Set-Location "$($SiteCode.Name):\"

$CMComputer=(Get-CMDevice -Name $SCompName).ResourceID

Add-CMDeviceCollectionDirectMembershipRule -CollectionName $SCollName -ResourceId $CMComputer

}

$CMSession=New-PSSession -ComputerName $SiteServer

Invoke-Command -Session $CMSession `
               -ScriptBlock $Scriptblock `
               -Args $CompName, $CollName
