[CmdletBinding()]
Param (
  [Parameter(Mandatory=$True,Position=0)]
  [string]$FILEPATH
)


$FILEPATH = "\\btcnas12\memcm\Scripts\Build and Maintenance Scripts\DP.CSV"
$MEMCMDPS = Import-csv -Path $FILEPATH #-Header DistributionPointName, PullDP 
$LOGFILE = "$env:TEMP\testlog.log"

$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1" 
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"
$CERTTIME = "December 31, 2025 10:10:00 PM"


foreach ($MEMCMDP in $MEMCMDPS) {
    $ServerName = $MEMCMDP.DistributionPointName
    $PullDPSourceName = $MEMCMDP.PullDP
    
        Write-Output "The dp server name is $ServerName" | Out-File -FilePath $LOGFILE -Force -Append -NoClobber
        Write-Output "The PULL server name is $PullDPName" | Out-File -FilePath $LOGFILE -Force -Append -NoClobber
        
        #Install Site System Server
        New-CMSiteSystemServer -ServerName $ServerName -SiteCode $SiteCode
        #Test-Connection -ComputerName $ServerName -Count 1

        
        #Install Distribution Point Role
        Add-CMDistributionPoint -CertificateExpirationTimeUtc $CERTTIME -SiteCode $SiteCode -SiteSystemServerName $ServerName -MinimumFreeSpaceMB 10240 -ClientConnectionType 'Intranet' -PrimaryContentLibraryLocation Automatic -PrimaryPackageShareLocation Automatic -SecondaryContentLibraryLocation Automatic -SecondaryPackageShareLocation Automatic -EnablePullDP -SourceDistributionPoint $PullSourceDPName


        #Check for Boundary Group that Matches DP name
        $CMBGName = $null
        $CMBGName = Get-CMBoundaryGroup -Name $ServerName
        if (!$CMBGName) {
            Write-Output "There is not a Boundary Group that Matches the DP Name.  Creating Boundary Group." | Out-File -FilePath $LOGFILE -Force -Append -NoClobber
            New-CMBoundaryGroup -Name $ServerName -DefaultSiteCode P01 -AddSiteSystemServerName "$ServerName.bok.com"
        }else{
            Write-Output "There is a Boundary Group that Matches the DP Name. Adding Site System to Boundary Group." | Out-File -FilePath $LOGFILE -Force -Append -NoClobber
            Set-CMBoundaryGroup -InputObject $CMBGName -AddSiteSystemServerName "$ServerName.bok.com"
       }
 }

    Set-Location C:




