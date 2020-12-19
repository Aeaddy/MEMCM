$Path="HKLM:\SOFTWARE\7-Zip"
$value="Path64"
(Get-Item -Path $path).GetValue($value) -ne $null