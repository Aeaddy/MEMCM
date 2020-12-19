#
# Press 'F5' to run this script. Running this script will load the ConfigurationManager
# module for Windows PowerShell and will connect to the site.
#
# This script was auto-generated at '5/1/2017 6:26:01 PM'.

# Uncomment the line below if running in an environment where script signing is 
# required.
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" # Import the ConfigurationManager.psd1 module 
Set-Location "SCI:" # Set the current location to be the site code.

#Path to CSV containing application information
$AppImport = Import-Csv -Path C:\Users\PCAMPBEL\Desktop\ApplicationImport.csv

#For Each Row in $AppImport, create a new CMapplication based on the columns Name, Publisher and SoftwareVersion.  Name is the only required field.
$AppImport | ForEach-Object {
    New-CMApplication -Name $_.Name -Publisher $_.Publisher -SoftwareVersion $_.SoftwareVersion
}