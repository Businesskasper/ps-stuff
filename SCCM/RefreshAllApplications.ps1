Import-Module (Join-Path -Path $(Split-Path $env:SMS_ADMIN_UI_PATH) -ChildPath "ConfigurationManager.psd1") -ErrorAction Stop | Out-Null
$sitecode = Get-CimInstance -Namespace "root\sms" -ClassName "SMS_ProviderLocation" -Property SiteCode -KeyOnly | select -ExpandProperty SiteCode -ErrorAction Stop    
cd "$($siteCode):"
Set-CMQueryResultMaximum 50000

$applications = Get-CMApplication | select *

$nodes = Get-WmiObject -Class SMS_ObjectContainerNode -Namespace "root\sms\site_$($siteCode)"
$ignoreNodes = @("Adobe", "Citrix")
$ignoreNodesIds = $nodes | ? { $_.ObjectType -eq 6000 -and $_.Name -in $ignoreNodes } | select ContainerNodeID -ExpandProperty ContainerNodeID
$nodeObjects = Get-WmiObject -class SMS_ObjectContainerItem -namespace "root\sms\site_$($siteCode)"
$ignoreNodesObjects = $NodeObjects | Where-Object { $_.ContainerNodeID -in $ignoreNodesIds }
$ignoreNodseInstanceKeys = $AUMNodeObjects | select InstanceKey -ExpandProperty InstanceKey
$ignoreApplications = ($applications | Where-Object { $_.ModelName -in $ignoreNodseInstanceKeys }).LocalizedDisplayName

$applicationsToUpdate = $applications | Where-Object { $_.LocalizedDisplayName -notin $ignoreApplications }

foreach ($applicationToUpdate in $applicationsToUpdate) {
    
    (Get-Wmiobject -Namespace "root\sms\site_$($siteCode)" -Class SMS_ContentPackage -Filter  "PackageID='$($applicationToUpdate.PackageId)'").Commit() | Out-null
}      
