<#
Author: Adam Eaddy
Company: ITS Partners
Date: 12/01/2020
Email: aeaddy@itsdelivers.com
Purpose: The purpose of the script is to automatically deploy Applications for use with ServiceNow.  This script will identify applications with a specified Category, and
will check for install/uninstall collections.  If they do not exist it will create the collections.  It will also validate that the content is distributed out to at least 1
Distribution Point, and if it is, it will check that the Application is deployed, and deploy it is necessary.
Requirements: The Application must include and Install and Uninstall string, and must be distributed to at least 1 Distribution Point.
/#>


#Set these values to: 
#The name of the SCCM folder to store the ServiceNow device collections.
$SNDIR = 'ServiceNow Software'
#The name of the Category that the Applications will use.
$APPCAT = "ServiceNow"
#The postfix that should be appended to the application name to create the respective collection names. (E.g. "Adobe Acrobat DC" = "Adobe Acrobat DC SN-Install")
$uCollAppend = " SN-Uninstall"
$iCOllAppend = " SN-Install"
#The directory that the logs will be written to. (Please be sure to choose a directory with permissions to write to.)
$LOGDIR = "$env:TEMP\SCCM-SN"
#SCCM Limiting Collection
$LIMITINGCOLL = "All Systems"



#DO NOT MODIFY ANYTHING BELOW THIS LINE.

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

Function GetInstallString{
Param ($AppName)
$CMADT = Get-CMDeploymentType -ApplicationName $AppName
    foreach ($CMADTI in $CMADT) {
        $CD = $CMADTI.SDMPackageXML
        $doc = [xml]$CD
        $doc.AppMgmtDigest.DeploymentType.Installer.InstallAction.Args.Arg[0].'#text'
    }
}

Function GetUninstallString{
Param ($AppName)
$CMADT = Get-CMDeploymentType -ApplicationName $AppName
    foreach ($CMADTI in $CMADT) {
        $CD = $CMADTI.SDMPackageXML
        $doc = [xml]$CD
        $doc.AppMgmtDigest.DeploymentType.Installer.UninstallAction.Args.Arg[0].'#text'
    }
}


#Configure Logging
$FORMATTEDDATE = Get-Date -format "MM-dd-yy"
$UFORMATTEDDATE = get-date
$LOGFILE = "CreateSNAppCollectionsAndDeploy_" + $FORMATTEDDATE + ".log"
$LOGPATH = "$LOGDIR\$LOGFILE"
$LOGTEST = Test-Path $LOGPATH
If ($LOGTEST -eq $false) {
    New-Item -Path $LOGDIR -Name $LOGFILE -Force
}

Write-Output "********Begin Logging $UFORMATTEDDATE********" | out-file $LOGPATH -Append -Force -NoClobber 

#Clear logs older than 6 days
Get-ChildItem $LOGDIR -Recurse -File | Where CreationTime -lt  (Get-Date).AddDays(-6)  | Remove-Item -Force


#Import the ConfigMgr PowerShell module & connect to ConfigMgr PSDrive
$snip = $env:SMS_ADMIN_UI_PATH.Length-5
$modPath = $env:SMS_ADMIN_UI_PATH.Substring(0,$snip)
Import-Module "$modPath\ConfigurationManager.psd1"
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"
$PSD = $($SiteCode.Name)


#Check for SCCM Console Collection Directory.  If it does not exist, create it.
$NEWPATH = $PSD + ':\DeviceCollection\'
$SNCMDIR = $NEWPATH + $SNDIR
$TESTPATH = test-path -Path $SNCMDIR

If ($TESTPATH -eq $false) {
    New-Item -Name $SNDIR -Path $NEWPATH
    $TESTAGAIN = test-path -Path $SNCMDIR
    if ($TESTAGAIN -eq $true) {
        $UFORMATTEDDATE = get-date
        write-output "$UFORMATTEDDATE - The new SCCM Directory was created: $SNCMDIR" | out-file $LOGPATH -Append -Force -NoClobber
        }else{
        $UFORMATTEDDATE = get-date
        write-output "$UFORMATTEDDATE - Error: The new SCCM Directory was not created.  Please troubleshoot manually." | out-file $LOGPATH -Append -Force -NoClobber
        }
}else{
    $UFORMATTEDDATE = get-date
    write-output "$UFORMATTEDDATE - The SCCM Directory already exists: $SNCMDIR" | out-file $LOGPATH -Append -Force -NoClobber
}


