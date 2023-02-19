Write-Host "Getting Subscription Details" -ForegroundColor "Yellow"
Get-AzSubscription | Where-Object {$PSItem.State -eq "Enabled"} | Export-Csv -Path "C:\Scripts\storageAccount\All-VMs-MMAextensionsubscription.csv"

$subscriptions = Import-Csv -Path "C:\Scripts\ViewVM-Extensions\All-VMs-MMAextensionsubscription.csv"
$path = "C:\Scripts\storageAccount\log\SA-PublicAccessStatus.csv"

foreach ($sub in $subscriptions) {

    #Set contexts
    Set-AzContext -Subscription $sub.Name
    $SubName = $sub.Name
    $SAaccount = get-azstorageaccount

    foreach ($SAacc in $SAaccount){
        $SAname = $SAacc.StorageAccountName
        $SApublicAccess = $SAacc.AllowBlobPublicAccess

        Write-Host "$SAname's public access is $SApublicAccess" -ForegroundColor "Blue"
            
        $export = [PSCustomObject]@{
            StorageAccountName = $SAname
            PublicAccess = $SApublicAccess
            Subscription = $SubName
        }

        $export | export-csv -Path $path -Append -NoTypeInformation
}

}