#Create log path and log file
$FILEPATH="C:\temp"
$PSLOG = "$FILEPATH\MEMCM_DP_Prereg.log"
$tP = test-path $FILEPATH
if ($tP -eq $false) {
New-Item -ItemType Directory $FILEPATH 
}
New-Item -ItemType File $PSLOG

#This section defines the Windows roles and features that will be installed.  
#Modify this section to add or remove Windows roles/features
$DPROLES = "FS-FileServer", 
"RDC", 
"Web-WebServer", 
"Web-Common-Http", 
"Web-Default-Doc", 
"Web-Dir-Browsing", 
"Web-Http-Errors", 
"Web-Static-Content",
"Web-Http-Redirect",
"Web-Health",
"Web-Http-Logging",
"Web-Performance",
"Web-Stat-Compression",
"Web-Security",
"Web-Filtering",
"Web-Windows-Auth",
"Web-App-Dev",
"Web-ISAPI-Ext",
"Web-Mgmt-Tools",
"Web-Mgmt-Console",
"Web-Mgmt-Compat",
"Web-Metabase",
"Web-WMI",
"Web-Scripting-Tools"

#This loops through each item in the list above and installs the Windows role/feature and writes the output to the log
Foreach ($i in $DPROLES)

    { 

    $WINFEATS = Get-WindowsFeature -Name $i
        if ($WINFEATS.InstallState -eq "Installed") {
            write-output "The feature: $i is already installed." | out-file $PSLOG -Append -NoClobber
            #write-output $WINFEATS | out-file $PSLOG -Append -NoClobber
            write-output "________________________________________" | out-file $PSLOG -Append -NoClobber
            } else {
            write-output "the feature is not installed. Installing feature: $i" | out-file $PSLOG -Append -NoClobber
            #write-output $WINFEATS | out-file $PSLOG -Append -NoClobber

            Install-WindowsFeature "$i" | Out-Null
            #Start-Sleep -Seconds 10
            Get-WindowsFeature -Name $i
            $WINFEATS2 = Get-WindowsFeature -Name $i
            
                if ($WINFEATS2.InstallState -eq "Installed") {
                    write-output "The feature: $i has successfully been installed." | out-file $PSLOG -Append -NoClobber
                    }else{
                    write-output "The feature: $i has failed to install. Please troubleshoot manually." | out-file $PSLOG -Append -NoClobber
                    }
            write-output "________________________________________"

        }
    }

    


#This section defines the no_sms_on_drive file, tests to see if it exists, and if it does not exists, creates it.
$NOSMSFILE = "C:\no_sms_on_drive.sms"

$TESTNOSMS = Test-Path $NOSMSFILE
IF ($TESTNOSMS -eq $false) {
New-Item -ItemType File $NOSMSFILE | out-file $PSLOG -Append -NoClobber
}
