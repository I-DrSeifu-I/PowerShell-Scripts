Import-Module -Name ActiveDirectory

#logf file patch
$logPath = "C:\$(get-date -Format "yyMMdd")PHINetComputerGroupMemCheck.txt"

#List of computers
$Computers = Import-Csv "C:\Users\a_mseifu\Documents\CoD-Computers-JAN010522.csv" -Header "name"

#Loop through all computers in the list to see if they are part of the specified group
foreach($Computer in $Computers){

#Variable for storing name
$ComName = $Computer."name"

#Variable for AD group
$ADgroup = ""

#test to see if computer exists in AD  
$test = Get-ADComputer -Filter { Name -eq $ComName }

#Searchs through AD for the computers group memberships
$groupMem = Get-ADComputer -Identity $ComName -Properties memberof | select -Expand memberof


#Logging for results
if (($groupMem -like "*$ADgroup*")) 
{
    "$ComName, Computer is in $ADgroup, $(get-date -Format "yyyyMMdd hh:mm:ss")" |out-file $logPath -append 
            Write-Host "$ComName is in $ADgroup"
            }

else
{
    "$ComName, Computer is not in $ADgroup group, $(get-date -Format "yyyyMMdd hh:mm:ss")" |out-file $logPath -append
        Write-Host "$ComName is not in $ADgroup"
    
}

 if($test){
      Write-Output "Computer object $server exists in AD" 
    }
  
  else{
  "$ComName, Computer is not in $ADgroup group, $(get-date -Format "yyyyMMdd hh:mm:ss")" |out-file $logPath -append
    Write-Output "Computer object $ComName does not exist in AD" | Out-File $logPath -append

    }

   

    }

    
