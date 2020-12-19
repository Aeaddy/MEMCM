[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true,Position=0)]
    [string]$SiteServer,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$CollectionID
)

$Scriptblock = { param($SSiteServer, $SCollectionID)

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modpath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modpath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite

Invoke-WmiMethod `
-Path "Root\SMS\Site_$($SiteCode):SMS_Collection.CollectionId='$SCollectionID'" `
-Name RequestRefresh -ComputerName $SSiteServer
}

$CMSession=New-PSSession -ComputerName $SiteServer

Invoke-Command -Session $CMSession `
               -ScriptBlock $Scriptblock `
               -Args $SiteServer, $CollectionID