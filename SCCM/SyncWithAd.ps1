$domainController = ""

Import-Module ActiveDirectory
$computers = Get-ADComputer -Filter 'ObjectClass -eq "computer"' -Server $domainController | select -ExpandProperty Name | Sort-Object

Import-Module (Join-Path -Path $(Split-Path $env:SMS_ADMIN_UI_PATH) -ChildPath "ConfigurationManager.psd1") -ErrorAction Stop | Out-Null
$sitecode = Get-CimInstance -Namespace "root\sms" -ClassName "SMS_ProviderLocation" -Property SiteCode -KeyOnly | select -ExpandProperty SiteCode -ErrorAction Stop    
cd "$($siteCode):"

Get-CMDevice | Sort-Object Name | % {

    if ($_.Name -notin $computers -and $_.Name -notlike "Unknown Computer (x") {

        $_ | Remove-CMDevice -Force
    }
}