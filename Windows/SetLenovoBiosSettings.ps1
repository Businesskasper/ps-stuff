function SetLenovoBiosSettings([String]$Computername, [String]$Setting, [String]$Value, [string]$supervisorPassword) {

    try {

        $computerReachable = Test-Connection $ComputerName -Count 1 -ErrorAction Stop >null
    }
    catch [System.Net.NetworkInformation.PingException] {
    
        throw [Exception]::new("$($Computername) nicht per ICMP erreichbar")
    }

    
    $set = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi -ComputerName $Computername -ErrorAction Stop
    $save = Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi -ComputerName $Computername -ErrorAction Stop
    
    $passwordstate = (Get-WmiObject -class Lenovo_BiosPasswordSettings -namespace root\wmi -ComputerName $Computername).PasswordState     
    if ($passwordstate -eq 0) {

        $set.SetBiosSetting("$($Setting),$($Value)")
        $save.SaveBiosSettings()
    }
    else {

        $set.SetBiosSetting("$($Setting),$($Value),$($supervisorPassword),ascii,us")
        $save.SaveBiosSettings("sup3radmin,ascii,us")
    }
}