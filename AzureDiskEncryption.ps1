 #________________Switch Subs_________________________________________________________#
 Function get-CorrectedSub($rawSub){

    switch($rawSub){
    
        "Subscription Name" { return "Subscription ID"}
        

    default {write-host "No case for $rawSub"}
    
    }


}
#________________________________________________________________________________________

#Tenant ID for your azure environment
$TenantID = ""

#Connect-AzAccount

$date = (get-date -Format "MM-dd-yy")
$logs = "C:\Scripts\DiskEncryption\Logs\Logs-AzureDiskEncryption-($date).txt"
$report = "C:\Scripts\DiskEncryption\Logs\Report-AzureDiskEncryption-($date).csv"
$vms = Import-Csv "C:\Scripts\DiskEncryption\ADE-VMs.csv" -Header "VMname", "sub" | Select -skip 1

foreach($vm in $vms) {

        
        $vmName = $vm.vmname
        $resourceGroupName = "$((get-azvm -Name $vmName).ResourceGroupName)"
        $keyVaultName      = "ETS-Azure-DiskEncrpytion"
        $keyVaultRG = "Azure-Disk-Encryption"
        $subscription = get-CorrectedSub($vm.sub)

        Select-AzSubscription -SubscriptionId $subscription -Tenant "$TenantID"

        Write-Host "$keyVaultName has been retrived!"
        "$keyVaultName has been retrived!" | Out-File -FilePath $logs -Append
        Get-AzKeyVault -VaultName $keyVaultName `
        -ResourceGroupName $keyVaultRG | Select-Object EnabledForDiskEncryption

        write-host "Ensuring $keyVaultName is enabled for disk encryption"
        "Ensuring $keyVaultName is enabled for disk encryption" | Out-File -FilePath $logs -Append

        Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName `
                                -ResourceGroupName $keyVaultRG `
                                -EnabledForDiskEncryption -Confirm:$false
        Write-Host "$keyVaultName has been enabled for disk encryption"
        "$keyVaultName has been enabled for disk encryption" | Out-File -FilePath $logs -Append

        $KeyVault = Get-AzKeyVault -VaultName $keyVaultName `
                                -ResourceGroupName $keyVaultRG

        "Setting disk encryption for $vmName for OS and data disk...."
        "Setting disk encryption for $vmName for OS and data disk...." | Out-File -FilePath $logs -Append
        Set-AzVMDiskEncryptionExtension -ResourceGroupName $resourceGroupName `
                                -VMName $vmName `
                                -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri `
                                -DiskEncryptionKeyVaultId $KeyVault.ResourceId `
                                -VolumeType "All" -Force
        write-host "Disk encryption has been completed on $vmName"
        "Disk encryption has been completed on $vmName
        
        --------------------------------------------------------" | Out-File -FilePath $logs -Append
                                
        Get-AzVmDiskEncryptionStatus -VMName $vmName `
                                -ResourceGroupName $resourceGroupName

        $reportCSV = [PSCustomObject]@{
            VM = $vmName
            OSDiskEncryption = "Enabled"
            DataDiskEncryption = "Enabled"
        }

        $reportCSV | Export-Csv -Path $report -Append -NoTypeInformation

}
