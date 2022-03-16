function AddComputerToLocalAdmins([string]$computerName, [string]$groupName = "Administratoren") {
    
    $groupObject = [ADSI]"WinNT://$($env:COMPUTERNAME)/$($groupName),group"
    $computerPath = GetAdComputer -computerName $computerName | select -ExpandProperty Path
    $groupObject.Add($computerPath)
}

