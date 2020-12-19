#Want the script to allow us to determine what dependencies are in the task,
#then export those dependencies (using a seperate function)
#Create collections and deployments in disabled state

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true,Position=0)]
    [string]$PACKAGENAME,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$FILEPATH
)

$FULLPATH="$FILEPATH\$PACKAGENAME"
$EXPORTEDCONTENT="$FILEPATH\$PACKAGENAME\$PACKAGENAME.zip"
$SNIP = $env:SMS_ADMIN_UI_PATH.Length-5
$MODPATH = $env:SMS_ADMIN_UI_PATH.Substring(0,$SNIP)
Import-Module "$MODPATH\ConfigurationManager.psd1"
$SITECODE = Get-PSDrive -PSProvider CMSite
Set-Location "$($SITECODE.Name):\"

if(!(Test-Path -Path $FILEPATH )){
   New-Item -ItemType directory -Path $FILEPATH
}

if(!(Test-Path -Path $FILEPATH"\"$PACKAGENAME )){
    New-Item -ItemType Directory -Path $FILEPATH"\"$PACKAGENAME
}

if(!(Test-Path -Path $FILEPATH"\"$PACKAGENAME"\"$PACKAGENAME )){
    Export-CMTaskSequence -WithContent $false -WithDependence $false -ExportFilePath $EXPORTEDCONTENT -Name $PACKAGENAME
}

