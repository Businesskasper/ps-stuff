# Creates a bootable, updated and optimized vhdx from a windows iso
function IsoToBootableVhdx {
    
    param(
        [string]$isoPath, 
        [string]$vhdxPath, 
        [string]$workingDir, 
        [string]$sdeletePath, 
        [ValidateSet('Standard', 'Datacenter', 'Standard (Desktop Experience)')]
        [string]$sku = 'Standard', 
        [string[]]$windowsFeatures = @('NetFx3'),
        [string]$updatePath = $null
    )
    
    # Prepare working directory
    md $workingDir -ea 0 | Out-Null
    
    # Mount ISO and get drive letter
    $before = Get-PSDrive -PSProvider FileSystem
    $isoMount = Mount-DiskImage -ImagePath $isoPath -StorageType ISO -Access ReadOnly -PassThru
    $after = Get-PSDrive -PSProvider FileSystem 
    $isoDriveLetter = Compare-Object -ReferenceObject $before -DifferenceObject $after | select -ExpandProperty InputObject | select -ExpandProperty Root

    #Create new vhdx
    $isoLength = (Get-Item -Path $isoPath | select -ExpandProperty Length) / 1GB
    $vhdxInitialSize = ([Math]::Round($isoLength, 0) * 3) * 1GB
    if (Test-Path -Path $vhdxPath) {

        Remove-Item -Path $vhdxPath -Force
    }
    $vhdx = New-VHD -Dynamic -Path $vhdxPath -SizeBytes $vhdxInitialSize  | Mount-VHD -Passthru | Initialize-Disk -PassThru -PartitionStyle GPT

    # Create partitions
    $systemPartition = $vhdx | New-Partition -Size 200MB -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
    $systemPartition | Format-Volume -FileSystem FAT32 -Force
    $systemPartition | Set-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
    $systemPartition | Add-PartitionAccessPath -AssignDriveLetter

    $reservedPartition = $vhdx | New-Partition -Size 128MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'

    $osPartition = $vhdx | New-Partition -UseMaximumSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
    $osVolume = $osPartition | Format-Volume -FileSystem NTFS -Force
    $osPartition = $osPartition | Add-PartitionAccessPath -AssignDriveLetter -PassThru | Get-Partition
    $windowsDrive = $(Get-Partition -Volume $osVolume).AccessPaths[0].substring(0, 2)

    $systemPartition = $systemPartition | Get-Partition
    $systemDrive = $systemPartition.AccessPaths[0].trimend("\").replace("\?", "??")

    #Apply .wim file to .vhdx
    $imageIndex = Get-WindowsImage -ImagePath ([System.IO.Path]::Combine($isoDriveLetter, "sources", "install.wim")) | ? { $_.ImageName -like "*$($sku)" } | select -ExpandProperty ImageIndex
    Expand-WindowsImage -ImagePath ([System.IO.Path]::Combine($isoDriveLetter, "sources", "install.wim")) -ApplyPath "$($osPartition.DriveLetter):" -Index $imageIndex

    #Make .vhdx bootable
    $bcdBootArgs = @(
        "$($windowsDrive)\Windows", # Path to the \Windows on the VHD
        "/s $systemDrive", # Specifies the volume letter of the drive to create the \BOOT folder on.
        "/v", # Enabled verbose logging.
        "/f UEFI"                   # ÜFI
    )
    Start-Process -FilePath "C:\windows\system32\bcdboot.exe" -ArgumentList $bcdBootArgs -Wait | out-null

    #Add features
    foreach ($windowsFeature in $windowsFeatures) {

        Enable-WindowsOptionalFeature -FeatureName $windowsFeature -Path "$($osPartition.DriveLetter):"  -Source ([System.IO.Path]::Combine($isoDriveLetter, "sources", "sxs"))  -All -NoRestart
    }

    #Patch
    if (-not [String]::IsNullOrWhiteSpace($updatePath)) {

        Add-WindowsPackage -PackagePath $updatePath -Path "$($osPartition.DriveLetter):" -PreventPending
    }

    
    #Unmount and cleanup
    $systemPartition | Remove-PartitionAccessPath -AccessPath $systemPartition.AccessPaths[0]

    #Zeroing free space
    if (-not (Test-Path -Path "HKCU:\Software\Sysinternals\SDelete")) {

        New-Item -Path "HKCU:\Software\Sysinternals\" -Name Sdelete | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Sysinternals\SDelete" -Name EulaAccepted -Value 1 | Out-Null
    }
    
    Start-Process -FilePath $sdeletePath -ArgumentList @("-q", "-s", "-c", $windowsDrive) -Wait -PassThru
    #Cleaning free space
    Start-Process -FilePath $sdeletePath -ArgumentList @("-q", "-s", "-z", $windowsDrive) -Wait -PassThru

    Dismount-DiskImage -ImagePath $isoPath -StorageType ISO
    Dismount-VHD -Path $vhdxPath


    #Optimize .vhdx -> Needs to be remounted in read-only mode
    Mount-VHD -Path $vhdxPath -ReadOnly
    Optimize-VHD -Path $vhdxPath -Mode Full
    Resize-VHD -Path $vhdxPath -ToMinimumSize 
    Dismount-VHD -Path $vhdxPath 

    Remove-Item -Path $workingDir -Force -Recurse -Confirm:$false
}