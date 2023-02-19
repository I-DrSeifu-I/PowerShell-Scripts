$textFile = ""
$log = ""
$list = get-content -Path $textFile

foreach($server in $list ) {

    #Specifiy app name to unistall here between the astricts '*APP NAME*'
    $AppName = "*PowerShell 7*"

$session = New-PSSession -ComputerName $server

try{
    Invoke-command $session -ScriptBlock {

            
            $Application = Get-WmiObject -Class Win32_Product  | Where-Object{($_.Name -like $AppName)}


            if ($Application){
                Write-warning "uninstalling $($Application.Name) ..."
                $MyAppARC.Uninstall()
                }

            else{
            Write-host "$($Application.Name) is not installed on this machine"
        }

    }
    
    write-host "Signed in to $server and uninstalling $($Application.Name)" -ForegroundColor Green
    "Signed in to $server and uninstalling $($Application.Name)" | out-file -Path $log -Append

}
catch{

    write-host "Unable to sign-in to $server and uninstall $($Application.Name)"
    "Unable to sign-in to $server and uninstall $($Application.Name)" | out-file -Path $log -Append


}
Remove-PSSession
}