$todaysdate = get-date -Format "yy-MM-dd"
$exportfilepath = ""
$InactiveDays = ""

Get-ADUser -Filter {(enabled -eq $true) } `
-Properties Name, userprincipalname, lastLogonDate, whencreated| where {($_.DistinguishedName -notlike "*OU=Disbaled*") -and ($_.DistinguishedName -notlike "*OU=Service Accounts*")} |`
where-object {($_.lastLogonDate -lt (Get-Date).AddDays(-$($InactiveDays)))}| `
Select-Object Name, userprincipalname, lastLogonDate, whencreated `
| export-csv -Path $exportfilepath -Append -notypeinformation -force 