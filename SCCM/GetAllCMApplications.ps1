function GetAllCMApplications() {

    Import-Module (Join-Path -Path $(Split-Path $env:SMS_ADMIN_UI_PATH) -ChildPath "ConfigurationManager.psd1") -ErrorAction Stop | Out-Null
    $sitecode = Get-CimInstance -Namespace "root\sms" -ClassName "SMS_ProviderLocation" -Property SiteCode -KeyOnly | select -ExpandProperty SiteCode -ErrorAction Stop    
    
    $allApplications = @()

    [array]$appDeployments = Get-WmiObject -ComputerName $siteServerFQDN -Namespace "root\sms\site_$($SiteCode)" -Class SMS_DeploymentSummary
    [array]$applications = Get-WmiObject -ComputerName $siteServerFQDN -Namespace "root\sms\site_$($SiteCode)" -Class SMS_Applicationlatest

    foreach ($application in $applications) {

        $app = [PSCustomObject]@{
            LocalizedDisplayName           = $application.LocalizedDisplayName
            LocalizedCategoryInstanceNames = $application.LocalizedCategoryInstanceNames
            IsUserApp                      = $false
            IsComputerApp                  = $false
        }
            
        if ($app.LocalizedDisplayName -in ($appDeployments | select -ExpandProperty ApplicationName)) {

            [array]$deploymentCollections = $appDeployments | ? { $_.ApplicationName -eq $app.LocalizedDisplayName } | select -ExpandProperty CollectionID
            foreach ($deploymentCollection in $deploymentCollections) {

                $collectionType = Get-WmiObject -ComputerName $siteServerFQDN -Namespace "root\sms\site_$($SiteCode)" -Class SMS_Collection -Filter "CollectionID = '$($deploymentCollection)'" -Property CollectionType | select -ExpandProperty CollectionType  
                $appObject.IsUserApp = $collectionType -eq 1
                $appObject.IsComputerApp = $collectionType -eq 2
            }       
        }

        $allApplications += $appObject
    }
 
    return $allApplications
}

