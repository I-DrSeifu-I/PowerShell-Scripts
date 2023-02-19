
#Get the subscriptions
Write-Host "Getting Subscription Details" -ForegroundColor "Yellow"
Get-AzSubscription | Where-Object {$PSItem.State -eq "Enabled"} | Export-Csv -Path "C:\Scripts\ViewVM-Extensions\All-VMs-MMAextensionsubscription.csv"
#Import the Subscriptions
Write-Host "Importing Subscriptions" -ForegroundColor "Yellow"
$subscriptions = Import-Csv -Path "C:\Scripts\ViewVM-Extensions\All-VMs-MMAextensionsubscription.csv"

foreach ($sub in $subscriptions) {

    #Set contexts
    Set-AzContext -Subscription $sub.Name
    $SubName = $sub.Name
    # Getting VMs in the subscription
    Write-Host "Getting VM Details.." -ForegroundColor "Yellow"
    $VMs = Get-AzVM 

    $extensionName = ""

    Write-Host "Filtering Windows VMs" -ForegroundColor "Yellow"

    $WindowsVMs = $VMs | Where-Object { $PSItem.StorageProfile.ImageReference.Offer -eq "WindowsServer" }

        $export = "C:\Scripts\ViewVM-Extensions\All-VMs-MMAextension.csv"
    foreach ($VM in $WindowsVMs) {
        $extension = Get-AzVMExtension -ResourceGroupName $Vm.ResourceGroupName -VMName $VM.Name

        if ($extension.Name -contains "$($extensionName)") {
            Write-Host "$($extensionName) is Installed in" $VM.Name -ForegroundColor "Cyan"

            $sucesshash = @{
                VMName            = $VM.Name
                Extension         = "$($extensionName)"
                ProvisionedStatus = "Succeeded"
                Subscription      = $SubName
            }

            New-Object -TypeName PSObject -Property $sucesshash | Export-Csv -Path $export -Append -NoClobber

        }
        else {
            Write-Host "$($extensionName) is Not Installed in" $VM.Name -ForegroundColor "Red"

            $failhash = @{
                VMName            = $VM.Name
                Extension         = "$($extensionName)"
                ProvisionedStatus = "Not Installed"
                Subscription      = $SubName
            }

            New-Object -TypeName PSObject -Property $failhash | Export-Csv -Path $export -Append -NoClobber
        }
    }
}