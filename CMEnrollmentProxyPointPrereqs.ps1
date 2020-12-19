$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration EnrollmentProxyPoint    
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   
  
$ENPRXYPNTROLES = "Web-Server","Web-WebServer","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Logging","Web-Stat-Compression","Web-Filtering","Web-Windows-Auth","Web-Net-Ext","Web-Net-Ext45","Web-Asp-Net","Web-Asp-Net45","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Mgmt-Console","Web-Metabase","NET-Framework-Core","NET-Framework-Features","NET-Framework-45-Features","NET-Framework-45-Core","NET-Framework-45-ASPNET","NET-WCF-Services45","NET-WCF-TCP-PortSharing45"
$LOGPATH = "C:\EPPPrereqs.log"

Foreach ($i in $ENPRXYPNTROLES)

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
EnrollmentProxyPoint -Servers localhost -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

Remove-Item $FILEPATH -Recurse
