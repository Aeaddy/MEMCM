Get-WmiObject -Namespace "root\SMS\Site_KIS" -Query "Select * from SMS_Collection" | 
Select-Object -Property Name, CollectionID | 
Export-Csv C:\Collections.csv -NoTypeInformation
