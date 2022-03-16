# Checks if a user is either a direct or indirect member of a group
# Example: IsUserInGroup -userName "CONTOSO\John.Doe" -groupObject ([adsi]::new("WinNT://$($env:COMPUTERNAME)/Administratoren"))
function IsUserInGroup([string]$userName, [adsi]$groupObject, [int]$maxHops = 5, [int]$currentHop = 1) {

    if ($currentHop -ge $maxHops) {

        return $false
    }

    $members = $groupObject.Invoke("Members")
    $memberObjects = @()
    foreach ($member in $members) {

        $memberObjects += [PSCustomObject]@{

            Name       = $member.GetType().InvokeMember("Name", 'GetProperty', $null, $member, $null)
            Class      = $member.GetType().InvokeMember("Class", 'GetProperty', $null, $member, $null)
            Path       = $member.GetType().InvokeMember("Adspath", 'GetProperty', $null, $member, $null)
            AdsiObject = $member
        }
    }

    if ($userName -in ($memberObjects | ? { $_.Class -eq "User" } | select -ExpandProperty Name)) {

        return $true
    }

    foreach ($memberGroup in ($memberObjects | ? { $_.Class -eq "Group" })) {

        if (IsUserInGroup -userName $userName -groupObject $memberGroup.AdsiObject -hops ($hops + 1)) {

            return $true
        }
    }

    return $false
}