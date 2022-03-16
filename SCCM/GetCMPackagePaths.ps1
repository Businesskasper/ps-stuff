function GetCMPackagePaths([string]$SiteServer = $env:COMPUTERNAME) {

    Import-Module (Join-Path -Path $(Split-Path $env:SMS_ADMIN_UI_PATH) -ChildPath "ConfigurationManager.psd1") -ErrorAction Stop | Out-Null

    $sitecode = Get-CimInstance -Namespace "root\sms" -ClassName "SMS_ProviderLocation" -Property SiteCode -KeyOnly | select -ExpandProperty SiteCode -ErrorAction Stop
    cd "$($sitecode):"
    Set-CMQueryResultMaximum 50000
    
    $cmPackages = Get-CMPackage | select Name, PkgSourcePath -ErrorAction Stop | Sort-Object -Property Name

    $packages = $cmPackages | % {  
        [PSCustomObject]@{
            Name = $_.Name
            Path = $_.PkgSourcePath
        }
    }
    
    return $packages
}


