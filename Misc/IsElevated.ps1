# Checks if current script is run with elevated permissions
function IsElevated() {
    $currentIdentity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentIdentity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}