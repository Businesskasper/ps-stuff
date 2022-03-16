# Downloads the latest stable release of Google Chrome
function DownloadLatestChrome([string]$workingDir) {
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    $zipPath = [System.IO.Path]::Combine($workingDir, "chrome.zip")
    $unzipPath = [System.IO.Path]::Combine($workingDir, "chrome")
    
    Invoke-WebRequest -Method Get -Uri "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B434CE955-AD3C-B4E8-6190-542FBB516D20%7D%26lang%3Den%26browser%3D4%26usagestats%3D1%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26ap%3Dx64-stable-statsdef_0%26brand%3DGCEB/dl/chrome/install/GoogleChromeEnterpriseBundle64.zip" -OutFile $zipPath
    
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $unzipPath)
    Remove-Item -Path $zipPath -Force -Confirm:$false
    
    Move-Item -Path ([System.IO.Path]::Combine($unzipPath, "Installers", "GoogleChromeStandaloneEnterprise64.msi")) -Destination $workingDir -Force -Confirm:$false
    Remove-Item -Path $unzipPath -Force -Confirm:$false -Recurse
}