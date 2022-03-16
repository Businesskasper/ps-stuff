$driveName = "MyDrive"

function BackupFiles([string]$sourcePath, [string]$destinationPath) {

    New-EventLog -LogName Application -Source "Backup" -ErrorAction SilentlyContinue | Out-null
    Write-EventLog -LogName Application -Source "Backup" -EntryType SuccessAudit -EventId 2 -Message "Copy $($sourcePath) to $($destinationPath)"
    if (-not (Test-Path -Path $destinationPath)) {

        New-Item -ItemType Directory -Path $destinationPath
    }
    $copy = Start-Process -FilePath "C:\Windows\System32\Robocopy.exe" -ArgumentList $sourcePath, $destinationPath, "/MIR" -Wait -PassThru
    if ($copy.ExitCode -in @(0, 1, 2, 3, 5, 6, 7)) {

        Write-EventLog -LogName Application -Source "Backup" -EntryType SuccessAudit -EventId 2 -Message "Done! (Exit Code $($copy.ExitCode))"
    }
    else {

        Write-EventLog -LogName Application -Source "Backup" -EntryType FailureAudit -EventId 2 -Message "Failed! (Exit Code $($copy.ExitCode))"  
    }
}

New-EventLog –LogName Application –Source "Backup" -ErrorAction SilentlyContinue
Write-EventLog -LogName Application -Source "Backup" -EntryType Information -EventId 1 -Message "Starte Backup"
Write-EventLog -LogName Application -Source "Backup" -EntryType Information -EventId 1 -Message "Backup auf Laufwerk $($drive)"

$drive = Get-WmiObject -Namespace root\cimv2 -Class win32_logicaldisk -Filter "VolumeName = '$($driveName)'" -Property Name | select -ExpandProperty Name
if (-not $drive) {
    
    Write-EventLog -LogName Application -Source "Backup" -EntryType FailureAudit -EventId 2 -Message "Externe Festplatte nicht erkannt!" 
    exit 1
}

#Dokumente
Write-EventLog -LogName Application -Source "Backup" -EntryType Information -EventId 1 -Message "Kopiere Dokumente"
BackupFiles -sourcePath "$($env:USERPROFILE)\Documents" -destinationPath "$($drive)\$($env:USERPROFILE)\Backup\Documents"

    
#Bilder
Write-EventLog -LogName Application -Source "Backup" -EntryType Information -EventId 1 -Message "Kopiere Bilder"
BackupFiles -sourcePath "$($env:USERPROFILE)\Pictures" -destinationPath "$($drive)\$($env:USERPROFILE)\Backup\Pictures"

#Musik
Write-EventLog -LogName Application -Source "Backup" -EntryType Information -EventId 1 -Message "Kopiere Musik"
BackupFiles -sourcePath "$($env:USERPROFILE)\Music" -destinationPath "$($drive)\$($env:USERPROFILE)\Backup\Music"
