param(
[Parameter(Mandatory=$True,HelpMessage='Input your P-role name.')]
[string]$pRole,
[string]$LimitingCollection = 'All Users and User Groups',
[string]$RefreshType = 'Both'
)

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

$random = Get-Random -Minimum 0 -Maximum 59
$tempDate = Convert-DateString -date '22:00:00' -Format 'HH:mm:ss'
$DateTime = $tempDate.AddMinutes($random)

#Import the ConfigMgr PowerShell module & witch to ConfigMgr
$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"

$CMSched = New-CMSchedule -DayOfWeek Friday -Start $DateTime
  
New-CMUserCollection -Name "$pRole" -LimitingCollectionName "$LimitingCollection" -RefreshType "$RefreshType" -RefreshSchedule $CMSched
Add-CMUserCollectionQueryMembershipRule -CollectionName "$pRole" -QueryExpression "select SMS_R_User.FullUserName, SMS_R_User.UserGroupName from  SMS_R_User where SMS_R_User.UserGroupName = 'DUS\\$pRole'" -RuleName "$pRole"