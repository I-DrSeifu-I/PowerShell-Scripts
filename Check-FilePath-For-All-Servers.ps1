

$OUpath = '--OU PATH---'

#gathers the servers 
#$ListOfServers = Get-ADComputer -Filter {operatingSystem -like "*2012*"} -SearchBase $OUpath | Where-Object { ($_.DistinguishedName -notlike "*Retired*") } | select name
$ListOfServers = Get-Content -Path "C:\Logging\2012-check-log\2012serverlist.txt"
$logPS = "C:\Logging\2012-check-log\Logs-2012-PS-Check.csv"

foreach($serverCCM in $ListOfServers){

    $PSServer = $serverCCM

    if( test-connection -cn $PSServer -quiet){
    $filetest = test-path -path "\\$PSServer\c$\Program Files\PowerShell\7\pwsh.exe"

    if($filetest -eq $true){
        write-host "$PSServer has the file path"
        "$PSServer | True" | Out-File -FilePath $logPS -Append

    }

    else {
        write-host "$PSServer DOES NOT have PS"
        "$PSServer | False" | Out-File -FilePath $logPS -Append
    }
}
else {
    "$PSServer is Offline" | Write-Host
    "$PSServer | Offline" | Out-File -FilePath $logPS -Append
}


}