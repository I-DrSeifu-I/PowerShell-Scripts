
$users = Get-Content -Path "C:\Export\Disable-Graduate\Users.txt"
$phase = "4"

$loggingDescription = "Disabled-Users"
$Todaysdate = get-date -format "yy-MM-dd"
$logging = "C:\Export\Disable-Graduate\export\$($loggingDescription)_$($Todaysdate)_Phase$($phase)_log.txt"
$report = "C:\Export\Disable-Graduate\export\$($loggingDescription)_$($Todaysdate)_Phase$($phase)_report.csv"

foreach($user in $users){

     try{
        $username = $user
        Write-Warning "Disabling $username.."
        get-aduser -Filter {(userprincipalname -eq $username)} | Disable-ADAccount 
        "$username has been disabled" | out-file -FilePath $logging -Append 

        $info = [PSCustomObject]@{
         UserPrincipalName = $username
         AccountStatus = "Disabled"
        }
         $info | export-csv -Path $report -Append -NoTypeInformation
     }
     catch{
        Write-Host "User $username can't be found on AD" -ForegroundColor "Red"
        "User $username can't be found on AD" | out-file -FilePath $logging -Append 
     }
    
}
