#Load Configuration Manager PowerShell Module
Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0, $Env:SMS_ADMIN_UI_PATH.Length - 5) + '\ConfigurationManager.psd1')
#Get SiteCode
$SiteCode = Get-PSDrive -PSProvider CMSITE
Set-location $SiteCode":"

$Boundaries = Get-CMBoundary
$BoundaryNames = Get-CMBoundary | SELECT DisplayName

$seperator = '/'
$options = [System.StringSplitOptions]::RemoveEmptyEntries

#Create Boundary Groups for any boundary groups that do not exist
Write-Output "Updating Boundary Groups..."

foreach ($boundary in $Boundaries) {
 $boundaryname = $boundary.DisplayName
 #Write-Output "Boundary Name is : $boundaryname"
 $boundarydata = $boundary.DisplayName.Split($seperator, 3, $options)
 #Write-Output "Boundary data domain is : $($boundarydata[0])"
 #Write-Output "Boundary data site name is: $($boundarydata[1])"
 #Write-Output "Boundary data extra is: $($boundarydata[2])"

 $boundarysite = $boundarydata[1]
 #Check if Boundary Group exists in DB
 #Write-Output "Checking if $boundarysite boundary group exists in DB"
 if (!(Get-CMBoundaryGroup | WHERE { $_.Name -like $boundarysite })) {
  Write-Output "Boundary Group $boundarysite does not exist, creating"
  New-CMBoundaryGroup -Name $boundarysite -Description "Scripted site for $boundarysite" -DefaultSiteCode $SiteCode -ErrorAction SilentlyContinue | Out-Null
 } else {
  #Boundary Group Exists already, skip creation
  Write-Output "Boundary Group $boundarysite already exists, skipping"
 }
}

#Update all Boundary Groups with appropriate Boundaries (note we only add, we don't remove
$boundarygroups = Get-CMBoundaryGroup
foreach($group in $boundarygroups) {
 $boundarysite = $group.Name 
 $Boundaries = Get-CMBoundary | WHERE {$_.DisplayName -like "*/$boundarysite/*"}
 Write-Host "Boundary Group is: $boundarysite"
 foreach ($boundary in $boundaries) {
  Write-Host "Adding $($boundary.DisplayName) to $($group.Name)"
  Write-host "-----"
  Write-Host $boundary
  Write-Host "-----"
  Write-Host $group
  Add-CMBoundaryToGroup -InputObject $boundary -BoundaryGroupInputObject $group
 }
}