[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Corning New Computer Wizard"
$objForm.Size = New-Object System.Drawing.Size(450,320) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objTextBox.Text;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,230)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$x=$objTextBox.Text;$objForm.Close()})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,230)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(370,20) 
$objLabel.Text = "Please enter the domain\username"
$objForm.Controls.Add($objLabel) 

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,40) 
$objLabel.Size = New-Object System.Drawing.Size(310,20) 
$objLabel.Text = "of the user that will own this device."
$objForm.Controls.Add($objLabel) 

$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Location = New-Object System.Drawing.Size(10,70) 
$objTextBox.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBox) 

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,120) 
$objLabel.Size = New-Object System.Drawing.Size(220,20) 
$objLabel.Text = "Please select a language:"
$objForm.Controls.Add($objLabel) 

$objListBox = New-Object System.Windows.Forms.ListBox 
$objListBox.Location = New-Object System.Drawing.Size(10,140) 
$objListBox.Size = New-Object System.Drawing.Size(260,20) 
$objListBox.Height = 80

[void] $objListBox.Items.Add("English-UnitedStates")
[void] $objListBox.Items.Add("Chinese-Simplified")
[void] $objListBox.Items.Add("Chinese-Traditional")
[void] $objListBox.Items.Add("English-UK")
[void] $objListBox.Items.Add("French")
[void] $objListBox.Items.Add("Danish")
[void] $objListBox.Items.Add("German-Standard")
[void] $objListBox.Items.Add("German-Swiss")
[void] $objListBox.Items.Add("German-Austrian")
[void] $objListBox.Items.Add("Italian-Standard")
[void] $objListBox.Items.Add("Italian-Swiss")
[void] $objListBox.Items.Add("Japanese")
[void] $objListBox.Items.Add("Korean")
[void] $objListBox.Items.Add("Polish")
[void] $objListBox.Items.Add("Russian")
[void] $objListBox.Items.Add("Spanish-ModernSort")
[void] $objListBox.Items.Add("Spanish-Mexican")
[void] $objListBox.Items.Add("Spanish-TraditionalSort")
[void] $objListBox.Items.Add("Spanish-Argentina")
[void] $objListBox.Items.Add("Spanish-Guatemala")
[void] $objListBox.Items.Add("Spanish-CostaRica")
[void] $objListBox.Items.Add("Spanish-Panema")
[void] $objListBox.Items.Add("Spanish-Venezuela")
[void] $objListBox.Items.Add("Spanish-Columbia")
[void] $objListBox.Items.Add("Turkish")

$objForm.Controls.Add($objListBox) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

$x
$NAME=$objTextBox.Text
$LOCATION=$objlistbox.SelectedItem

$ADDOMAIN=$NAME.split('\')[0]
$USERNAME=$NAME.split('\')[1]
$ADSERVER = switch ($ADDOMAIN)     {         ITS {"dc1"}         EMEA {"dc2"}         AP {"dc3"}         default {"dc1"}    }$LOCATION1=$LOCATION$LANGUAGE = switch ($LOCATION)     {     	Chinese-Simplified {"0804:00000804/zh-CN"}
        Chinese-Traditional {"0404:00000404/zh-TW"}
        English-UnitedStates {"0409:00000409/en-US"}
        English-UK {"0809:00000809/en-GB"}
        French {"040c:0000040c/fr-FR"}
        Danish {"0406:00000406/da-DK"}
        German-Standard {"0407:00000407/de-DE"}
        German-Swiss {"0807:00000807/de-DE"}
        German-Austrian {"0c07:00000407/de-DE"}
        Italian-Standard {"0410:00000410/it-IT"}
        Italian-Swiss {"0810:00000410/it-IT"}
        Japanese {"0411:e0010411/ja-JP"}
        Korea {"0412:e0010412/ko-KR"}
        Polish {"0415:00000415/pl-PL"}
        Russian {"0419:00000419/ru-RU"}
        Spanish-ModernSort {"0c0a:0000040a/es-ES"}
        Spanish-TraditionalSort {"040a:0000040a/es-ES"}
        Spanish-Mexican {"080a:0000080a/es-ES"}
        Spanish-Argentina {"2c0a:0000080a/es-ES"}
        Spanish-Guatemala {"100a:0000080a/es-ES"}
        Spanish-CostaRica {"140a:0000080a/es-ES"}
        Spanish-Panama {"180a:0000080a/es-ES"}
        Spanish-Venezuela {"200a:0000080a/es-ES"}
        Spanish-Colombia {"240a:0000080a/es-ES"}
        Turkish {"041f:0000041f/tr-TR"}        #Default {"0409:00000409/en-US"}    }$LOCALID=$LANGUAGE.split('/')[0]
$LANGUAGEID=$LANGUAGE.split('/')[1]Write-output $ADSERVER
Write-output $LOCATION1
Write-output $LANGUAGE
Write-output $LANGUAGEID
Write-output $LOCALID



import-module ActiveDirectory
new-psdrive -Name AD -PSProvider ActiveDirectory -Server $ADSERVER".its.lab" -Credential (Get-Credential "its\adam") -Root "//RootDSE/"
CD AD:

$COMPNAME=Get-WmiObject -Class Win32_BIOS | select -ExpandProperty serialnumber
$NEWCOMPNAME="C$COMPNAME"


$ADUSER=Get-ADUser $USERNAME | Select-Object -ExpandProperty DistinguishedName
$USEROU = ($ADUSER -split ',' | Select -Skip 2) -Join ',' #splits on , then skips the first 2 values of the split, then rejoins the array with a ,
$NEWOU = "OU=Computers,$USEROU" #adds OU=Computers
cd X:


#Write-Output to unattend.xm
(Get-Content c:\temp\unattend.xml).replace('@compName', $NEWCOMPNAME) | Set-Content c:\temp\unattend.xml
(Get-Content c:\temp\unattend.xml).replace('@domainou', $NEWOU) | Set-Content c:\temp\unattend.xml
(Get-Content c:\temp\unattend.xml).replace('@userName', $USERNAME) | Set-Content c:\temp\unattend.xml
(Get-Content c:\temp\unattend.xml).replace('@LocalID', $LOCALID) | Set-Content c:\temp\unattend.xml
(Get-Content c:\temp\unattend.xml).replace('@LanguageID', $LANGUAGEID) | Set-Content c:\temp\unattend.xml
