############################AAD APP AUTHENTICATION########################################
$clientID = "AAD APP ID"
$tenantID = "TENANT ID"
$ClientSecret = "AAD APP SECRET"
$resource = "https://graph.microsoft.com/"
$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
}
#############################################################################################
###########LOGGING#####################################################################################
$CSVdate = get-date -Format "MM-dd-yyyy"
$exportStudentLocation = "C:\Scripts\90day\Student-LastLoginDateReport($CSVdate).CSV"
$exportEmployeeLocation = "C:\Scripts\90day\Employee-LastLoginDateReport($CSVdate).CSV"
$HealthRunStatus = "C:\Export\AADreport\Health-Run-Status($CSVdate).txt"
#########################################################################################################
##############LOGGING USER INFORMATION REGARDING WHO/WHEN THE SCRIPT WAS RAN########
$Time1 = Get-Date -format "h:mm:ss tt"
$Date = get-date -Format "MM-dd-yy"
#logging run as users information

#####################################################################################
##############AAD APP TOKEN RETRIEVAL###############################################################################################################
 $TokenResponse = (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody).access_token
#Form request headers with the acquired $AccessToken
$headers = @{'Content-Type'="application\json";'Authorization'="Bearer $TokenResponse"}
#This request get users list with signInActivity.
$ApiUrl = "https://graph.microsoft.com/beta/users?`$select=displayName,givenName,surname,userPrincipalName,CreatedDateTime,signInActivity,userType,AccountEnabled,assignedLicenses,Onpremisesdistinguishedname&`$top=999"
############################################################################################################################################################################

 $todaysDate = get-date -Format "MM-dd-yyyy"
 write-host "Gathering all users from AAD....."
$Result = @()
While ($ApiUrl -ne $Null) #Perform pagination if next page link (odata.nextlink) returned.
{
$Response =  Invoke-RestMethod -Method GET -Uri $ApiUrl -ContentType "application\json" -Headers $headers
    if($Response.value)
        {
        #EDIT THE NUMBER TO SEE INACTIVE USERS GREATER THAN THE DESIRED NUMBER    
        $DaysInactive = 90
        $dateTime = (Get-Date).Adddays(-($DaysInactive))
        $Users = $Response.value
        ForEach($User in $Users)
            {
            if (($User.signInActivity.lastSignInDateTime)){
                $totalDays = ([math]::Round((New-TimeSpan -Start ([DateTime]$User.signInActivity.lastSignInDateTime) -End (Get-Date)).TotalDays))
            }
            $Result += New-Object PSObject -property $([ordered]@{
            DisplayName = $User.displayName
            Firstname = $user.givenName
            Lastname = $user.surname
            UserPrincipalName = $User.userPrincipalName
            CreatedDateTime = $User.CreatedDateTime
            Location = $user.onPremisesDistinguishedName
            Licenses = $user.assignedLicenses
            LastSignInDateTime = if($User.signInActivity.lastSignInDateTime) { [DateTime]$User.signInActivity.lastSignInDateTime } Else {$null}
            TotalInactiveDays = $totalDays
            UserType  = if ($User.userType -eq 'Guest') { "Guest" } else { "Member" }
            AccountEnabledStatus = if($user.accountEnabled -eq $true){"Enabled"}else{"Disabled"}
            AccountType = if($User.onPremisesDistinguishedName -like "*OU=visitors*"){"Visitor"} elseif($user.onPremisesDistinguishedName -like "*OU=Staff*") {"Staff"} elseif($user.onPremisesDistinguishedName -like "*OU=temp*") {"Temp"} elseif($user.onPremisesDistinguishedName -like "*OU=12Faculty*") {"12Faculty"} elseif($user.onPremisesDistinguishedName -like "*OU=9Faculty*") {"9Faculty"} elseif($User.onPremisesDistinguishedName -like "*OU=HPCU-O365*") {"OU=HPCU-O365"}
            #EmployeeAccountType = 
            })
            }
        }
        $ApiUrl=$Response.'@odata.nextlink'
}
write-host "All users have been gathered from AAD!" -ForegroundColor "Blue"

$newExport = $Result | Where-Object { $_.userPrincipalName -like "*howard.edu" -and $_.AccountEnabledStatus -like "*Enabled*" -and $_.Location -like "*Disabled*"}

################EXPORT LOCATION#################
$exportLocation = "C:\temp\UsersInformationAAD--2.csv"

$newExport | export-csv -path $exportLocation -Append -NoTypeInformation