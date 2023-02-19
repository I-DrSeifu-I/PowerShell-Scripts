$samaccountname = "Test.account"
$exchangeServer = ""



Function EnableRemoteMailbox {

try {

    $RemoteRoutingAddress = "$($samaccountname)@howardu.mail.onmicrosoft.com"

    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$($exchangeServer).howardu.net/PowerShell/"

    Import-PSSession $Session -DisableNameChecking 

    Enable-RemoteMailbox $samaccountname -RemoteRoutingAddress $RemoteRoutingAddress

    Remove-PSSession $Session

    Write-host "RemoteMailbox has been enabled for $($samaccountname)" -ForegroundColor Green

    }

catch {

    Write-host "Unable to enable RemoteMailbox for $($samaccountname). Error: $($_)" -ForegroundColor red


     }

}