#Get list of CM Applications with the defined Category assigned to it.
$SNAPPS = Get-CMApplication | Where-Object { $_.LocalizedCategoryInstanceNames -like $APPCAT }


#Loop through the list of Applications and check for the install and uninstall collections, validate content is distributed, and deploy if applicable. 
foreach ($SNAPP in $SNAPPS) { #1
$UFORMATTEDDATE = get-date
write-output "$UFORMATTEDDATE - $($SNAPP.LocalizedDisplayName) : Begin Collection, Distribution and Deployment Check" | out-file $LOGPATH -Append -Force -NoClobber

    #Validating Content exists on Distribution Points
    $DPLIST = Get-CMDistributionPoint
    $ContentExists = $false
    write-output "$UFORMATTEDDATE - $($SNAPP.LocalizedDisplayName) : Content Validation" | out-file $LOGPATH -Append -Force -NoClobber
    foreach ($DP in $DPLIST) {
        $UFORMATTEDDATE = get-date
            Write-Output "$UFORMATTEDDATE - Checking Distribution Point: $($DP.NetworkOSPath.trimstart('\\')) for the Application: $($SNAPP.LocalizedDisplayName)." | out-file $LOGPATH -Append -Force -NoClobber
        $DPCHECK = checkForContentDistribution -DPName $DP.NetworkOSPath.trimstart('\\') -AppNameToCheck $SNAPP.LocalizedDisplayName
        if ($DPCHECK) {
        $ContentExists = $true
        $UFORMATTEDDATE = get-date
            Write-Output "$UFORMATTEDDATE - The content for Application: $($SNAPP.LocalizedDisplayName) exists on Distribution Point: $($DP.NetworkOSPath.trimstart('\\'))." | out-file $LOGPATH -Append -Force -NoClobber
        }else{
        $UFORMATTEDDATE = get-date
            Write-Output "$UFORMATTEDDATE - Warning!  The content for Application: $($SNAPP.LocalizedDisplayName) does not exist on Distribution Point: $($DP.NetworkOSPath.trimstart('\\'))." | out-file $LOGPATH -Append -Force -NoClobber
        }
    }
    if ($ContentExists -eq $false) {
        $UFORMATTEDDATE = get-date
            Write-Output "$UFORMATTEDDATE - Error! The content for Application: $($SNAPP.LocalizedDisplayName) does not exist on any Distribution Points!  This must be remediated prior to deploying the Application.  Please manually distribute the content. The next time the script is run, the Application will be deployed." | out-file $LOGPATH -Append -Force -NoClobber
    }

    #Validate Install and Uninstall Strings exist in DeploymentType
    $iDeploymentExists = $false
    $UFORMATTEDDATE = get-date
    Write-Output "$UFORMATTEDDATE - Checking for the Install string for: $($SNAPP.LocalizedDisplayName)." | out-file $LOGPATH -Append -Force -NoClobber
    $InstallString = GetInstallString -AppName $SNAPP.LocalizedDisplayName
    if (!$InstallString) {
        $UFORMATTEDDATE = get-date
            write-output "$UFORMATTEDDATE - Warning! There is no Install string provided with this deployment type." | out-file $LOGPATH -Append -Force -NoClobber
    }else{
        $iDeploymentExists = $true
        $UFORMATTEDDATE = get-date
            Write-Output "$UFORMATTEDDATE - The Install string is: $InstallString." | out-file $LOGPATH -Append -Force -NoClobber
    } 
    
    $uDeploymentExists = $false
    $UFORMATTEDDATE = get-date
        Write-Output "$UFORMATTEDDATE - Checking for the Uninstall string for: $($SNAPP.LocalizedDisplayName)." | out-file $LOGPATH -Append -Force -NoClobber
    $UninstallString = GetUninstallString -AppName $SNAPP.LocalizedDisplayName
    if (!$UninstallString) {
        $UFORMATTEDDATE = get-date
            write-output "$UFORMATTEDDATE - Warning! There is no Uninstall string provided with in deployment type for: $($SNAPP.LocalizedDisplayName)." | out-file $LOGPATH -Append -Force -NoClobber
    }else{
        $uDeploymentExists = $true
        $UFORMATTEDDATE = get-date
            Write-Output "$UFORMATTEDDATE - The Uninstall string is: $UninstallString." | out-file $LOGPATH -Append -Force -NoClobber
    } 
    

    #Install Collection
    $iVar1 = checkForInstallCollection -AppName $SNAPP.LocalizedDisplayName
        write-output "$UFORMATTEDDATE - $($SNAPP.LocalizedDisplayName) : Begin Install Collection Validation" | out-file $LOGPATH -Append -Force -NoClobber
    #Check to see if an install collection does NOT exist.
    $ICOLLNAME = $SNAPP.LocalizedDisplayName + $iCollAppend
    if (!$iVar1) { 
        $UFORMATTEDDATE = get-date
        $iCollExists = $false
            write-output "$UFORMATTEDDATE - $ICOLLNAME : Warning. The Install Collection does not exist and is being created." | out-file $LOGPATH -Append -Force -NoClobber


    #Creating the collection and moving the collection to the proper location in the console
        New-CMDeviceCollection -Name $ICOLLNAME -LimitingCollectionName $LIMITINGCOLL -RefreshType None
        moveCollectionToFolder -CollNameToMove $ICOLLNAME


    #Validate Collection was created
        $iVar2 = checkForInstallCollection -AppName $SNAPP.LocalizedDisplayName
        if (!$iVar2) { #3
            $iCollExists = $false
            $UFORMATTEDDATE = get-date
                write-output "$UFORMATTEDDATE - $ICOLLNAME : Error. The Install Collection could not be created. Please check SCCM logs for more details." | out-file $LOGPATH -Append -Force -NoClobber
        }else{
            $iCollExists = $true
            $UFORMATTEDDATE = get-date
                write-output "$UFORMATTEDDATE - $ICOLLNAME : The Install Collection was created successfully." | out-file $LOGPATH -Append -Force -NoClobber
        }   
    
    }else{
        $UFORMATTEDDATE = get-date
        $iCollExists = $true
            write-output "$UFORMATTEDDATE - $($iVar1.Name) : The Collection already exists." | out-file $LOGPATH -Append -Force -NoClobber
    }
    #End of if collection not exist    
    

    #Deploy Software to collection. Install/Required
    if ($ContentExists -eq $true) { 
        
            write-output "$UFORMATTEDDATE - $($SNAPP.LocalizedDisplayName) : Begin Install Deployment Check" | out-file $LOGPATH -Append -Force -NoClobber
        #Check to see if application is deployed to collection
        $iAPPDEPCHECK = Get-CMApplicationDeployment | Where-Object { $_.CollectionName -eq $ICOLLNAME }
        if (!$iAPPDEPCHECK) { 
            $UFORMATTEDDATE = get-date
                write-output "$UFORMATTEDDATE - Warning! A deployment for $ICOLLNAME does not exist. Attempting to deploy the installation in a required state." | out-file $LOGPATH -Append -Force -NoClobber

            #Validate Install string exists
            if ($iDeploymentExists -eq $true) {
                DeployApplicationInstall -IAppToDeploy $SNAPP.LocalizedDisplayName -INewCollName $ICOLLNAME

                #Validate the deployment was created successfully
                $iAPPDEP = Get-CMApplicationDeployment | Where-Object { $_.CollectionName -eq $ICOLLNAME }
                if (!$iAPPDEP) {
                    $UFORMATTEDDATE = get-date
                        write-output "$UFORMATTEDDATE - $ICOLLNAME : Error! The Deployment could not be created. Please check SCCM logs for more details." | out-file $LOGPATH -Append -Force -NoClobber               
                }else{
                    $UFORMATTEDDATE = get-date
                        write-output "$UFORMATTEDDATE - $ICOLLNAME : The Deployment was created successfully. Please check SCCM console for more details." | out-file $LOGPATH -Append -Force -NoClobber
                }
            }else{
                    write-output "$UFORMATTEDDATE - Error! A deployment for $($SNAPP.LocalizedDisplayName) to the collection $ICOLLNAME could not be created. No Install string was found for the application." | out-file $LOGPATH -Append -Force -NoClobber    
            }
        }else{
                write-output "$UFORMATTEDDATE - A deployment for $ICOLLNAME already exists." | out-file $LOGPATH -Append -Force -NoClobber            
        }
   }



    #Uninstall Collection
    $uVar1 = checkForUninstallCollection -AppName $SNAPP.LocalizedDisplayName
    write-output "$UFORMATTEDDATE - $($SNAPP.LocalizedDisplayName) : Begin Uninstall Collection Validation" | out-file $LOGPATH -Append -Force -NoClobber
    #Check to see if an uninstall collection does NOT exist.
    $UCOLLNAME = $SNAPP.LocalizedDisplayName + $UCollAppend
    if (!$uVar1) { 
        $UFORMATTEDDATE = get-date
        $uCollExists = $false
        write-output "$UFORMATTEDDATE - $UCOLLNAME : Warning. The Uninstall Collection does not exist and is being created." | out-file $LOGPATH -Append -Force -NoClobber


    #Creating the collection and moving the collection to the proper location in the console
        New-CMDeviceCollection -Name $UCOLLNAME -LimitingCollectionName $LIMITINGCOLL -RefreshType None
        moveCollectionToFolder -CollNameToMove $UCOLLNAME


    #Validate Collection was created
        $uVar2 = checkForUninstallCollection -AppName $SNAPP.LocalizedDisplayName
        if (!$uVar2) { 
            $uCollExists = $false
            $UFORMATTEDDATE = get-date
            write-output "$UFORMATTEDDATE - $UCOLLNAME : Error. The Install Collection could not be created. Please check SCCM logs for more details." | out-file $LOGPATH -Append -Force -NoClobber
        }else{
            $uCollExists = $true
            $UFORMATTEDDATE = get-date
            write-output "$UFORMATTEDDATE - $UCOLLNAME : The Install Collection was created successfully." | out-file $LOGPATH -Append -Force -NoClobber
        }   
    
    }else{
        $UFORMATTEDDATE = get-date
        $uCollExists = $true
        write-output "$UFORMATTEDDATE - $($uVar1.Name) : The Collection already exists." | out-file $LOGPATH -Append -Force -NoClobber
    }
    #End of if collection not exist    
    

    #Deploy Software to collection. Uninstall/Required
    if ($ContentExists -eq $true) { 
        
        write-output "$UFORMATTEDDATE - $($SNAPP.LocalizedDisplayName) : Begin Uninstall Deployment Check" | out-file $LOGPATH -Append -Force -NoClobber
        #Check to see if application is deployed to collection
        $uAPPDEPCHECK = Get-CMApplicationDeployment | Where-Object { $_.CollectionName -eq $UCOLLNAME }
        if (!$uAPPDEPCHECK) { 
            $UFORMATTEDDATE = get-date
            write-output "$UFORMATTEDDATE - Warning! A deployment for $UCOLLNAME does not exist. Attempting to deploy the installation in a required state." | out-file $LOGPATH -Append -Force -NoClobber
            
            #Validate uninstall string exists
            if ($uDeploymentExists -eq $true) {
                DeployApplicationUninstall -UAppToDeploy $SNAPP.LocalizedDisplayName -UNewCollName $UCOLLNAME
           
                #Validate the deployment was created successfully
                $uAPPDEP = Get-CMApplicationDeployment | Where-Object { $_.CollectionName -eq $UCOLLNAME }
                if (!$uAPPDEP) {
                    $UFORMATTEDDATE = get-date
                    write-output "$UFORMATTEDDATE - $UCOLLNAME : Error! The Deployment could not be created. Please check SCCM logs for more details." | out-file $LOGPATH -Append -Force -NoClobber               
                }else{
                    $UFORMATTEDDATE = get-date
                    write-output "$UFORMATTEDDATE - $UCOLLNAME : The Deployment was created successfully. Please check SCCM console for more details." | out-file $LOGPATH -Append -Force -NoClobber
                }
            }else{
                write-output "$UFORMATTEDDATE - Error! A deployment for $($SNAPP.LocalizedDisplayName) to the collection $UCOLLNAME could not be created. No Install string was found for the application." | out-file $LOGPATH -Append -Force -NoClobber    
            }
        }else{
            write-output "$UFORMATTEDDATE - A deployment for $UCOLLNAME already exists." | out-file $LOGPATH -Append -Force -NoClobber            
        }
   }

}
#1 End of Foreach loop

#End Logging
$UFORMATTEDDATE = get-date
Write-Output "********End Logging $UFORMATTEDDATE********" | out-file $LOGPATH -Append -Force -NoClobber 


