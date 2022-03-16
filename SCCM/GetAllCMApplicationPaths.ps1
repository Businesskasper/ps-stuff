function GetAllCMApplicationPaths() {

    Import-Module (Join-Path -Path $(Split-Path $env:SMS_ADMIN_UI_PATH) -ChildPath "ConfigurationManager.psd1") -ErrorAction Stop | Out-Null

    $sitecode = Get-CimInstance -Namespace "root\sms" -ClassName "SMS_ProviderLocation" -Property SiteCode -KeyOnly | select -ExpandProperty SiteCode -ErrorAction Stop
    cd "$($sitecode):"
    Set-CMQueryResultMaximum 50000
    
    $deploymentTypes = @()

    $applications = Get-CMApplication | select LocalizedDisplayName, SDMPackageXML -ErrorAction Stop | Sort-Object -Property LocalziedDisplayName
    foreach ($application in $applications) {

        $sdPackageXML = $application.SDMPackageXML.ToString()
        $sdPackageXMLDeserialized = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($sdPackageXML)
        foreach ($deploymentType in $sdPackageXMLDeserialized.DeploymentTypes) {

            $deploymentTypes += [PSCustomObject]@{
                title               = $deploymentType.Title
                deploymentTypePaths = $deploymentType.Installer.Contents | select -ExpandProperty Location
            }

        }
    }

    return $deploymentTypes
}


