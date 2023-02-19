Function get-Sub($rawSub){

    switch($rawSub){
    
        "Subscription Name" { return "Subscription ID"}
        
        

    default {write-host "No case for $rawSub"}
    
    }
}
#tenant ID of your environment
$TenantID = ""

$listOfVms = import-csv "C:\Scripts\Removing-AMA\Remove-AMA-Agent - Copy.csv" -Header "VMName","RG", "Sub"

$extensionName = "AzureMonitorWindowsAgent"

$logging = "C:\Scripts\Removing-AMA\Log\Removing-AMA-Agent.txt"

foreach($vm in $listOfVms){

    $vmname = $vm.VMName
    $VMinfo = get-azvm -Name $vmname
    $RG = $vm.RG
    $sub = get-Sub($vm.Sub)
    
    Set-AzContext -SubscriptionId $sub -TenantId "$TenantID"

    Write-Warning "removing $extensionName from $vmname"
    Remove-AzVMExtension -ResourceGroupName $RG -Name $extensionName -VMName $vmname
    write-host "removed $extensionName from $vmname"

    "removed $extensionName from $vmname" | out-file -FilePath $logging -Append


}
