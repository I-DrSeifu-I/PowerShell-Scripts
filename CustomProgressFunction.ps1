#Function for custom progress bar 
Function Print-Progress{

    param(
        [parameter(Position = 0)]
        $CurrentItem,
        [parameter(Position = 1,Mandatory)]
        $AllItems,
        [int]$startingProgress,
        [string]$status
        
    )
    #stores percentage calculation and formatting. 'F2' refers to how the percent will be no more than 2 decimals
    $currentPercentage = ((($startingProgress/$AllItems.Count)*100)).ToString("F2")
    
    If(($startingProgress) -and ($status -ne "Completed")){
        #Custom formatting for progress bar. 
        $progress = Write-Progress "Processing item $($startingProgress) of $($AllItems.Count)" `
            -PercentComplete $currentPercentage `
            -CurrentOperation "Current object: $CurrentItem" `
            -Status "Current Percentage: $currentPercentage%"

        #Returns progress bar 
        return $progress
    }else {
        #Custom formatting for progress bar. 
        $progress = Write-Progress "Processed items $($AllItems.Count) of $($AllItems.Count)" `
            -PercentComplete 100 `
            -Status "Completed all items"
  

        #Returns progress bar 
        return $progress
    }
}

#example list of names
$add = ("John", "Doe", "Sam", "John", "Doe", "Sam", "John", "Doe", "Sam")

#initializing for the foreach to start at 0 for the prgress bar
[int]$start = 0

foreach($number in $add){

    Print-Progress -CurrentItem $number `
    -AllItems $add `
    -startingProgress $start

    Start-Sleep 2

    $start++
}

Print-Progress -AllItems $add -status Completed

