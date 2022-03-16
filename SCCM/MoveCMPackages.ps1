function MoveCMPackages([string]$logDir, [string]$nodeName, [string]$from, [string]$to) {

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
    $node = Get-CimInstance -ComputerName $SiteServer -Namespace root\sms\site_$sitecode -ClassName SMS_ObjectContainerNode -Filter "Name = '$($nodeName)' AND ObjectType = 2"

    # Get Packages by id
    [array]$allPackages = Get-CMPackage -ErrorAction Stop
    [array]$packagesById = Get-CimInstance -ComputerName $SiteServer -Namespace root\sms\site_$sitecode -ClassName SMS_ObjectContainerItem -Filter "ContainerNodeID = '$($node.ContainerNodeID)'" -KeyOnly -Property InstanceKey | select -ExpandProperty InstanceKey
    [array]$packages = $allPackages | ? { $_.PackageID -like "$($PackageByID)*" }
    
    $copyError = 0

    foreach ($package in $packages) {
        
        "Package: $($package.Name)" | Out-File -Path $logPath -Encoding utf8 -Append -Force                           
        $pfadAlt = $package.PkgSourcePath.ToLower().trimend('\')
        $pfadNeu = $package.PkgSourcePath.ToLower().replace($From.ToLower(), $To.ToLower()).trimend('\')
        "Alter Pfad: $($pfadAlt)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
        "Neuer Pfad: $($pfadNeu)" | Out-File -Path $logPath -Encoding utf8 -Append -Force

        if ($pfadAlt -ne $pfadNeu) {

            #Content kopieren
            #Copylog vorbereiten
            $copyLogTitle = $package.Name
            [System.IO.Path]::GetInvalidFileNameChars() | % { $copyLogTitle = $copyLogTitle.replace($_, '.').Replace(" ", "_").Replace(".", "") }
            $copylog = [System.IO.Path]::combine($logDir, "Move_$($copyLogTitle)_$($runGuid).log")

            #Kopieren
            "Logge Kopiervorgang in $($copylog)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
            $copy = Start-Process -FilePath "$env:windir\system32\robocopy.exe" -ArgumentList ('"' + $pfadAlt + '"'), ( '"' + $pfadNeu + '"'), "/E /COPYALL" -Wait -PassThru -RedirectStandardOutput $copylog
            "Kopieren beendet mit Exitcode $($copy.ExitCode.ToString())" | Out-File -Path $logPath -Encoding utf8 -Append -Force

            #Hats geklappt?
            $successfulExitCodes = "0", "1", "2", "3", "4", "5", "6", "7"        
            $fso = New-Object -ComObject Scripting.FileSystemObject
            if (($copy.ExitCode.ToString() -in $successfulExitCodes) -and ($fso.GetFolder($pfadNeu).Size -eq $fso.GetFolder($pfadAlt).Size)) {

                "$($pfadAlt)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                "Neuen Pfad schreiben" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                $package.PkgSourcePath = $pfadNeu

                #Änderungen speichern
                "Neuen Pfad speichern" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                $put = $package.Put() | Out-String
                "Speichern:" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                "$($put)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
            }
            else {
                
                if (($copy.ExitCode.ToString() -notin $successfulExitCodes)) {

                    "Errorbeim Kopiervorgang!" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                }
                elseif ($fso.GetFolder($pfadNeu).Size -eq $fso.GetFolder($pfadAlt).Size) {

                    "Error: Hashfehler $($pfadAlt) <-> $($pfadNeu)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                }
                else {

                    "Error: Unbekannter Fehler beim Kopieren!" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                }
                $copyError++

                "$($package.Name)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                "Quelle: $($pfadAlt)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                "Ziel: $($pfadNeu)" | Out-File -Path $logPath -Encoding utf8 -Append -Force
            }
            if ($copyError -eq 3) {

                "Error: Kopierfehlergrenze(3) überschritten!" | Out-File -Path $logPath -Encoding utf8 -Append -Force
                throw("Error: Kopierfehlergrenze(3) überschritten!")
            }
        }
        else {

            "Pfade stimmen überein. - Tue nichts." | Out-File -Path $logPath -Encoding utf8 -Append -Force
        }  
    }    
  
}


