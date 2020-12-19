[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true,Position=0)]
    [string]$PACKAGENAME,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$FILEPATH
)

$FULLPATH="$FILEPATH\$PACKAGENAME"
$SNIP = $env:SMS_ADMIN_UI_PATH.Length-5
$MODPATH = $env:SMS_ADMIN_UI_PATH.Substring(0,$SNIP)
Import-Module "$MODPATH\ConfigurationManager.psd1"
$SITECODE = Get-PSDrive -PSProvider CMSite
Set-Location "$($SITECODE.Name):\"

Import-CMDriverPackage -ImportFilePath $FULLPATH"\"$PACKAGENAME".zip"
