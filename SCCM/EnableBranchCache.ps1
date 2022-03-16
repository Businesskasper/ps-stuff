Get-CMDistributionPoint | Set-CMDistributionPoint -EnableBranchCache $true

Get-CMSoftwareUpdateDeployment | Set-CMSoftwareUpdateDeployment -UseBranchCache $true

Get-CMApplicationDeployment | % {

    $appName = $_.ApplicationName

    Get-CMDeploymentType -ApplicationName $appName | % {

        if ($_.Technology -match "Script") {
            Set-CMScriptDeploymentType -ApplicationName $appName -DeploymentTypeName $_.LocalizedDisplayName -EnableBranchCache $true
        }
        elseif ($_.Technology -match "MSI") {

            Set-CMMsiDeploymentType -ApplicationName $appName -DeploymentTypeName $_.LocalizedDisplayName -EnableBranchCache $true
        }

    }
}

Get-CMPackageDeployment | % { Set-CMPackageDeployment -AllowSharedContent $true -PackageId $_.PackageId -StandardProgramName $_.ProgramName -CollectionId $_.CollectionId }