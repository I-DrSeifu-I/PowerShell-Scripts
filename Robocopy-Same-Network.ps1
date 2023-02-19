$now = Get-Date -Format MM-dd-yyyy_HH_mm_ss
Start-Transcript "C:\Temp\robocopyTranscript_$now.log"
$source = \\HUASRSCHMSPP01\D$
$dest = \\HUASRSCHMSPP02\D$
if(Test-Path -Path $source){
    if(Test-Path -Path $dest){
        Write-Host "Copying $source to $dest"
        robocopy $source $dest /e /COPY:DAT /DCOPY:DAT /z /r:3 /W:5 /MT:32 /log:"C:\Temp\RobocopyLog_$now.log"
    }else{
        Write-Host "Cannot connect to $dest , exiting script"
    }
}else{
    Write-Host "Cannot connect to $source , exiting script"
    }
Stop-Transcript