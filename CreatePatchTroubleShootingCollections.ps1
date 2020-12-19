

##########################################################################
## Script to create collections for Software Update installation errors ##
##########################################################################

<#

Find SUP error codes in your environment (SQL):

"
Select Count(ResourceID),LastEnforcementErrorCode
from vSMS_SUMDeploymentStatusPerAsset 
where StatusType in (4,5)
and LastEnforcementErrorCode is not null
Group by LastEnforcementErrorCode
"

#>

###############
## VARIABLES ##
###############

# Limiting collection
$LimitingCollection = "All Systems"

# Folders to place the collections in (must exist)
$ErrorFolder = "Devicecollection\SUP\SUP Errors\Enforcement State Error"
$UnknownFolder = "Devicecollection\SUP\SUP Errors\Enforcement State Unknown"

# Error Code Translation table
$ErrorCodes = @{
    0 = 'Success'
    -2016409844	= 'Software update execution timeout'
    -2016409966	= 'Group policy conflict'
    -2016410008	= 'Software update still detected as actionable after apply'
    -2016410012	= 'Updates handler job was cancelled'
    -2016410026	= 'Updates handler was unable to continue due to some generic internal error'
    -2016410031	= 'Post install scan failed'
    -2016410032	= 'Pre install scan failed'
    -2016410855	= 'Unknown error'
    -2016411012	= 'CI documents download timed out'
    -2016411115	= 'Item not found'
	-2145107951	= 'WUServer policy value is missing in the registry.'
    -2145120257	= 'An operation failed due to reasons not covered by another error code.'
    -2145123272	= 'There is no route or network connectivity to the endpoint.'
	-2145124320	= 'Operation did not complete because there is no logged-on interactive user.'
    -2145124341	= 'Operation was cancelled.'
	-2146498304	= 'Unknown error'
	-2146762496	= 'No signature was present in the subject.'
    -2146889721	= 'The hash value is not correct.'
    -2147010798	= 'The component store has been corrupted.'
	-2147010815	= 'The referenced assembly could not be found.'
	-2147010893	= 'The referenced assembly is not installed on your system.'
	-2147018095	= 'Transaction support within the specified resource manager is not started or was shut down due to an error.'
	-2147021879	= 'The requested operation failed. A system reboot is required to roll back changes made.'
	-2147023436	= 'This operation returned because the timeout period expired.'
	-2147023728	= 'Element not found.'
	-2147023890	= 'The volume for a file has been externally altered so that the opened file is no longer valid.'
	-2147024598	= 'Too many posts were made to a semaphore.'
	-2147024784	= 'There is not enough space on the disk.'
	-2147217865	= 'Unknown error'
	-2147467259	= 'Unspecified error'
	-2147467260	= 'Operation aborted'
}


#################
## MAIN SCRIPT ##
#################

# Import ConfigMgr Module
Import-Module $env:SMS_ADMIN_UI_PATH.Replace('i386','ConfigurationManager.psd1')
$SiteCode = (Get-PSDrive -PSProvider CMSITE).Name
Set-Location ("$SiteCode" + ":")

# Create collections for each error code in the error code table
Foreach ($ErrorCode in $ErrorCodes.Keys)
{
    ## Create collections for the "error" enforcement state
    # Set Target folder location
    $TargetFolder = "$SiteCode" + ":\" + $ErrorFolder

    # Set WQL Queries
    $Query = "select SYS.ResourceID,SYS.ResourceType,SYS.Name,SYS.SMSUniqueIdentifier,SYS.ResourceDomainORWorkgroup,SYS.Client from SMS_R_System as SYS Inner Join SMS_SUMDeploymentAssetDetails as SUM on SYS.ResourceID = SUM.ResourceID  WHERE SUM.StatusType = 5 and SUM.LastEnforcementErrorCode = $ErrorCode"

    # Create Collection
    Write-host "Creating collection: '[Enforcement State: Error] Code $ErrorCode"
    $Collection = New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name "[Enforcement State: Error] Code $ErrorCode" -Comment "$($ErrorCodes[$ErrorCode])" -RefreshType Periodic -RefreshSchedule (Convert-CMSchedule -ScheduleString "920A8C0000100008")
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Collection.Name -QueryExpression $Query -RuleName "$($Collection.Name)"
    $Collection | Move-CMObject -FolderPath $TargetFolder  

    ## Create collections for the "unknown" enforcement state
    # Set Target folder location
    $TargetFolder = "$SiteCode" + ":\" + $UnknownFolder

    # Set WQL Queries
    $Query = "select SYS.ResourceID,SYS.ResourceType,SYS.Name,SYS.SMSUniqueIdentifier,SYS.ResourceDomainORWorkgroup,SYS.Client from SMS_R_System as SYS Inner Join SMS_SUMDeploymentAssetDetails as SUM on SYS.ResourceID = SUM.ResourceID  WHERE SUM.StatusType = 4 and SUM.LastEnforcementErrorCode = $ErrorCode"

    # Create Collection
    Write-host "Creating collection: '[Enforcement State: Unknown] Code $ErrorCode"
    $Collection = New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name "[Enforcement State: Unknown] Code $ErrorCode" -Comment "$($ErrorCodes[$ErrorCode])" -RefreshType Periodic -RefreshSchedule (Convert-CMSchedule -ScheduleString "920A8C0000100008")
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Collection.Name -QueryExpression $Query -RuleName "$($Collection.Name)"
    $Collection | Move-CMObject -FolderPath $TargetFolder  
}