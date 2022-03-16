# Updates sql queries and so on. Sleep is necessary
function UpdateExcelFile([string]$filePath) {

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
}