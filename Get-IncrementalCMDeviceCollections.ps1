#
# Press 'F5' to run this script. Running this script will load the ConfigurationManager
# module for Windows PowerShell and will connect to the site.
#
# This script was auto-generated at '2/13/2019 11:21:29 AM'.

# Uncomment the line below if running in an environment where script signing is 
# required.
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Site configuration
$SiteCode = "JAM" # Site code 
$ProviderMachineName = "cm1.jam.on" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

$CMCOLLS = Get-CMDeviceCollection
foreach ($CMCOLL in $CMCOLLS) {
    IF ($CMCOLL.RefreshType -like 4 -or $CMCOLL -like 6) {
        Write-Output $CMCOLL.Name
        }
    }


