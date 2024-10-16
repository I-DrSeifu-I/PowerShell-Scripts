Import-Module az
Import-Module Az.Monitor
Import-Module AzureRM.OperationalInsights


#connect-azaccount
$DiagnosticsLogging = "C:\AzureDiagnostics.csv"
Set-AzContext -Subscription "" -Tenant ""



$names = (Get-AzVM -Name "AZ-ORCH-P01").Name
$nameOfStorageAccount = "howardedudiagnostics"
$diagConfigxml = "C:\WadConfig.json"


$workspaceName = "AZ-HUSentinel-Workspace"
$workspace = (Get-AzureRmOperationalInsightsWorkspace).Where({$_.Name -eq $workspaceName})
$workspaceId = $workspace.CustomerId
$workspaceKey = (Get-AzureRmOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $workspace.ResourceGroupName -Name $workspace.Name).PrimarySharedKey


$workspace = (Get-AzureRmOperationalInsightsWorkspace).Where({$_.Name -eq $workspaceName})

if ($workspace.Name -ne $workspaceName)
{
    Write-Error "Unable to find OMS Workspace $workspaceName. Do you need to run Select-AzureRMSubscription?"
    
    exit
}


#--Will pull resourceID for any Azure resource & show the Diagnostics settings. Used for quality testing purposes--#
#$resourceID = (Get-AzResource -Name "$names").ResourceId 
#Get-AzDiagnosticSetting -ResourceId $resourceID

foreach ($name in $names) {

    $RG = (Get-AzResource -Name "$names").ResourceGroupName 
    $location = (Get-AzResource -Name "$names").Location
    
    #Enable Diagnostics Settings
    #Set-AzVMDiagnosticsExtension -ResourceGroupName $RG -VMName $name -StorageAccountName $nameOfStorageAccount -DiagnosticsConfigurationPath $diagConfigxml

    Write-Host "$name now has Diasnostig Settings enabled with $nameOfStorageAccount storage account"
    "$name now has Diagnostics Settings enabled with $nameOfStorageAccount storage account" | out-file -FilePath $DiagnosticsLogging -Append


     #Enable Insights for VM
     Set-AzureRMVMExtension -ResourceGroupName $RG -VMName $name -Name 'MicrosoftMonitoringAgent' `
     -Publisher 'Microsoft.EnterpriseCloud.Monitoring' -ExtensionType 'MicrosoftMonitoringAgent' `
     -TypeHandlerVersion '1.0' -Location $location -SettingString "{'workspaceId':  '$workspaceId'}" `
     -ProtectedSettingString "{'workspaceKey': '$workspaceKey' }"

     Write-Host "$name now has Diasnostig Settings enabled with $nameOfStorageAccount storage account"
     
     "$name now has Diagnostics Settings enabled with $nameOfStorageAccount storage account" | out-file -FilePath $DiagnosticsLogging -Append
}
