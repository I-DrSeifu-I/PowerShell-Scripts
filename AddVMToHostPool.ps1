#host pool registration token
$RegistrationInfoToken = ""

#this directory will be where all the installers are downloaded and ran in
$dir = ""

try {
    Set-Location -Path "C:\temp"
}
catch {
    Write-Error -Message "Unable to switch directories to $($dir) . Error = $($_)"
}


#----------remove features--------------#
$applicationsToUninstall = @(
    "Remote Desktop Agent Boot Loader",
    "Remote Desktop Services Infrastructure Agent"
)

foreach ($appName in $applicationsToUninstall) {
    $app = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%$appName%'"

    if ($app) {
        try {
            Write-Host "Uninstalling $appName..."
            $app.Uninstall() | Out-Null
            Write-Host "$appName uninstalled successfully." -ForegroundColor Green
        }
        catch {
            Write-Error -Message "Unable to uninstall $($appName) . Error = $($_)"
        }
    }
    else {
        Write-Host "$appName not found on this system." -ForegroundColor Yellow
    }
}

#---------------------------install packages-------------------------------------#

$uris = @(
    "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
    "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"
)

$installers = @()
foreach ($uri in $uris) {
    try {
        $download = Invoke-WebRequest -Uri $uri -UseBasicParsing
        Write-Host "Downloaded $uri" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Unable to download $uri . Error = $($_)"
    }

    $fileName = ($download.Headers.'Content-Disposition').Split('=')[1].Replace('"', '')
    $output = [System.IO.FileStream]::new("$pwd\$fileName", [System.IO.FileMode]::Create)
    $output.write($download.Content, 0, $download.RawContentLength)
    $output.close()
    $installers += $output.Name
}

#------------------------unblock downloaded installers--------------------------#
foreach ($installer in $installers) {
    try {
        Unblock-File -Path "$installer"
        write-host "Unblocked file $($installer)" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Unable to unblock $($installer) . Error = $($_)"
    }
}

#--------------------run installers---------------------------------------------#
try {
    $fileRDAinstaller = (Get-ChildItem -Path "$(get-location)\Microsoft.RDInfra.RDAgent.Installer*").Name
    $fileRDABootLoaderinstaller = (Get-ChildItem -Path "$(get-location)\Microsoft.RDInfra.RDAgentBootLoader*").Name
}
catch {
    Write-Error -Message "Unable to find the installed file. Error = $($_)" 
}


cmd.exe /c "msiexec /i $fileRDAinstaller /quiet REGISTRATIONTOKEN=$RegistrationInfoToken"

cmd.exe /c "msiexec /i $fileRDABootLoaderinstaller /quiet"
