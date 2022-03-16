function UnzipArchive([string]$zipFilePath, [string]$destinationDir) {

    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
    Add-Type -AssemblyName System.IO.Compression | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.ZipFile") | Out-Null
    
    $zipFile = [System.IO.Compression.ZipFile]::Open($zipFilePath, [System.IO.Compression.ZipArchiveMode]::Read)
    
    foreach ($entry in $zipFile.Entries) {

        if ($entry.CompressedLength -eq 0) {

            New-Item -ItemType Directory -Path ([System.IO.Path]::Combine($destinationDir, $entry.FullName.TrimStart("/"))) | Out-Null
        }
        else {

            $fileStream = $null
            $zipStream = $null

            $filePath = [System.IO.Path]::Combine($destinationDir, $entry.FullName.TrimStart("/"))
            $fileStream = [System.IO.File]::Create($filePath)

            try {

                $zipStream = $entry.Open()
                $zipStream.CopyTo($fileStream)
            }
            catch [Exception] {

                continue
            }
            finally {

                $zipStream.Close()
                $zipStream.Dispose()
                $fileStream.Close()
                $fileStream.Dispose()
            }
        }
    }

    $zipFile.Dispose()
}