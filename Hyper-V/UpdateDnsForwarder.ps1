# Can be installed as scheduled task on a virtualized ad controller / dns server behind a natted nic
# It will then forward requests to the hyper-v host

New-EventLog -LogName Application -Source "UpdateDnsForwarder"

try {
    
    Write-EventLog -LogName Application -Source "UpdateDnsForwarder" -EntryType Information -EventId 2 -Message "Starting DNS service"
    Set-Service -Name DNS -Status Running -ErrorAction Stop
}
catch {

    Write-EventLog -LogName Application -Source "UpdateDnsForwarder" -EntryType Error -EventId 2 -Message "Could not start Service!"
    Break
}

try {

    Write-EventLog -LogName Application -Source "UpdateDnsForwarder" -EntryType Information -EventId 2 -Message "Importing DnsServer Module"
    Import-Module DnsServer
}
catch {

    Write-EventLog -LogName Application -Source "UpdateDnsForwarder" -EntryType Error -EventId 2 -Message "Could not import - DNS probably isn't installed yet"
    Break
}


$dhcp = Get-WmiObject Win32_NetworkAdapterConfiguration | ? { $_.DHCPEnabled -eq $true -and $_.DHCPServer -ne $null } | select -ExpandProperty DHCPServer

if ($null -ne $dhcp) {
    
    Write-EventLog -LogName Application -Source "UpdateDnsForwarder" -EntryType Information -EventId 2 -Message "Found $($dhcp) as external DHCP and DNS address from HV NAT switch - updating Forwarders"
    
    try {
        
        Get-DnsServerForwarder | Remove-DnsServerForwarder -Force | Out-Null
        Add-DnsServerForwarder -IPAddress $dhcp | Out-Null
    }
    catch {

        Write-EventLog -LogName Application -Source "UpdateDnsForwarder" -EntryType Error -EventId 2 -Message "Failed :("
    }
}
