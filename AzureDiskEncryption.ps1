 #________________Switch Subs_________________________________________________________#
 Function get-CorrectedSub($rawSub){

    switch($rawSub){
    
        "Enterprise Technology Services" { return "c99494c5-e512-41dc-9197-e8255578cb6b"}
        "Department of Radiology" { return "a7fff3ad-7cc7-4ae7-abae-4a2eb95907a1"}
        "Researchers" { return "1dabc7b1-29be-4aa9-be13-f2a6ee39558a"}
        "Design3D" { return "f57d0ecf-3491-403b-ba77-541e098fa2c0"}
        "Researches-SickleCell" { return "4a357d4b-a9fc-4211-98a6-2512dcc835e4"}
        "Graduate School" { return "cfe71554-94fb-4112-96e8-158b10d5fcb3"}
        "HU-Football" { return "b385ec06-15a0-4403-97e6-b1275774acde"}
        "Citrix Infrastructure" { return "10e1799-6b32-4221-b5c4-7d5ccfbe8853"}
        "Lowman-Dev-(PartnerCredits)" { return "e80d8d01-6c1c-4b19-aaa7-ad83deec8bdf"}
        "College Of Dentistry" { return "df3d9a81-2373-485e-8d96-c698d1ceb3ff"}
        

    default {write-host "No case for $rawSub"}
    
    }


}
#________________________________________________________________________________________

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

        Select-AzSubscription -SubscriptionId $subscription -Tenant "02ac0c07-b75f-46bf-9b13-3630ba94bb69"

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