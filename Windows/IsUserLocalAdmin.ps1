# Checks if a user is local admin through direct or indirect group membership.
# Uses IsUserInGroup.ps1
function IsUserLocalAdmin([PSCredential]$credentialsToCheck) {
        
    try {

        # Get the name of the local admin group (german <> english)
        $adsiConnection = [ADSI]::new("WinNT://$($env:COMPUTERNAME)")
        $adminGroup = $adsiConnection.Children | ? { $_.Path -in @("WinNT://$($env:USERDOMAIN)/$($env:COMPUTERNAME)/Administratoren", "WinNT://$($env:USERDOMAIN)/$($env:COMPUTERNAME)/Administrators") } | select -First 1

        if ($null -eq $adminGroup -or [String]::IsNullOrWhiteSpace($adminGroup.Name)) {

            return $false
        }

        $userName = $credentialsToCheck.UserName.Replace("$($env:USERDOMAIN)\", "")
        
        return IsUserInGroup -userName $userName -groupObject $adminGroup -hops 0
        
    }
    catch [Exception] {

        return $false
    }
}