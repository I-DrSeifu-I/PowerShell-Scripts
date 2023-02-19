$svrObjs = @()

$OUpath = 'OU=All Servers,DC=howardu,DC=net'

$ExportPath = 'C:\Users\d_vhoang\Desktop\localAdminMembers.csv'

$servers = Get-ADComputer -Filter * -SearchBase $OUpath|Where-Object { ($_.DistinguishedName -notlike "*Retired*")} | Select-object DistinguishedName,DNSHostName,Name

#$servers = 'APS1WRKRV1','fist'

function Get-LocalGroupUsers {

    param (

        [Parameter(Mandatory = $true)]

        [String]

        $group,$serverName

    )

    # ADSI does NOT support 2016 Nano, meanwhile Get-LocalGroupMember does NOT support downlevel and also has bug

    $ComputerName = $env:COMPUTERNAME

    try {

        $groupconnection = [ADSI]("WinNT://$serverName/$group,group")

        $contents = $groupconnection.Members() | ForEach-Object {

            $path=$_.GetType().InvokeMember("ADsPath", "GetProperty", $NULL, $_, $NULL)

            # $path will looks like:

            # WinNT://ComputerName/Administrator

            # WinNT://DomainName/Domain Admins

            # Find out if this is a local or domain object and trim it accordingly

            if ($path -like "*/$ComputerName/*"){

                $start = 'WinNT://' + $ComputerName + '/'

            }

            else {

                $start = 'WinNT://'

            }

            $name = $path.Substring($start.length)

            $name.Replace('/', '\') #return name here

        }

        return $contents

    }

    catch { # if above block failed (say in 2016Nano), use another cmdlet

        # clear existing error info from try block

        $Error.Clear()

        #There is a known issue, in some situation Get-LocalGroupMember return: Failed to compare two elements in the array.

        $contents = Invoke-Command -ComputerName $serverName -ScriptBlock{net localgroup $group}

        $names = $contents.Name | ForEach-Object {

            $name = $_

            if ($name -like "$ComputerName\*") {

                $name = $name.Substring($ComputerName.length+1)

            }

            $name

        }

        return $names

    }

   

}

foreach($server in $servers){

    $serverName = $server.name

    $group = 'Administrators'

    write-host $serverName

    $AdminGroupMembers = Get-LocalGroupUsers -group $group -serverName $serverName

        $srvInfo =[pscustomobject]@{

            'ServerName' = $serverName

            'GroupName' = $group

            'AdminGroupMembers' = (@($AdminGroupMembers) -join',')

        }

        $svrObjs += $srvInfo

}

$svrObjs | Export-Csv -NoTypeInformation -Path $ExportPath