$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration DistributionPoint    
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   
  
$DPROLES = "FS-FileServer", "RDC", "Web-WebServer", "Web-Common-Http", "Web-Default-Doc", "Web-Dir-Browsing", "Web-Http-Errors", "Web-Static-Content","Web-Http-Redirect","Web-Health","Web-Http-Logging","Web-Performance","Web-Stat-Compression","Web-Security","Web-Filtering","Web-Windows-Auth","Web-App-Dev","Web-ISAPI-Ext","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Mgmt-Compat","Web-Metabase","Web-WMI","Web-Scripting-Tools"
$LOGPATH = "C:\DPPrereqs.log"

Foreach ($i in $DPROLES)

    {

  WindowsFeature "$i"
{
    Name = "$i"
    Ensure = "Present"
    LogPath = "$LOGPATH"
}

     }

$NOSMSFILE = "C:\no_sms_on_drive.sms"

  File SMSONDRIVE
{
    Type = "File"
    Ensure = "Present"
    DestinationPath = "$NOSMSFILE"
    Contents = ""
}

  } 
}  


#Commands to execute:
DistributionPoint -Servers localhost -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

Remove-Item $FILEPATH -Recurse
