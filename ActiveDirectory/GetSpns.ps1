# Gets all service principal names 
function GetSpns() {

    $search = New-Object DirectoryServices.DirectorySearcher([ADSI]"")
    $search.filter = "(servicePrincipalName=*)"
    $search.SizeLimit = 2147483647
    $search.PageSize = 1000
    $results = $search.Findall()

    $resultObjects = @()
    foreach ( $result in $results ) {
    
        $userEntry = $result.GetDirectoryEntry()

        $resultObjects += @{

            ObjectName        = $userEntry.name.Value
            DistinguishedName = $userEntry.distinguishedName.Value
            ObjectCategory    = $userEntry.objectCategory.Value
            SPNs              = $userEntry.servicePrincipalName.Value
        }
    }

    return $resultObjects
}
