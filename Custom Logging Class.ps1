class Logging {

    [string]$Private:message
    [string]$Private:LogFile
    [string]$Private:status
    
    Logging([string]$message, [string]$LogFile, [string]$status = "info") {
        if (-not $message) { throw [ArgumentNullException]::new("message cannot be null or empty") }
        if (-not $LogFile) { throw [ArgumentNullException]::new("LogFile cannot be null or empty") }

        $this.message = $message
        $this.LogFile = $LogFile
        $this.status = $status
    }

    [void] SetMessage([string]$message) {
        if (-not $message) { throw [ArgumentNullException]::new("message cannot be null or empty") }
        $this.message = $message
    }

    [string] GetMessage() {
        return $this.message
    }

    [void] SetStatus([string]$status) {
        $this.status = if ($status) { $status } else { "info" }
    }

    [string] GetStatus() {
        return $this.status
    }

    [void] OutputLog() {
        if (-not $this.status -or $this.status -eq "") {
            $this.status = "info"
        }

        $timestamp = Get-Date -Format "MM-dd-yy | hh:mm:ss tt"
        $logEntry = ""

        switch (($this.status).ToLower()) {
            "info" {
                $logEntry = "[INFO][$timestamp] $($this.message)"
                Write-Host $logEntry -ForegroundColor Cyan
            }
            "success" {
                $logEntry = "[SUCCESS][$timestamp] $($this.message)"
                Write-Host $logEntry -ForegroundColor Green
            }
            "warning" {
                $logEntry = "[WARNING][$timestamp] $($this.message)"
                Write-Host $logEntry -ForegroundColor Yellow
            }
            "error" {
                $logEntry = "[ERROR][$timestamp] $($this.message)"
                Write-Host $logEntry -ForegroundColor Red
            }
            default {
                $logEntry = "*[$timestamp] $($this.message)"
                Write-Host $logEntry -ForegroundColor Cyan
            }
        }

        try {
            if (-not (Test-Path $this.LogFile)) {
                New-Item -ItemType File -Path $this.LogFile -Force | Out-Null
            }
            $logEntry | Out-File -FilePath $this.LogFile -Append -ErrorAction Stop
        } catch {
            Write-Host "Failed to write to log file: $($this.LogFile). Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

$logExample = [logging]::new("starting script", ".\Newtext.txt", "info")

$logExample.SetMessage("Logged Successfully again!"), $logExample.SetStatus("Success")
$logExample.OutputLog()


