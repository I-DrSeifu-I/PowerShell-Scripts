
#Get the subscriptions
Write-Host "Getting Subscription Details" -ForegroundColor "Yellow"
get-AzSubscription | Where-Object {$PSItem.State -eq "Enabled"} | Export-Csv -Path "C:\Scripts\ViewVM-Extensions\All-VMs-MMAextensionsubscription.csv"
#Import the Subscriptions
Write-Host "Importing Subscriptions" -ForegroundColor "Yellow"
$subscriptions = Import-Csv -Path "C:\Scripts\ViewVM-Extensions\All-VMs-MMAextensionsubscription.csv"
$export = "C:\Scripts\ViewVM-Extensions\log\All-VMs-MMAextension-logs.txt"

#Set the extension you wish to uninstall here 
$extensionName = ""


foreach ($sub in $subscriptions) {

    #Set contexts
    Set-AzContext -Subscription $sub.Name
    $SubName = $sub.Name
    # Getting VMs in the subscription
    Write-Host "Getting VM Details.." -ForegroundColor "Yellow"
    $VMs = Get-AzVM 

    

    Write-Host "Filtering Windows VMs" -ForegroundColor "Yellow"

    $WindowsVMs = $VMs | Where-Object { $PSItem.StorageProfile.ImageReference.Offer -eq "WindowsServer" }

        #$export = "C:\Scripts\ViewVM-Extensions\All-VMs-MMAextension.csv"
    foreach ($VM in $WindowsVMs) {
        $extension = Get-AzVMExtension -ResourceGroupName $Vm.ResourceGroupName -VMName $VM.Name

        if ($extension.Name -contains "$($extensionName)") {


            Write-Host "$($extensionName) is Installed in" $VM.Name -ForegroundColor "Cyan"
            write-host "Removing $($extensionName) from " $VM.Name -ForegroundColor "Cyan"

            try{
                Remove-AzVMExtension -Name "$($extensionName)" -ResourceGroupName $Vm.ResourceGroupName -VMName $VM.Name -Verbose -Force

                "MMA has been uninstalled from $($VM.Name)" | Out-File -FilePath $export -Append 
            }
            catch{
                Write-Warning "Unable to remove $($extensionName) from $($VM.Name)"
                "Unable to remove $($extensionName) from $($VM.Name)" | Out-File -FilePath $export -Append 

            }

        }
        else {
            Write-Host "$($extensionName) is Not Installed in" $VM.Name -ForegroundColor "Red"


            "$($extensionName) is Not Installed in $($VM.Name)" | Out-File -FilePath $export -Append 
        }
    }
}