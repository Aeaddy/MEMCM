[CmdletBinding()]
Param (
  [Parameter(Mandatory=$True,Position=0)]
  [string]$SSNAME
)

#Use DSC to install server roles remotely. PSRemoting must be enabled on site server.
$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration SSPrereqs   
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   
  
$ROLES = "Web-Server","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Logging","Web-Dyn-Compression","Web-Filtering","Web-Windows-Auth", "FS-FileServer", "RDC","Web-Http-Redirect","Web-Health","Web-Performance","Web-Stat-Compression","Web-Security","Web-App-Dev","Web-ISAPI-Ext","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Mgmt-Compat","Web-Metabase","Web-WMI","Web-Scripting-Tools", "WDS"
$LOGPATH = "C:\SiteServerSetupLog.log"

Foreach ($ROLE in $ROLES)

    {

  WindowsFeature "$ROLE"
{
    Name = "$ROLE"
    Ensure = "Present"
    LogPath = "$LOGPATH"
}

     }


#Create no_sms_on_drive.sms file on C: drive
$NOSMSFILE = "C:\no_sms_on_drive.sms"

  File SMSONDRIVE
{
    Type = "File"
    Ensure = "Present"
    DestinationPath = "$NOSMSFILE"
    Contents = ""
}

  } 
}  

#Commands to execute:
SSPrereqs -Servers $SSNAME -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

#Install Configuration Manager roles

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1" 
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"
$CERTTIME = "December 31, 2025 10:10:00 PM"
$LOGPATH = "C:\SiteServerSetupLog.log"

#Install Site System Server
$CMSITESERVER = Get-CMSiteSystemServer
$CMSITESERVERPATH = $CMSITESERVER.NetworkOSPath

IF ($CMSITESERVERPATH -contains "\\$SSNAME") { Write-Output "This server already exists as a site server on $SSNAME"; Write-Output "This server already exists as a site server on $SSNAME" | Out-File $LOGPATH -Append}
else {New-CMSiteSystemServer -ServerName $SSNAME -SiteCode $SiteCode; Write-Output "The Site System role has been installed on $SSNAME" | Out-File $LOGPATH -Append }

#Install Distribution Point Role
$CMDPSERVER = Get-CMDistributionPoint
$CMDPSERVERPATH = $CMDPSERVER.NetworkOSPath

IF ($CMDPSERVERPATH -contains "\\$SSNAME") { Write-Output "This server already has the Distribution Point server role installed on server $SSNAME"; Write-Output "This server already has the Distribution Point server role installed on server $SSNAME" | Out-File $LOGPATH -Append}
else {Add-CMDistributionPoint -CertificateExpirationTimeUtc $CERTTIME -SiteCode $SiteCode -SiteSystemServerName $SSNAME -MinimumFreeSpaceMB 10240 -ClientConnectionType 'Intranet' -PrimaryContentLibraryLocation Automatic -PrimaryPackageShareLocation Automatic -SecondaryContentLibraryLocation Automatic -SecondaryPackageShareLocation Automatic -AllowPreStaging
 
#Enable PXE, Unknown Computer Support, Client Communication Method
Set-CMDistributionPoint -SiteSystemServerName $SSNAME -SiteCode $SiteCode -EnablePxe $true -EnableUnknownComputerSupport $true -AllowPxeResponse $true -UserDeviceAffinity AllowWithAutomaticApproval
Write-Output "The DP and PXE System role have been installed on $SSNAME" | Out-File $LOGPATH -Append
}

#Create StorageDirectory Object for SMP Role
$STORAGEDIR = New-CMStorageFolder -StorageFolderName "D:\SMP" -MaximumClientNumber 10 -MinimumFreeSpace 10240 -SpaceUnit Megabyte
 
#Install State Migration Point Role
$CMSMPSERVER = Get-CMStateMigrationPoint
$CMSMPSERVERPATH = $CMDPSERVER.NetworkOSPath

IF ($CMSMPSERVERPATH -contains "\\$SSNAME") { Write-Output "This server already has the SMP Point server role installed"; Write-Output "This server already has the SMP Point server role installed" | Out-File $LOGPATH -Append}
else {Add-CMStateMigrationPoint -SiteSystemServerName $SSNAME -SiteCode $SiteCode -TimeDeleteAfter "3" -TimeUnit Days -StorageFolder $STORAGEDIR -EnableRestoreOnlyMode $False -AllowFallbackSourceLocationForContent $False; Write-Output "The State Migration Point System role has been installed on $SSNAME" | Out-File $LOGPATH -Append}

Remove-Item $FILEPATH -Recurse

#PXE user affinity and prestaged content