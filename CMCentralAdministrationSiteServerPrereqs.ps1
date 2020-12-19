$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration CentralAdministrationSite  
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   
  
$CASITE = "NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Net-Ext","Web-Net-Ext45","Web-ASP-Net","Web-ASP-Net45","Web-ASP","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Stat-Compression","Web-Dyn-Compression","Web-Metabase","Web-WMI","Web-HTTP-Redirect","Web-Log-Libraries","Web-HTTP-Tracing","UpdateServices-RSAT","UpdateServices-API","UpdateServices-UI"
$LOGPATH = "C:\CASPrereqs.log"

Foreach ($i in $CASITE)

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
CentralAdministrationSite -Servers localhost -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

Remove-Item $FILEPATH -Recurse
