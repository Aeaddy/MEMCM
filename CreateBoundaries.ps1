Import-Module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

#SCCM Site Code
cd DUS: 

#Define all your boundary group name here:
New-CMBoundaryGroup -Name "Group1"
New-CMBoundaryGroup -Name "Group2"
New-CMBoundaryGroup -Name "Group3"
New-CMBoundaryGroup -Name "Group4"
New-CMBoundaryGroup -Name "Group5" 

#Define the boundary group site server:
Set-CMDistributionPoint -sitecode DUS -SiteSystemServerName DP1.domain.com -AddBoundaryGroupName "Group1"
Set-CMDistributionPoint -sitecode DUS -SiteSystemServerName DP2.domain.com -AddBoundaryGroupName "Group2"
Set-CMDistributionPoint -sitecode DUS -SiteSystemServerName DP3.domain.com -AddBoundaryGroupName "Group3"
Set-CMDistributionPoint -sitecode DUS -SiteSystemServerName DP4.domain.com -AddBoundaryGroupName "Group4"
Set-CMDistributionPoint -sitecode DUS -SiteSystemServerName DP5.domain.com -AddBoundaryGroupName "Group5" 

#Define the boundaries:
$CSVFile = $Args
Import-CSV $CSVFile -Header Name,Type,Value | Foreach-Object {

    New-CMBoundary -Name $_.Name -Type $_.Type -Value $_.Value
	}
 
# This is the format the the CSV file needs to be in.
# Group1,IPSubnet,10.130.136.0/21
# Group2,IPSubnet,10.130.144.0/23
# Group3,IPSubnet,10.130.146.0/24
# Group4,IPSubnet,10.130.147.0/24
# Group5,IPSubnet,10.130.148.0/22