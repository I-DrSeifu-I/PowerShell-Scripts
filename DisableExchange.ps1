$users = Get-AzureADUser -ObjectId "eric.green@bison.howard.edu"
$SKUs = Get-AzureADSubscribedSku

$plansToDisable = @("efb87545-963c-4e0d-99df-69c6916d9eb0","EXCHANGE_S_ENTERPRISE")

foreach ($user in $users) {
    $userLicenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    foreach ($license in $user.AssignedLicenses) {
        $SKU =  $SKUs | ? {$_.SkuId -eq $license.SkuId}
        foreach ($planToDisable in $plansToDisable) {
            if ($planToDisable -notmatch "^[{(]?[0-9A-F]{8}[-]?([0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$") { $planToDisable = ($SKU.ServicePlans | ? {$_.ServicePlanName -eq "$planToDisable"}).ServicePlanId }
            if ($planToDisable -in $SKU.ServicePlans.ServicePlanId) {
                $license.DisabledPlans = ($license.DisabledPlans + $planToDisable | sort -Unique)
                
            }
        }
        $userLicenses.AddLicenses += $license
    }

    
        Set-AzureADUserLicense -ObjectId $user.ObjectId -AssignedLicenses $userLicenses -Verbose 
        #Write-Host "Removed plan $planToDisable from license $($license.SkuId)"
   

}


