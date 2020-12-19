﻿[Threading.Thread]::CurrentThread.CurrentCulture = 'en-US'
$XLSX = New-Object -ComObject "Excel.Application"
$XLSX.Visible = $True
$NewWorkBook = $XLSX.Workbooks.Add()
$Sheet1 = $NewWorkBook.WorkSheets.item(1)
$Cells = $Sheet1.Cells
 
$Row = 1
    $Cells.Item($Row,1) = "Boundary ID"
        $Cells.item($Row,1).Font.Bold = $True
    $Cells.Item($Row,2) = "Boundary Type"
        $Cells.item($Row,2).Font.Bold = $True
    $Cells.Item($Row,3) = "Created By"
        $Cells.item($Row,3).Font.Bold = $True
    $Cells.Item($Row,4) = "Display Name"
        $Cells.item($Row,4).Font.Bold = $True
    $Cells.Item($Row,5) = "Group Count"
        $Cells.item($Row,5).Font.Bold = $True
    $Cells.Item($Row,6) = "Value"
        $Cells.item($Row,6).Font.Bold = $True
$Row++
 
$BoundaryQuery = Get-WmiObject -Namespace "Root\SMS\Site_BHS" -Class SMS_Boundary -ComputerName BSCFGCASP01.bhs.org
 
foreach($item in $BoundaryQuery)
{
    Switch($item.BoundaryType)
    {
        0 {$Type = "IP Subnet"}
        1 {$Type = "Active Directory Site"}
        2 {$Type = "IPv6"}
        3 {$Type = "Ip Address Range"}
    }
    $Cells.Item($Row,1) = $item.BoundaryID
    $Cells.Item($Row,2) = $Type
    $Cells.Item($Row,3) = $item.CreatedBy
    $Cells.Item($Row,4) = $item.DisplayName
    $Cells.Item($Row,5) = $item.GroupCount
    $Cells.Item($Row,6) = $item.Value
    $Row++
}
 
$Cells.EntireColumn.AutoFit() 
