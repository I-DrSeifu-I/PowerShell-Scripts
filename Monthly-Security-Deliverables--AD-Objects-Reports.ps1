$AppId = "--AAD AAP ID--"
$AppSecret = "--AAD AAP SECRET--"
$TenantId = "TENANT ID"

# Construct URI and body needed for authentication
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    client_id     = $AppId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $AppSecret
   grant_type    = "client_credentials"
}

#----------------------------Logging----------------------------------------------------#
$date = get-date -format "MM-dd-yy"
$privAccountLogging = "C:\Monthly-Reports\Priv-Users\Stale-Priv-Accounts($($date)).csv"
$staleADcomputersLogging = "C:\Monthly-Reports\AD-Stale-Computers\Stale-AD-Computers($($date)).csv"
$staleADusersLogging = "C:\Monthly-Reports\AD-Stale-Users\Stale-AD-Users($($date)).csv"

$CSVdate = get-date -Format "MM-dd-yyyy" 
$exportStudentLocation = "C:\Logging\Account Management\AAD-90-Daily-User-Export\Students\Student-LastLoginDateReport($CSVdate).CSV"
$exportEmployeeLocation = "C:\Logging\Account Management\AAD-90-Daily-User-Export\Employees\Employee-LastLoginDateReport($CSVdate).CSV"
$HealthRunStatus = "C:\Monthly-Reports\Script-Health-Status\Health-Run-Status($CSVdate).txt"
#-------------------------------------------------------------------------------------------------#

function SendMonthlyEmailReport {

    $Attachment = $exportEmployeeLocation
    $FileName=(Get-Item -Path $Attachment).name
    $base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Attachment))

    $Attachment1 = $exportStudentLocation
    $FileName1=(Get-Item -Path $Attachment1).name
    $base64string1 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Attachment1))

    $Attachment2 = $privAccountLogging
    $FileName2 =(Get-Item -Path $Attachment2).name
    $base64string2 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Attachment2))

    $Attachment3 = $staleADcomputersLogging
    $FileName3 = (Get-Item -Path $Attachment3).name
    $base64string3 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Attachment3))
   
    $CountOfEmployees = (import-csv $exportEmployeeLocation -Header "Employee").count
    $CountOfStudents = (import-csv $exportStudentLocation -Header "Student").count

    Write-Host "Sending email....." -ForegroundColor "blue"

    $tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
# Unpack Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token
$Headers = @{
            'Content-Type'  = "application\json"
           'Authorization' = "Bearer $Token" }

           #DEFINE THE EMAIL ACCOUNT USED TO SEND OUT EMAILS
            $MsgFrom = ""

           $ccRecipient1 = ""
            # Define attachment to send to new users
                  $EmailRecipient = ""
                  $MsgSubject = 'Monthly Security Deliverables'
                  $htmlbody = " 
                  <br>Hello All,<br>
                  <br>
                 For today's report($(get-date -Format "MM/dd/yy")), above attached will be all stale AD computer objects, stale AD privileged accounts, and stale AD user accounts. 
                 Please see the attached CSV spreadsheets above. 
                 Below will be the current metrics for the month of $((get-date).AddMonths(-1).ToString( "MMMM")): 
                
                 <br>
                 <ul>
                    <li> Number of Stale AD Computers: $StaleADcompCount </li>
                    <li> Number of Stale AD Privileged Accounts: $PrivAccountsCount </li>
                    <li> Number of Stale AD Employee Accounts: $CountOfEmployees </li>
                    <li> Number of Stale AD Student Accounts: $CountOfStudents </li>

                 </ul>
                 
                 <br>Sincerely,<br>
                 <br>Monthly Report Script<br>

                  "

                  $HtmlMsg = $HtmlHead + $HtmlBody
            # Create message body and properties and send
                    $MessageParams = @{
                      "URI"         = "https://graph.microsoft.com/v1.0/users/$MsgFrom/sendMail"
                      "Headers"     = $Headers
                      "Method"      = "POST"
                      "ContentType" = 'application/json'
                      "Body" = (@{
                            "message" = @{
                            "subject" = $MsgSubject
                            "body"    = @{
                                "contentType" = 'HTML'
                                 "content"     = $htmlMsg }
                       "toRecipients" = @(
                       @{
                         "emailAddress" = @{"address" = $EmailRecipient }
                       } )
                       "attachments" = @(
                       @{
                      "@odata.type" = "#microsoft.graph.fileAttachment"
                    "name" = "$FileName"
                    "contentType" = "text/plain"
                  "contentBytes" = "$base64string"
                },
                @{
                    "@odata.type" = "#microsoft.graph.fileAttachment"
                  "name" = "$FileName1"
                  "contentType" = "text/plain"
                "contentBytes" = "$base64string1"
              },
              @{
                  "@odata.type" = "#microsoft.graph.fileAttachment"
                "name" = "$FileName2"
                "contentType" = "text/plain"
              "contentBytes" = "$base64string2"
              },
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
              "name" = "$FileName3"
              "contentType" = "text/plain"
            "contentBytes" = "$base64string3"
            }
                      
          
                       )}
                  }) | ConvertTo-JSON -Depth 6
               }   # Send the message
               Invoke-RestMethod @Messageparams


               Write-Host "Email has been sent!" -ForegroundColor "green"
    
}


