#Step 1
Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1")
$SiteCode = Get-PSDrive -PSProvider CMSITE
Set-Location "$($SiteCode.Name):\"

#Step 2
#Where P01 is the CfgMgr PS Drive Code
New-Item -Name 'OSD' -Path 'P01:\DeviceCollection'
New-Item -Name 'Mobile Device Management' -Path 'P01:\DeviceCollection'
New-Item -Name 'Power Management' -Path 'P01:\DeviceCollection'
New-Item -Name 'ViaMonstra' -Path 'P01:\DeviceCollection'
New-Item -Name 'Software Updates' -Path 'P01:\DeviceCollection'
New-Item -Name 'Compliance' -Path 'P01:\DeviceCollection'

#Step 3
New-CMDeviceCollection -Name 'Test 1' -LimitingCollectionName 'All Systems'
New-CMDeviceCollection -Name 'Test 2' -LimitingCollectionName 'All Systems'
New-CMDeviceCollection -Name 'Test 3' -LimitingCollectionName 'All Systems'
New-CMDeviceCollection -Name 'Test 4' -LimitingCollectionName 'All Systems'
New-CMDeviceCollection -Name 'Test 5' -LimitingCollectionName 'All Systems'

#Step 4
$Collection1 = Get-CMDeviceCollection -Name 'Test 1'
$Collection2 = Get-CMDeviceCollection -Name 'Test 2'
$Collection3 = Get-CMDeviceCollection -Name 'Test 3'
$Collection4 = Get-CMDeviceCollection -Name 'Test 4'
$Collection5 = Get-CMDeviceCollection -Name 'Test 5'

#Step 5
Move-CMObject -InputObject $Collection1 -FolderPath 'P01:\DeviceCollection\OSD'
Move-CMObject -InputObject $Collection2 -FolderPath 'P01:\DeviceCollection\Mobile Device Management'
Move-CMObject -InputObject $Collection3 -FolderPath 'P01:\DeviceCollection\Power Management'
Move-CMObject -InputObject $Collection4 -FolderPath 'P01:\DeviceCollection\ViaMonstra'
Move-CMObject -InputObject $Collection5 -FolderPath 'P01:\DeviceCollection\Software Updates'