# Some stuff on how to use System.Management with Hyper-V

function getVSwitchMgmtMO() {
    [System.Management.ManagementObjectSearcher] $searcher = [System.Management.ManagementObjectSearcher]@{
        Query = [System.Management.WqlObjectQuery]::new("select * from Msvm_VirtualEthernetSwitchManagementService")
        Scope = [System.Management.ManagementScope]::new("\\localhost\ROOT\virtualization\v2")
    }

    foreach ($mo in $searcher.Get()) {

        [System.Management.ManagementObject]$vSwitchMgmtMO = $mo
    }

    return $vSwitchMgmtMO
}

$SwitchName = "Extern"

[System.Management.ManagementClass] $portClass = [System.Management.ManagementClass]::new("ROOT\virtualization\v2:Msvm_EthernetPortAllocationSettingData")
[System.Management.ManagementObject] $portObject = $portClass.CreateInstance()



$CreatedSwitch = (getVSwitchMgmtMO.CreateSwitch([guid]::NewGuid().ToString(), $SwitchName, "1024", "") `
    | ProcessWMIJob $VirtualSwitchService "CreateSwitch").CreatedVirtualSwitch

$ExternalNic = Get-WmiObject -Namespace "root\virtualization" -Class "Msvm_ExternalEthernetPort" `
    -Filter "Name = '$PhysicalNICName'"
    
$VirtualSwitchService.BindExternalEthernetPort($ExternalNic.__PATH) `
| ProcessWMIJob $VirtualSwitchService "BindExternalEthernetPort"
    
$ExternalNicEndPoint = $ExternalNic.GetRelated("CIM_LanEndpoint")
    
$ExternalSwitchPort = ($VirtualSwitchService.CreateSwitchPort($CreatedSwitch, `
            [Guid]::NewGuid().ToString(), "ExternalSwitchPort", "") `
    | ProcessWMIJob $VirtualSwitchService "CreateSwitchPort").CreatedSwitchPort
        
$VirtualSwitchService.ConnectSwitchPort($ExternalSwitchPort, $ExternalNicEndPoint) `
| ProcessWMIJob $VirtualSwitchService "ConnectSwitchPort"
