[CmdletBinding()]
Param (
  [Parameter(Mandatory=$True,Position=0)]
  [string]$CMSiteServer
)

$SUPOINT = "$env:COMPUTERNAME.its.lab"

$ScriptBlock = { param($SSUPOINT)

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1" 
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"

#Install Site System Server
#New-CMSiteSystemServer -ServerName $SSUPOINT -SiteCode $SiteCode
 
#Install Software Update Point Role
Add-CMSoftwareUpdatePoint -SiteCode $SiteCode -SiteSystemServerName $SSUPOINT -ClientConnectionType Intranet -WsusIisPort "8530" -WsusIisSslPort "8531"

}

#End of declarations

#Connect to CM Primary Site Server
$CMSESSION=New-PSSession -ComputerName $CMSiteServer


#Execute commands on remote server 
invoke-command  -Session $CMSESSION `
                -ScriptBlock $Scriptblock `
                -Args $SUPOINT

 
