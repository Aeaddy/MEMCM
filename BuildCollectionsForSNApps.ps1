#Set this value to the name of the SCCM folder to store the ServiceNow device collections and the name of the Category that the Applications will use.
$SNDIR = 'ServiceNow Software'
$APPCAT = "ServiceNow"

#DO NOT MODIFY ANYTHING BELOW THIS LINE.

#Configure Logging
$FORMATTEDDATE = Get-Date -format "MM-dd-yy"
$UFORMATTEDDATE = get-date
$LOGFILE = "CreateSNAppCollectionsAndDeploy_" + $FORMATTEDDATE + ".log"
$LOGPATH = "$env:TEMP\$LOGFILE"
$LOGTEST = Test-Path $LOGPATH
If ($LOGTEST -eq $false) {
    New-Item -Path $env:TEMP -Name $LOGFILE -Force
}
Write-Output "********Begin Logging $UFORMATTEDDATE********" | out-file $LOGPATH -Append -Force -NoClobber 

#Import the ConfigMgr PowerShell module & witch to ConfigMgr
$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"
$PSD = $($SiteCode.Name)

#Check for ServiceNow Console Collection Directory.  If it does not exist, create it.
$NEWPATH = $PSD + ':\DeviceCollection\'
$SNCMDIR = $NEWPATH + $SNDIR
$TESTPATH = test-path -Path $SNCMDIR

If ($TESTPATH -eq $false) {
    New-Item -Name $SNDIR -Path $NEWPATH
    $TESTAGAIN = test-path -Path $SNCMDIR
    if ($TESTAGAIN -eq $true) {
        $UFORMATTEDDATE = get-date
        write-output "$UFORMATTEDDATE - The new Directory was created: $SNCMDIR" | out-file $LOGPATH -Append -Force -NoClobber
        }else{
        $UFORMATTEDDATE = get-date
        write-output "$UFORMATTEDDATE - Error: The new Directory was not created.  Please troubleshoot manually." | out-file $LOGPATH -Append -Force -NoClobber
        }
}else{
    $UFORMATTEDDATE = get-date
    write-output "$UFORMATTEDDATE - The Directory already exists: $SNCMDIR" | out-file $LOGPATH -Append -Force -NoClobber
}

#Get list of CM Applications with the "ServiceNow" Category assigned to it.
$SNAPPS = Get-CMApplication | Where-Object { $_.LocalizedCategoryInstanceNames -like $APPCAT }

