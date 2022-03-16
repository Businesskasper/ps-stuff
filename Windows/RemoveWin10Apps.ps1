$packages = Get-AppxProvisionedPackage -Online 

@(
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
"Microsoft.WindowsStore",
"Microsoft.GrooveMusic",
"Microsoft.Office.OneNote",
"Microsoft.MicrosoftOfficeHub",
"Microsoft.WindowsFeedbackHub",
"Microsoft.Getstarted",
"Microsoft.SkypeApp",
"Microsoft.BingWeather",
"Microsoft.GetHelp",
"Microsoft.MicrosoftSolitaireCollection",
"Xbox",
"Microsoft.WindowsMaps",
"XINGAG.XING",
"king.com.CandyCrushSaga",
"4DF9E0F8.Netflix",
"Fitbit.FitbitCoach") | % {

    $name = $_
    
    $packages | ? {$_.DisplayName -eq $name} | Remove-AppxProvisionedPackage -AllUsers -Online | out-file "c:\install.log" -Append
    Get-AppxPackage -AllUsers  | ? {$_.DisplayName -eq $name}  | % { Remove-AppxPackage -AllUsers -Package $_}
    $(Get-AppxPackage -Name $name) | Remove-AppxPackage
}


Get-AppxPackage -AllUsers | select -ExpandProperty Name > C:\asdfl.txt

Remove-AppxPackage -Package $(Get-AppxPackage -AllUsers -Name "king.com.CandyCrushSaga")  | ? {$_.Name -eq "king.com.CandyCrushSaga"}