$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

function logMessage ([string]$message) {
    (get-date -Format HH:mm).ToString() + " - " + $message | Out-File c:\install.log -Append
}

logMessage -message "Installing drivers" 
Start-Process -FilePath "$($env:windir)\system32\pnputil.exe" -ArgumentList @("/add-driver", "$($scriptDir)\Drivers\*.inf", "/subdirs", "/install") -Wait -PassThru


logMessage -message "Copying WMIExplorer to %windir%\system32"
try {
    Copy-Item -Path "$($scriptDir)\Apps\WMIExplorer.exe" -Destination "$env:windir\system32\WMIExplorer.exe" -Force -ErrorAction Stop
}
catch [Exception] {
    logMessage $_.Exception.ToString()
}

logMessage -message "Installing System Update" 
$su_setup = Start-Process -FilePath "$($scriptDir)\Apps\systemupdate5.07.0072.exe" -ArgumentList "/silent" -Wait -PassThru
logMessage -message "Exit code: $($su_setup.ExitCode)"

logMessage -message "Installing 7-Zip" 
$7z_setup = Start-Process -FilePath C:\windows\system32\msiexec.exe -ArgumentList "/i", "$($scriptDir)\Apps\7z1805-x64.msi", "/q" -Wait -PassThru
logMessage -message "Exit code: $($7z_setup.ExitCode)"

logMessage -message "Installing Notepad++" 
$np_setup = Start-Process -FilePath "$($scriptDir)\Apps\npp.7.5.6.Installer.x64.exe" -ArgumentList "/S" -Wait -PassThru
logMessage -message "Exit code: $($np_setup.ExitCode)"

logMessage -message "Installing Hotkey Integration"
$hk_setup = Start-Process -FilePath "$($scriptDir)\Drivers\Hotkey\setup.exe" -ArgumentList '/silent' -Wait -PassThru
logMessage -message "Exit code: $($hk_setup.ExitCode)"

logMessage -message "Installing Chocolatey"
$choco_setup = Start-Process -FilePath c:\windows\system32\WindowsPowerShell\v1.0\powershell.exe -ArgumentList "-NoProfiles", "-InputFormat None", "-ExecutionPolicy Bypass", "-Command", "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" -Wait -PassThru
Start-Process -FilePath c:\windows\system32\cmd.exe -ArgumentList "/c", "SET", '"PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"' -Wait -PassThru
logMessage -message "Exit code: $($choco_setup.ExitCode)"

logMessage -message "Installing .Net Core"
$netCore_Setup = Start-Process -FilePath "$($scriptDir)\Apps\dotnet-sdk-2.1.300-win-gs-x64.exe" -ArgumentList "/S" -Wait -PassThru
logMessage -message "Exit code: $($netCore_Setup.ExitCode)"

logMessage -message "Installing .Net 4 Developer"
$netDev_Setup = Start-Process -FilePath "$($scriptDir)\Apps\NDP472-DevPack-ENU.exe" -ArgumentList "/S" -Wait -PassThru
logMessage -message "Exit code: $($netCore_Dev.ExitCode)"

logMessage -message "Installing VS Code"
$vscode_Setup = Start-Process -FilePath "c:\windows\system32\cmd.exe" -ArgumentList "/C", "choco", "install", "vscode", "y" -Wait -PassThru
logMessage -message "Exit code: $($vscode_Dev.ExitCode)"


$packagesToRemove = @(
    "Microsoft.BingWeather"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Messaging"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.Office.OneNote"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.Print3D"
    "Microsoft.SkypeApp"
    "Microsoft.StorePurchaseApp"
    "Microsoft.Wallet"
    "Microsoft.WindowsCamera"
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.ZuneVideo2"
) 
$allPackages = Get-AppxProvisionedPackage -Online 
foreach ($packageToRemove in $packagesToRemove) {
    logMessage -message "Removing app $($packageToRemove)"
    $allPackages | ? { $_.DisplayName -eq $packageToRemove } | Remove-AppxProvisionedPackage -AllUsers -Online | out-file "c:\install.log" -Append
}


logMessage -message "Importing root certificate"
Start-Process -FilePath "$($env:windir)\system32\certutil.exe" -ArgumentList "-addstore", "-enterprise", "-f", "-v", "Root", "$($scriptDir)\OSSetup\root.cer"


logMessage -message "Importing start layout"
Import-StartLayout -LayoutPath "$($scriptDir)\OSSetup\LayoutModification.xml" -MountPath c:\
if ($? -ne $True) { logMessage $($Error[0].ToString()) }


logMessage -message "Rebooting"
restart-computer -force
