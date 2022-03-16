function GetAdComputer([string]$computerName) {

    $searcher = [System.DirectoryServices.DirectorySearcher]@{
        SearchRoot = [System.DirectoryServices.DirectoryEntry]('LDAP://DC=contoso,DC=com')
        Filter     = "(&(objectCategory=computer) (objectClass=computer) (name=$($computerName)))"
        SizeLimit  = 2147483647
        PageSize   = 1000
    }

    $results = $searcher.FindAll()
    
    $resultObjects = @()
    foreach ( $result in $results ) {
        $resultObject = [PSCustomObject]::new()

        $entry = $result.GetDirectoryEntry()
        $properties = $entry.Properties

        foreach ($key in $properties.Keys) {

            $resultObject | Add-Member -MemberType NoteProperty -Name $key -Value $properties[$key].Value
        }

        $resultObjects += $resultObject
    }

    return $resultObjects
}
