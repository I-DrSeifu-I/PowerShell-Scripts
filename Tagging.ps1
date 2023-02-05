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