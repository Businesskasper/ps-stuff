# Uses youtube-dl to download a youtube video as mp3
# Cookies can be extracted from chrome using https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc?pli=1

<#
Example:

$youtubeDlPath = "C:\...\youtube-dl.exe"
$cookieFilePath = "C:\...\www.youtube.com_cookies.txt"
$outDir = "C:\...\Songs"

DownloadVideoAsMp3 -youtubeDlPath $youtubeDlPath `
                   -cookieFilePath $cookieFilePath `
                   -outDir $outDir `
                   -link "https://www.youtube.com/watch?v=C0DPdy98e4c"

Equivalent of 
youtube-dl.exe --no-mark-watched --cookies "C:\Users\LukaW\Downloads\www.youtube.com_cookies.txt" --extract-audio --audio-format mp3 https://www.youtube.com/watch?v=C0DPdy98e4c
#>

function DownloadVideoAsMp3([string]$link, [string]$cookieFilePath, [string]$youtubeDlPath, [string]$outDir) {
    md -ea 0 $outDir
    $download = Start-Process -FilePath $youtubeDlPath -ArgumentList @(
        "--no-mark-watched",
        "--cookies",
        $cookieFilePath,
        "--extract-audio",
        "--audio-format",
        "mp3",
        "--output",
        "%(title)s.%(ext)s"
        $link
    ) -Wait -PassThru -WorkingDirectory $outDir

    if ($download.ExitCode -ne 0) {
        throw [Exception]::new("Download exited with code $($download.ExitCode)")
    }
}
