# Downloads the latest stable release of Microsoft Visual Studio 2019 Professional
# Required certmgr.exe
function DownloadAndInstallLatestVSCommunity2019([string]$workingDir, [switch]$runInstallation, [string]$certMgrPath) {
        
    # Download
    $setupFile = [System.IO.Path]::Combine($workingDir, "vs_professional.exe")
    Invoke-WebRequest -Method Get -Uri "https://aka.ms/vs/16/release/vs_professional.exe" -OutFile $setupFile
    
    $buildPackage = Start-Process -FilePath ([System.IO.Path]::Combine($workingDir, "vs_professional.exe")) -ArgumentList @(
        "--layout $($workingDir)",
        "--add Microsoft.VisualStudio.Workload.ManagedDesktop",
        "--add Microsoft.VisualStudio.Workload.NetWeb"
        "--add Component.GitHub.VisualStudio",
        "--includeOptional",
        "--lang en-US",
        "--passive"
    ) -Wait -PassThru
    
    if ($buildPackage.ExitCode -ne 0) {
    
        throw [Exception]::new("$($buildPackage.StartInfo.FileName) exited with Exit Code $($buildPackage.ExitCode)")
    }

    if (-not $runInstallation.IsPresent) {
        
        return
    }

    # Install
    Start-Process -FilePath $certMgrPath -ArgumentList @("-add", ([System.IO.Path]::Combine($workingDir, "certificates", "manifestRootCertificate.cer")), "Microsoft Root Certificate Authority 2011", "-s", "-r", "LocalMachine", "root") -Wait
    Start-Process -FilePath $certMgrPath -ArgumentList @("-add", ([System.IO.Path]::Combine($workingDir, "certificates", "manifestCounterSignRootCertificate.cer")), "Microsoft Root Certificate Authority 2010", "-s", "-r", "LocalMachine", "root") -Wait
    Start-Process -FilePath $certMgrPath -ArgumentList @("-add", ([System.IO.Path]::Combine($workingDir, "certificates", "vs_installer_opc.RootCertificate.cer")), "Microsoft Root Certificate Authority", "-s", "-r", "LocalMachine", "root") -Wait
    
    $install = Start-Process -FilePath $setupFile -ArgumentList @(
        "--add Microsoft.VisualStudio.Workload.ManagedDesktop",
        "--add Microsoft.VisualStudio.Workload.NetWeb"
        "--add Component.GitHub.VisualStudio",
        "--includeOptional",
        #"--lang en-US", -> Exception "Unsupported Parameter "lang""
        "--passive",
        "--norestart",
        "--noWeb"
    ) -Wait -PassThru
    
    if ($install.ExitCode -ne 0) {
    
        throw [Exception]::new("$($install.StartInfo.FileName) exited with Exit Code $($install.ExitCode)")
    }
}
