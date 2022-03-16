# Configures a hyper-v vm nic identified by its virtual switch. Device naming must be enabled.

$nic = [PSCustomObject]@{
    SwitchName = "Extern"
    DHCP       = $true
}

$nic = [PSCustomObject]@{
    SwitchName = "Extern"
    DHCP       = $false
    IPAddress  = '192.168.178.13'
    SubnetCidr = '24'
    DNSAddress = '192.168.178.1'
}

New-EventLog -LogName Application -Source "UpdateNicIP_$($nic.SwitchName)"

$adapter = Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | ? { $_.DisplayValue -eq "$($nic.SwitchName)" } | select -ExpandProperty Name
Write-EventLog -LogName Application -Source "UpdateNicIP_$($nic.SwitchName)" -EntryType Information -EventId 2 -Message "Found adapter $($adapter)"


if ($nic.DHCP) {

    Write-EventLog -LogName Application -Source "UpdateNicIP_$($nic.SwitchName)" -EntryType Information -EventId 2 -Message "Enabling DHCP on $($adapter)"    
    Set-NetIPInterface -InterfaceAlias $adapter -Dhcp Enabled

    Write-EventLog -LogName Application -Source "UpdateNicIP_$($nic.SwitchName)" -EntryType Information -EventId 2 -Message "Resetting DNS on $($adapter)"    
    Set-DnsClientServerAddress -InterfaceAlias $adapter -ResetServerAddresses 
}
elseif ((Get-NetIPAddress -InterfaceAlias $adapter | ? { $_.AddressFamily -ne "IPv6" }).IPAddress -ne "$($nic.IPAddress)") {

    Write-EventLog -LogName Application -Source "UpdateNicIP_$($nic.SwitchName)" -EntryType Information -EventId 2 -Message "Removing addresses on $($adapter)"    
    Get-NetIPAddress -InterfaceAlias $adapter | ? { $_.AddressFamily -ne "IPv6" } | Remove-NetIPAddress -Confirm:$false

    Write-EventLog -LogName Application -Source "UpdateNicIP_$($nic.SwitchName)" -EntryType Information -EventId 2 -Message "Assign $($nic.IPAddress)/$($nic.SubnetCidr) to $($adapter)"   
    New-NetIPAddress –InterfaceAlias $adapter –IPAddress $($nic.IPAddress) –PrefixLength $($nic.SubnetCidr) -AddressFamily IPv4

    Write-EventLog -LogName Application -Source "UpdateNicIP_$($nic.SwitchName)" -EntryType Information -EventId 2 -Message "Setting DNS on $($adapter) to $($nic.DNSAddress)"    
    Set-DnsClientServerAddress -InterfaceAlias $adapter -ResetServerAddresses
    Set-DnsClientServerAddress -InterfaceAlias $adapter -ServerAddresses @("$($nic.DNSAddress)") 
}