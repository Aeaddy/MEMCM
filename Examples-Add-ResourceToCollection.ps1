#Example 1
$ResourceName = "Server100"
$CollectionName = "OSD Bare Metal"
$ResourceQuery =  Get-WmiObject -Namespace "Root\SMS\Site_PRI" -Class SMS_R_SYSTEM -Filter "Name = '$ResourceName'"
$CollectionQuery = Get-WmiObject -Namespace "Root\SMS\Site_PRI" -Class SMS_Collection -Filter "Name = '$CollectionName' and CollectionType='2'"

#Read Lazy properties
$CollectionQuery.Get()

#Create new direct membership rule
$NewRule = ([WMIClass]"\\Localhost\root\SMS\Site_PRI:SMS_CollectionRuleDirect").CreateInstance()
$NewRule.ResourceClassName = "SMS_R_System"
$NewRule.ResourceID = $ResourceQuery.ResourceID
$NewRule.Rulename = $ResourceQuery.Name

#Commit changes and initiate the collection evaluator 
$CollectionQuery.CollectionRules += $NewRule.psobject.baseobject
$CollectionQuery.Put()
$CollectionQuery.RequestRefresh()

#Example 2
$ResourceName = "Server100"
$CollectionName = "OSD Bare Metal"
$ResourceQuery =  Get-WmiObject -Namespace "Root\SMS\Site_PRI" -Class SMS_R_SYSTEM -Filter "Name = '$ResourceName'"
$CollectionQuery = Get-WmiObject -Namespace "Root\SMS\Site_PRI" -Class SMS_Collection -Filter "Name = '$CollectionName' and CollectionType='2'"

#Create new direct membership rule
$NewRule = ([WMIClass]"\\Localhost\root\SMS\Site_PRI:SMS_CollectionRuleDirect").CreateInstance()
$NewRule.ResourceClassName = "SMS_R_System"
$NewRule.ResourceID = $ResourceQuery.ResourceID
$NewRule.Rulename = $ResourceQuery.Name
    
#Commit changes and initiate the collection evaluator                   
$CollectionQuery.AddMemberShipRule($NewRule)
$CollectionQuery.RequestRefresh()

#Example 3
Function Add-ResourceToCollection
{
    [CmdLetBinding()]
    Param(
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Site Server Site code")]
              $SiteCode,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Site Server Name")]
              $SiteServer,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Collection Name")]
              $CollectionName,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Resource Name")]
              $ResourceName
          )

    $ResourceName = "Server100"
    $CollectionName = "OSD Bare Metal"
    $ResourceQuery =  Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_R_SYSTEM -ComputerName $SiteServer -Filter "Name = '$ResourceName'"
    $CollectionQuery = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name = '$CollectionName' and CollectionType='2'"

    #Read Lazy properties
    $CollectionQuery.Get()

    #Create new direct membership rule
    $NewRule = ([WMIClass]"\\$SiteServer\root\SMS\Site_$($SiteCode):SMS_CollectionRuleDirect").CreateInstance()
    $NewRule.ResourceClassName = "SMS_R_System"
    $NewRule.ResourceID = $ResourceQuery.ResourceID
    $NewRule.Rulename = $ResourceQuery.Name
    
    #Commit changes and initiate the collection evaluator 
    $CollectionQuery.CollectionRules += $NewRule.psobject.baseobject
    $CollectionQuery.Put()
    $CollectionQuery.RequestRefresh()                
}
Add-ResourceToCollection -SiteCode PRI -SiteServer Server100 -CollectionName "OSD Bare Metal" -ResourceName Server100