[CmdletBinding()]
Param (
  [Parameter(Mandatory=$True,Position=0)]
  [string]$DISTPOINT
)


$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1" 
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"
#$DISTPOINT = "cmss1.its.lab"
$CERTTIME = "December 31, 2025 10:10:00 PM"

#Install Site System Server
New-CMSiteSystemServer -ServerName $DISTPOINT -SiteCode $SiteCode
 
#Install Distribution Point Role
Add-CMDistributionPoint -CertificateExpirationTimeUtc $CERTTIME -SiteCode $SiteCode -SiteSystemServerName $DISTPOINT -MinimumFreeSpaceMB 10240 -ClientConnectionType 'Intranet' -PrimaryContentLibraryLocation Automatic -PrimaryPackageShareLocation Automatic -SecondaryContentLibraryLocation Automatic -SecondaryPackageShareLocation Automatic
 
#Enable PXE, Unknown Computer Support, Client Communication Method
Set-CMDistributionPoint -SiteSystemServerName $DISTPOINT -SiteCode $SiteCode -EnablePxe $true -EnableUnknownComputerSupport $true -AllowPxeResponse $true