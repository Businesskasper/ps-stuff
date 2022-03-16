# Sends a previously exported outlook mail. Includes all content as base64 into the html body.
# Example: SendOutlookMail -exportPath "c:\maintenancemail" -smtpServer smtp.contoso.com -from "John.Doe@contoso.com" -receipients @("customers@contoso.com") -subject "Upcoming maintenance work"
function SendOutlookMail([string]$exportPath, [string]$smtpServer, [string]$from, [string[]]$receipients, [string]$subject) {

    $exportedMailFile = Get-ChildItem -Path $exportPath -Filter "*.htm" | select -First 1
    $exportedMailContentFolder = Get-ChildItem -Path $exportPath -Directory | select -First 1

    $body = [System.IO.File]::ReadAllText($exportedMailFile.FullName, [System.Text.Encoding]::Default)
    $body = $body.Replace("$($exportedMailContentFolder.Name)/", "cid:")
    
    $smtpClient = [System.Net.Mail.SmtpClient]::new()
    $mailMessage = [System.Net.Mail.MailMessage]::new()

    $smtpClient.Host = $smtpServer
    $mailMessage.from = $from

    foreach ($receipient in $receipients) {
        
        $mailMessage.To.Add($receipient)
    }
    
    foreach ($file in (Get-ChildItem -Path $exportedMailContentFolder.FullName -Exclude "filelist.xml")) {

        $attachment = [System.Net.Mail.Attachment]::new($file.FullName)
        $attachment.ContentId = $file.Name
        $attachment.ContentDisposition.Inline = $true
        $attachment.ContentDisposition.DispositionType = [System.Net.Mime.DispositionTypeNames]::Inline
        $attachment.ContentType.MediaType = "image/png"
        $attachment.ContentType.Name = $file.Name
        $mailMessage.Attachments.Add($attachment)
    }
  
    $mailMessage.Subject = $subject
    $mailMessage.IsBodyHtml = $true
    $mailMessage.Body = $body

    $smtpClient.Send($mailMessage)
}
