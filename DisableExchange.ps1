$users = Get-AzureADUser -ObjectId ""
$SKUs = Get-AzureADSubscribedSku

$plansToDisable = @("PLAN ID","PLAN NAME")

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


