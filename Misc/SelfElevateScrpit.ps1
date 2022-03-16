# If the script is not run as admin it invokes itself with an elevation prompt

$currentIdentity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isElevated = $currentIdentity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isElevated) {

    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

