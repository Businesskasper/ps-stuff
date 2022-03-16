# Finds files with specific content
# Example: FindStringInFiles -regex "*match*" -fileType = "*.ps1"

function FindStringInFiles([string]$regex, [string]$fileType = '*.*') {

    $files = Get-ChildItem -Path "c:\folder\" -Recurse -Filter *.* | select -ExpandProperty FullName
    
    foreach ($file in $files) {

        $filesWithContent = @()
        $content = get-content -Path $file
        $match = $content -match $regex
        if ($match) {

            $filesWithContent += [PSCustomObject]@{
                file         = $file.FullName
                matchingLine = $match
            }
        }

        return $filesWithContent
    } 
}