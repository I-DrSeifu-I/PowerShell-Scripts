$export = "C:\Export\Number-Breakdown.csv"

$OUToBreakdown = "---BASE OU TO BREAK DOWN---"

$ous = Get-ADOrganizationalUnit -Filter * -SearchBase $OUToBreakdown | Select-Object -ExpandProperty DistinguishedName
$ous | ForEach-Object{
    $result  = [PSCustomObject]@{
        OU = $_
        Count = (Get-ADUser -Filter * -SearchBase "$_").count
    }

    $result | Export-Csv -path $export -Append -NoTypeInformation
}