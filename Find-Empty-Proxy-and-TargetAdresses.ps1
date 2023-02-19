
$searchbase = "OU=Visitors,OU=All Users,DC=howardu,DC=net"
$users = Get-ADUser -Filter {(-not(targetAddress -like "*")) -or (-not(proxyAddresses -like "*")) -or (enabled -eq $true)} -SearchBase $searchbase -Properties proxyAddresses, targetaddress, name, samaccountname  | select proxyAddresses, targetaddress, name, samaccountname  

$OU = "Visitors"
$export = "C:\Logging\ViewEmptyAttributes\Export-EmptyTarget-Proxy($OU).csv"

foreach($user in $users) {
    $proxy = $user.proxyAddresses
    $target = $user.targetaddress
    $name = $user.name
    $samAcc = $user.samaccountname
    
    
    if (-not($proxy -like "*")){
    
        write-host "$samAcc , NO PROXY ADDRESS"
    
        "$samAcc , NO PROXY ADDRESS" | Out-File -FilePath $export -Append
    
    }

    elseif(($target -eq $null) -or ($target -eq "")){
         write-host "$samAcc , NO TARGET ADDRESS"
    
        "$samAcc , NO TARGET ADDRESS" | Out-File -FilePath $export -Append
    
    }






}