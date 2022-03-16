# Logs to console and file
function LogMessage(
    [object]$MessageObject,
    
    [ValidateSet("Message", "Warning", "Error")]
    [string]$MessageType,
    
    [string]$LogPath,
    
    [switch]$NoLineBreak,

    [ValidateSet("Console", "Log", "ConsoleAndLog")]
    [string]$LogTo,

    [ConsoleColor]$ForegroundColor
) {

    $logParam = @{
        NoNewline = $NoLineBreak.IsPresent
    }

    if ($MessageObject -is [System.Object[]]) {

        $logParam["Object"] = ($MessageObject | Out-String)
    }
    else {

        $logParam["Object"] = $MessageObject
    }

    switch ($MessageType) {
        'Error' {
        
            $logParam["ForegroundColor"] = "Red"
        }
        'Warning' {

            $logParam["ForegroundColor"] = "Yellow"
        }
        Default {
            # -> Message
            
            $logParam["ForegroundColor"] = "White"
        }
    }

    if ($null -ne $ForegroundColor) {

        $logParam["ForegroundColor"] = $ForegroundColor
    }

    # Dumpen
    if ($LogTo -in @("Console", "ConsoleAndLog")) {

        try {

            Write-Host @logParam
        }
        # Falls das Skript mit Strg + C beendet wurde, wurde die Pipeline unterbrochen. Write-Host könnte damit eventuell einen Fehler schmeißen
        catch [Exception] { }
    }

    # Loggen
    if ($LogTo -in @("Log", "ConsoleAndLog")) {

        if (-not [String]::IsNullOrWhiteSpace($LogPath)) {
        
            # Log Verzeichnis anlegen
            $logDir = $LogPath | Split-Path -Parent
            if (-not (Test-Path -Path $logDir)) {

                New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue
            }

            # Log schreiben und Präfix anhängen (cmtrace.exe highlited Zeilen mit "WARNING" bzw. "ERROR"
            $messageToLog = ($MessageObject | Out-String)
            if ($MessageType -eq "Error") {

                $messageToLog = "ERROR: " + $messageToLog
            }
            elseif ($MessageType -eq "Warning") {

                $messageToLog = "WARNUNG: " + $messageToLog
            }
            $messageToLog | Out-File $LogPath -Encoding utf8 -Append -Force
        }    
    }
}