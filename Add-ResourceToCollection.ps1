#Add-ResourceToCollection

#Script Requires the Execution Policy to be set to Remote Signed. Use following command on CM server (one time): Set-ExecutionPolicy RemoteSigned

#Variables and Objects
#---Change "ITS" to the Site Code. Change on two lines.
$ResourceName = "wn700014"
$CollectionName = "SCCM 2012 Help Files"
$ResourceQuery =  Get-WmiObject -Namespace "Root\SMS\Site_ITS" -Class SMS_R_SYSTEM -Filter "Name = '$ResourceName'"
$CollectionQuery = Get-WmiObject -Namespace "Root\SMS\Site_ITS" -Class SMS_Collection -Filter "Name = '$CollectionName' and CollectionType='2'"

#Create new direct membership rule
#---Change "Localhost" to the SCCM primary sit server name.
#---Change "ITS" to the Site Code.
$NewRule = ([WMIClass]"\\Localhost\root\SMS\Site_ITS:SMS_CollectionRuleDirect").CreateInstance()
$NewRule.ResourceClassName = "SMS_R_System"
$NewRule.ResourceID = $ResourceQuery.ResourceID
$NewRule.Rulename = $ResourceQuery.Name
    
#Commit changes and initiate the collection evaluator                   
$CollectionQuery.AddMemberShipRule($NewRule)
$CollectionQuery.RequestRefresh()

Start-Sleep -s 30

#Refresh Machine Policy on Client
$SCCMClient = [wmiclass] "\\$ResourceName\root\ccm:SMS_Client"

#Run a Machine Policy Evaluation
#$SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000022}") #Trigger Machine Policy Retrieval
$SCCMClient.RequestMachinePolicy()
$SCCMClient.EvaluateMachinePolicy()
$SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000121}") #Trigger Application Deployment Evaluation Cycle 
