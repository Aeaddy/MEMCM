#Import the ConfigMgr PowerShell module & witch to ConfigMgr
$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"


$CSVFile = "C:\test.csv"
Import-CSV $CSVFile -Header Name,Group,Server | Foreach-Object {

  New-CMBoundaryGroup -Name $_.Group
  Add-CMBoundaryToGroup -BoundaryName $_.Name -BoundaryGroupName $_.Group
  Set-CMDistributionPoint -sitecode HEN -SiteSystemServerName $_.Server -AddBoundaryGroupName $_.Group
   }


# This is the format the the CSV file needs to be in.
# Boundary1,Group1,cm1.its.lab
