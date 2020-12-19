[CmdletBinding()]
Param (
  [Parameter(Mandatory=$True,Position=0)]
  [string]$CMSiteServer
)

$MPOINT = "$env:COMPUTERNAME.its.lab"

$ScriptBlock = { param($SMPOINT)

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1" 
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"

#Install Site System Server
#New-CMSiteSystemServer -ServerName $SMPOINT -SiteCode $SiteCode
 
#Install Management Point Role
Add-CMManagementPoint  -SiteCode $SiteCode -SiteSystemServerName $SMPOINT -ClientConnectionType Intranet

}

#End of declarations

#Connect to CM Primary Site Server
$CMSESSION=New-PSSession -ComputerName $CMSiteServer


#Execute commands on remote server 
invoke-command  -Session $CMSESSION `
                -ScriptBlock $Scriptblock `
                -Args $MPOINT
