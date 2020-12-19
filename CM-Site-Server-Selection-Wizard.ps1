Function Config-Server {
Param ([String]$CMROLESLIST)

switch ($CMROLESLIST) 
    { 

        DistributionPoint{"Distribution Point"}
        ManagementPoint{"Management Point"}
        StateMigrationPoint{"State Migration Point"}
        SoftwareUpdatePoint{"Software Update Point"}
        #ApplicationWebSite{"Application WebSite"}
        #EnrollmentPoint{"Enrollment Point"}
        #EnrollmentProxyPoint{"Enrollment Proxy Point"}
        Default {"Distribution Point"}
    }
}

#Begin Form
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form 
$form.Text = "Server Role Wizard"
$form.Size = New-Object System.Drawing.Size(430,350) 
$form.StartPosition = "CenterScreen"

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(100,250)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(190,250)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
 
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20) 
$label.Size = New-Object System.Drawing.Size(500,20) 
$label.Text = "Please select a Configuration Manager" 
   # Set the font of the text to be used within the form
    $Font = New-Object System.Drawing.Font("Times New Roman",10)
    $label.Font = $Font

$label1 = New-Object System.Windows.Forms.Label
$label1.Location = New-Object System.Drawing.Point(90,50) 
$label1.Size = New-Object System.Drawing.Size(500,20) 
$label1.Text = "site server role:"
   # Set the font of the text to be used within the form
    $Font1 = New-Object System.Drawing.Font("Times New Roman",10)
    $label1.Font = $Font1

$listBox = New-Object System.Windows.Forms.ListBox 
$listBox.Location = New-Object System.Drawing.Point(60,95) 
$listBox.Size = New-Object System.Drawing.Size(250,200) 
$listBox.Height = 130


#!!!!!Add a new line here with the new name of the language to display in the drop-down menu!!!!!
#!!!!!This MUST match the language added above exactly!!!!!
[void] $ListBox.Items.Add("Distribution Point")
[void] $ListBox.Items.Add("Management Point")
[void] $ListBox.Items.Add("State Migration Point")
[void] $ListBox.Items.Add("Software Update Point")
#[void] $ListBox.Items.Add("Application Web Site")
#[void] $ListBox.Items.Add("Enrollment Point")
#[void] $ListBox.Items.Add("Enrollment Proxy Point")
 

$listBox.SetSelected(0,$true)
    
    $form.Topmost = $True
    $form.Controls.AddRange(@($listBox,$OKButton,$CancelButton,$label,$label1))
    $form.Add_Shown({$form.Activate()})   
$result = $form.ShowDialog()
#END FORM

#If OK Button was pressed, run this code block
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{


$SELECTEDROLE = $ListBox.SelectedItem;

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$tsenv.Value('CMROLE') = $SELECTEDROLE

#[System.Windows.Forms.MessageBox]::Show("$SELECTEDROLE" , "Selected Role")

}