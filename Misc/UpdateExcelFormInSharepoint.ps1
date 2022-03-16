$file = "path/in/sharepoint/Documents/Form.xlsx"
$creds = [PSCredential]::new("CONTOSO\user", (ConvertTo-SecureString -AsPlainText -Force -String "Passw0rd"))
$spUrl = "https://sharepoint.contoso.com/"
$workingDir = New-Item -ItemType Directory -Path ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ([guid]::NewGuid().Guid))) | select -ExpandProperty FullName


if ((Get-Module -Name SharePointPnPPowerShell2016 -ListAvailable) -eq $null) {

    Install-Module SharePointPnPPowerShell2016
}

Import-Module SharePointPnPPowerShell2016

try {

    # Open sharepoint connection
    $connection = Connect-PnPOnline -Url $spUrl -Credentials $creds -AuthenticationMode Default -ReturnConnection

    Get-PnPFile -Url $file -Path $workingDir -Filename "Form.xlsx" -AsFile -Connection $connection -Force
    
    # Download file
    $downloadedFile = [System.IO.Path]::Combine($workingDir, "Form.xlsx")
    if (-not (Test-Path $downloadedFile)) {

        throw [Exception]::new("Could not download file")
    }

    # Update data
    $excelObj = New-Object -ComObject "Excel.Application"
    $excelObj.Visible = $false
    $excelObj.DisplayAlerts = $false
    Start-Sleep -Seconds 3
    $workBook = $excelObj.workbooks.Open($downloadedFile)
    Start-Sleep -Seconds 3
    $workBook.RefreshAll()
    Start-Sleep -Seconds 3
    $workBook.Save()
    Start-Sleep -Seconds 3
    $workBook.Close()
    Start-Sleep -Seconds 3
    
    # Upload file
    Add-PnPFile -Path $downloadedFile -Folder "Documents" -Web "/path/in/sharepoint" 
}
catch {

    #exit(1)
}
finally {

    # Cleanup
    Disconnect-PnPOnline -Connection $connection
    $excelObj.Quit()
    Remove-Item -Path $workingDir -Force -ErrorAction SilentlyContinue -Recurse
}