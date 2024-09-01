$samaccountname = "Test.account"
$exchangeServer = ""



Function EnableRemoteMailbox {

try {

    $RemoteRoutingAddress = "$($samaccountname)@<ADDRESS>"

    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$($exchangeServer).<DOMAIN>/PowerShell/"

    Import-PSSession $Session -DisableNameChecking 

    Enable-RemoteMailbox $samaccountname -RemoteRoutingAddress $RemoteRoutingAddress

    Remove-PSSession $Session

    Write-host "RemoteMailbox has been enabled for $($samaccountname)" -ForegroundColor Green

    }

catch {

    Write-host "Unable to enable RemoteMailbox for $($samaccountname). Error: $($_)" -ForegroundColor red


     }

}
