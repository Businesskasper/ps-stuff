# Gets uninstall strings for installed software from the registry
function Get-UninstallString([string]$ApplicationName) {

	$keys = @()
	$keys += (get-childitem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall), (get-childitem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall)

	$uninstallstrings = @()
	foreach ($_ in $keys) {
            
		$uninstallstrings += Get-ItemProperty -Path ($_.Name -replace "HKEY_LOCAL_MACHINE", "HKLM:") | Where-Object { $_.DisplayName -like "*$ApplicationName*" -and $_.UninstallString -ne $Null } | select DisplayName, UninstallString
	}

	return $uninstallstrings
}
