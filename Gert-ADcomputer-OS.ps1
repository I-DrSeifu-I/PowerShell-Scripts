$listofserverMaster = Get-Content "C:\Scripts\Servers in master spreadsheet.txt"
$OUpath = '---OU-Path----'
$logMaster = "C:\Scripts\MasterSpreadsheet.csv"
foreach($computerName in $listofserverMaster){

        Get-ADComputer -Filter {name -like $computerName} `
        -SearchBase $OUpath -Properties name, operatingsystem | `
        select name, operatingsystem |`
        Export-Csv -Path $logMaster -Append

}