# Creates and signes certificates. Uses CopyCertificate.ps1
# Example which creates a ca and signes a client and a ssl certificate:

# $rootCert = CreateSignedCertificate -signer -commonName "RootCert"
# $clientCert = CreateSignedCertificate -client -commonName "Client" -signerThumbprint $rootCert.Thumbprint
# $sslCert = CreateSignedCertificate -ssl -dnsName "site.contoso.com" -commonName "SSL" -signerThumbprint $rootCert.Thumbprint

function CreateSignedCertificate {

    param(

        [Parameter(ParameterSetName = 'Signer')]
        [switch]$signer,

        [Parameter(ParameterSetName = 'Client')]
        [switch]$client,

        [Parameter(ParameterSetName = 'SSL')]
        [switch]$ssl,

        [string]$commonName = $env:COMPUTERNAME,

        [string]$dnsName = "$($env:COMPUTERNAME).$($env:USERDOMAIN)",

        [Parameter(ParameterSetName = "Client")]
        [Parameter(ParameterSetName = "SSL")]
        [string]$certStore = "Cert:\LocalMachine\My",

        [string]$exportCaPath = $null,
        
        [string]$exportPfxPath = $null,

        [SecureString]$exportPfxPassword = $null,

        [Parameter(ParameterSetName = "Client")]
        [Parameter(ParameterSetName = "SSL")]
        [string]$signerThumbprint = $null
    )

    $p = @{
        Subject           = "CN=$($commonName)"
        KeyExportPolicy   = "Exportable"
        NotAfter          = (Get-Date).AddMonths(24)
        KeySpec           = "KeyExchange"
        HashAlgorithm     = "sha256" 
        KeyLength         = "2048"
        CertStoreLocation = "Cert:\LocalMachine\My"
    }

    if (-not [String]::IsNullOrWhiteSpace($dnsName)) {

        $p += @{
            DnsName = $dnsName
        }
    }

    if ($PsCmdlet.ParameterSetName -eq "Signer") {

        Write-Debug -Message "Create CA certificate for $($commonName)"
        $p += @{
            KeyUsage         = @("KeyEncipherment", "DigitalSignature", "CertSign", "cRLSign")
            KeyusageProperty = "All"
            TextExtension    = @("2.5.29.19 ={critical} {text}ca=1&pathlength=3")
        }
    }
    else {
    
        if (-not [String]::IsNullOrWhiteSpace($signerThumbprint)) {

            $signerCert = CopyCertificate -certificateThumbprint $signerThumbprint -destination "Cert:\LocalMachine\My"
            if ($null -ne $signerCert) {

                $p += @{
                    Signer = $signerCert
                }
            }
        }
        if ($PsCmdlet.ParameterSetName -eq "Client") {
            
            Write-Debug -Message "Create Client certificate for $($commonName)"
            $p += @{
                KeyUsage = @("KeyEncipherment", "DigitalSignature")
            }
        }
        elseif ($PsCmdlet.ParameterSetName -eq "SSL") {
            
            Write-Debug -Message "Create SSL certificate for $($commonName)"
        }
    }

    try {

        $cert = New-SelfSignedCertificate @p
    }
    finally {

        if ($signerCert) {

            Remove-Item -Path $signerCert.PSPath
        }
    }

    if (-not [String]::IsNullOrWhiteSpace($exportCaPath)) {

        Write-Debug -Message "Export certificate without private key to `"$($exportCaPath)`""
        Export-Certificate -Cert $cert -FilePath $exportCaPath
    }

    if (-not [String]::IsNullOrWhiteSpace($exportPfxPath) -and -not $null -eq $exportPfxPassword) {

        Write-Debug -Message "Export certificate with private key to `"$($exportPfxPath)`""
        Export-PfxCertificate -Cert $cert -FilePath $exportPfxPath -Password $exportPfxPassword
    }

    if ($PsCmdlet.ParameterSetName -eq "Signer") {
        
        Write-Debug -Message "Move certificate to `"Cert:\LocalMachine\Root`""
        Move-Item -Path ([System.IO.Path]::combine("Cert:\LocalMachine\My", $cert.Thumbprint)) -Destination "Cert:\LocalMachine\Root"
    }
    elseif (
        (-not [String]::IsNullOrWhiteSpace($certStore) -and (Test-Path -Path $certStore)) -and 
        ($cert.PSParentPath -ne (Get-Item -Path $certStore).PSPath)
    ) {

        Write-Debug -Message "Move certificate to `"$($certStore)`""
        Move-Item -Path ([System.IO.Path]::combine("Cert:\LocalMachine\My", $cert.Thumbprint)) -Destination $certStore
    }

    return Get-ChildItem -Path "Cert:\LocalMachine" -Recurse | ? { $_.Thumbprint -eq $cert.Thumbprint } | select -First 1
}