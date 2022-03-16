# Encrypts all drives with bitlocker, enables auto unlock and stores the keys in active directory

Import-Module BitLocker

#System drive
Enable-BitLocker -MountPoint c: -EncryptionMethod XtsAes128 -UsedSpaceOnly -SkipHardwareTest -TpmProtector
Get-BitLockerVolume | Add-BitLockerKeyProtector -RecoveryPasswordProtector

#Data drives
$Password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort { Get-Random })[0..15] -join ''

$dataDrives = Get-WmiObject -Namespace ROOT\CIMV2\Security\MicrosoftVolumeEncryption -Class Win32_EncryptableVolume | ? { $_.VolumeType -eq 1 -and $_.DriveLetter } | select -ExpandProperty Driveletter 
$dataDrives | % {

    Enable-BitLocker -MountPoint $_ -SkipHardwareTest -EncryptionMethod XtsAes128 -UsedSpaceOnly -PasswordProtector $(ConvertTo-SecureString -String $Password -AsPlainText -Force)
    Enable-BitLockerAutoUnlock -MountPoint $_
}

#Backup keys
Get-BitLockerVolume | % {

    $mountPoint = $_.MountPoint
    $_.KeyProtector | ? { $_.KeyProtectorType -eq "RecoveryPassword" } | select -ExpandProperty KeyProtectorId | % {

        Backup-BitLockerKeyProtector -MountPoint $mountPoint -KeyProtectorId $_
    }
}

