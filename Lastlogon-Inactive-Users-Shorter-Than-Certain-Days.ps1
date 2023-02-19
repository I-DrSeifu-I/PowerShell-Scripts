$todaysdate = get-date -Format "yy-MM-dd"
$exportfilepath = ""

#Put in the number of days which a user has been inactive for
$InactiveDays = "90"

Get-ADUser -Filter {(enabled -eq $true) } `
-Properties Name, userprincipalname, lastLogonDate, whencreated| where {($_.DistinguishedName -notlike "*OU=Disbaled*") -and ($_.DistinguishedName -notlike "*OU=Service Accounts*")} |`
where-object {($_.lastLogonDate -gt (Get-Date).AddDays(-$($InactiveDays)))}| `
Select-Object Name, userprincipalname, lastLogonDate, whencreated `
| export-csv -Path $exportfilepath -Append -notypeinformation -force 