$date = get-date -Format "MM-dd-yy"
$users = get-content -path "C:\export\a5\UPN - Copy.txt"
$log = "C:\export\a5\Log\Removed-A5-License-StudentAccounts($date).txt"
$reportA5 = "C:\export\a5\Log\Removed-A5-License-StudentAccounts-Report($date).csv"

foreach($user in $users){


$time = get-date -Format "hh:mm:ss tt"

Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses "howardu:M365EDU_A5_FACULTY"

Write-Host "Removed A5 Faculty license from $user"
"Removed A5 Faculty license from $user , $time" | Out-File -FilePath $log -Append


$result = [PSCustomObject]@{
         UserPrincipalName = $user
         A5LicenseRemoval = "Completed"
         TimeOfRemoval = $time

           }
         $result | export-csv -Path $reportA5 -append -NoTypeInformation -force
         
         


}