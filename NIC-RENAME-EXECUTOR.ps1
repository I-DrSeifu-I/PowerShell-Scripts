
###############PLEASE ENTER THE PROPER CSV FILE PATH THAT CONATINS THE VMs: Resourcegroup, VM name, and subscription name
$csv = Import-Csv "C:\Scripts\DiskRenaming\RenameDisks.csv" -Header "RG", "VMname", "Sub"
#########################################################################################################################

###-Copy and run by it seperatley in the terminal to Connect to Azure-##
#   Connect-AzAccount   #
#########################

####The Function Below Will Convert The Sub Name into The Sub ID###
Function get-CorrectedOU($rawSub){

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
##################################################################################



####################LOOP THROUGH VMs#################################################
foreach($vm in $csv){
    $vmname = $vm.VMName
    $RG = $vm.RG
    $sub = get-CorrectedOU($vm.Sub)
    $newNicname = "$($vmname)-NIC01"

    #setting the subscription 
    Set-AzContext -SubscriptionId $sub -TenantId "02ac0c07-b75f-46bf-9b13-3630ba94bb69"

    #This command below will call the nic renaming script and input the values from the csv 
    & "C:\Scripts\NICrename.ps1" -resourceGroup $RG -VMName $vmname -NewNicName $newNicname -Verbose

}
#####################################################################################################
