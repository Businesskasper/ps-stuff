function GetLenovoBiosSettings([string]$ComputerName) {

    try {

        Test-Connection $ComputerName -Count 1 -ErrorAction Stop | Out-Null
    }
    catch [System.Net.NetworkInformation.PingException] {
    
        throw [Exception]::new("$($Computername) nicht per ICMP erreichbar")
    }

    return Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\wmi -ComputerName $Computername | select -ExpandProperty CurrentSetting | Sort-Object
}