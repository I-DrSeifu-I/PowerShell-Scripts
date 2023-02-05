Function get-Sub($rawSub){

    switch($rawSub){
    
        "Enterprise Technology Services" { return "c99494c5-e512-41dc-9197-e8255578cb6b"}
        "Department of Radiology" { return "a7fff3ad-7cc7-4ae7-abae-4a2eb95907a1"}
        "Researchers" { return "1dabc7b1-29be-4aa9-be13-f2a6ee39558a"}
        "Design3D" { return "f57d0ecf-3491-403b-ba77-541e098fa2c0"}
        "Researches-SickleCell" { return "4a357d4b-a9fc-4211-98a6-2512dcc835e4"}
        "Graduate School" { return "cfe71554-94fb-4112-96e8-158b10d5fcb3"}
        "HU-Football" { return "b385ec06-15a0-4403-97e6-b1275774acde"}
        "College Of Dentistry" { return "df3d9a81-2373-485e-8d96-c698d1ceb3ff"}
        "Citrix Infrastructure" { return "10e1799-6b32-4221-b5c4-7d5ccfbe8853"}
        

    default {write-host "No case for $rawSub"}
    
    }
}


$listOfVms = import-csv "C:\Scripts\Removing-AMA\Remove-AMA-Agent - Copy.csv" -Header "VMName","RG", "Sub"

$extensionName = "AzureMonitorWindowsAgent"

$logging = "C:\Scripts\Removing-AMA\Log\Removing-AMA-Agent.txt"

foreach($vm in $listOfVms){

    $vmname = $vm.VMName
    $VMinfo = get-azvm -Name $vmname
    $RG = $vm.RG
    $sub = get-Sub($vm.Sub)
    }
    Set-AzContext -SubscriptionId $sub -TenantId "02ac0c07-b75f-46bf-9b13-3630ba94bb69"

    Write-Warning "removing $extensionName from $vmname"
    Remove-AzVMExtension -ResourceGroupName $RG -Name $extensionName -VMName $vmname
    write-host "removed $extensionName from $vmname"

    "removed $extensionName from $vmname" | out-file -FilePath $logging -Append


}