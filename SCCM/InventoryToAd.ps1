# Inventories the devices serial number into its their ad computer object
function InventoryToAd([string]$logPath, [string]$exportPath) {
       
    try {

        $siteCode = Get-CimInstance -Namespace "root\sms" -ClassName "SMS_ProviderLocation" -Property SiteCode -KeyOnly | select -ExpandProperty SiteCode -ErrorAction Stop    
        Import-Module ActiveDirectory -ErrorAction Stop | Out-Null     
    }
    catch [Exception] {

        "Error während der Vorbereitung: $($_.Exception.ToString())" | Out-File -Path $logPath -Encoding utf8 -Append -Force
        throw
    }

    try {

        $devices = Get-WmiObject -Namespace root\sms\site_$($siteCode) -Class SMS_R_System -ErrorAction Stop | select Name, ResourceId
    }
    catch {

        "Error bei Device Abfrage: $($_.Exception.ToString())" | Out-File -Path $logPath -Encoding utf8 -Append -Force
        throw
    }

    $allDevices = @()

    foreach ($device in $devices) {
        
        $logDevice = [PSCustomObject]@{
            Name                   = $device.Name
            ResourceID             = $device.ResourceID
            SerialNumber           = ''
            $WasAlreadyInventoried = $false
            $IsHardwareInventoried = $false
            $IsInventoried         = $false
            $IsDouble              = $false
            $IsInAd                = $false
            $InventoryError        = ''
        }
        
        $loggedDevice = $allDevices | ? { $_.Name -eq $device.Name } | select -first 1
        $logDevice.IsDouble = $null -ne $loggedDevice

        $serialNumber = Get-WmiObject -Namespace root\sms\site_$($siteCode) -Class SMS_G_System_COMPUTER_SYSTEM_PRODUCT -Filter "ResourceID = $($device.ResourceId)" | select -ExpandProperty IdentifyingNumber
        $logDevice.IsHardwareInventoried = $null -ne $serialNumber

        $deviceInAd = Get-ADComputer $device.Name
        if ($null -eq $deviceInAd) {
            
            $logDevice.IsInAd = $false
        } 
        else {

            $logDevice.IsInAd = $true
            if ($deviceInAd.extensionAttribute10 -eq $serialNumber) {
    
                $logDevice.WasAlreadyInventoried = $true
            }
            else {
    
                try {

                    Set-ADComputer $device.Name –replace @{extensionAttribute10 = $serialNumber } -ErrorAction Stop
                    $logDevice.IsInventoried = $true
                }
                catch [Exception] {

                    $logDevice.InventoryError = $_.Exception.ToString()
                }
            }
        }

        $allDevices += $logDevice
    }

    $allDevices | Export-Csv -Path $exportPath -Encoding UTF8 -Delimiter ';' -NoClobber -NoTypeInformation
}






