1. Winrm aktivieren
winrm quickconfig


2. PSWindowsUpdate installieren
Find-Module PSWindowsUpdate | install-module


3. Updates installieren
Get-WindowsUpdate -Download -Install -AcceptAll -AutoReboot


4. Hostnamen ändern
Rename-Computer -NewName host1


5. net config
$adapter = Get-NetAdapter -InterfaceAlias Ethernet
$adapter | Remove-NetIPAddress -Confirm:$false
$adapter | New-NetIPAddress -AddressFamily IPv4 -IPAddress 192.168.178.11 -PrefixLength 24 -DefaultGateway 192.168.178.1
$adapter | Set-DnsClientServerAddress -ResetServerAddresses
$adapter | Set-DnsClientServerAddress -ServerAddresses 192.168.178.2


6. rdp aktivieren
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1


7. Enable Hyper-V
Install-WindowsFeature hyper-v


8. Set up docker
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider
Restart-Computer -Force


9. Install compose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-Windows-x86_64.exe" -UseBasicParsing -OutFile $Env:ProgramFiles\Docker\docker-compose.exe


9. Set up network
docker network create -d transparent TransparentNetwork
-> Net config wiederholen


