<#
Written by Ryan Ephgrave for ConfigMgr 2012 PS Right Click Tools
http://myitforum.com/myitforumwp/author/ryan2065/
#>

$CompName = $args[0]
$Popup = new-object -comobject wscript.shell
If (test-connection -computername $CompName -count 1 -quiet){
	$cachesize = Get-WmiObject -ComputerName $CompName -Class CacheConfig -Namespace root\ccm\softmgmtagent
	foreach ($instance in $cachesize) {$CurrentCacheSize = $instance.Size}
	[Void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic');
	do {
		$NewCacheSize = [Microsoft.VisualBasic.Interaction]::InputBox("Current cache size: $CurrentCacheSize MB `n Please enter the new cache size in MB","Change cache size of $CompName","");
		$refnum = 0
		if ($NewCacheSize -ne "" -and [System.Int32]::TryParse($NewCacheSize, [ref]$refnum)){break}
		elseif ($NewCacheSize.length -eq 0){exit}
	} while ($x -ne 1)
	$Error.Clear()
	$count = 0
	$cachesize.Size = "$NewCacheSize"
	$cachesize.Put() | Out-Null
	if ($Error[0]) {$Popup.popup("Error changing cache size...",0,"Error",16)}
	else {$x = $Popup.popup("Successfully changed cache size!",0,"Successful",1)}
}
else {$Popup.popup(“$CompName is not on“,0,”Results”,16)}