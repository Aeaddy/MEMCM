#Load Configuration Manager PowerShell Module
Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

#Get SiteCode
$SiteCode = Get-PSDrive -PSProvider CMSITE
Set-location $SiteCode":"

function Convert-DateString ([String]$Date, [String[]]$Format)
{
 $result = New-Object DateTime

 $convertible = [DateTime]::TryParseExact(
    $Date,
    $Format,
    [System.Globalization.CultureInfo]::InvariantCulture,
    [System.Globalization.DateTimeStyles]::None,
    [ref]$result)

 if ($convertible) { $result }
}

$GROUP1 = "US-GRR",
"ES-MAD",
"US-ATN",
"US-COI"

#Device Collections 
foreach ($COL in $GROUP1){

$random = Get-Random -Minimum 0 -Maximum 59
$tempDate = Convert-DateString -date '22:00:00' -Format 'HH:mm:ss'
$DateTime = $tempDate.AddMinutes($random)
$CMSched = New-CMSchedule -DayOfWeek Friday -Start $DateTime

$QUERY = "select *  from  SMS_R_System where SMS_R_System.ADSiteName like `"`%"+$COL+"`%`""

New-CMCollection -CollectionType Device -Name "AD Site | $COL" -LimitingCollectionName "All Systems" -RefreshType Both -RefreshSchedule $CMSched

Add-CMDeviceCollectionQueryMembershipRule -CollectionName "AD Site | $COL" -RuleName "AD Site | $COL" -QueryExpression $QUERY 

#User Collections
<#
$QUERY2 = "select *  from  SMS_R_User where SMS_R_User.DistinguishedName like `"`%"+$COL+"`%`""

New-CMUserCollection -Name "Users | $COL" -LimitingCollectionName "All Users and User Groups" -RefreshType Both -RefreshSchedule $CMSched

Add-CMUserCollectionQueryMembershipRule -CollectionName "Users | $COL" -RuleName "Users | $COL" -QueryExpression $QUERY2 

#>

}