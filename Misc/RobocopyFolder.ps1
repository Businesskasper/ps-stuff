function RobocopyFolder([string]$sourcePath, [string]$destinationPath) {

    if (-not (Test-Path -Path $destinationPath)) {

        New-Item -ItemType Directory -Path $destinationPath
    }
    $copy = Start-Process -FilePath "C:\Windows\System32\Robocopy.exe" -ArgumentList $sourcePath, $destinationPath, "/MIR" -Wait -PassThru
    if ($copy.ExitCode -notin @(0, 1, 2, 3, 5, 6, 7)) {

        throw [Exception]::new("Copying failed with exit Code $($copy.ExitCode)")
    }
}