# Downloads the latest stable release of Microsoft Visual Studio Code
function DownloadAndInstallLatestVSCode([string]$workingDir, [switch]$runInstallation, [string]$extensionsDir = $null) {

    # Download
    
    $setupPath = [System.IO.Path]::Combine($workingDir, "setup.exe")
    Invoke-WebRequest -Method Get -Uri "https://update.code.visualstudio.com/latest/win32-x64/stable" -OutFile $setupPath

    if (-not $runInstallation.IsPresent) {

        return
    }

    # Install


    $install = Start-Process -FilePath $setupPath -ArgumentList @("/VERYSILENT", "/MERGETASKS=!runcode") -Wait -PassThru

    if ($install.ExitCode -ne 0) {
                
        throw [Exception]::new("$($install.StartInfo.FileName) exited with Exit Code $($install.ExitCode)")
    }
    
    if ([String]::IsNullOrWhiteSpace($extensionsDir)) {

        return
    }
    
    # Install extensions for all users
    md c:\users\default\.vscode\extensions -ea 0 | Out-Null
    md c:\users\public\.vscode\extensions -ea 0 | out-null
    
    foreach ($extension in (gci -Path $extensionsDir)) {
        
        Copy-Item -Path $extension.FullName -Destination "C:\users\Public\.vscode\extensions\" -Recurse -Force
        Copy-Item -Path $extension.FullName -Destination "C:\users\default\.vscode\extensions\" -Recurse -Force
    }
}
      

