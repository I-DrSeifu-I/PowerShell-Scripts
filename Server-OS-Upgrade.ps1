Select-AzSubscription -SubscriptionId "e80d8d01-6c1c-4b19-aaa7-ad83deec8bdf" -Tenant "9717d0e2-1404-4ee3-b021-42b15582c6ae"

$VMname = ""

$newVmname = ""
$UserName=''
$Password=''| ConvertTo-SecureString -Force -AsPlainText
$Credential=New-Object PSCredential($UserName,$Password)

$VM = Get-AzVM -Name $VMname

#---------------------------------------------------------------------------------------------------------------------#
$sourceOSDisk = Get-AzDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $VM.StorageProfile.OsDisk.Name
$diskConfig = New-AzDiskConfig -SkuName $sourceOSDisk.Sku.Name -Location $VM.Location `
            -DiskSizeGB $VM.StorageProfile.OsDisk.DiskSizeGB -SourceResourceId $sourceOSDisk.Id -CreateOption Copy
$newOSDisk = New-AzDisk -Disk $diskConfig -DiskName "$newVmname-osDisk" -ResourceGroupName $vm.ResourceGroupName
#----------------------------------------------------------------------------------------------------------------------#
for ($i = 0; $i -lt $oldNics.Count; $i++) {
$oldNics = $VM.NetworkProfile.NetworkInterfaces
$oldNicName = $oldNics[$i].Id.Split('/')[-1]
    $vNic = Get-AzNetworkInterface -Name $oldNicName -ResourceGroupName $vm.ResourceGroupName
}
    
$oldNics = $VM.NetworkProfile.NetworkInterfaces
$NIC = New-AzNetworkInterface -Name "$newVmname-NIC01" -ResourceGroupName $VM.ResourceGroupName `
        -Location $VM.Location -SubnetId $vnic.IpConfigurations.Subnet.Id `
        -IpConfigurationName $vnic.IpConfigurations.Name

        $NIC.DnsSettings = $vNIC.DnsSettings
        $NIC.EnableIPForwarding = $vNIC.EnableIPForwarding
        $NIC.EnableAcceleratedNetworking = $vNIC.EnableAcceleratedNetworking
        $NIC.NetworkSecurityGroup = $vNIC.NetworkSecurityGroup

If ($NIC.IpConfigurations.PrivateIpAddress -ne $vNIC.IpConfigurations.PrivateIpAddress) {
        Set-AzNetworkInterfaceIpConfig -NetworkInterface $NIC -Name $NIC.IpConfigurations.Name `
            -PrivateIpAddressVersion $vNIC.IpConfigurations.PrivateIpAddressVersion `
            -PrivateIpAddress $vNIC.IpConfigurations.PrivateIpAddress -SubnetId $vnic.IpConfigurations.Subnet.id | Out-Null
            
    }

$newVMconfig = New-AzVMConfig -VMName $newVmname -VMSize $VM.HardwareProfile.VmSize -Tags $VM.Tags 
$newVMconfig = Set-AzVMOperatingSystem `
  -VM $newVMconfig `
  -Windows `
  -ComputerName $newVmname `
  -Credential $Credential -ProvisionVMAgent

$newVMconfig = Set-AzVMSourceImage `
  -VM $newVMconfig `
  -PublisherName "MicrosoftWindowsServer" `
  -Offer "WindowsServer" `
  -Skus "2022-Datacenter" `
  -Version "latest"


#Remove-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Force

New-AzVM -ResourceGroupName $VM.ResourceGroupName -Location $VM.Location -VM $newVMconfig

Stop-AzVM -Name $newVmname -ResourceGroupName $newVmname.ResourceGroupName -Force

Set-AzVMOSDisk -VM $newVmname -ManagedDiskId $newOSDisk.Id -Name $newOsDiskName
Add-AzVMNetworkInterface -VM $VM -Id $NIC.Id -Primary

Update-AzVM -Name $newVmname -ResourceGroupName $newVmname.ResourceGroupName -Force

