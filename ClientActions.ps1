<#
Written by Ryan Ephgrave for ConfigMgr 2012 PS Right Click Tools
http://myitforum.com/myitforumwp/author/ryan2065/
#>

#Get Arguments
$strCompName = $args[0]
$strAction = $args[1]
$strActionName = $args[2]
$objpopup = new-object -comobject wscript.shell

If (test-connection -computername $strCompName -count 1 -quiet){
	$Error.Clear()
	$WMIPath = "\\" + $strCompName + "\root\ccm:SMS_Client"
	$SMSwmi = [wmiclass] $WMIPath
	[Void]$SMSwmi.TriggerSchedule($strAction)
	if($Error[0]){$actualpopup = $objpopup.popup(“Error triggering $strActionName on $strCompName“,0,”Results”,16)}
	else{$actualpopup = $objpopup.popup(“Successfully triggered $strActionName on $strCompName“,0,”Results”,0)}
}
else {$actualpopup = $objpopup.popup(“$strCompName is not on“,0,”Results”,16)}