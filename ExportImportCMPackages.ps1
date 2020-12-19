$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modpath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modpath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite

Set-Location "$($SiteCode.Name):\"

$PACKAGENAME="OSD PowerShell Scripts"
$FILEPATH="D:\exports"
$FULLPATH="$FILEPATH\$PACKAGENAME"
$EXPORTEDCONTENT="$FILEPATH\$PACKAGENAME\$PACKAGENAME.zip"
#$IMPORTEDCONTENT="\\ius.meijer.com\infra\SCCM\imports"
$USSERVERSHARE="\\w0982dappv0601.dus.meijer.com\sources"

New-Item -ItemType Directory -Path $FILEPATH"\"$PACKAGENAME
Export-CMPackage -WithContent $true -ExportFilePath $EXPORTEDCONTENT -Name $PACKAGENAME

#Extract Manifest File
$SHELL=New-Object -ComObject shell.application
$ZIP=$SHELL.Namespace($EXPORTEDCONTENT)

foreach($item in $ZIP.items()){
    if([System.IO.Path]::GetExtension($item.Path) -eq ".xml"){
        $shell.Namespace($FULLPATH).copyhere($item)
    }
}

#Get OLD content location from XML
$XMLDATA=[XML](Get-Content "$FULLPATH\manifest.xml")
$OLDPATH=($XMLDATA.InnerXml -split '"')[25]

#Create new content location based off of old content location
$NEWPATHPART=($OLDPATH -split "\\")
$NEWPATH="$USSERVERSHARE\" + $NEWPATHPART[4]


#Copy content to new location
#Import package