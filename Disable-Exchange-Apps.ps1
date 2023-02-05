#########################################################
#                                                       #
# Please Ensure You Have Exchange Administrator Enabled # 
#                                                       #
#########################################################


##########################Logging / Reporing Destinations########################################
$date = get-date -format "MM-dd-yy"
$path = "C:\Scripts\Exchange-Disablement-BisonAccounts\List-Of-Users.txt"
$users = get-content -Path $path
$logging = "C:\Scripts\Exchange-Disablement-BisonAccounts\Log\Exchange-Apps-Settings-Disablement($date).txt"
$report = "C:\Scripts\Exchange-Disablement-BisonAccounts\Log\Exchange-App-Disablement-Report($date).csv"
#####################################################################################################

#---Uncomment The Command Below & Run The Command By Itself

#Connect-ExchangeOnline


Foreach($user in $users){

$time = get-date -Format "hh:mm:ss tt"

    Write-Warning "Disabling all email app settings for $user...."

    ##################Exchange email app setting disablement#############
    Set-CASMailbox $user `
        -ImapEnabled $false `
        -PopEnabled $false `
        -MAPIEnabled $false `
        -EwsEnabled $false `
        -ActiveSyncEnabled $false `
        -OWAEnabled $false `
        -Verbose
     #####################################################################



     #########################LOGGING / REPORTING####################################

         Write-Host "All email app setting have been disabled for $user !"

         "-------------------------($date | $time)------------------------------
         User:($user) has the following disabled: 
            Outlook on the web
            Outlook desktop (MAPI)
            Exchange web services
            Mobile (Exchange ActiveSync)
            IAMP
            POP3 
         ---------------------------------------------------------------------------------------
         
         " | out-file -FilePath $logging -Append

         $result = [PSCustomObject]@{
         UserPrincipalName = $User 
         OutlookOnTheWeb = "Disabled"
          OutlookDesktopMAPI = "Disabled"
          ExchangeWebServices = "Disabled"
          MobileExchangeActiveSync = "Disabled" 
           IMAP = "Disabled"
           POP3 = "Disabled"

           }
         $result | export-csv -Path $report -append -NoTypeInformation -force
    #######################################################################################################
    

    
    

}

