$userName = ""

$headers = @{
    "Accept"        = "application/json"
    "Authorization" = "Bearer "
}

#Get playlists and songs
$table = @{
    Playlists = @(
    )
}

$req = Invoke-RestMethod -Method Get -UseBasicParsing -Uri "https://api.spotify.com/v1/users//playlists" -Headers $headers

$req.items | ? { $_.owner.id -eq $userName } | % {

    $pl = [PSCustomObject]@{
        Name    = $_.name
        Id      = $_.id
        Content = Invoke-RestMethod -Method Get -UseBasicParsing -Uri $("https://api.spotify.com/v1/users/$($userName)/playlists/" + $_.id + "/tracks") -Headers $headers | select -ExpandProperty items
    }

    $table.Playlists += $pl
}


#Create new playlists
$table.Playlists | % {

    #Playlist anlegen
    $body = @{
        "description" = ""
        "name"        = $($_.Name + "_")
        "public"      = "false"
    }

    $newPlaylist = Invoke-RestMethod -Method Post -UseBasicParsing -Uri "https://api.spotify.com/v1/users/$($userName)/playlists" -Headers $headers -Body $($body | ConvertTo-Json) -ContentType 'application/json'


    #Add songs to new playlists
    $_.Content | Sort-Object added_at -Descending | % {
        
        $bodyFill = @{
            "uris" = $_.track.uri
        }
        
        Invoke-RestMethod -Method Post -UseBasicParsing -Uri $("https://api.spotify.com/v1/users/$($userName)/playlists/" + $newPlaylist.id + "/tracks" + "?uris=" + $($_.track.uri -replace ":", "%3A")) -Headers $headers -ContentType 'application/json'
    }
}