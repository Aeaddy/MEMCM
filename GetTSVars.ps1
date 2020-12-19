# Determine where to do the logging 
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
$logPath = $tsenv.Value("_SMSTSLogPath") 
$logFile = "$logPath\TaskSequenceVariables.log" 

# Start the logging 
Start-Transcript $logFile 

# Write all the variables and their values 
$tsenv.GetVariables() | % { Write-Host "$_ = $($tsenv.Value($_))" } 

# Stop logging 
Stop-Transcript 
