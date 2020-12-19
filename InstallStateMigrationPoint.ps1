[CmdletBinding()]
Param (
  [Parameter(Mandatory=$True,Position=0)]
  [string]$CMSiteServer
)

$SMPOINT = "$env:COMPUTERNAME.its.lab"

$ScriptBlock = { param($SSMPOINT)

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1" 
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"
$STORAGEDIR = New-CMStorageFolder -StorageFolderName "D:\SMP" -MaximumClientNumber 100 -MinimumFreeSpace 10240 -SpaceUnit Megabyte
 
#Install State Migration Point Role
Add-CMStateMigrationPoint -SiteSystemServerName $SSMPOINT -SiteCode $SiteCode -TimeDeleteAfter "3" -TimeUnit Days -StorageFolder $STORAGEDIR -EnableRestoreOnlyMode $False -AllowFallbackSourceLocationForContent $False

}

#End of declarations

#Connect to CM Primary Site Server
$CMSESSION=New-PSSession -ComputerName $CMSiteServer


#Execute commands on remote server 
invoke-command  -Session $CMSESSION `
                -ScriptBlock $Scriptblock `
                -Args $SMPOINT

 
