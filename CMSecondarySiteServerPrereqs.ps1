$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration SecondarySite  
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   
  
$SSITE = "NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Metabase","Web-WMI"
$LOGPATH = "C:\SSPrereqs.log"

Foreach ($i in $SSITE)

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
SecondarySite -Servers localhost -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

Remove-Item $FILEPATH -Recurse
