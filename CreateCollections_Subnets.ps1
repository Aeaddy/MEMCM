$CSVPATH = "E:\temp\subnets.csv"
$HEADER1 = "names"
$HEADER2 = "subnets"

$Subnets = Import-Csv -Path $CSVPATH -Header $HEADER1, $HEADER2

#Import the ConfigMgr PowerShell module & witch to ConfigMgr
$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"

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

foreach ($subnet in $Subnets.$HEADER2) {

$random = Get-Random -Minimum 0 -Maximum 59
$tempDate = Convert-DateString -date '22:00:00' -Format 'HH:mm:ss'
$DateTime = $tempDate.AddMinutes($random)
$CMSched = New-CMSchedule -DayOfWeek Friday -Start $DateTime

$QUERY = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.IPSubnets in (`"`%"+$subnet+"`%`") and SMS_R_System.OperatingSystemNameandVersion like '%workstation%'"

New-CMCollection -CollectionType Device -LimitingCollectionName "All Systems" -Name $subnet -RefreshType Both -RefreshSchedule $CMSched

Add-CMDeviceCollectionQueryMembershipRule -CollectionName $subnet -RuleName $subnet -QueryExpression $QUERY 

}
