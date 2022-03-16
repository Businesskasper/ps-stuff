# Verifies domain credentials by establishing a ldap connection
function VerifyDomainCredentials([PSCredential]$credentialsToCheck) {

    try {

        $domainCN = "LDAP://" + ([ADSI]"").distinguishedName
        $domainObject = [System.DirectoryServices.DirectoryEntry]::new($domainCN, $credentialsToCheck.UserName, $credentialsToCheck.GetNetworkCredential().Password)

        return -not [String]::IsNullOrWhiteSpace($domainObject.Name)
    }
    catch [Exception] {

        return $false
    }
}