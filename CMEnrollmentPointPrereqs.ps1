$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration EnrollmentPoint    
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   
  
$ENPNTROLES = "Web-Server","Web-WebServer","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Logging","Web-Stat-Compression","Web-Filtering","Web-Net-Ext","Web-Asp-Net","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Mgmt-Console","Web-Metabase","NET-Framework-Core","NET-Framework-Features","NET-HTTP-Activation","NET-Framework-45-Features","NET-Framework-45-Core","NET-Framework-45-ASPNET","NET-WCF-Services45","NET-WCF-TCP-PortSharing45"
$LOGPATH = "C:\EPPrereqs.log"

Foreach ($i in $ENPNTROLES)

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
EnrollmentPoint -Servers localhost -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

Remove-Item $FILEPATH -Recurse