##############LOGGING USER INFORMATION REGARDING WHO/WHEN THE SCRIPT WAS RAN########
$Time1 = Get-Date -format "h:mm:ss tt" 
$Date = get-date -Format "MM-dd-yy" 
#logging run as users information
"

__________($Time1 || $Date)__________" | Out-File -FilePath $HealthRunStatus -Append
whoami /user | Out-File -FilePath $HealthRunStatus -Append
#####################################################################################

#-----------------------------------PrivAccounts---------------------------------------------------#
$days = "90"
$time = (get-date).AddDays(-$days)

$OU = "---OU WHERE ALL ADMIN ACCOUNTS ARE CONTAINED---"

Write-Host "Running report for privileged accounts...." -ForegroundColor "Blue"
$PrivAccounts = Get-ADUser -Filter {((samaccountname -like "d_*")-or (samaccountname -like "a_*") -or (samaccountname -like "w_*")) -and (enabled -eq $true)-and (lastLogonDate -ne "$null") -and (lastLogonDate -lt $time)} -Server WPDC-AD01  -SearchBase $OU `
 -Properties Name, userprincipalname, lastLogonDate, whencreated, samaccountname | `
  select Name, userprincipalname, lastLogonDate, whencreated, samaccountname 
  
  $PrivAccounts| Export-Csv -Path $privAccountLogging -Append -NoTypeInformation

  Write-Host "Report for privileged accounts has been completed!" -ForegroundColor "Green"

  $PrivAccountsCount = $PrivAccounts.count

#------------------------------------------------------------------------------------------------------------#


#-------------------------------------------ADComputers------------------------------------------------------------------#
$days = "180"
$time = (get-date).AddDays(-$days)

$OUs = "---OU WHERE ALL SERVERS ARE CONTAINED---" , "---OU WHERE ALL WORKSTATIONS ARE CONTAINED---"

Write-Host "Running report for Stale AD Computer Objects...." -ForegroundColor "Blue"
Foreach ($OU in $OUs){

       

       $StaleADcomputers = Get-ADComputer -Filter {(enabled -eq $true) -and (lastLogonDate -lt $time) -and (lastLogonDate -ne "$null")} -SearchBase $OU -Properties Name, distinguishedName, lastLogonDate, Enabled, whencreated, dNSHostName `
         | select Name, distinguishedName, lastLogonDate, Enabled, whencreated, dNSHostName

        

        $StaleADcompCount =  $StaleADcomputers.count

         foreach ($StaleADcomputer in $StaleADcomputers){

         $staleADcompCSV = [PSCustomObject]@{
        
            Name = $StaleADcomputer.name
            Location = $StaleADcomputer.distinguishedName
            LastActiveDate = ([DateTime]$StaleADcomputer.lastLogonDate)
            EnabledStatus = "Enabled"
            CreationDate = ([DateTime]$StaleADcomputer.whencreated)
            DNShostname = $StaleADcomputer.dNSHostName
            TypeOfComputer = if($StaleADcomputer.distinguishedName -like "*Workstations*") {"Workstation"} elseif($StaleADcomputer.distinguishedName -like "*Servers*") {"Server"}
            

         }
        
         $staleADcompCSV | Export-csv -Path $staleADcomputersLogging -Append -NoTypeInformation -Force

        }
}
Write-Host "Report for Stale AD Computer Objects has been completed!" -ForegroundColor "Green"

#---------------------------------------------------------------------------------------------------------------------------#


    
#Calling functiont to send reports via email

SendMonthlyEmailReport