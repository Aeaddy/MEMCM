PARAM(
    [Parameter(Mandatory = $true, HelpMessage = "Enter the SMS Provider computer name")] $smsprovider,
    [Parameter(Mandatory = $false, HelpMessage = "Number of Days for HealthCheck")] $NumberofDays = 7,
	[Parameter(Mandatory = $false, HelpMessage = "HealthCheck query file name")] $healthcheckfilename = 'cm12R2healthcheck.xml',
	[Parameter(Mandatory = $false, HelpMessage = "Debug mode?")] $healthcheckdebug = $true
)
$FormatEnumerationLimit = -1
$currentFolder = $PWD.Path
if ($currentFolder.substring($currentFolder.length-1) -ne '\') { $currentFolder+= '\' }

$logFolder = $currentFolder + "_Logs\"
$reportFolder = $currentFolder + (Get-Date -uformat "%Y-%m-%d") + "\" + $smsprovider + "\"

$component = ($MyInvocation.MyCommand.Name -replace '.ps1', '')
$logfile = $logFolder + $component + ".log"
$Error.Clear()
$bLogValidation = $false

#####START FUNCTIONS#####
function Test-Powershell
{
    PARAM(
        [int]$version = 4
    )
    return ($PSVersionTable.psversion.Major -ge $version)
}

function Test-Powershell64bit
{
    return ([IntPtr]::size -eq 8)
}

function Set-ReplaceString
{
    PARAM(
	    [string]$value,
	    [string]$SiteCode,
	    $NumberOfDays = "",
		[string]$servername = "",
		[bool]$space = $true
	)
	
	$return = $value
    $date = Get-Date
	
	if ($space)
	{	
		$return = $return -replace "\r\n", " " 
		$return = $return -replace "\r", " " 
		$return = $return -replace "\n", " " 
		$return = $return -replace "\s", " " 
		$return = $return -replace "\s{2}\b"," "
	}
	$return = $return -replace "@@SITECODE@@",$SiteCode
	$return = $return -replace "@@STARTMONTH@@",$date.tostring("01/MM/yyyy")
	$return = $return -replace "@@TODAYMORNING@@",$date.tostring("yyyy/MM/dd")
	$return = $return -replace "@@NUMBEROFDAYS@@",$NumberOfDays
	$return = $return -replace "@@SERVERNAME@@",$ServerName

	if ($space)
	{
		while (($return.indexof("  ") -ge 0)) { $return = $return -replace "  ", " " }
	}
	
	
	return $return
}

Function Write-Log
{
    PARAM(
        [String]$Message,
        [int]$severity = 1,
        [string]$logfile = '',
        [bool]$showmsg = $true
        
    )
    $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"
    $Date= Get-Date -Format "HH:mm:ss.fff"
    $Date2= Get-Date -Format "MM-dd-yyyy"
    $type=1
    
    if (($logfile -ne $null) -and ($logfile -ne ''))
    {    
        "<![LOG[$Message]LOG]!><time=`"$date+$($TimeZoneBias.bias)`" date=`"$date2`" component=`"$component`" context=`"`" type=`"$severity`" thread=`"`" file=`"`">" | Out-File -FilePath $logfile -Append -NoClobber -Encoding default
    }
    
    if ($showmsg -eq $true)
    {
        switch ($severity)
        {
            3 { Write-Host $Message -ForegroundColor Red }
            2 { Write-Host $Message -ForegroundColor Yellow }
            1 { Write-Host $Message }
        }
    }
}

Function Test-Folder
{
    PARAM(
        [String]$Path,
        [bool]$Create = $true
    )
    if (Test-Path -Path $Path) { return $true }
    elseif ($Create -eq $true)
    {
        try
        {
            New-Item ($Path) -type directory -force | out-null
            return $true        	
        }
        catch 
        {
            return $false
        }        
    }
    else { return $false }
}

Function Get-RegistryValue
{
    PARAM(
        [String]$computername,
        [string]$logfile = '' ,
        [string]$keyname,
        [string]$keyvalue,
        [string]$accesstype = 'LocalMachine'
    )
    if ($healthcheckdebug -eq $true) { Write-Log -message "Getting registry value from $($computername), $($accesstype), $($keyname), $($keyvalue)" -logfile $logfile }
    try
    {
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($accesstype, $computername)
        $RegKey= $Reg.OpenSubKey($keyname)
	    if ($RegKey -ne $null) 
	    { 
		    try { $return = $RegKey.GetValue($keyvalue) }
		    catch { $return = $null }
	    }
	    else { $return = $null }
        if ($healthcheckdebug -eq $true) { Write-Log -message "Value returned $return" -logfile $logfile }
    }
    catch
    {
        $return = "ERROR: Unknown"
        $Error.Clear()
    }
    return $return    
}

Function ReportSection
{
    PARAM(
	    $HealthCheckXML,
		[string]$Section,
		$sqlConn,
		[string]$SiteCode,
		$NumberOfDays,
		[string]$logfile,
		[string]$servername,
		$reporttable,
        [boolean]$detailed = $false
	)
	
	Write-Log -message "Starting Secion $section with detailed as $($detailed.ToString())" -logfile $logfile
	
	foreach ($healthCheck in $HealthCheckXML.dtsHealthCheck.HealthCheck)
    {
        if ($healthCheck.IsTextOnly.tolower() -eq 'true') { continue }
        if ($healthCheck.IsActive.tolower() -ne 'true') { continue }
		if ($healthCheck.Section.tolower() -ne $Section) { continue }
		
		$sqlquery = $healthCheck.sqlquery
        $tablename = (Set-ReplaceString -value $healthCheck.XMLFile -sitecode $SiteCode -NumberOfDays $NumberOfDays -servername $servername)
        $xmlTableName = $healthCheck.XMLFile

        if ($Section -eq 5)
        {
            if ($detailed -eq $false)
            { 
                $tablename += "summary" 
                $xmlTableName += "summary"
                $gbfiels = ""
                foreach ($field in $healthCheck.Fields.Field)
	            {
                    if ($field.groupby -in ("2"))
                    {
                        if ($gbfiels.Length -gt 0) { $gbfiels += "," }
                        $gbfiels += $field.FieldName
                    }
                }
                $sqlquery = "select $($gbfiels), count(1) as Total from ($($sqlquery)) tbl group by $($gbfiels)"
            } 
            else 
            { 
                $tablename += "detail"
                $xmlTableName += "detail"
                $sqlquery = $sqlquery -replace "select distinct", "select"
                $sqlquery = $sqlquery -replace "select", "select distinct"
            }
            
        }
    	$filename = $reportFolder + $tablename + '.xml'
		
		$row = $ReportTable.NewRow()
    	$row.TableName = $xmlTableName
    	$row.XMLFile = $tablename + ".xml"
    	$ReportTable.Rows.Add($row)
		
		Write-Log -message ("$tablename Information...Starting") -logfile $logfile
		Write-Log -message ("Type: $($healthCheck.querytype)") -logfile $logfile
		
		switch ($healthCheck.querytype.ToLower())
        {
			'mpconnectivity' { Write-MPConnectivity -filename $filename -tablename $tablename -sitecode $SiteCode -SiteCodeQuery $SiteCodeQuery -NumberOfDays $NumberOfDays -logfile $logfile -type 'mplist' | Out-Null}
			'mpcertconnectivity' { Write-MPConnectivity -filename $filename -tablename $tablename -sitecode $SiteCode -SiteCodeQuery $SiteCodeQuery -NumberOfDays $NumberOfDays -logfile $logfile -type 'mpcert' | Out-Null}

			'sql' { Get-SQLData -sqlConn $sqlConn -SQLQuery $sqlquery -fileName $fileName -tableName $tablename -siteCode $siteCode -NumberOfDays $NumberOfDays -servername $servername -healthcheck $healthCheck -logfile $logfile -section $section -detailed $detailed | Out-Null}
			'baseosinfo' { Write-BaseOSInfo -filename $filename -tablename $tablename -sitecode $SiteCode -NumberOfDays $NumberOfDays -servername $servername -logfile $logfile -continueonerror $true | Out-Null}
			'diskinfo' { Write-DiskInfo -filename $filename -tablename $tablename -sitecode $SiteCode -NumberOfDays $NumberOfDays -servername $servername -logfile $logfile -continueonerror $true | Out-Null}
			'networkinfo' { Write-NetworkInfo -filename $filename -tablename $tablename -sitecode $SiteCode -NumberOfDays $NumberOfDays -servername $servername -logfile $logfile -continueonerror $true | Out-Null}
			'rolesinstalled' { Write-RolesInstalled -filename $filename -tablename $tablename -sitecode $SiteCode -NumberOfDays $NumberOfDays -servername $servername -logfile $logfile | Out-Null}
			'servicestatus' { Write-ServiceStatus -filename $filename -tablename $tablename -sitecode $SiteCode -NumberOfDays $NumberOfDays -servername $servername -logfile $logfile -continueonerror $true | Out-Null}
			#'hotfixstatus' { Write-HotfixStatus -filename $filename -tablename $tablename -sitecode $SiteCode -NumberOfDays $NumberOfDays -servername $servername -logfile $logfile -continueonerror $true | Out-Null}
           	default
            {
            }
        }
		Write-Log -message ("$tablename Information...Done") -logfile $logfile
    }
	Write-Log -message "End Secion $section" -logfile $logfile
}

Function Set-FormatedValue 
{
    PARAM(
	    $value,
	    [string]$format,
		[string]$SiteCode
	)
	switch ($format.tolower())
	{
		'schedule'
		{
			$schedule_Class = [wmiclass]""
			$schedule_class.psbase.path = "\\$($smsprovider)\root\sms\site_$($SiteCodeNamespace):SMS_ScheduleMethods"
			$schedule = ($schedule_class.ReadFromString($value)).TokenData
			if ($schedule.DaySpan -ne 0) { $return = ($schedule.DaySpan * 24 * 60) }
			elseif ($schedule.HourSpan -ne 0) { $return = ($schedule.HourSpan * 60) }
			elseif ($schedule.MinuteSpan -ne 0) { $return = ($schedule.MinuteSpan) }
			return $return
			break
		}
        'alertsname' {
            switch ($value.ToString().ToLower())
            {
                '$databasefreespacewarning' {
                    $return = 'Low free space alert for database on site'
                    break
                }
                '$sumcompliance2updategroupdeploymentname' {
                    $return = 'Low deployment success rate alert of update group'
                    break
                }
                default {
                    $return = $value
                    break
                }
            }
            return $return

            break
        }
        'alertsseverity'
        {
            switch ($value.ToString().ToLower())
            {
                '1' {
                    $return = 'Error'
                    break
                }
                '2' {
                    $return = 'Warning'
                    break
                }
                '3' {
                    $return = 'Informational'
                    break
                }
            }
            return $return
            break
        }
        'alertstypeid'
        {
            switch ($value.ToString().ToLower())
            {
                '12' {
                    $return = 'Update group deployment success'
                    break
                }
                '25' {
                    $return = 'Database free space warning'
                    break
                }
                '31' {
                    $return = 'Malware detection'
                    break
                }
                default {
                    $return = $value
                    break
                }
            }
            return $return
            break
        }
		default
		{
			return $value
			break
		}
	}

}

Function Get-SQLData
{
    PARAM(
	    $sqlConn,
	    [string]$SQLQuery,
	    [string]$fileName,
	    [string]$tableName,
	    [string]$SiteCode,
	    $NumberOfDays,
	    [string]$logfile,
		[string]$servername,
		[bool]$continueonerror = $true,
		$healthCheck,
        $section,
        [boolean]$detailed = $false
	)
    Try{
        $SqlCommand = $sqlConn.CreateCommand()
		
		$logQuery = Set-ReplaceString -value $SQLQuery -sitecode $SiteCode -NumberOfDays $NumberOfDays -servername $servername
		$executionquery = Set-ReplaceString -value $SQLQuery -sitecode $SiteCode -NumberOfDays $NumberOfDays -servername $servername -space $false
		
        if ($healthcheckdebug -eq $true) 
        { 
            Write-Log -message ("SQL Query: $executionquery") -logfile $logfile -showmsg $false
		    Write-Log -message ("SQL Query: $logQuery") 
        } 

        $SqlCommand.CommandTimeOut = 0
        $SqlCommand.CommandText = $executionquery

        $DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $SqlCommand
        $dataset = new-object System.Data.Dataset
        $DataAdapter.Fill($dataset)
		
		if (($dataset.Tables.Count -eq 0) -or ($dataset.Tables[0].Rows.Count -eq 0))
		{ 
			if ($healthcheckdebug -eq $true) { Write-Log -message ("SQL Query returned 0 records") -logfile $logfile }
			Write-Log -message ("Table $tablename is empty skipping writting file $filename ...") -logfile $logfile -severity 2 
		}
		else
		{
			if ($healthcheckdebug -eq $true) { Write-Log -message ("SQL Query returned $($dataset.Tables[0].Rows.Count) records") -logfile $logfile }
			foreach ($field in $healthCheck.Fields.Field)
	        {
                if ($section -eq 5)
                {
                    if (($detailed -eq $true) -and ($field.groupby -notin ('1','2'))) { continue }
                    elseif (($detailed -eq $false) -and ($field.groupby -notin ('2','3'))) { continue }
                }
				if ($field.format -ne "")
				{
					foreach($row in $dataset.Tables[0].Rows)
					{
						$row.$($field.FieldName) = Set-FormatedValue -value $row.$($field.FieldName) -format $field.format -sitecode $SiteCode
					}
				}
			}				
        	, $dataset.Tables[0] | Export-Clixml -Path $filename
		}
    }
    Catch{
        $errorMessage = $Error[0].Exception.Message
        $errorCode = "0x{0:X}" -f $Error[0].Exception.ErrorCode
        if ($continueonerror -eq $false) { Write-Log -message "The following error happen, no futher action taken" -severity 3 -logfile $logfile }
        else { Write-Log -message "The following error happen" -severity 3 -logfile $logfile }
        Write-Log -message "Error $errorCode : $errorMessage connecting to $ComputerName" -logfile $logfile -severity 3
	    $Error.Clear()
        if ($continueonerror -eq $false) { Throw "Error $errorCode : $errorMessage connecting to $ComputerName" }
	}
}

function Create-DataTable
{
    PARAM(
	    [string]$tableName,
	    [String[]] $fields
    )

	$DataTable = New-Object system.Data.DataTable "$tableName"
	foreach($field in $fields)
	{
		$col = New-Object system.Data.DataColumn "$field",([string])
		$DataTable.columns.add($col)
	}
	return ,$DataTable
}

Function Write-BaseOSInfo
{
    PARAM(
	    [string]$fileName,
	    [string]$tableName,
	    [string]$SiteCode,
	    $NumberOfDays,
	    [string]$logfile,
		[string]$servername,
		[bool]$continueonerror = $true
    )
    $WMIOS = Get-RFLWmiObject -class "win32_operatingsystem" -computerName $servername -logfile $logfile -continueonerror $continueonerror
    if ($WMIOS -eq $null) { return }	

    $WMICS = Get-RFLWmiObject -Class "win32_computersystem" -ComputerName $servername -logfile $logfile -continueonerror $continueonerror
	$WMIProcessor = Get-RFLWmiObject -class "Win32_processor" -ComputerName $servername -logfile $logfile -continueonerror $continueonerror
    $WMITimeZone = Get-RFLWmiObject -class "Win32_TimeZone" -ComputerName $servername -logfile $logfile -continueonerror $continueonerror


    ##AV Information
    $avInformation = $null
    $AVArray = @("McAfee Security@McShield", "Symantec Endpoint Protection@symantec antivirus", "Sophos Antivirus@savservice", "Avast!@aveservice", "Avast!@avast! antivirus", "Immunet Protect@immunetprotect", "F-Secure@fsma", "AntiVir@antivirservice", "Avira@avguard", "F-Protect@fpavserver", "Panda Security@pshost", "Panda AntiVirus@pavsrv", "BitDefender@bdss", "ArcaBit/ArcaVir@abmainsv", "IKARUS@ikarus-guardx", "ESET Smart Security@ekrn", "G Data Antivirus@avkproxy", "Kaspersky Lab Antivirus@klblmain", "Symantec VirusBlast@vbservprof", "ClamAV@clamav", "Vipre / GFI managed AV@SBAMSvc", "Norton@navapsvc", "Kaspersky@AVP", "Windows Defender@windefend", "Windows Defender/@MsMpSvc", "Microsoft Security Essentials@msmpeng")

    foreach ($av in $AVArray)
    {
        $info = $av.Split("@")
        if ((Get-ServiceStatus -logfile $logfile -servername $servername -servicename $info[1]).ToString().Tolower().Indexof("error") -lt 0)
        {
            $avInformation = $info[0]
            break
        }
    }

    $OSProcessorArch = $WMIOS.OSArchitecture
    
    if ($OSProcessorArch -ne $null) 
    {
	    switch ($OSProcessorArch.ToUpper() ) 
        {
		    "AMD64" {$ProcessorArchDisplay = "64-bit"}
			"i386" {$ProcessorArchDisplay = "32-bit"}
			"IA64" {$ProcessorArchDisplay = "64-bit - Itanium"}
			default {$ProcessorArchDisplay = $OSProcessorArch }
	    }
	} else { $ProcessorArchDisplay = "" }
    
    $LastBootUpTime = $WMIOS.ConvertToDateTime($WMIOS.LastBootUpTime)
    $LocalDateTime = $WMIOS.ConvertToDateTime($WMIOS.LocalDateTime)
    
    $numProcs = 0
	$ProcessorType = ""
	$ProcessorName = ""
	$ProcessorDisplayName= ""

	foreach ($WMIProc in $WMIProcessor) 
	{
		$ProcessorType = $WMIProc.manufacturer
		switch ($WMIProc.NumberOfCores) 
		{
			1 {$numberOfCores = "single core"}
			2 {$numberOfCores = "dual core"}
			4 {$numberOfCores = "quad core"}
			$null {$numberOfCores = "single core"}
			default { $numberOfCores = $WMIProc.NumberOfCores.ToString() + " core" } 
		}
		
		switch ($WMIProc.Architecture)
		{
			0 {$CpuArchitecture = "x86"}
			1 {$CpuArchitecture = "MIPS"}
			2 {$CpuArchitecture = "Alpha"}
			3 {$CpuArchitecture = "PowerPC"}
			6 {$CpuArchitecture = "Itanium"}
			9 {$CpuArchitecture = "x64"}
		}
		
		if ($ProcessorDisplayName.Length -eq 0) { $ProcessorDisplayName = " " + $numberOfCores + " $CpuArchitecture processor " + $WMIProc.name } 
        else 
        {
			if ($ProcessorName -ne $WMIProc.name) { $ProcessorDisplayName += "/ " + " " + $numberOfCores + " $CpuArchitecture processor " + $WMIProc.name }
		}
		$numProcs += 1
		$ProcessorName = $WMIProc.name
	}
	$ProcessorDisplayName = "$numProcs" + $ProcessorDisplayName

    if ($WMICS.DomainRole -ne $null) 
    {
		switch ($WMICS.DomainRole) {
			0 {$RoleDisplay = "Workstation"}
			1 {$RoleDisplay = "Member Workstation"}
			2 {$RoleDisplay = "Standalone Server"}
			3 {$RoleDisplay = "Member Server"}
			4 {$RoleDisplay = "Backup Domain Controller"}
			5 {$RoleDisplay = "Primary Domain controller"}
            default: {$RoleDisplay = "unknown, $($WMICS.DomainRole)"}
		}
	}
	
	$Fields=@("ComputerName","OperatingSystem","ServicePack","Version","Architecture","LastBootTime","CurrentTime","TotalPhysicalMemory","FreePhysicalMemory","TimeZone","DaylightInEffect","Domain","Role","Model","NumberOfProcessors","NumberOfLogicalProcessors","Processors","AntiMalware")
	$BaseOSInfoTable = Create-DataTable -tablename $tableName -fields $Fields

	$row = $BaseOSInfoTable.NewRow()
	$row.ComputerName = $servername
	$row.OperatingSystem = $WMIOS.Caption
	$row.ServicePack = $WMIOS.CSDVersion
	$row.Version = $WMIOS.Version
	$row.Architecture = $ProcessorArchDisplay
	$row.LastBootTime = $LastBootUpTime.ToString()
	$row.CurrentTime = $LocalDateTime.ToString()
	$row.TotalPhysicalMemory = ([string]([math]::round($($WMIOS.TotalVisibleMemorySize/1MB), 2)) + " GB")
	$row.FreePhysicalMemory = ([string]([math]::round($($WMIOS.FreePhysicalMemory/1MB), 2)) + " GB")
	$row.TimeZone = $WMITimeZone.Description
	$row.DaylightInEffect = $WMICS.DaylightInEffect
	$row.Domain = $WMICS.Domain
	$row.Role = $RoleDisplay
	$row.Model = $WMICS.Model
	$row.NumberOfProcessors = $WMICS.NumberOfProcessors
	$row.NumberOfLogicalProcessors = $WMICS.NumberOfLogicalProcessors
	$row.Processors = $ProcessorDisplayName
	
    if ($avInformation -ne $null) { $row.AntiMalware = $avInformation }
    else { $row.AntiMalware = "AntiMalware software not detected" }
	
    $BaseOSInfoTable.Rows.Add($row)
    , $BaseOSInfoTable | Export-Clixml -Path ($filename)
}

Function Write-DiskInfo
{
    PARAM(
	    [string]$fileName,
	    [string]$tableName,
	    [string]$SiteCode,
	    $NumberOfDays,
	    [string]$logfile,
		[string]$servername,
		[bool]$continueonerror = $true
    )
    $DiskList = Get-RFLWmiObject -class "Win32_LogicalDisk" -filter "DriveType = 3" -ComputerName $servername -logfile $logfile -continueonerror $continueonerror
    if ($DiskList -eq $null) { return }
    
	$Fields=@("DeviceID","Size","FreeSpace","FileSystem")
	$DiskDetails = Create-DataTable -tablename $tableName -fields $Fields

	foreach ($Disk in $DiskList) 
	{
		$row = $DiskDetails.NewRow()
		$row.DeviceID = $Disk.DeviceID
		$row.Size = ([int](($Disk.Size) / 1024 / 1024 / 1024)).ToString()
		$row.FreeSpace = ([int](($Disk.FreeSpace) / 1024 / 1024 / 1024)).ToString()
		$row.FileSystem = $Disk.FileSystem
	    $DiskDetails.Rows.Add($row)
    }
    , $DiskDetails | Export-Clixml -Path ($filename)}

function Write-NetworkInfo
{
    PARAM(
	    [string]$fileName,
	    [string]$tableName,
	    [string]$SiteCode,
	    $NumberOfDays,
	    [string]$logfile,
		[string]$servername,
		[bool]$continueonerror = $true
    )
    
    $IPDetails = Get-RFLWmiObject -class "Win32_NetworkAdapterConfiguration" -filter "IPEnabled = true" -ComputerName $servername -logfile $logfile -continueonerror $continueonerror
    if ($IPDetails -eq $null) { return }

	$Fields=@("IPAddress","DefaultIPGateway","IPSubnet","MACAddress","DHCPEnabled")
	$NetworkInfoTable = Create-DataTable -tablename $tableName -fields $Fields

	foreach ($IPAddress in $IPDetails) 
	{
		$row = $NetworkInfoTable.NewRow()
		$row.IPAddress = ($IPAddress.IPAddress -join ", ")
		$row.DefaultIPGateway = ($IPAddress.DefaultIPGateway -join ", ")
		$row.IPSubnet = ($IPAddress.IPSubnet -join ", ")
		$row.MACAddress = $IPAddress.MACAddress
		if ($IPAddress.DHCPEnable -eq $true) { $row.DHCPEnabled = "TRUE" } else { $row.DHCPEnabled = "FALSE" }
	    $NetworkInfoTable.Rows.Add($row)
    }
    , $NetworkInfoTable | Export-Clixml -Path ($filename)
}

function Write-RolesInstalled
{
    PARAM(
	    [string]$fileName,
	    [string]$tableName,
	    [string]$SiteCode,
	    $NumberOfDays,
	    [string]$logfile,
		[string]$servername,
		[bool]$continueonerror = $true
    )
    $WMISMSListRoles = Get-RFLWMIObject -query "select distinct RoleName from SMS_SCI_SysResUse where NetworkOSPath = '\\\\$Servername'" -computerName $smsprovider -namespace "root\sms\site_$SiteCodeNamespace" -logfile $logfile
    $SMSListRoles = @()
    foreach ($WMIServer in $WMISMSListRoles) { $SMSListRoles += $WMIServer.RoleName }
    $DPProperties = Get-RFLWMIObject -query "select * from SMS_SCI_SysResUse where RoleName = 'SMS Distribution Point' and NetworkOSPath = '\\\\$Servername' and SiteCode = '$SiteCode'" -computerName $smsprovider -namespace "root\sms\site_$SiteCodeNamespace" -logfile $logfile
  
 	$Fields=@("SiteServer", "IIS", "SQLServer", "DP", "PXE", "MultiCast", "PreStaged", "MP", "FSP", "SSRS", "EP", "SUP", "AI", "AWS", "PWS", "SMP", "Console", "Client")
	$RolesInstalledTable = Create-DataTable -tablename $tableName -fields $Fields
	
	$row = $RolesInstalledTable.NewRow()
	$row.SiteServer = ($SMSListRoles -contains 'SMS Site Server').ToString()
	$row.SQLServer = ($SMSListRoles -contains 'SMS SQL Server').ToString()
	$row.DP = ($SMSListRoles -contains 'SMS Distribution Point').ToString()
	if ($DPProperties -eq $null)
	{
		$row.PXE = "False"
		$row.MultiCast = "False"
		$row.PreStaged = "False"
	}
	else
	{
		$row.PXE = (($DPProperties.Props | where {$_.PropertyName -eq "IsPXE"}).Value -eq 1).ToString()
		$row.MultiCast = (($DPProperties.Props | where {$_.PropertyName -eq "IsMulticast"}).Value -eq 1).ToString()
		$row.PreStaged = (($DPProperties.Props | where {$_.PropertyName -eq "PreStagingAllowed"}).Value -eq 1).ToString()
	}
	$row.MP = ($SMSListRoles -contains 'SMS Management Point').ToString()
	$row.FSP = ($SMSListRoles -contains 'SMS Fallback Status Point').ToString()
	$row.SSRS = ($SMSListRoles -contains 'SMS SRS Reporting Point').ToString()
	$row.EP = ($SMSListRoles -contains 'SMS Endpoint Protection Point').ToString()
	$row.SUP = ($SMSListRoles -contains 'SMS Software Update Point').ToString()
	$row.AI = ($SMSListRoles -contains 'AI Update Service Point').ToString()
	$row.AWS = ($SMSListRoles -contains 'SMS Application Web Service').ToString()
	$row.PWS = ($SMSListRoles -contains 'SMS Portal Web Site').ToString()
	$row.SMP = ($SMSListRoles -contains 'SMS State Migration Point').ToString()
	$row.Console = (Test-RegistryExist -computername $servername -logfile $logfile -keyname 'SOFTWARE\\Wow6432Node\\Microsoft\\ConfigMgr10\\AdminUI').ToString()
	$row.Client = (Test-RegistryExist -computername $servername -logfile $logfile -keyname 'SOFTWARE\\Microsoft\\CCM\\CCMExec').ToString()
	$row.IIS = ((Get-RegistryValue -computername $server -logfile $logfile -keyname 'SOFTWARE\\Microsoft\\InetStp' -keyvalue 'InstallPath') -ne $null).ToString()
    $RolesInstalledTable.Rows.Add($row)
 
    , $RolesInstalledTable | Export-Clixml -Path ($filename)
}

Function Get-ServiceStatus
{
	PARAM(
	    $logfile,
		$servername,
		$servicename
    )
	Write-Log -message "Getting service status for $servername, $servicename" -logfile $logfile
    try
    {
	    $service = Get-Service -ComputerName $servername | Where-Object {$_.Name -eq $servicename}
        if ($service -ne $null) { $return = $service.Status }
        else  { $return = "ERROR: Not Found" }
	    Write-Log -message "Service status $return" -logfile $logfile
    }
    catch
    {
        $return = "ERROR: Unknown"
        $Error.Clear()
    }
    return $return
}

function Write-MPConnectivity
{
    PARAM(
	    $fileName,
	    $tableName,
	    $SiteCode,
	    $NumberOfDays,
	    $logfile,
		$type = 'mplist'
    )
 	$Fields=@("ServerName", "HTTPReturn")
	$MPConnectivityTable = Create-DataTable -tablename $tableName -fields $Fields

	$MPList = Get-RFLWMIObject -query "select * from SMS_SCI_SysResUse where SiteCode = '$SiteCode' and RoleName = 'SMS Management Point'" -computerName $smsprovider -namespace "root\sms\site_$SiteCodeNamespace" -logfile $logfile
	foreach ($MPInformation in $MPList)
	{
	    $SSLState = ($MPInformation.Props | where {$_.PropertyName -eq "SslState"}).Value
		$mpname = $MPInformation.NetworkOSPath -replace '\\', ''
	    if ($SSLState -eq 0) 
		{
			$protocol = 'http'
			$port = $HTTPport 
		} 
		else 
		{
			$protocol = 'https'
			$port = $HTTPSport 
		}
	            
		$web = New-Object -ComObject msxml2.xmlhttp
		$url = $protocol + '://' + $mpname + ':' + $port + '/sms_mp/.sms_aut?' + $type
        if ($healthcheckdebug -eq $true) { Write-Log -message ("URL Connection: $url") -logfile $logfile }
		$row = $MPConnectivityTable.NewRow()
		$row.ServerName = $mpname
	    try
	    {   
		    $web.open('GET', $url, $false)
		    $web.send()
			
			$row.HTTPReturn = $web.status
	    }
	    catch
	    {
			$row.HTTPReturn = "313 - Unable to connect to host"
	        $Error.Clear()
	    }
		Write-Log -message ("Status: $($web.status)") -logfile $logfile
		$MPConnectivityTable.Rows.Add($row)
	}
	
    , $MPConnectivityTable | Export-Clixml -Path ($filename)
}

Function Write-HotfixStatus
{
    PARAM(
	    $fileName,
	    $tableName,
	    $SiteCode,
	    $NumberOfDays,
	    $logfile,
		$servername,
		$continueonerror = $true
    )
    Write-Log -message "Connecting to server $servername" -logfile $logfile
    try
    {         
        $Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$servername))
        $Searcher = $Session.CreateUpdateSearcher()
        $historyCount = $Searcher.GetTotalHistoryCount()
        $return = $Searcher.QueryHistory(0, $historyCount) 
        Write-Log -message "Hotfix count: $HistoryCount" -logfile $logfile
    }
    catch
    {
        $errorMessage = $Error[0].Exception.Message
        $errorCode = "0x{0:X}" -f $Error[0].Exception.ErrorCode
        Write-Log -message "The following error happen" -severity 3 -logfile $logfile
        Write-Log -message "Error $errorCode : $errorMessage connecting to $ComputerName" -logfile $logfile -severity 3
	    $Error.Clear()
        return
    }

    $Fields=@("Title", "Date")
	$HotfixTable = Create-DataTable -tablename $tableName -fields $Fields
    foreach ($hotfix in $return)
    {
		$row = $HotfixTable.NewRow()
		$row.Title = $hotfix.Title
        $row.Date = $hotfix.Date
	    $HotfixTable.Rows.Add($row)
    }
	
    , $HotfixTable | Export-Clixml -Path ($filename)
}

function Write-ServiceStatus
{
    PARAM(
	    $fileName,
	    $tableName,
	    $SiteCode,
	    $NumberOfDays,
	    $logfile,
		$servername,
		$continueonerror = $true
    )
	$SiteInformation = Get-RFLWmiObject -query "select Type from SMS_Site where ServerName = '$Server'" -namespace "Root\SMS\Site_$SiteCodeNamespace" -computerName $smsprovider -logfile $logfile
    if ($SiteInformation -ne $null) { $SiteType = $SiteInformation.Type }

    $WMISMSListRoles = Get-RFLWMIObject -query "select distinct RoleName from SMS_SCI_SysResUse where NetworkOSPath = '\\\\$Server'" -computerName $smsprovider -namespace "root\sms\site_$SiteCodeNamespace" -logfile $logfile
    $SMSListRoles = @()
    foreach ($WMIServer in $WMISMSListRoles) { $SMSListRoles += $WMIServer.RoleName }
	Write-Log -message ("Roles discovered: " + $SMSListRoles -join(", ")) -logfile $logfile
	
 	$Fields=@("ServiceName", "Status")
	$ServicesTable = Create-DataTable -tablename $tableName -fields $Fields

    if ($SMSListRoles -contains 'AI Update Service Point')
    {
		$row = $ServicesTable.NewRow()
		$row.ServiceName = "AI_UPDATE_SERVICE_POINT"
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
	    $ServicesTable.Rows.Add($row)
    }

    if (($SMSListRoles -contains 'SMS Application Web Service') -or ($SMSListRoles -contains 'SMS Distribution Point') -or ($SMSListRoles -contains 'SMS Fallback Status Point') -or ($SMSListRoles -contains 'SMS Management Point') -or ($SMSListRoles -contains 'SMS Portal Web Site')  )
    {
		$row = $ServicesTable.NewRow()
		$row.ServiceName = "IISADMIN"
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
	    $ServicesTable.Rows.Add($row)
		
		$row = $ServicesTable.NewRow()
		$row.ServiceName = "W3SVC"
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
	    $ServicesTable.Rows.Add($row)
    }
    
    if ($SMSListRoles -contains 'SMS Component Server')
    {
		$row = $ServicesTable.NewRow()
		$row.ServiceName = "SMS_Executive"
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
	    $ServicesTable.Rows.Add($row)
    }
    
    if ($SMSListRoles -contains 'SMS Site Server')
    {
		$row = $ServicesTable.NewRow()
		$row.ServiceName = "SMS_NOTIFICATION_SERVER"
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
	    $ServicesTable.Rows.Add($row)

		$row = $ServicesTable.NewRow()
		$row.ServiceName = "SMS_SITE_COMPONENT_MANAGER"
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
	    $ServicesTable.Rows.Add($row)
		
		if ($SiteType -ne 1)
		{
			$row = $ServicesTable.NewRow()
			$row.ServiceName = "SMS_SITE_VSS_WRITER"
			$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
		    $ServicesTable.Rows.Add($row)
		}
    }
    
    if ($SMSListRoles -contains 'SMS Software Update Point')
    {
		$row = $ServicesTable.NewRow()
		$row.ServiceName = "WsusService"
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
	    $ServicesTable.Rows.Add($row)
    }
   
    if ($SMSListRoles -contains 'SMS SQL Server')
    {
		$row = $ServicesTable.NewRow()
		if ($SiteType -ne 1)
		{		
			$row.ServiceName = "$SQLServiceName"
		}
		else
		{
			$row.ServiceName = 'MSSQL$CONFIGMGRSEC'
		}
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
		$ServicesTable.Rows.Add($row)

		$row = $ServicesTable.NewRow()
		$row.ServiceName = "SQLWriter"
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
	    $ServicesTable.Rows.Add($row)
    }
    
    if ($SMSListRoles -contains 'SMS SRS Reporting Point')
    {
		$row = $ServicesTable.NewRow()
		$row.ServiceName = "ReportServer"
		$row.Status = (Get-ServiceStatus -logfile $logfile -servername $servername -servicename $row.ServiceName)
	    $ServicesTable.Rows.Add($row)
    }
	
    , $ServicesTable | Export-Clixml -Path ($filename)
}

function Get-RFLCredentials
{
    try
    {
        $cred = Get-Credentials
        if ($healthcheckdebug -eq $true) { Write-Log -message ("Trying username: $($cred.Username)") -logfile $logfile }
        return $cred
    }
    catch
    {
        return $null
    }
}

function Get-RFLWmiObject
{
    PARAM(
        [String]$class,
        [string]$filter = '',
        [string]$query = '',
        [String]$ComputerName,
        [String]$Namespace = "root\cimv2",
        [String]$LogFile,
        [bool]$continueonerror = $false
    )
    if ($query -ne '') { $class = $query }
    if ($healthcheckdebug -eq $true) { Write-Log -message ("WMI Query: \\$ComputerName\$Namespace, $class, filter: $filter") -logfile $logfile }

    if ($query -ne '') { $WMIObject = get-wmiobject -Query $query -Namespace $Namespace -ComputerName $ComputerName -ErrorAction SilentlyContinue }
    elseif ($filter -ne '') { $WMIObject = get-wmiobject -class $class -Filter $filter -namespace $Namespace -ComputerName $ComputerName -ErrorAction SilentlyContinue }
    else { $WMIObject = get-wmiobject -class $class -namespace $Namespace -ComputerName $ComputerName -ErrorAction SilentlyContinue }

	if ($WMIObject -eq $null)
	{
        if ($healthcheckdebug -eq $true) { Write-Log -message ("WMI Query returned 0) records") -logfile $logfile -severity 2 }
	}
	else
	{
		$i = 1
		foreach ($obj in $wmiobj) { i++ }
		if ($healthcheckdebug -eq $true) { Write-Log -message ("WMI Query returned $($i) records") -logfile $logfile }
	}
	
    if ($Error.Count -ne 0) 
    {
        $errorMessage = $Error[0].Exception.Message
        $errorCode = "0x{0:X}" -f $Error[0].Exception.ErrorCode
        if ($continueonerror -eq $false) { Write-Log -message "The following error happen, no futher action taken" -severity 3 -logfile $logfile }
        else { Write-Log -message "The following error happen" -severity 3 -logfile $logfile }
        Write-Log -message "Error $errorCode : $errorMessage connecting to $ComputerName" -logfile $logfile -severity 3
	    $Error.Clear()
        if ($continueonerror -eq $false) { Throw "Error $errorCode : $errorMessage connecting to $ComputerName" }
    }
    
    return $WMIObject
}

Function Get-SQLServerConnection
{
    PARAM(
        [string]$SQLServer,
        [string]$DBName
    )
    if($DBName.Contains("\"))
    {
    $DBSplit = $DBName.Split("\")
    $instance = $DBSplit[0]
    $DBName = $DBSplit[1]
    }
    Try
    {
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Data Source=$SQLServer;Initial Catalog=$DBName;Integrated Security=SSPI;"
        return $conn
    }
    Catch
    {
        $errorMessage = $_.Exception.Message
        $errorCode = "0x{0:X}" -f $_.Exception.ErrorCode
        Write-Log -message "The following error happen, no futher action taken" -severity 3 -logfile $logfile
        Write-Log -message "Error $errorCode : $errorMessage connecting to $ComputerName" -logfile $logfile -severity 3
	    $Error.Clear()
        Throw "Error $errorCode : $errorMessage connecting to $SQLServer"
    }
}

Function Test-RegistryExist
{
    PARAM(
        [String]$computername,
        [string]$logfile = '' ,
        [string]$keyname,
        [string]$accesstype = 'LocalMachine'
    )
	Write-Log -message "Testing registry key from $($computername), $($accesstype), $($keyname)" -logfile $logfile

    try
    {
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($accesstype, $computername)
        $RegKey= $Reg.OpenSubKey($keyname)
        $return = ($RegKey -ne $null)
    }
    catch
    {
        $return = "ERROR: Unknown"
        $Error.Clear()
    }
    return $return
}
#####END FUNCTION#####
try
{
	if (Test-Path -Path $reportFolder)
    {
        Write-Host "Folder $reportFolder already exist, no futher action taken" -ForegroundColor Red
		Exit
    }


    if (Test-Folder -Path $logFolder)
    {
    	try
    	{
        	New-Item ($logFolder + 'Test.log') -type file -force | out-null 
        	Remove-Item ($logFolder + 'Test.log') -force | out-null 
    	}
    	catch
    	{
        	Write-Host "Unable to read/write file on $logFolder folder, no futher action taken" -ForegroundColor Red
        	Exit    
    	}
	}
	else
	{
        Write-Host "Unable to create Log Folder, no futher action taken" -ForegroundColor Red
        Exit
	}
	$bLogValidation = $true

	if (!(Test-Path -Path ($currentFolder + $healthcheckfilename)))
    {
        Write-Host "File $($currentFolder)$($healthcheckfilename) does not exist, no futher action taken" -ForegroundColor Red
		Exit
    }
    else { [xml]$HealthCheckXML = Get-Content ($currentFolder + $healthcheckfilename) }

	if (Test-Folder -Path $reportFolder)
    {
    	try
    	{
        	New-Item ($reportFolder + 'Test.log') -type file -force | out-null 
        	Remove-Item ($reportFolder + 'Test.log') -force | out-null 
    	}
    	catch
    	{
        	Write-Host "Unable to read/write file on $reportFolder folder, no futher action taken" -ForegroundColor Red
        	Exit    
    	}
	}
	else
	{
        Write-Host "Unable to create Log Folder, no futher action taken" -ForegroundColor Red
        Exit
	}
	
	$poshversion = $PSVersionTable.psversion.Major
	
    if (!(Test-Powershell -version 3))
    {
        Write-Log -message "Powershell version ($poshversion) not supported. Minimum version should be 3, no futher action taken" -severity 3 -logfile $logfile
        Exit
    }
    
    if (!(Test-Powershell64bit))
    {
        Write-Log -message "Powershell is not 64bit, no futher action taken" -severity 3 -logfile $logfile
        Exit
    }
 
    Write-Log -message "==========" -logfile $logfile -showmsg $false
    Write-Log -message "Starting HealthCheck" -logfile $logfile
    
    Write-Log -message "Running Powershell version $($PSVersionTable.psversion.Major)" -logfile $logfile
    Write-Log -message "Running Powershell 64 bits" -logfile $logfile
    Write-Log -message "SMS Provider: $smsprovider" -logfile $logfile
        
    $WMISMSProvider = Get-RFLWmiObject -class "SMS_ProviderLocation" -namespace "Root\SMS" -computerName $smsprovider -logfile $logfile
    $SiteCodeNamespace = $WMISMSProvider.SiteCode
	Write-Log -message "Site Code: $SiteCodeNamespace" -logfile $logfile
	
    $WMISMSSite = Get-RFLWmiObject -class "SMS_Site" -namespace "Root\SMS\Site_$SiteCodeNamespace" -Filter "SiteCode = '$SiteCodeNamespace'" -computerName $smsprovider -logfile $logfile
	$SMSSiteServer = $WMISMSSite.ServerName
	Write-Log -message "Site Server: $($WMISMSSite.ServerName)" -logfile $logfile
	Write-Log -message "Site Version: $($WMISMSSite.Version)" -logfile $logfile
	
    $SQLServerName = Get-RegistryValue -computername $SMSSiteServer -logfile $logfile -keyname 'SOFTWARE\\Microsoft\\SMS\\SQL Server\\Site System SQL Account' -keyvalue 'Server'
    $SQLServiceName = Get-RegistryValue -computername $SMSSiteServer -logfile $logfile -keyname 'SOFTWARE\\Microsoft\\SMS\\SQL Server' -keyvalue 'Service Name'
    $SQLPort = Get-RegistryValue -computername $SMSSiteServer -logfile $logfile -keyname 'SOFTWARE\\Microsoft\\SMS\\SQL Server\\Site System SQL Account' -keyvalue 'Port'
    $SQLDBName = Get-RegistryValue -computername $SMSSiteServer -logfile $logfile -keyname 'SOFTWARE\\Microsoft\\SMS\\SQL Server\\Site System SQL Account' -keyvalue 'Database Name'
	
	Write-Log -message ("SQLServerName: $SQLServerName") -logfile $logfile
	Write-Log -message ("SQLServiceName: $SQLServiceName") -logfile $logfile
	Write-Log -message ("SQLPort: $SQLPort") -logfile $logfile
	Write-Log -message ("SQLDBName: $SQLDBName") -logfile $logfile

    $arrServers = @()
    $WMIServers = Get-RFLWMIObject -query "select distinct NetworkOSPath from SMS_SCI_SysResUse where NetworkOSPath not like '%.microsoft.com' and Type in (1,2,4,8)" -computerName $smsprovider -namespace "root\sms\site_$SiteCodeNamespace" -logfile $logfile
    foreach ($WMIServer in $WMIServers) { $arrServers += $WMIServer.NetworkOSPath -replace '\\', '' }
	Write-Log -message ("Servers discovered: " + $arrServers -join(", ")) -logfile $logfile
	
	$Fields=@("TableName", "XMLFile")
	$ReportTable = Create-DataTable -tablename $tableName -fields $Fields

 	$Fields=@("SiteServer", "SQLServer","DBName","SiteCode","NumberOfDays","HealthCheckFileName")
	$ConfigTable = Create-DataTable -tablename $tableName -fields $Fields

	$row = $ConfigTable.NewRow()
    $row.SiteServer = $SMSSiteServer
    $row.SQLServer = $SQLServerName
    $row.DBName = $SQLDBName
    $row.SiteCode = $SiteCodeNamespace
    $row.NumberOfDays = [System.Convert]::ToInt32($NumberOfDays)
    $row.HealthCheckFileName = $HealthCheckFileName

    $ConfigTable.Rows.Add($row)
    , $ConfigTable | Export-Clixml -Path ($reportFolder + 'config.xml')
	
    $sqlConn = Get-SQLServerConnection -SQLServer "$SQLServerName,$SQLPort" -DBName $SQLDBName
    $sqlConn.Open()
	
	if ($healthcheckdebug -eq $true) { Write-Log -message ("SQL Query: Creating Functions") -logfile $logfile }
	$functionsSQLQuery = @"
CREATE FUNCTION [fn_CM12R2HealthCheck_ScheduleToMinutes](@Input varchar(16))
RETURNS bigint
AS
BEGIN
	if (ISNULL(@Input, '') <> '')
	begin
		declare @hex varchar(64), @flag char(3), @minute char(6), @hour char(5), @day char(5), @Cnt tinyint, @Len tinyint, @Output bigint, @Output2 bigint = 0
		
		set @hex = @Input

		SET @HEX=REPLACE (@HEX,'0','0000')
		set @hex=replace (@hex,'1','0001')
		set @hex=replace (@hex,'2','0010')
		set @hex=replace (@hex,'3','0011')
		set @hex=replace (@hex,'4','0100')
		set @hex=replace (@hex,'5','0101')
		set @hex=replace (@hex,'6','0110')
		set @hex=replace (@hex,'7','0111')
		set @hex=replace (@hex,'8','1000')
		set @hex=replace (@hex,'9','1001')
		set @hex=replace (@hex,'A','1010')
		set @hex=replace (@hex,'B','1011')
		set @hex=replace (@hex,'C','1100')
		set @hex=replace (@hex,'D','1101')
		set @hex=replace (@hex,'E','1110')
		set @hex=replace (@hex,'F','1111')
		
		select @Flag = SUBSTRING(@hex,43,3), @minute = SUBSTRING(@hex,46,6), @hour = SUBSTRING(@hex,52,5), @day = SUBSTRING(@hex,57,5)

		if (@flag = '010') --SCHED_TOKEN_RECUR_INTERVAL
		BEGIN
			set @Cnt = 1
			set @Len = LEN(@minute)
			set @Output = CAST(SUBSTRING(@minute, @Len, 1) AS bigint)
			 
			WHILE(@Cnt < @Len) BEGIN
			  SET @Output = @Output + POWER(CAST(SUBSTRING(@minute, @Len - @Cnt, 1) * 2 AS bigint), @Cnt)
			  SET @Cnt = @Cnt + 1
			END
			set @Output2 = @Output
			
			set @Cnt = 1
			set @Len = LEN(@hour)
			set @Output = CAST(SUBSTRING(@hour, @Len, 1) AS bigint)
			 
			WHILE(@Cnt < @Len) BEGIN
			  SET @Output = @Output + POWER(CAST(SUBSTRING(@hour, @Len - @Cnt, 1) * 2 AS bigint), @Cnt)
			  SET @Cnt = @Cnt + 1
			END		
			set @Output2 = @Output2 + (@Output*60)
			
			set @Cnt = 1
			set @Len = LEN(@day)
			set @Output = CAST(SUBSTRING(@day, @Len, 1) AS bigint)
			 
			WHILE(@Cnt < @Len) BEGIN
			  SET @Output = @Output + POWER(CAST(SUBSTRING(@day, @Len - @Cnt, 1) * 2 AS bigint), @Cnt)
			  SET @Cnt = @Cnt + 1
			END		
			set @Output2 = @Output2 + (@Output*60*24)
		END
		ELSE
			set @Output2 = -1
	end
	else
			set @Output2 = -2
		
	return @Output2
END
"@
	$SqlCommand = $sqlConn.CreateCommand()
    $SqlCommand.CommandTimeOut = 0
    $SqlCommand.CommandText = $functionsSQLQuery
	try
	{
		$SqlCommand.ExecuteNonQuery() | out-null
	}
	catch
	{
		#
	}
	$SqlCommand = $null

	$arrSites = @()
    $SqlCommand = $sqlConn.CreateCommand()
	
	$executionquery = "select distinct st.SiteCode, (select top 1 srl2.ServerName from v_SystemResourceList srl2 where srl2.RoleName = 'SMS Provider' and srl2.SiteCode = st.SiteCode) as ServerName from v_Site st"
	if ($healthcheckdebug -eq $true) { Write-Log -message ("SQL Query: $executionquery") -logfile $logfile }

    $SqlCommand.CommandTimeOut = 0
    $SqlCommand.CommandText = $executionquery

    $DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $SqlCommand
    $dataset = new-object System.Data.Dataset
    $DataAdapter.Fill($dataset) | Out-Null
	foreach($row in $dataset.Tables[0].Rows) { $arrSites += "$($row.SiteCode)@$($row.ServerName)" }	
	Write-Log -message ("Sites discovered: " + $arrSites -join(", ")) -logfile $logfile
	$SqlCommand = $null		

	##section 1 = information that needs be collected against each site
	foreach ($Site in $arrSites)
    {
		$arrSiteInfo = $Site.split("@")
		$PortInformation = Get-RFLWmiObject -query "select * from SMS_SCI_Component where FileType=2 and ItemName='SMS_MP_CONTROL_MANAGER|SMS Management Point' and ItemType='Component' and SiteCode='$($arrSiteInfo[0])'" -namespace "Root\SMS\Site_$SiteCodeNamespace" -computerName $smsprovider -logfile $logfile
		foreach ($portinfo in $PortInformation)
		{
			$HTTPport = ($portinfo.Props | where {$_.PropertyName -eq "IISPortsList"}).Value1
			$HTTPSport = ($portinfo.Props | where {$_.PropertyName -eq "IISSSLPortsList"}).Value1
		}
		 
		ReportSection -HealthCheckXML $HealthCheckXML -section '1' -sqlConn $sqlConn -siteCode $arrSiteInfo[0] -NumberOfDays $NumberOfDays -servername $arrSiteInfo[1] -ReportTable $ReportTable -logfile $logfile 
	}
	
	##section 2 = information that needs be collected against each computer. should not be site specific. query will run only against the higher site in the hierarchy
    foreach ($server in $arrServers)
    { ReportSection -HealthCheckXML $HealthCheckXML -section '2' -sqlConn $sqlConn -siteCode $SiteCodeNamespace -NumberOfDays $NumberOfDays -servername $server -ReportTable $ReportTable -logfile $logfile }
	
	##section 3 = database analisys information, running on all sql servers in the hierarchy. should not be site specific as it connects to the "master" database
    $DBServers = Get-RFLWMIObject -query "select distinct NetworkOSPath from SMS_SCI_SysResUse where RoleName = 'SMS SQL Server'" -computerName $smsprovider -namespace "root\sms\site_$SiteCodeNamespace" -logfile $logfile
    foreach ($DB in $DBServers) 
	{ 
		$DBServerName = $DB.NetworkOSPath.Replace('\',"") 
		Write-Log -message ("Analysing SQLServer: $DBServerName") -logfile $logfile
		if ($SQLServerName.ToLower() -eq $DBServerName.ToLower()) { $tmpConnection = $sqlConn }
		else
		{
			$tmpConnection = Get-SQLServerConnection -SQLServer "$DBServerName,$SQLPort" -DBName "master"
    		$tmpConnection.Open()
		}
		try
		{
	    	ReportSection -HealthCheckXML $HealthCheckXML -section '3' -sqlConn $tmpConnection -siteCode $SiteCodeNamespace -NumberOfDays $NumberOfDays -servername $DBServerName -ReportTable $ReportTable -logfile $logfile
		}
		finally
		{
			if ($SQLServerName.ToLower() -ne $DBServerName.ToLower()) { $tmpConnection.Close()  }
		}
	}

    ##Section 4 = Database analysis against whole SCCM infrastructure, query will run only against top SQL Server
	ReportSection -HealthCheckXML $HealthCheckXML -section '4' -sqlConn $sqlConn -siteCode $SiteCodeNamespace -NumberOfDays $NumberOfDays -ReportTable $ReportTable -logfile $logfile

    ##Section 5 = summary information against whole SCCM infrastructure. query will run only against the higher site in the hierarchy
	ReportSection -HealthCheckXML $HealthCheckXML -section '5' -sqlConn $sqlConn -siteCode $SiteCodeNamespace -NumberOfDays $NumberOfDays -ReportTable $ReportTable -logfile $logfile
	
	##Section 5 = detailed information against whole SCCM infrastructure. query will run only against the higher site in the hierarchy
	ReportSection -HealthCheckXML $HealthCheckXML -section '5' -sqlConn $sqlConn -siteCode $SiteCodeNamespace -NumberOfDays $NumberOfDays -ReportTable $ReportTable -detailed $true -logfile $logfile

	##Section 6 = troubleshooting information
	ReportSection -HealthCheckXML $HealthCheckXML -section '6' -sqlConn $sqlConn -siteCode $SiteCodeNamespace -NumberOfDays $NumberOfDays -ReportTable $ReportTable -logfile $logfile
}
catch
{
	Write-Log -message "Something bad happen that I don't know about" -severity 3 -logfile $logfile
	Write-Log -message "The following error happen, no futher action taken" -severity 3 -logfile $logfile
    $errorMessage = $Error[0].Exception.Message
    $errorCode = "0x{0:X}" -f $Error[0].Exception.ErrorCode
    Write-Log -message "Error $errorCode : $errorMessage" -logfile $logfile -severity 3
    Write-Log -message "Full Error Message Error $($error[0].ToString())" -logfile $logfile -severity 3
	$Error.Clear()
}
finally
{
    #close sql connection
    if ($sqlConn -ne $null) 
	{ 		
		if ($healthcheckdebug -eq $true) { Write-Log -message ("SQL Query: Deleting Functions") -logfile $logfile }
		$functionsSQLQuery = @"
IF OBJECT_ID (N'fn_CM12R2HealthCheck_ScheduleToMinutes', N'FN') IS NOT NULL
	DROP FUNCTION fn_CM12R2HealthCheck_ScheduleToMinutes;
"@
	  	$SqlCommand = $sqlConn.CreateCommand()
		$SqlCommand.CommandTimeOut = 0
	    $SqlCommand.CommandText = $functionsSQLQuery
		try 
		{
			$SqlCommand.ExecuteNonQuery() | Out-Null 
		}
		catch
		{
			#
		}
		$SqlCommand = $null		

		$sqlConn.Close() 
	}
	if ($ReportTable -ne $null) { , $ReportTable | Export-Clixml -Path ($reportFolder + 'report.xml') }

	if ($bLogValidation -eq $false)
	{
		Write-Host "Ending HealthCheck CollectData"
        Write-Host "==========" 
	}
	else
	{
        Write-Log -message "Ending HealthCheck CollectData" -logfile $logfile
        Write-Log -message "==========" -logfile $logfile
	}
}