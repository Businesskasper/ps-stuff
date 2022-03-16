# Gets a windows users SID.
# Example: GetUserSid -userName "CONTOSO\Administrator"
function GetUserSid([string]$userName = $null) {
    
    if ([String]::IsNullOrWhiteSpace($userName)) {
        $userName = "$($env:USERDOMAIN)\$($env:USERNAME)"
    }
    $runningUserObject = [System.Security.Principal.NTAccount]::new($userName)

    return $runningUserObject.Translate([System.Security.Principal.SecurityIdentifier]).value
}