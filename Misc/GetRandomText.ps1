# Gets lorem ipsum in the specified length
function GetRandomText([int]$length, [bool]$spaces) {

    $text = Invoke-WebRequest -Method Get -Uri "https://loripsum.net/api/short" -UseBasicParsing | select -ExpandProperty Content

    $text = $text.Replace("<p>", "").Replace("</p>", "")
    $text = $text.Replace("`n", " ")
    $text = $text.Replace("`r", " ")
    if (-not $spaces) {

        $text = $text.Replace(" ", "")
    }
    
    $randomStart = Get-Random -Minimum 0 -Maximum ($text.Length - $length)
    
    return $text.Substring($randomStart, $length)

}
