$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration AppCatalog    
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   
  
$APPCATROLES = "NET-Framework-Features","NET-Framework-Core","NET-HTTP-Activation","NET-Non-HTTP-Activ","NET-WCF-Services45","NET-WCF-HTTP-Activation45","RDC","WAS","WAS-Process-Model","WAS-NET-Environment","WAS-Config-APIs","Web-Server","Web-WebServer","Web-Common-Http","Web-Static-Content","Web-Default-Doc","Web-App-Dev","Web-ASP-Net","Web-ASP-Net45","Web-Net-Ext","Web-Net-Ext45","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Security","Web-Windows-Auth","Web-Filtering","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Scripting-Tools","Web-Mgmt-Compat","Web-Metabase","Web-Lgcy-Mgmt-Console","Web-Lgcy-Scripting","Web-WMI"
$LOGPATH = "C:\ACPrereqs.log"

Foreach ($i in $APPCATROLES)

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
AppCatalog -Servers localhost -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

Remove-Item $FILEPATH -Recurse
