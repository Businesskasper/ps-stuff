# Tihs includes functions to encrypt and read back secrets on a specific machine.
# Can be used to store encrypted passwords on server which runs a scheduled task.
# This way the script can be checked into source control and nothing gets leaked.

# Example usage

# Create an encryption certificate with a non exportable private key:
$encryptionCert = createCertificate -CommonName "ScheduledTaskSecrets"
$cipheredPassword = encrypt -CertificateThumbprint $encryptionCert.Thumbprint -Text "MyStrongPassword"

# Store the cipheredPassword in the script which is run on the local machine:
$encryptedPassword = '...'
$decryptedPassword = decrypt -CertificateThumbprint 'encryptionCertThumbprint' -CipherText $encryptedPassword


function createCertificate ([string]$CommonName) {

    $arguments = @{
        Subject           = $CommonName
        HashAlgorithm     = "sha256"
        KeyLength         = 2048
        NotAfter          = (Get-Date).AddMonths(24) 
        CertStoreLocation = "Cert:\LocalMachine\My"
        KeyUsage          = "KeyEncipherment", "DataEncipherment", "KeyAgreement", "DigitalSignature"
        KeyusageProperty  = "All"
        TextExtension     = @("2.5.29.19 ={critical} {text}ca=1&pathlength=3")
        KeySpec           = "KeyExchange"
        Type              = "DocumentEncryptionCert"
        KeyExportPolicy   = "NonExportable"
    }
        
    return New-SelfSignedCertificate @arguments
}

function encrypt([string] $Text, [string] $CertificateThumbprint) {

    $certificate = Get-ChildItem -Path Cert:\LocalMachine\My | ? { $_.Thumbprint -eq $CertificateThumbprint } | select -First 1
    $byteText = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $encrypted = $certificate.PublicKey.Key.Encrypt($byteText, $false)

    return [System.Convert]::ToBase64String($encrypted)
}

function decrypt([string] $CipherText, [string] $CertificateThumbprint) {

    $certificate = Get-ChildItem -Path Cert:\LocalMachine\My | ? { $_.Thumbprint -eq $CertificateThumbprint } | select -First 1
    $byteText = [System.Convert]::FromBase64String($CipherText)
    $decrypted = $certificate.PrivateKey.Decrypt($byteText, $false)

    return [System.Text.Encoding]::UTF8.GetString($decrypted)
}
