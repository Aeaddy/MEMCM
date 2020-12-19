

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modpath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modpath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"

#Get TS
(Get-CMTaskSequence).name
$DFW7TS = (Get-CMTaskSequence -name "DF Workstations - Windows 7")

#Get DP
$DP=(Get-CMDistributionPoint -SiteSystemServerName "\\W0982DAPPV0603.dus.meijer.com")

# Build Offline Media
New-CMStandaloneMedia -TaskSequence $DFW7TS -DistributionPoint $DP -MediaType CdDvd -Path "D:\Sources\Exports\Offline\offline.iso"