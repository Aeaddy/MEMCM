[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true,Position=0)]
    [string]$SUPKGNAME,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$SUPPATHNAME
)

#$SUPKGNAME="Test Software Updates"
#$SUPPATHNAME = "\\w0982dappv0601\sources\Software Updates\test"

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modpath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modpath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite

$LOGFILE = $env:SMS_LOG_PATH + "\ModifyADR.log"
if ( ! (Test-Path $LOGFILE)){
New-Item -ItemType File $LOGFILE
}ELSE{
date | Out-File $LOGFILE -Append
Write-Output "Starting new session.  The log file $LOGFILE already exists." | Out-File $LOGFILE -Append
}

#Get Server Name
$PSERVER=(Get-WmiObject -Class Win32_ComputerSystem).Name 

#Get years
$YEARLESS1=(Get-Date).AddYears(-1)
$LASTYEAR=($YEARLESS1).Year
$THISYEAR = (Get-Date).Year

#Set package name
$OLDPKG = $SUPKGNAME + " " + $LASTYEAR
$NEWPKG = $SUPKGNAME + " " + $THISYEAR

#Set pathname
$PKGPATH = $SUPPATHNAME + "\" + $THISYEAR 

#Set CM PS env
Set-Location "$($SiteCode.Name):\"

#Check for existence of package path about to be created
Set-Location $env:TEMP
If (Test-Path $PKGPATH){
date | Out-File $LOGFILE -Append
Write-Output "This directory already exists." | Out-File $LOGFILE -Append
}ELSE{
#create 
date | Out-File $LOGFILE -Append
New-Item $PKGPATH -ItemType directory | Out-File $LOGFILE -Append
}

#Get CM PS env
Set-Location "$($SiteCode.Name):\"

#Check for existence of package about to be created
$DPKGCOUNT=(Get-CMSoftwareUpdateDeploymentPackage -name $NEWPKG).count
If ($DPKGCOUNT -eq 1){
date | Out-File $LOGFILE -Append
Write-Output "This package already exists." | Out-File $LOGFILE -Append
}ELSE{

#Create package
date | Out-File $LOGFILE -Append
New-CMSoftwareUpdateDeploymentPackage -Name $NEWPKG -Path $PKGPATH | Out-File $LOGFILE -Append

#Distribute package
$DPG=(Get-CMDistributionPointGroup).name
foreach ($DISTP in $DPG){
date | Out-File $LOGFILE -Append
Start-CMContentDistribution -DistributionPointGroupName $DISTP -DeploymentPackageName $NEWPKG | Out-File $LOGFILE -Append
}

}

#Get the ID from the package name.
$PackageId=(Get-CMSoftwareUpdateDeploymentPackage -name $NEWPKG).PackageID

#Get last year CMDPKGID
$OldPackageId=(Get-CMSoftwareUpdateDeploymentPackage -name $OLDPKG).PackageID

#Get All ADR names
$ADRNAME=(Get-CMSoftwareUpdateAutoDeploymentRule -Fast).name

#############################################################################

#Function: Change-ContentTemplete
function Change-ContentTemplate {
    [wmi]$AutoDeployment = (Get-WmiObject -Class SMS_AutoDeployment -Namespace root/SMS/site_$($SiteCode) -ComputerName $PSERVER | Where-Object -FilterScript {$_.Name -eq $AutoDeploymentName}).__PATH
    [xml]$ContentTemplateXML = $AutoDeployment.ContentTemplate

If (($AutoDeployment.ContentTemplate).Contains($OldPackageId) -and $OldPackageId.Length -gt 4){

    $ContentTemplateXML.ContentActionXML.PackageId = $PackageId
   
    $AutoDeployment.ContentTemplate = $ContentTemplateXML.OuterXML
    date | Out-File $LOGFILE -Append
    Write-Output "Changing Package File" | Out-File $LOGFILE -Append
    $AutoDeployment.Put() | Out-File $LOGFILE -Append
    Write-Output "Package Update Completed Successfully." | Out-File $LOGFILE -Append
}ELSE{
date | Out-File $LOGFILE -Append
Write-Output "There is no matching ADR using the $OLDPKG package." | Out-File $LOGFILE -Append
}
}

#############################################################################

#Run Function
foreach ($AutoDeploymentName in $ADRNAME){
Change-ContentTemplate
}