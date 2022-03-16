# Downloads specspecified (or ified )(or ified )(or ified )(or ified )(or ified )(or ified )(or ified )(or latest) major version of nodejs

function DownloadNodeJs([string]$workingDir, [string]$majorVersion = 'LatestStable') {

    #Get Versions
    $versions = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing | ConvertFrom-Json
    $versions.ForEach({
            $_.version = [Version]::new($_.version.ToString().TrimStart("v"))
            $ve = $_.version
            $_ | Add-Member -MemberType NoteProperty -Name MajorVersion -Value $ve.Major
        }) 
    
    $versionsByMajor = $versions | ? { $_.lts -ne $false -and $_.files -contains "win-x64-msi" } | Sort-Object version -Descending | Group-Object MajorVersion 
    
    if ($majorVersion -eq 'LatestStable') {
        
        # Download latest stable
        $versionToDownload = $versionsByMajor[0].Group | select -First 1
        Write-Host "Download latest stable: $($versionToDownload.version)"
    }
    else {

        $versionToDownloadGroup = $versionsByMajor | ? { $_.Name -eq $majorVersion } | select -First 1
        if ($null -eq $versionToDownload) {

            throw [Exception]::new("Version `"$($majorVersion)`" was not found")
        }
        $versionToDownload = $versionToDownloadGroup.Group | select -First 1
    }

    Write-Host "Downloading Version `"$($versionToDownload.version)`""
    
    $downloadPath = New-Item -Path $workingDir -Name LatestStable -ItemType Directory -Force
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v$($versionToDownload.version.ToString())/node-v$($versionToDownload.version.ToString())-x64.msi" -OutFile ([System.IO.Path]::Combine($downloadPath.FullName, "node-LatestStable-x64.msi")) -UseBasicParsing              
}    

