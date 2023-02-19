Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
Import-Module ActiveDirectory

#logging file path
$logPath = "C:\$(get-date -Format "yyMMdd")DisabledUsers.csv"

# Import the data from CSV file and assign it to variable
$header = "samAc"
$employees = Import-Csv "C:\Users\a_mseifu\Documents\users1.csv" -Header $header
$TargetOU = "--TARGET OU---"
foreach($emp in $employees){

    #variables for name and distinguishedname
    $name = $emp.samAc
    $DN = (Get-ADUser -Identity $name -Properties distinguishedname).distinguishedname

    Get-ADUser -Identity $name | Move-ADObject -TargetPath $TargetOU -Confirm
    Disable-ADAccount -Identity $name
    

    Get-AdPrincipalGroupMembership -Identity $name | Where-Object -Property Name -Ne -Value 'Domain Users' | Remove-AdGroupMember -Members $name
    Write-Host "Moving Accounts....."
    # Move user to target OU. Remove the -WhatIf parameter after you tested.

    
    #logging
     Get-ADUser -Identity $name -Properties memberOf, enabled, name | Select name, memberOf, enabled | Foreach { 
     if (($_.memberOf.length -lt 1) -and ($_.enabled -eq $false )) {
        "$name, has been disabled and removed from all groups, $(get-date -Format "yyyyMMdd hh:mm:ss")" |out-file $logPath -append
        Write-Host "$name has been disabled and all groups have been removed"
        } 
        else{
        "$name, has Not been disabled and removed from all groups, $(get-date -Format "yyyyMMdd hh:mm:ss")" |out-file $logPath -append
        Write-Host "$name has NOT been disabled and all groups have NOT been removed"
        }
    }

  }