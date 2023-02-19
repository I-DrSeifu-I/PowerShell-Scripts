$FromAddress = ''
$SmtpServerIP = ''
$SmtpPort = '25'
$personalEmail = ""
$Subject = ""
$body = ""

send-MailMessage -SmtpServer $SmtpServer -To $personalEmail -From $FromAddress -Subject $Subject -Body $body -BodyAsHtml -Priority high 