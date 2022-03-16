# Copies a certificate from one store to another.
function CopyCertificate([string]$certificateThumbprint, [string]$destination) {

    $sourceCert = Get-ChildItem -Path cert:\ -Recurse | ? { $_.Thumbprint -eq $certificateThumbprint } | select -First 1
    if ($null -eq $sourceCert) {

        throw [Exception]::new("Cert with thumbprint `"$($certificateThumbprint)`" not found")
    }

    $destinationStore = Get-Item -Path $destination
    
    $destinationStore.Open("ReadWrite") | Out-Null
    
    try {

        $destinationStore.Add($sourceCert) | Out-Null
    }
    finally {
        
        $destinationStore.Close() | Out-Null
    }
        

    return Get-Item -Path ([System.IO.Path]::combine($destination, $certificateThumbprint))
}

