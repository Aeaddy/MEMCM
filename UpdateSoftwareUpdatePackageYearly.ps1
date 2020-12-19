#These can be modified
#Set package name
$NEWPKG = "Test Software Updates " + $THISYEAR
#Set pathnames
$PKGPATH = "\\" + $PSERVER + "\sources\Software Updates\test\" + $THISYEAR 
$LOCALPKGPATH = "D:\sources\Software Updates\test\" + $THISYEAR

#--------------------------------------------------------------------------------------------------

#Do Not modify
#Connect to CM env
$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modpath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modpath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"
#Get Server Name
$PSERVER=(Get-WmiObject -Class Win32_ComputerSystem).Name 
#Get year
$THISYEAR = (Get-Date).Year
#Check for existing Package
$DPKGCOUNT=(Get-CMSoftwareUpdateDeploymentPackage -name $NEWPKG).count

#--------------------------------------------------------------------------------------------------

#Test for package path existence
If (Test-Path $LOCALPKGPATH){
Write-Output "This directory already exists."
}ELSE{
#create directory locally
New-Item $LOCALPKGPATH -ItemType directory
}

#--------------------------------------------------------------------------------------------------

#Test for package existence
If ($DPKGCOUNT -eq 1){
Write-Output "This package already exists."
}ELSE{
#create package
New-CMSoftwareUpdateDeploymentPackage -Name $NEWPKG -Path $PKGPATH
#distribute package
Start-CMContentDistribution -DistributionPointGroupName "Campus" -DeploymentPackageName $NEWPKG
}
