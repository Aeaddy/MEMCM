$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration StateMigrationPoint    
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   
  
$SMPROLES = "Web-Server","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Logging","Web-Dyn-Compression","Web-Filtering","Web-Windows-Auth","Web-Mgmt-Tools","Web-Mgmt-Console"
$LOGPATH = "C:\SMPPrereqs.log"

Foreach ($i in $SMPROLES)

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
StateMigrationPoint  -Servers localhost -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

Remove-Item $FILEPATH -Recurse
