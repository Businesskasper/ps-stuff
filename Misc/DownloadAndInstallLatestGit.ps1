# Downloads the latest stable release of git and installs it
function DownloadAndInstallLatestGit([string]$workingDir, [switch]$runInstallation) {

    $setupPath = [System.IO.Path]::Combine($workingDir, "setup.exe")

    # Download
    $latestRequest = Invoke-WebRequest -Method Get -Uri https://api.github.com/repos/git-for-windows/git/releases/latest -UseBasicParsing | ConvertFrom-Json
    $latestAsset = $latestRequest.assets | ? { $_.content_type -eq "application/executable" -and $_.name -like "*64-bit.exe" } | select -First 1  
    Invoke-WebRequest -Method Get -Uri $latestAsset.browser_download_url -UseBasicParsing -OutFile $setupPath

    if (-not $runInstallation.IsPresent) {

        return
    }
    
    # Install
    $install = Start-Process -FilePath $setupPath ArgumentList @("/VERYSILENT") -Wait -PassThru

    if ($install.ExitCode -ne 0) {
            
        throw [Exception]::new("$($install.StartInfo.FileName) exited with Exit Code $($install.ExitCode)")
    }

    return $install.ExitCode
}
