#---------required Azure modules---------------------------#
# Install-Module -Name Az.Resources -RequiredVersion 2.5.0
# Install-Module -Name Az.Accounts
#----------------------------------------------------------#

#-----Use Command below to connect to Azure----#
#Connect-AzAccount
#----------------------------------------------#

#---------Function to change subscription name to subscription ID---#
Function get-Sub($rawSub){

    switch($rawSub){
        #List of sub(s) and their IDs 
        "<SUBSCRIPTION NAME>" { return "SUBSCRIPTION ID"}
        

    default {write-host "No case for $rawSub"}
    
    }
}
#-------------------------------------------------------------------------------------#


#---------------Logging Information and file path---------------------#
$Date = Get-Date -Format "MM-dd-yy"

#Change file path accordily to have logging information
$logpath = "C:\Scripts\Tagging\log\VM-Tagging-Policy-Log($($Date)).txt"
#---------------------------------------------------------------------#

#---------------CSV information-----------------------------------------------------------------------------------------------------------------------------#
$header = "VMName", "Subscription", "PrimaryOwner", "SecondaryOwner", "RequestorName","SupportTeam", "BusinessUnit", "BusinessCriticality", "Environment", "ApplicationName"

#Change the File location of the CSV file accordingly
$FilePath = "C:\Scripts\Tagging\Batches\Tagging-CSV-File - Final ll batches.csv"

$csvFile = import-csv $FilePath -Header $header | select -Skip 1
#-----------------------------------------------------------------------------------------------------------------------------------------------------------#


#------------------Loop used to tag all identified VMs in the CSV file-----------------------#
foreach ($Items in $csvFile){

    #obtains correct subscription ID
    $subID = get-Sub($Items.Subscription)

    #sets the correct subscription scope
    Set-AzContext -SubscriptionId $subID -TenantId "02ac0c07-b75f-46bf-9b13-3630ba94bb69"

    #VM information###
    $name = $Items.VMName
    $vm = Get-AzVM -Name $name
    $resourceG = ($vm).ResourceGroupName
    $vmID = ($vm).id
    #######################

    #####TAG Information pulled from CSV file######
    $PrimaryOwner = $Items.PrimaryOwner
    $SecondaryOwner = $Items.SecondaryOwner
    $SupportTeam = $Items.SupportTeam
    $RequestorName = $Items.RequestorName
    $BusinessUnit = $Items.BusinessUnit
    $BusinessCriticality = $Items.BusinessCriticality
    $Environment = $Items.Environment
    $ApplicationName = $Items.ApplicationName
    ##############################################

    ###Storing tags in a hashtable##############
    $tags = @{
    "Primary Owner"="$PrimaryOwner";
    "Secondary Owner" = "$SecondaryOwner"; 
    "Support Team" = "$SupportTeam";
    "Requestor Name" = "$RequestorName"
    "Business Unit" = "$BusinessUnit";
    "Business Criticality" = "$BusinessCriticality";
    "Environment" = "$Environment";
    "Application Name" = "$ApplicationName" 

    }
    ############################################

    #Checks the current tag values of the VM
    $ExistingTags = (get-aztag -ResourceId $vmID).propertiesTable

        #if the VM doesn't have any tags currently, new tags from the CSV file will be implemented
        if($ExistingTags -eq $null){
        Write-Warning "New Tags Being Implemened on $($name).."
        
            New-aztag -ResourceId $($vmID) -tag $tags 

            "Implemented the following tags on VM: $($name):
            Primary Owner=$PrimaryOwner
            Secondary Owner = $SecondaryOwner
            Requestor Name = $RequestorName
            Support Team = $SupportTeam
            Business Unit = $BusinessUnit
            Business Criticality = $BusinessCriticality
            Environment = $Environment
            Application Name = $ApplicationName
            ____________________________________" | Out-File -FilePath $logpath -Append
        } 

        #if the VM does have tags, those tags will be replaced with the new tags from the CSV file
        else{
        Write-Warning "Updating current tags on $($name).."
            update-aztag -ResourceId $($vmID) -tag $tags -Operation Replace

            "Implemented the following tags on VM: $($name):
            Primary Owner= $PrimaryOwner
            Secondary Owner = $SecondaryOwner
            Requestor Name = $RequestorName
            Support Team = $SupportTeam
            Business Unit = $BusinessUnit
            Business Criticality = $BusinessCriticality
            Environment = $Environment
            Application Name = $ApplicationName
            ____________________________________" | Out-File -FilePath $logpath -Append
        }

    }
