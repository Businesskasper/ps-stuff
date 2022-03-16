Start-Process -FilePath "C:\windows\system32\klist.exe" -ArgumentList "-li", "0x3e7", "purge" -Wait 
Start-Process -FilePath "C:\windows\System32\gpupdate.exe" -ArgumentList "/force" -Wait
Start-Process -FilePath "C:\windows\system32\certutil.exe" -ArgumentList "-pulse" -Wait
Restart-Service -Name CCMExec -Force
