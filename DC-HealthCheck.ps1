
$AppId = "AAD APP ID"
$AppSecret = "AAD AAP SECRET"
$TenantId = "TENANT ID"

# Construct URI and body needed for authentication
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    client_id     = $AppId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $AppSecret
   grant_type    = "client_credentials"
}

#$logDestination = out-file -FilePath ""
#=======================================================================
# Servers
$ServerNames = Get-Content -Path "C:\DC-Healthcheck\DCservers.txt"

#=======================================================================
# Setup email parameters
$SubDate = (Get-Date).ToString('MMMM-dd')
$subject = "Domain Controllers - " + $SubDate


#=======================================================================

$output = $null
$DCDiag = @()
$ADServices = @()
$ADSystem = @()

#======================  FUNCTIONS  =======================================================================  
    function Get-ADSystem {
         
    [CmdletBinding()]
    [OutputType([Array])] 
    param
    (
        [Parameter(Position=0, Mandatory = $true, HelpMessage="Provide server names", ValueFromPipeline = $true)]
        $Server
    )

    $SystemArray = @()

        $Server = $Server.trim()
        $Object = "" | Select ServerName, BootUpTime, UpTime, "Physical RAM", "C: Free Space", "Memory Usage", "CPU usage"
                        
        $Object.ServerName = $Server

        # Get OS details using WMI query
        $os = Get-WmiObject win32_operatingsystem -ComputerName $Server -ErrorAction SilentlyContinue | Select-Object LastBootUpTime,LocalDateTime
                        
        If($os)
        {
            # Get bootup time and local date time  
            $LastBootUpTime = [Management.ManagementDateTimeConverter]::ToDateTime(($os).LastBootUpTime)
            $LocalDateTime = [Management.ManagementDateTimeConverter]::ToDateTime(($os).LocalDateTime)

            # Calculate uptime - this is automatically a timespan
            $up = $LocalDateTime - $LastBootUpTime
            $uptime = "$($up.Days) days, $($up.Hours)h, $($up.Minutes)mins"

            $Object.BootUpTime = $LastBootUpTime 
            $Object.UpTime = $uptime
        }
        Else
        {
            $Object.BootUpTime = "(null)" 
                $Object.UpTime = "(null)"
        }

        # Checking RAM, memory and cpu usage and C: drive free space
        $PhysicalRAM = (Get-WMIObject -class Win32_PhysicalMemory -ComputerName $server | Measure-Object -Property capacity -Sum | % {[Math]::Round(($_.sum / 1GB),2)})
                        
        If($PhysicalRAM)
        {
            $PhysicalRAM = ("$PhysicalRAM" + " GB")
            $Object."Physical RAM"= $PhysicalRAM
        }
        Else
        {
            $Object.UpTime = "(null)"
        }
   
        $Mem = (Get-WmiObject -Class win32_operatingsystem -ComputerName $Server  | Select-Object @{Name = "MemoryUsage"; Expression = { "{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize)}}).MemoryUsage
                       
        If($Mem)
        {
            $Mem = ("$Mem" + " %")
            $Object."Memory Usage"= $Mem
        }
        Else
        {
            $Object."Memory Usage" = "(null)"
        }

        $Cpu =  (Get-WmiObject win32_processor -ComputerName $Server  |  Measure-Object -property LoadPercentage -Average | Select Average).Average 
                        
        If($PhysicalRAM)
        {
            $Cpu = ("$Cpu" + " %")
            $Object."CPU usage"= $Cpu
        }
        Else
        {
            $Object."CPU Usage" = "(null)"
        }

        $FreeSpace =  (Get-WmiObject win32_logicaldisk -ComputerName $Server -ErrorAction SilentlyContinue  | Where-Object {$_.deviceID -eq "C:"} | select @{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}}).freespace 
                        
        If($FreeSpace)
        {
            $FreeSpace = ("$FreeSpace" + " GB")
            $Object."C: Free Space"= $FreeSpace
        }
        Else
        {
            $Object."C: Free Space" = "(null)"
        }

        $SystemArray += $Object 
 
        $SystemArray 
} 
  
#============================================================================================================== 
  function Get-DCDiag {
         
    [CmdletBinding()]
    [OutputType([Array])] 
    param
    (
        [Parameter(Position=0, Mandatory = $true, HelpMessage="Provide server names", ValueFromPipeline = $true)]
        $Computername
    )
    $DCDiagArray = @()

            # DCDIAG ===========================================================================================
            $Dcdiag = (Dcdiag /skip:systemlog /s:$Computername) -split ('[\r\n]')
            $Results = New-Object Object
            $Results | Add-Member -Type NoteProperty -Name "ServerName" -Value $Computername
            $Dcdiag | %{ 
            Switch -RegEx ($_) 
            { 
                "Starting test"      { $TestName   = ($_ -Replace ".*Starting test: ").Trim() } 
                "passed test|failed test" { If ($_ -Match "passed test") {  
                $TestStatus = "Passed"  
                # $TestName 
                # $_ 
                }  
                Else  
                {  
                $TestStatus = "Failed"  
                # $TestName 
                # $_ 
                } 
                } 
            } 
            If ($TestName -ne $Null -And $TestStatus -ne $Null) 
            { 
                $Results | Add-Member -Name $("$TestName".Trim()) -Value $TestStatus -Type NoteProperty -force 
                $TestName = $Null; $TestStatus = $Null 
            } 
            } 
            $DCDiagArray += $Results

    $DCDiagArray
            
}
#============================================================================================================== 
  function Get-ADServices {
         
    [CmdletBinding()]
    [OutputType([Array])] 
    param
    (
        [Parameter(Position=0, Mandatory = $true, HelpMessage="Provide server names", ValueFromPipeline = $true)]
        $Computername
    )

    $ServiceNames = "HealthService","NTDS","NetLogon","DFSR"
    $ErrorActionPreference = "SilentlyContinue"
    $report = @()

        $Services = Get-Service -ComputerName $Computername -Name  $ServiceNames

        If(!$Services)
        {
            Write-Warning "Something went wrong"
        }
        Else
        {
            #Adding properties to object
            $Object = New-Object PSCustomObject
            $Object | Add-Member -Type NoteProperty -Name "ServerName" -Value $Computername

            foreach($item in $Services)
            {
                $Name = $item.Name
                $Object | Add-Member -Type NoteProperty -Name "$Name" -Value $item.Status 
            }
            
            $report += $object 
        }
    
    $report
}

#=======================================================================
#Add Text to the HTML file 
Function Create-HTMLTable{
        
    param([array]$Array)
        
    $arrHTML = $Array | ConvertTo-Html
    $arrHTML[-1] = $arrHTML[-1].ToString().Replace('</body></html>',"")
        
    Return $arrHTML[5..2000]
}
#====================== END FUNCTIONS  =======================================================================  

#=======================================================================
#Creating head style 
$output = @()
$output += '<html><head></head><body>'
$output += 
@"
<style>
  body {
    font-family: "Arial";
    font-size: 7pt;
    }
  th, td, tr { 
    border: 1px solid #A4A4A4;
    border-collapse: collapse;
    padding: 10px;
    text-align: center;
    }
  th {
    font-size: 8pt;
    text-align: center;
    background-color: #0B2161;
    color: #EFF2FB;
    }
  td {
    color: #000000;
    
    }
  .even { background-color: #E6E6E6; }
  .odd { background-color: #084B8A; }
  h6 { font-size: 8pt; 
       font-color: black;
       font-weight: bold;
       }

text { font-size: 7pt;
        font-color: black;
        }
}
</style>
"@
$output += "<h2 style='color: #0B2161'>Domain Controllers</h2>"


#=======================================================================
# Looping servers
ForEach ($Server in $ServerNames) 
{
        $Server = $Server.Trim()
        $CheckPath = $null

        Write-Host "Processing $Server " -ForegroundColor Green -NoNewline
        
        # Check if server is up
        Try
        {
            $CheckPath = Test-Path "\\$Server\c$" -ErrorAction Stop
        }
        Catch 
        {
            $_.Exception.Message
            Continue
        }

        If($CheckPath -notmatch "True")
        {
            Write-Warning "Failed to connect to $Server"
        }
        Else
        {
            Write-Host "DCDIAG, " -NoNewline
            $DCDiagCheck = $Server | Get-DCDiag

            Write-Host "AD Services, " -NoNewline
            $ADServicesCheck = $Server | Get-ADServices

            Write-Host "AD System "
            $ADSystemCheck = $Server| Get-ADSystem


            $DCDIAG += $DCDiagCheck
            $ADServices += $ADServicesCheck
            $ADSystem += $ADSystemCheck
        }
}
$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@
$DomainAdmin = (Get-ADgroup -Identity "Domain Admins" -Properties members).members | Get-ADUser | Select-Object name, samaccountname| ConvertTo-Html -Head $Header
#======================  Preparing output  =======================================================================  
                #Variables
                $Date = Get-Date

                #Checking DCDIAG:"
                $output += '<p>'
                $output += '<h4>DCDIAG:</h4>'
                $output += '<p>'
                $output += Create-HTMLTable $DCDiag
                $output += '</p>' 

                #Checking AD Services:"
                $output += '<p>'
                $output += '<h4>AD Services:</h4>'
                $output += '<p>'
                $output += Create-HTMLTable $ADServices
                $output += '</p>'

                #Checking System information:"
                $output += '<p>'
                $output += '<h4>System information:</4>'
                $output += '<p>'
                $output += Create-HTMLTable $ADSystem
                $output += '<p>'
                $output += '</p>'

                $output += '<p>'
                $output += '<h4>Domain Admins</h4>'
                $output +=  $DomainAdmin
                $output += '<p>'
                $output += '</p>'

                $output += "<h5>Date and time: $Date</h5>"

                # End
                $output += '</body></html>' 

                #The Out-String cmdlet converts the objects that Windows PowerShell manages into an array of strings.
                $output =  $output | Out-String

#=======================================================================
#Continue if report was created
If(!$output)
{
    Write-Warning "Failed to create report"
}
Else
{
    # Color failed values
    $colorTagTable = @{ 
                        Stopped = ' bgcolor="red">Stopped<';
                        "Failed" = ' bgcolor="red">Failed<'
    }

    $colorTagTable.Keys | foreach { $output = $output -replace ">$_<",($colorTagTable.$_) }  

    #  Send mail code===================================================
    # Use loop to do 5 attempts in case of failure
    $n=1
    do 
    {
        $ErrorMessage = $null
        Write-Host "Attempt $n - Sending email"
                        
        #Send email
        #Send-MailMessage -ErrorAction SilentlyContinue -ErrorVariable SendError -To $emailTo -Subject $subject -BodyAsHtml $output -SmtpServer $smtpServer -port $port -From $emailFrom -Priority $priority
         
        
        $tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
        # Unpack Access Token
        $token = ($tokenRequest.Content | ConvertFrom-Json).access_token
        $Headers = @{
                    'Content-Type'  = "application\json"
                   'Authorization' = "Bearer $Token" }
                    $MsgFrom = "ets-automation@howard.edu"
                  
                    # Define attachment to send to new users
                          $EmailRecipient = ""
                          $MsgSubject = "$subject"
                          $HtmlBody = $output
                          $htmlHeaderUser = "&lt;h2>New User " + $EmailRecipient + "&lt;/h2>"

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
                   }
                  }) | ConvertTo-JSON -Depth 6
               }   # Send the message
               Invoke-RestMethod @Messageparams
              

        $ErrorMessage = $SendError.exception.message
        If($ErrorMessage)
        {
            Write-Warning "$ErrorMessage"
            Start-Sleep -Seconds 5
        }
        
        $n++
    } 
    until ( $SendError.exception.message -eq $null -or $n -eq 6 )

    If($SendError.exception.message -eq $null)
    {
        Write-Host "`nEmail has been sent to $emailto" -ForegroundColor Yellow
    }
    Else
    {
        Write-Host "`nFailed to sent email to $emailto" -ForegroundColor Yellow
    }

}
#=======================================================================

 