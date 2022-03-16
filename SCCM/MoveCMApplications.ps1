function MoveCMApplications([string]$logDir, [string]$nodeName, [string]$from, [string]$to) {

    $runGuid = [Guid]::newGuid().Guid
    $logPath = [System.IO.Path]::combine($logDir, "MoveCMApplications_$($runGuid).log")
    
    try {

        Import-Module (Join-Path -Path $(Split-Path $env:SMS_ADMIN_UI_PATH) -ChildPath "ConfigurationManager.psd1") -ErrorAction Stop | Out-Null
    }
    catch [Exception] {

        "Error beim Import von ConfigurationManager.psd1: $($_.Exception.ToString())" | Out-File -Path $logPath -Encoding utf8 -Append -Force
        throw($_.exception.message)
    }

    #Mit Site verbinden
    try {

        $sitecode = Get-CimInstance -Namespace "root\sms" -ClassName "SMS_ProviderLocation" -Property SiteCode -KeyOnly | select -ExpandProperty SiteCode -ErrorAction Stop    
        cd "$($siteCode):"
        Set-CMQueryResultMaximum 50000
    }
    catch [Exception] {
        
        "Error beim Verbinden mit Site: $($_.Exception.ToString())"  | Out-File -Path $logPath -Encoding utf8 -Append -Force
        throw
    }

    # Get node
    $node = Get-CimInstance -ComputerName $SiteServer -Namespace root\sms\site_$sitecode -ClassName SMS_ObjectContainerNode -Filter "Name = '$($nodeName)' AND ObjectType = 6000"

    # Get apps by CI_UniqueID
    [array]$allApplications = Get-CMApplication -ErrorAction Stop
    [array]$appsByCIUID = Get-CimInstance -ComputerName $SiteServer -Namespace root\sms\site_$($sitecode) -ClassName SMS_ObjectContainerItem -Filter "ContainerNodeID = '$($node.ContainerNodeID)'" -KeyOnly -Property InstanceKey | select -ExpandProperty InstanceKey
    [array]$applications = $allApplications | ? { $_.CI_UniqueID -in $appsByCIUID }

    $copyError = 0

    foreach ($application in $applications) {
        
        "Application: $($application.LocalizedDisplayName)" | Out-File -Path $logPath -Encoding utf8 -Append -Force

        $SDMPackageXML = ($application | select -ExpandProperty SDMPackageXML).ToString()
        $SDMPackageXMLDeserialized = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($SDMPackageXML)

        $wmiObjectPath = [wmi](Get-WmiObject -ComputerName $SiteServer -Namespace root\sms\site_$($sitecode) -ClassName SMS_Application -Filter "LocalizedDisplayName = '$($application.LocalizedDisplayName)' AND IsLatest = 'True'").__Path

        foreach ($deploymentType in $SDMPackageXMLDeserialized.DeploymentTypes) {

            "Deployment Type: $($deploymentType.Title)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
            #Pfad lesen und neuen generieren
            $oldPath = $deploymentType.Installer.Contents[0].Location.ToLower().trimend('\')
            $newPath = $deploymentType.Installer.Contents[0].Location.ToLower().replace($from.ToLower(), $to.ToLower()).trimend('\')
            "Alter Pfad: $($oldPath)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
            "Neuer Pfad: $($newPath)" | Out-File -Path $logPath -Encoding utf8 -Append -Force

            if ($oldPath -ne $newPath) {
                #Content kopieren
                #Copylog vorbereiten
                $copyLogTitle = "$($application.LocalizedDisplayName)--$($deploymentType.Title)"
                [System.IO.Path]::GetInvalidFileNameChars() | % { $copyLogTitle = $copyLogTitle.replace($_, '.').Replace(" ", "_").Replace(".", "") }
                $copylog = [System.IO.Path]::combine($logDir, "Move_$($copyLogTitle)_$($runGuid).log")

                #Kopieren
                "Logge Kopiervorgang in $($copylog)" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                $copy = Start-Process -FilePath "$env:windir\system32\robocopy.exe" -ArgumentList ('"' + $oldPath + '"'), ( '"' + $newPath + '"'), "/E /COPYALL" -Wait -PassThru -RedirectStandardOutput $copylog
                "Kopieren beendet mit Exitcode $($copy.ExitCode.ToString())" | Out-File -Path $logDir -Encoding utf8 -Append -Force

                #Hats geklappt?
                $successfulExitCodes = "0", "1", "2", "3", "4", "5", "6", "7"
                $fso = New-Object -ComObject Scripting.FileSystemObject
                if (($copy.ExitCode.ToString() -in $successfulExitCodes) -and ($fso.GetFolder($newPath).Size -eq $fso.GetFolder($oldPath).Size)) {

                    #Neuen Pfad schreiben 
                    "$($oldPath)" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    "Neuen Pfad schreiben" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    $deploymentType.Installer.Contents[0].Location = $newPath

                    #Änderungen speichern
                    "Neuen Pfad speichern" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    $newSDMPackageXMLDeserialized = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::Serialize($SDMPackageXMLDeserialized, $false)
                    $wmiObjectPath.SDMPackageXML = $newSDMPackageXMLDeserialized
                    $put = $wmiObjectPath.Put() | Out-String
                    "Speichern:" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    "$($put)" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                }
                else {

                    if (($copy.ExitCode.ToString() -notin $successfulExitCodes)) {

                        "Error beim Kopiervorgang!" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    }
                    elseif ($fso.GetFolder($newPath).Size -eq $fso.GetFolder($oldPath).Size) {

                        "Error: Hashfehler $($oldPath) <-> $($newPath)" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    }
                    else {

                        "Error: Unbekannter Fehler beim Kopieren!" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    }
                    $copyError++

                    "$($application.LocalizedDisplayName) - $($deploymentType.Title)" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    "Quelle: $($oldPath)" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    "Ziel: $($newPath)" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                }

                if ($copyError -eq 3) {

                    "Error: Kopierfehlergrenze(3) überschritten!" | Out-File -Path $logDir -Encoding utf8 -Append -Force
                    throw("Error: Kopierfehlergrenze(3) überschritten!")
                }
            }
            else {
                
                "Pfade stimmen überein. - Tue nichts." | Out-File -Path $logDir -Encoding utf8 -Append -Force
            }
        }
    }
}