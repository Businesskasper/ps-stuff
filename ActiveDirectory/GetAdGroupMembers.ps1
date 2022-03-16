# Gets ad group members including nested members recursively
function GetAdGroupUsers([string]$groupName, [string[]]$users = $null) {

    if ($null -eq $users) {

        $users = @()
    }

    $search = [DirectoryServices.DirectorySearcher]::new([ADSI]::new())

    $search.filter = "(&(objectClass=group) (SAMAccountName=$($groupName)))"
    $search.SizeLimit = 2147483647
    $search.PageSize = 1000
    $result = $search.FindOne()

    if ($null -eq $result) {

        return $users
    }

    $groupObject = $result.GetDirectoryEntry()
    
    foreach ($member in $groupObject.Member) {
        
        try {

            $memberObject = [adsi]"LDAP://$($member)"
        
            if ($memberObject.objectCategory.Value.ToString() -like "CN=Person*") {

                $users += $memberObject.sAMAccountName.value
            }
            elseif ($memberObject.objectCategory.Value.ToString() -like "CN=Group*") {

                $users += GetAdGroupUsers -groupName $memberObject.sAMAccountName.value.ToString() -users $users
            }
        }
        catch {
            
            continue
        }
    }

    return $users
}
