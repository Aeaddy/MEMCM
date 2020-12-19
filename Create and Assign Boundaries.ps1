#Load Configuration Manager PowerShell Module
Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

#Get SiteCode
$SiteCode = Get-PSDrive -PSProvider CMSITE
Set-location $SiteCode":"

$GROUP1 = "US-GRR",
"ES-MAD",
"US-ATN",
"US-COI",
"US-STL",
"US-MSP"

foreach ($BG in $GROUP1){
#Write-Output $BG 
New-CMBoundaryGroup -Name $BG -Description $BG -DefaultSiteCode $SiteCode

} 

foreach ($BG in $GROUP1){

$BDVAR = get-cmboundary | where {$_.DisplayName -like "*$BG*"}

Foreach ($BDVAR1 in $BDVAR) {

Add-CMBoundaryToGroup -InputObject $BDVAR1 -BoundaryGroupName $BG

    }

}  