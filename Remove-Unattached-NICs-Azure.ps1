Connect-AzAccount
#Store the unattached NICs information
$orphanNICs = get-aznetworkinterface |select *| ?{$_.virtualmachine -eq $null}

#Logging file of which NIC has been removed
$logPath = "C:\$(get-date -Format "yyMMdd")RemovedNICs.txt"

#Looping through each unattached NIC
foreach ($orphanNIC in $orphanNICs)
{
   Write-Host "Deleting $($orphanNIC.name)"
   
   #Deleting the unattached NIC
   Remove-AzResource -resourceID $orphanNIC.Id
   
   "The NIC $($orphanNIC.name) has been removed" | Out-File $logPath -append
}