function SetItemProperty([string]$path, [string]$name, [string]$type, [object]$value) {

    EnsurePath -path $path

    $key = Get-Item -Path $path
    if ($null -eq $key) {

        New-Item -Path $path | Out-Null
    }
    $property = Get-ItemProperty -Path $path -Name $name
    if ($null -eq $property) {

        New-ItemProperty -Path $path -Name $name -PropertyType $type -Value $value
    }
    else {

        Set-ItemProperty -Path $path -Name $name -Value $value
    }
}


function EnsurePath([string]$path) {

    if ([String]::IsNullOrWhiteSpace($path)) {

        return
    }

    $parent = Split-Path -Path $path -Parent
    if ($null -ne $parent -and $parent -ne $path) {

        EnsurePath -path $parent
    }
    if (-not (Test-Path -Path $path)) {

        New-Item -Path $path -ItemType Directory | Out-Null
    }
}