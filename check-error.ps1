# Capture full error output
git push origin awawaw 2>&1 | Tee-Object -FilePath push-error.log
Write-Host "`n--- Full Error Log ---`n"
Get-Content push-error.log
