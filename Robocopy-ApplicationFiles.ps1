$Directories = Import-Csv C:\Users\pcampbel\Desktop\ApplicationImport.csv

$Directories | ForEach-Object {
    $oldDir = "\\na\altiris-master\packages\" + $_.Name
    $newDir = "\\az-ncus-cm1\sourcefiles$\Software\" + $_.Name
    $pathToLog = "C:\PackageMigration\"+$_.Name+"_ROBOCOPYstatus.txt"
    Robocopy /e /ipg:3 /z /r:3 /w:3 /tee /LOG+:$pathToLog $oldDir $newDir
}