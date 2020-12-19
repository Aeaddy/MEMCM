<#
Title: AddListOfComputersToCollection.ps1
Author: Adam Eaddy
Company: ITS Partners
Date: 10/16/2020
Description: The purpose of this script is to add computers to a device collection based on a .CSV file.
The list of computers should be a text based list of computer short names saved in .CSV format.
E.g. AddListOfComputersToCollection.ps1 -CSVFile C:\files\computerList.csv -CollID JAM000F5
!#>

#Input Parameters
[CmdletBinding()]
Param (
    [Parameter(Position=0)]
    [string]$CSVFile,

    [Parameter(Position=1)]
    [string]$CollID
)

#Code to connect to ConfigMgr PSDrive
$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1" 
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"

#Define Log File
$date = Get-Date -Format MMddyyyy
$Logfile = "$env:TEMP\AddComputersToCollection-$COLLID-$date.log"

#Functions
Function getCMCollectionDetails{
Param ($CollectionID)
Get-CMCollection -Id $CollectionID
}

Function getCMDevice{
Param ($CMComp)
Get-CMDevice -Name $CMComp
}

Function checkCollectionMembership{
Param ($CollectionID)
Get-CMCollectionMember -CollectionId $CollectionID
}

Function addComputerToCMDeviceCollection{
Param ($Collection, $Computer)
Add-CMDeviceCollectionDirectMembershipRule -InputObject $Collection -Resource $Computer
}

#Get Collection Name and write it to log file
$COLLDETS = getCMCollectionDetails -CollectionID $CollID
Write-Output "*******The collection being updated is: $($COLLDETS.Name)*******" | out-file $Logfile -Append -Force -NoClobber

#Import Device List from CSV File
$DeviceNames = Import-CSV $CSVFile -Header Name

#For each device in list, check is device exists in CfgMgr, then check is device already exists in specified device collection.  If not exist, and to collection.
Foreach ($DeviceName in $DeviceNames) {

    $CMCOMPOBJ = getCMDevice -CMComp $($DeviceName.Name)

    IF ($CMCOMPOBJ -eq $null) {

        write-output "The device $($DeviceName.Name) cannot be found in Configuration Manager." | out-file $Logfile -Append -Force -NoClobber

    } else {

        $COLLMEMS = checkCollectionMembership -CollectionID $CollID

        IF ($COLLMEMS.Name -like $CMCOMPOBJ.Name) {

            Write-Output "The device $($CMCOMPOBJ.Name) already exists in the collection: $($COLLDETS.Name)." | out-file $Logfile -Append -Force -NoClobber
            
        } else {
           
            Write-Output "Attempting to add device $($CMCOMPOBJ.Name) to the collection: $($COLLDETS.Name)." | out-file $Logfile -Append -Force -NoClobber
            
            addComputerToCMDeviceCollection -Collection $COLLDETS -Computer $CMCOMPOBJ

        }
    
    }
    
}

#Write the date and time to the log file and output the log file name and location
 get-date | Write-Output | out-file $Logfile -Append -Force -NoClobber
 Write-Output "Your log was created here: $Logfile"
