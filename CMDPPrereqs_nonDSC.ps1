$FILEPATH="C:\temp"
$PSLOG = "$FILEPATH\prereg.log"
New-Item -ItemType Directory $FILEPATH
New-Item -ItemType File $PSLOG


   
  
$DPROLES = "FS-FileServer", "RDC", "Web-WebServer", "Web-Common-Http", "Web-Default-Doc", "Web-Dir-Browsing", "Web-Http-Errors", "Web-Static-Content","Web-Http-Redirect","Web-Health","Web-Http-Logging","Web-Performance","Web-Stat-Compression","Web-Security","Web-Filtering","Web-Windows-Auth","Web-App-Dev","Web-ISAPI-Ext","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Mgmt-Compat","Web-Metabase","Web-WMI","Web-Scripting-Tools"

Foreach ($i in $DPROLES)

    {

  Install-WindowsFeature "$i"

$i | out-file $PSLOG -Append -NoClobber

     }

$NOSMSFILE = "C:\no_sms_on_drive.sms"

$TESTNOSMS = Test-Path $NOSMSFILE
IF ($TESTNOSMS -eq $false) {
New-Item -ItemType File $NOSMSFILE
}

Remove-Item $FILEPATH -Recurse
