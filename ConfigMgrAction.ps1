<#
Written by Ryan Ephgrave for ConfigMgr 2012 Right Click Tools
http://myitforum.com/myitforumwp/author/ryan2065/
#>

$CompName = $args[0]
$strAction = $args[1]

$Popup = new-object -comobject wscript.shell

<#
InstallLog
ClientLog
ConnectC
ManageComp
#>

if (Test-Connection -computername $CompName -count 1 -quiet){
	if ($strAction -eq "InstallLog"){
		Get-WmiObject -ComputerName $CompName -Class Win32_OperatingSystem | ForEach-Object {$WindowsDirectory = $_.WindowsDirectory}
		$RemoteCompDirPath = "\\" + $CompName + "\C$"
		$WindowsDirectory = $WindowsDirectory.replace("C:",$RemoteCompDirPath)
		$TestPath1 = $WindowsDirectory + "\ccmsetup"
		$TestPath2 = $WindowsDirectory + "\System32\ccmsetup"
		$TestPath3 = $WindowsDirectory + "\syswow64\ccmsetup"
		if (Test-Path $TestPath1){$CCMSetup = $TestPath1}
		elseif (Test-Path $TestPath2){$CCMSetup = $TestPath2}
		elseif (Test-Path $TestPath3){$CCMSetup = $TestPath3}
		else {
			$Popup.Popup("Error, could not find client install log folder on $CompName",0,"Error",16)
			break
		}
		explorer $CCMSetup
	}
	elseif ($strAction -eq "ClientLog"){
		Get-WmiObject -ComputerName $CompName -Class Win32_OperatingSystem | ForEach-Object {$WindowsDirectory = $_.WindowsDirectory}
		$RemoteCompDirPath = "\\" + $CompName + "\C$"
		$WindowsDirectory = $WindowsDirectory.replace("C:",$RemoteCompDirPath)
		$TestPath1 = $WindowsDirectory + "\CCM\Logs"
		$TestPath2 = $WindowsDirectory + "\System32\CCM\Logs"
		$TestPath3 = $WindowsDirectory + "\syswow64\CCM\Logs"
		if (Test-Path $TestPath1){$CCMLogs = $TestPath1}
		elseif (Test-Path $TestPath2){$CCMLogs = $TestPath2}
		elseif (Test-Path $TestPath3){$CCMLogs = $TestPath3}
		else {
			$Popup.Popup("Error, could not find client log folder on $CompName",0,"Error",16)
			break
		}
		explorer $CCMLogs
	}
	elseif ($strAction -eq "ConnectC"){
		$Path = "\\" + $CompName + "\c$"
		explorer $Path
	}
	Elseif ($strAction -eq "ManageComp"){& compmgmt.msc -s /computer:\\$CompName}
}
else {$Popup.Popup("Error, cannot ping $CompName",0,"Error",16)}