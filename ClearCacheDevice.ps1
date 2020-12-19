<#
Written by Ryan Ephgrave for ConfigMgr 2012 PS Right Click Tools
http://myitforum.com/myitforumwp/author/ryan2065/
#>

$CompName = $args[0]
$Popup = New-Object -ComObject wscript.shell
$msg = "Do you really want to clear the cache on $CompName"
$PopupAnswer = $Popup.popup($msg,0,"Are you sure?",1)
if ($PopupAnswer -eq 1){
			
	If (test-connection -computername $CompName -count 1 -quiet) {
		$psexecarguments = @()
		$psexecarguments += @("\\$CompName")
		$psexecarguments += @("wscript.exe")
		$psexecarguments += @("`"\\$CompName\Admin$\ClearClientCache.vbs`"")
		$psexeccmd = "C:\Program Files\SCCMConsoleExtensions\pstools\psexec.exe"
		Copy-Item "C:\Program Files\SCCMConsoleExtensions\clearClientCache.vbs" "\\$CompName\ADMIN$\"
		&  $psexeccmd $psexecarguments
		Remove-Item "\\$CompName\Admin$\ClearClientCache.vbs" -Force
		$checkcache = $null
		$strQuery = "select * from CacheInfoEx"
		$objCacheCheck = Get-WmiObject -Namespace root\ccm\SoftMgmtAgent -Query $strQuery -ComputerName $CompName
		foreach ($instance in $objCacheCheck){$checkcache = $instance.CacheID}
		if ($checkcache -ne $null){$Popup.popup("Could not clear the cache on $CompName",0,"Error",0)}
		Else {$Popup.popup("Successfully cleared the cache on $CompName",0,"Successful",0)}}
	Else {$Popup.popup("$CompName is not on",0,"Not On",0)}
}
