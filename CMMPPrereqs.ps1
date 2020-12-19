$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration ManagementPoint    
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   
$MPROLES = "NET-Framework-Core","NET-Framework-45-Features","NET-Framework-45-Core","NET-WCF-TCP-PortSharing45","NET-WCF-Services45","BITS","BITS-IIS-Ext","BITS-Compact-Server","RSAT-Bits-Server","Web-Server","Web-WebServer","Web-ISAPI-Ext","Web-WMI","Web-Metabase","Web-Windows-Auth","Web-ASP","Web-Asp-Net","Web-Asp-Net45"
$LOGPATH = "C:\MPPrereqs.log"

Foreach ($i in $MPROLES)

    {

  WindowsFeature "$i"
{
    Name = "$i"
    Ensure = "Present"
    Source = "C:\SXS"
    LogPath = "$LOGPATH"
}


     }


  } 
}


#Commands to execute:
ManagementPoint -Servers localhost -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

Remove-Item $FILEPATH -Recurse