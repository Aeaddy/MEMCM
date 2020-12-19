#Import the ConfigMgr PowerShell module & connect to ConfigMgr PSDrive
$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"
$PSD = $($SiteCode.Name)

#Functions

Function GetInstallString{
Param ($AppName)
$CMADT = Get-CMDeploymentType -ApplicationName $AppName
    foreach ($CMADTI in $CMADT) {
        $CD = $CMADTI.SDMPackageXML
        $doc = [xml]$CD
        $doc.AppMgmtDigest.DeploymentType.Installer.InstallAction.Args.Arg[0].'#text'
    }
}

Function GetUninstallString{
Param ($AppName)
$CMADT = Get-CMDeploymentType -ApplicationName $AppName
    foreach ($CMADTI in $CMADT) {
        $CD = $CMADTI.SDMPackageXML
        $doc = [xml]$CD
        $doc.AppMgmtDigest.DeploymentType.Installer.UninstallAction.Args.Arg[0].'#text'
    }
}


#Get install and uninstall String
$CMAPPS = Get-CMApplication
foreach ($CMAPP in $CMAPPS) {
    Write-Output "$($CMAPP.LocalizedDisplayName)"
    $InstallString = GetInstallString -AppName $CMAPP.LocalizedDisplayName
    if (!$InstallString) {
        write-output "There is no Install string provided with this deployment type."
    }else{
        Write-Output $InstallString
    } 
    $UninstallString = GetUninstallString -AppName $CMAPP.LocalizedDisplayName
    if (!$UninstallString) {
        write-output "There is no Uninstall string provided with this deployment type."
    }else{
        Write-Output $UninstallString
    } 
}
