#This script will run on any Windows 8 or Windows 10 device and extract the drivers into a temp directory.  It will then copy those drivers to a share provided in the parameter $SHARENAME.
#Next the script will connect to the primary site server provided in the $CMSITESERVER parameter and initiate the driver import and package build process.  
#PSremote must be enabled on the Primary Site server and you must be running the latest version of the PowerShell cmdlets.
#This script must be run w/ an account that has access to the Primary Site Server and the file shares that are being used.
#The $CMDPSiteServer parameter is distribution points for distributing the driver package.  This excepts multiple distribution points seperated by commas.
#The $PKGSHARENAME is the share location that the driver package will be stored.


[CmdletBinding()]
Param (
  [Parameter(Mandatory=$True,Position=0)]
  [string]$CMSiteServer,
  
  [Parameter(Mandatory=$True, Position=1)]
  [string[]]$CMDPSiteServer,

  [Parameter(Mandatory=$True, Position=2)]
  [string]$SHARENAME,

  [Parameter(Mandatory=$True, Position=3)]
  [string]$PKGSHARENAME
)

#Do not change these!
$COMPMODEL=(Get-WmiObject -Class win32_computersystem).Model
$OSVER=(Get-WmiObject -Class win32_operatingsystem).Caption
$OSARCH=(Get-WmiObject -Class win32_operatingsystem).OSArchitecture
$UTEMP=$env:TEMP
$DRIVERPATH ="$UTEMP\Drivers"
$LOGFILE ="$UTEMP\$COMPMODEL.log"
$NEWLOGFILE ="$UTEMP\Drivers\$COMPMODEL-$OSVER-$OSARCH.log"
$DriverPackageName = "$COMPMODEL-$OSVER-$OSARCH"
$DriverPackageSource="$PKGSHARENAME\$COMPMODEL-$OSVER-$OSARCH"
$DriverSource="$SHARENAME\$COMPMODEL-$OSVER-$OSARCH"
$DriverCategoryName01 = $OSVER
$DriverCategoryName02 = $COMPMODEL

$ScriptBlock = { param($SDriverPackageName, $SDriverPackageSource, $SDriverPackage, $SCMDPSiteServer, $SDriverCategoryName01, $SDriverCategoryName02, $SDrivers, $SDriverSource)

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1" 
$SiteCode = Get-PSDrive -PSProvider CMSite

#Create Driver Package
Set-Location "$($SiteCode.Name):\"
New-CMDriverPackage -Name $SDriverPackageName -Path $SDriverPackageSource -Verbose
$SDriverPackage = Get-CMDriverPackage -Name $SDriverPackageName
Start-CMContentDistribution -DriverPackageName $SDriverPackage.Name -DistributionPointName $SCMDPSiteServer -Verbose

#Create Administrative Categories
If ((Get-CMCategory -Name $SDriverCategoryName01) -eq $null) {New-CMCategory -CategoryType DriverCategories -Name $SDriverCategoryName01 }
$SDriverCategory01 = Get-CMCategory -Name $SDriverCategoryName01
If ((Get-CMCategory -Name $SDriverCategoryName02) -eq $null) {New-CMCategory -CategoryType DriverCategories -Name $SDriverCategoryName02 }
$SDriverCategory02 = Get-CMCategory -Name $SDriverCategoryName02

#Build Category array
$SDriverCategories = @()
$SDriverCategories += $SDriverCategory01
$SDriverCategories += $SDriverCategory02

#Get Drivers
Set-Location C:
$SDrivers = Get-ChildItem -Path $SDriverSource -Include *.inf -Recurse 
Set-Location "$($SiteCode.Name):\"

#Import Drivers
foreach ($SDriver in $SDrivers) {Import-CMDriver -UncFileLocation $SDriver.FullName -DriverPackage $SDriverPackage -EnableAndAllowInstall $true -AdministrativeCategory $SDriverCategories -ImportDuplicateDriverOption AppendCategory -ErrorAction SilentlyContinue -Verbose }

}

#End of declarations


#Export the drivers to a temp directory
If (Test-Path $NEWLOGFILE){
Write-Output "This script has been cancelled because it has already completed on this device." | out-file $NEWLOGFILE -Append
}Else{
Export-WindowsDriver -Destination "$DRIVERPATH\$COMPMODEL-$OSVER-$OSARCH" -Online | out-file $LOGFILE
move-item $LOGFILE $NEWLOGFILE
Remove-Item $DRIVERPATH'\'$COMPMODEL-$OSVER-$OSARCH'\'prn* -Recurse
}

#Copy Drivers to Driver Repository
If (Test-Path $SHARENAME'\'$COMPMODEL){
Write-Output "This Copy has been cancelled because it has already completed for this device." | out-file $NEWLOGFILE -Append
}Else{
copy-item $DRIVERPATH'\*' -Destination $SHARENAME -Recurse
}


#Connect to CM Primary Site Server
$CMSESSION=New-PSSession -ComputerName $CMSiteServer


#Execute commands on remote server 
invoke-command  -Session $CMSESSION `
                -ScriptBlock $Scriptblock `
                -Args $DriverPackageName, $DriverPackageSource, $DriverPackage, $CMDPSiteServer,$DriverCategoryName01, $DriverCategoryName02, $Drivers, $DriverSource

#Cleanup Temp directory
Remove-Item "$UTEMP\Drivers"-Recurse
