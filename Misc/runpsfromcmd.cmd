# 2>NUL & @CLS & PUSHD "%~dp0" & "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -nol -nop -ep bypass "[IO.File]::ReadAllText('%~f0')|iex" & POPD & EXIT /B

param (
	[Parameter(Mandatory=$true)]
	[string]$asdf
)

get-date
write-host $env:computername
write-host $asdf
pause