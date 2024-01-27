
#OU path to be users for the query
$OUpath = ''
$application = "--application youre looking for on servers--"
#gathers the servers 
$ListOfServers = Get-ADComputer -Filter * -SearchBase $OUpath|Where-Object { ($_.DistinguishedName -notlike "*Retired*")} | select name
#logging locations
$exportCSV = "C:\Scripts\List-Of-Servers-With-$($application)-Checkup.csv"
$logging = "C:\Scripts\$($application)-logging.txt"

#Loops through all online servers
foreach($server in $ListOfServers){


    $serverName = $server.name
    #First tests if a server is online
    if( test-connection -cn $serverName -quiet){
        #Checks for the app on the server
        $AppCheck = Get-WmiObject -Class Win32_Product -Computer $serverName | Where-Object {$_.name -like "*$application*"} |select name

                if ($AppCheck){
                Write-Host "$serverName : $application exists on the server" -ForegroundColor Green
        
                $export = [PSCustomObject]@{
                    "Server" = $serverName
                    "ApplicationStatus" = $application
                }
                $export | Export-Csv -path $exportCSV -Append -NoTypeInformation
            }
            else {
                Write-Host "$serverName : App Does not exist on server" -ForegroundColor Red
        
                $export = [PSCustomObject]@{
                    "Server" = $serverName
                    "ApplicationStatus" = "App does not exist"
                }
                $export | Export-Csv -path $exportCSV -Append -NoTypeInformation
            }

    }
    #if the server is offline, it is logged
    else{
        Write-Host "$servername is unreachable" -ForegroundColor DarkYellow
        "$servername is unreachable" | Out-File -FilePath $logging -Append
    
    }
  
  }


