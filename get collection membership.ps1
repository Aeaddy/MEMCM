#(get-command Get-CollectionMember).ScriptBlock
Param($CollName)
$SiteCode="KIS"
$SCCMServer="kisd-sccm-12"

# Get a list of collections and find the object to build the collection list.
$Collection = Get-WmiObject -ComputerName $SCCMServer  -Namespace `
"root\sms\site_$SiteCode" -Class 'SMS_Collection'
$MyCollection = $Collection | Where-Object { $_.Name -eq $CollName }
# Grab the Resource ID of the collection
$MyCollectionMembers = Get-WmiObject  -ComputerName $SCCMServer -Namespace `
"root\sms\site_$SiteCode"  -Query "select * from SMS_CM_RES_COLL_$($MyCollection.CollectionID)"
#Echo member of the collections to screen
Foreach ($member in $MyCollectionMembers) {
   $oldErrCount = $error.Count
  $Name = $member.Name.ToString()
$Name
  }