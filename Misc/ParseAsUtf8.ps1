#Sometimes necessary for parsing web responses because Convertto-Json throws an overflow limit on large bodies and seems to use wrong encoding
# Example
# $response = Invoke-WebRequest -Method Get -uri "https://jsonplaceholder.typicode.com/todos" -UseBasicParsing
# if ($response.StatusCode -eq 200) {

#     $result = ParseAsUtf8 -response $response
# }

function ParseAsUtf8([Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject]$response) {

    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")        
    $parsed = [System.Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray())
    
    $serializer = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
    $serializer.MaxJsonLength = 67108864
    
    $deserialized = $serializer.DeserializeObject($parsed)
    if ($deserialized -is [array]) {

        $results = @()
        foreach ($item in $deserialized) {

            $results += $item | HashtableAsObject
        }
        return $results
    }
    else {

        return $serializer.DeserializeObject($parsed) | HashtableAsObject
    }
}
