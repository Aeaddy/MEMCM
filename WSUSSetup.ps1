$FILEPATH="C:\temp"
New-Item -ItemType Directory $FILEPATH

Configuration DeployWSUS    
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers
  )
 
  Node $Servers
  { 
   

$SUPROLES = "UpdateServices-Services", "UpdateServices-WidDB", "UpdateServices-RSAT"
$LOGPATH = "C:\SUPPrereqs.log"

Foreach ($i in $SUPROLES)

    {

  WindowsFeature $i
{
    Name = "$i"
    Ensure = "Present"
    IncludeAllSubFeature = $true
    LogPath = "$LOGPATH"
}

    }

  File WSUS
{
    Type = "Directory"
    Ensure = "Present"
    DestinationPath = 'D:\WSUS'
}




  Script PostWSUSConfig
{
    SetScript = {
    set-location "C:\Program Files\Update Services\Tools\"
    .\wsusutil.exe postinstall CONTENT_DIR=D:\WSUS
    }

    TestScript = { 
    $CDIR0 = 'D:\WSUS'
    $WSUSKey = "hklm:\SOFTWARE\Microsoft\Update Services\Server\Setup"
    $WSUSValues = Get-ItemProperty $WSUSKey
    $CDIR1 = $WSUSValues.ContentDir
    $CDIR1 -eq $CDIR0
    }

    GetScript = { 
    $WSUSKey = "hklm:\SOFTWARE\Microsoft\Update Services\Server\Setup"
    $WSUSValues = Get-ItemProperty $WSUSKey
    $WSUSValues.ContentDir
    }

}

<# Need to import xHotfix DSC!!!
 xHotfix WSUSWin10Support 
    { 
        Ensure = "Present" 
        Path = "https://download.microsoft.com/download/D/3/8/D3854613-B1DB-40A2-BB05-5FF9CCDEFB74/Windows8.1-KB3095113-v2-x64.msu" 
        Id = "KB3095113" 
    }  
    #>
  } 
}  

#Commands to execute:
DeployWSUS -Servers localhost -OutputPath $FILEPATH

Start-DscConfiguration -Path $FILEPATH -wait -Verbose -Force -ErrorAction Stop  

Remove-Item $FILEPATH -Recurse