
###############PLEASE ENTER THE PROPER CSV FILE PATH THAT CONATINS THE VMs: Resourcegroup, VM name, and subscription name
$csv = Import-Csv "C:\Scripts\DiskRenaming\RenameDisks.csv" -Header "RG", "VMname", "Sub"
#########################################################################################################################

###-Copy and run by it seperatley in the terminal to Connect to Azure-##
#   Connect-AzAccount   #
#########################

####The Function Below Will Convert The Sub Name into The Sub ID###
Function get-CorrectedOU($rawSub){

    switch($rawSub){
    
        "<SUB NAME>" { return "SUB ID"}

        

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
