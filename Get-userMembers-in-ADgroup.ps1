#group name
$group = "--AD Group Name--"

#logging file
$log = "C:\Logging\$group.csv"

#export all users
$Members = Get-ADGroupMember -Identity $group | Where-Object { $_.objectClass -eq 'user' } | select samaccountname #| Export-Csv -Path $log -Append

foreach($Member in $Members){
    $username = $Member.samaccountname

    Get-ADUser -Filter "samaccountname -like '$username'" -Properties name, samaccountname, userprincipalname, enabled |`
     select name, samaccountname, userprincipalname, enabled |`
      Export-Csv -Path $log -Append -NoTypeInformation
}