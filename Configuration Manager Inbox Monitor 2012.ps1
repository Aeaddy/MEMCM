# SCCM Inbox Monitor
# Created by Greg Allen 2012

# Variables for Script
Write-Host "SCCM Inbox Monitor" -ForegroundColor White
$server = Read-Host "Server Name? "
$site = Read-Host "Site Code?"
$SCCMInboxesDir = "\\$server\sms_$site\inboxes"
$basethreshold = "0"
$safethreshhold = Read-Host "Alert Threshhold?"
$loop = "True"

#Loop-it
Do {
    cls
    #Engine
    Write-Host "SCCM Site Server: $server" -ForegroundColor White
    Write-Host "SCCM Inbox Path: $SCCMInboxesDir" -ForegroundColor White
    $items = Get-ChildItem -Name $SCCMInboxesDir | Where {!$_.PSIsContainer}
    foreach ($item in $items) {
        $ifolders = "$SCCMInboxesDir\$item"
        $numbers = Get-ChildItem $ifolders -Recurse | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -Property length -Sum
        $tnumber = $numbers.count
        $totalSize = "{0:N2}" -f ($numbers.sum / 1MB)
        IF ($tnumber -lt $safethreshhold)
            {
              Write-Host("-"*60) -ForegroundColor White
    		  # Write-Host 
              If ($tnumber -le $basethreshold)
                {
                    Write-Host "InboxFolder:" $item "\" "ItemCount:" $basethreshold -ForegroundColor Green
                }
              ELSE
                {
                    Write-Host "InboxFolder:" $item "\" "ItemCount:" $tnumber -ForegroundColor Green
                }         
            }
        ELSE
            {
              Write-Host("-"*60) -ForegroundColor White
              Write-Host "InboxFolder:" $item "\" "ItemCount:" $tnumber -ForegroundColor Red
            }
        Remove-Variable TotalSize, Tnumber
        }

#Kick to Do        
Start-Sleep -s 300
} 
until ($Loop -eq "False")

    