function Speak1([string]$message) {

    add-type -assemblyname system.speech 
    $speechSynthesizer = [System.Speech.Synthesis.SpeechSynthesizer]::new()
    $speechSynthesizer.speak($message) 
    $speechSynthesizer.Dispose()
}

function Speak2([string]$message, [int]$rate = 0) {

    $spVoice = New-Object -ComObject Sapi.SpVoice
    $spVoice.Rate = $rate
    $spVoice.Speak($message)
}