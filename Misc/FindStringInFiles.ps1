# Finds files with specific content
# Example: FindStringInFiles -regex "*match*" -fileType = "*.ps1" -dir c:\folder\

function FindStringInFiles([string]$dir, [string]$regex, [string]$fileType = '*.*') {

    $files = Get-ChildItem -Path $dir -Recurse -Filter *.* | select -ExpandProperty FullName
    
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