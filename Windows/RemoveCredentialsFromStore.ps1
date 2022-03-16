# Removes credentials from the credential store by filter.
# Useful after you updated your ad password and still have cached credentials.
function RemoveCredentialsFromStore([string]$filter = $env:USERNAME) {

    $credentials = cmdkey /list | Out-String
    
    $splitCredentials = $credentials.Split([Environment]::NewLine) | ? { -not ([String]::IsNullOrWhiteSpace($_)) }
    
    for ($i = 0; $i -lt $splitCredentials.Count; $i++) { 
        if ($splitCredentials[$i] -like "*$($filter.ToUpper())*") {
    
            $target = $null
    
            if ($splitCredentials[$i] -like "*Target:*" -or $splitCredentials[$i] -like "*Ziel:*") {
    
                #Allgmeine Credentials
                $target = $splitCredentials[$i].Replace("Ziel:", "").Replace("Target:", "").Trim()
            }
            else {
    
                #Domänen Credentials
                $target = $splitCredentials[$i - 2]
                if ($target -ne $null -and ($target -like "*Ziel:*" -or $target -like "*Target:*")) {
    
                    $target = $target.Replace("Ziel:", "").Replace("Target:", "").Trim()
                }
            }
    
            if ($target -ne $null) {
    
                $target
                & cmdkey /del:$($target) | Out-String
            }
        }
    }
}
