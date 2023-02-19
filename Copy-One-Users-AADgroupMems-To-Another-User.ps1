#USE SAMACCOUNTNAMES
$sourceAccount = ""
$targetAccount = ""

Get-ADUser -Identity $sourceAccount -Properties memberof |`
 Select-Object -ExpandProperty memberof |`
  Add-ADGroupMember -Members $targetAccount