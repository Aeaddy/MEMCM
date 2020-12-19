<#
Written by Ryan Ephgrave for ConfigMgr 2012 PS Right Click Tools
http://myitforum.com/myitforumwp/author/ryan2065/
#>

$CompName = $args[0]
$Popup = new-object -comobject wscript.shell

If (test-connection -computername $CompName -count 1 -quiet){

	[Void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic');

	$WMIPath = "\\" + $CompName + "\root\ccm:SMS_Client"
	$SMSwmi = [wmiclass] $WMIPath
	$CurrentSiteCode = $SMSwmi.GetAssignedSite().sSiteCode

	$msg = "Current site code is " + $currentsitecode + "`n Please enter a new site code"

	do {
		$TempString = "New site code for " + $CompName
		$NewSiteCode = [Microsoft.VisualBasic.Interaction]::InputBox($msg,$TempString,"");
		if ($NewSiteCode.length -eq 0) {exit}
		$msg = "Error, site code must be three chracters long `n Current site code: " + $currentsitecode + " `n Please enter a new site code"
	} while ($NewSiteCode.Length -ne 3)

	$Error.Clear()

	$SMSwmi.SetAssignedSite($NewSiteCode)

	if ($Error[0]){
		$TempString = “Error changing site code. You can only change the code to a valid site, please verify " + $NewSiteCode + " exists."
		$Popup.popup($TempString,0,”Error”,16)
	}
	else {
		$TempString = "Successfully changed site code to " + $NewSiteCode
		$Popup.popup($TempString,0,"Successful",0)
		}
}
else {$popup.popup(“$CompName is not on“,0,”Error”,16)}