<#
Loop through the list of Applications and check for the install and uninstall collections.  If they do
not exist, create them, move them into the ServiceNow folder, and deploy the application to the collection.
/#>
foreach ($SNAPP in $SNAPPS) {
$UFORMATTEDDATE = get-date
write-output "$UFORMATTEDDATE ---$($SNAPP.LocalizedDisplayName) : Begin Collection and Deployment Check---" | out-file $LOGPATH -Append -Force -NoClobber

$iVar1 = checkForInstallCollection -AppName $SNAPP.LocalizedDisplayName
if (!$iVar1) {
        $ICOLLNAME = $SNAPP.LocalizedDisplayName + " SN-Install"
        $UFORMATTEDDATE = get-date
        write-output "$UFORMATTEDDATE - $ICOLLNAME : Warning. The Install Collection does not exist and is being created." | out-file $LOGPATH -Append -Force -NoClobber


        #Creating the collection and moving the collection to the proper location in the console
        New-CMDeviceCollection -Name $ICOLLNAME -LimitingCollectionName "All Systems" -RefreshType None
        moveCollectionToFolder -CollNameToMove $ICOLLNAME


        #Validate Collection was created
        $iVar2 = checkForInstallCollection -AppName $SNAPP.LocalizedDisplayName
        if (!$iVar2) {
            write-output "$UFORMATTEDDATE - $ICOLLNAME : Error. The Install Collection could not be created. Please check SCCM logs for more details." | out-file $LOGPATH -Append -Force -NoClobber
        }else{
            write-output "$UFORMATTEDDATE - $ICOLLNAME : The Install Collection was created successfully" | out-file $LOGPATH -Append -Force -NoClobber
           
           
            #Deploy Software to collection. Install/Required
            write-output "$UFORMATTEDDATE - $ICOLLNAME : Attempting to deploy the installation in a required state." | out-file $LOGPATH -Append -Force -NoClobber
            DeployApplicationInstall -IAppToDeploy $SNAPP.LocalizedDisplayName -INewCollName $ICOLLNAME
           
           
            #Validate the deployment was created successfully
            $iAPPDEP = Get-CMApplicationDeployment | Where-Object { $_.CollectionName -eq $ICOLLNAME }
            if (!$iAPPDEP) {
                write-output "$UFORMATTEDDATE - $ICOLLNAME : Error. The Deployment could not be created. Please check SCCM logs for more details." | out-file $LOGPATH -Append -Force -NoClobber               
            }else{
                write-output "$UFORMATTEDDATE - $ICOLLNAME : The Deployment was created successfully. Please check SCCM console for more details." | out-file $LOGPATH -Append -Force -NoClobber
            }
        }
  
  
    }else{
        $UFORMATTEDDATE = get-date
        write-output "$UFORMATTEDDATE - $($iVar1.Name) : The Collection already exists." | out-file $LOGPATH -Append -Force -NoClobber
    }



$uVar1 = checkForUninstallCollection -AppName $SNAPP.LocalizedDisplayName
if (!$uVar1) {
        $UCOLLNAME = $SNAPP.LocalizedDisplayName + " SN-Uninstall"
        $UFORMATTEDDATE = get-date
        write-output "$UFORMATTEDDATE - $UCOLLNAME : Warning. The Uninstall Collection does not exist and is being created." | out-file $LOGPATH -Append -Force -NoClobber
        #Creating the collection and moving the collection to the proper location in the console
        New-CMDeviceCollection -Name $UCOLLNAME -LimitingCollectionName "All Systems" -RefreshType None
        moveCollectionToFolder -CollNameToMove $UCOLLNAME
        #Validate Collection was created
        $uVar2 = checkForInstallCollection -AppName $SNAPP.LocalizedDisplayName
        if (!$uVar2) {
            write-output "$UFORMATTEDDATE - $UCOLLNAME : Error. The Uninstall Collection could not be created. Please check SCCM logs for more details." | out-file $LOGPATH -Append -Force -NoClobber
        }else{
            write-output "$UFORMATTEDDATE - $UCOLLNAME : The Uninstall Collection was created successfully" | out-file $LOGPATH -Append -Force -NoClobber
            #Deploy Software to collection. Uninstall/Required
            write-output "$UFORMATTEDDATE - $UCOLLNAME : Attempting to deploy the uninstall in a required state." | out-file $LOGPATH -Append -Force -NoClobber
            DeployApplicationUninstall -UAppToDeploy $SNAPP.LocalizedDisplayName -UNewCollName $UCOLLNAME
            #Validate the deployment was created successfully
            $uAPPDEP = Get-CMApplicationDeployment | Where-Object { $_.CollectionName -eq $UCOLLNAME }
            if (!$uAPPDEP) {
                write-output "$UFORMATTEDDATE - $UCOLLNAME : Error. The Deployment could not be created. Please check SCCM logs for more details." | out-file $LOGPATH -Append -Force -NoClobber               
            }else{
                write-output "$UFORMATTEDDATE - $UCOLLNAME : The Deployment was created successfully. Please check SCCM console for more details." | out-file $LOGPATH -Append -Force -NoClobber
            }
        }
    }else{
        $UFORMATTEDDATE = get-date
        write-output "$UFORMATTEDDATE - $($uVar1.Name) : The Collection already exists." | out-file $LOGPATH -Append -Force -NoClobber
    }
}


    $DPLIST = Get-CMDistributionPoint
    foreach ($DP in $DPLIST) {
    $DP.NetworkOSPath.trimstart('\\')
    }

#Functions

Function checkForInstallCollection{
Param ($AppName)
    Get-CMDeviceCollection -Name "*$AppName*SN-Install"
}

Function checkForUninstallCollection{
Param ($AppName)
    Get-CMDeviceCollection -Name "*$AppName*SN-Uninstall"
}

Function DeployApplicationInstall{
Param ($IAppToDeploy, $INewCollName)
    $CMAPPI = Get-CMApplication -Name $IAppToDeploy
    $CMCOLLI = Get-CMDeviceCollection -Name $INewCollName
    New-CMApplicationDeployment -InputObject $CMAPPI -DeployAction Install -DeployPurpose Required -Collection $CMCOLLI
}

Function DeployApplicationUninstall{
Param ($UAppToDeploy, $UNewCollName)
    $CMAPPU = Get-CMApplication -Name $UAppToDeploy
    $CMCOLLU = Get-CMDeviceCollection -Name $UNewCollName
    New-CMApplicationDeployment -InputObject $CMAPPU -DeployAction Uninstall -DeployPurpose Required -Collection $CMCOLLU
}

Function checkForContentDistribution{
Param ($AppNameToCheck, $DPName)
        Get-CMDeploymentPackage -DistributionPointName $DPName -DeploymentPackageName $AppNameToCheck
}

Function moveCollectionToFolder{
Param ($CollNameToMove)
    $GetCMColl = Get-CMDeviceCollection -Name $CollNameToMove
    Move-CMObject -InputObject $GetCMColl -FolderPath $SNCMDIR
}