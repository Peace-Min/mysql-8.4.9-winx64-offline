<#
  setup.ps1 — MySQL 8.4 ZIP 무인스톨 자동 세팅 (폐쇄망 서버용)

  reassemble.cmd로 복원한 mysql-8.4.9-winx64.zip(또는 이미 압축 푼 폴더)에서:
    바이너리 배치 → my.ini → 데이터 초기화 → 서비스 등록/시작 → root 비번 → 방화벽 → 버전 확인
  까지 한 번에. 관리자 권한이 없으면 자동으로 다시 띄운다(UAC).

  보통은 setup.cmd 더블클릭이면 됨. 세부 지정이 필요하면:
    powershell -ExecutionPolicy Bypass -File setup.ps1 -BaseDir C:\mysql -Port 3306 -Central yes
#>
[CmdletBinding()]
param(
  [string]$BaseDir = "C:\mysql",                          # 설치 위치
  [int]$Port = 3306,                                      # 포트
  [string]$ServiceName = "MySQL84",                       # Windows 서비스명
  [string]$Source = "",                                   # 추출폴더/zip 경로(기본: 자동탐지)
  [ValidateSet("ask","yes","no")][string]$Central = "ask",# 원격 접속(중앙서버) 허용 여부
  [switch]$Reset                                          # 기존 세팅이 있으면 확인 없이 전부 삭제 후 새로 설치
)
$ErrorActionPreference = "Stop"
function Info($m){ Write-Host "[*] $m" }
function Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Die($m){ Write-Host "[오류] $m" -ForegroundColor Red; try{ Read-Host "엔터를 누르면 종료" }catch{}; exit 1 }

# --- 0. 관리자 권한 확인 → 없으면 재실행(UAC) ---
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $admin){
  Info "관리자 권한으로 다시 실행합니다 (UAC 창을 승인하세요)..."
  $a = @("-NoProfile","-ExecutionPolicy","Bypass","-File",('"'+$PSCommandPath+'"'),
         "-BaseDir",('"'+$BaseDir+'"'),"-Port",$Port,"-ServiceName",('"'+$ServiceName+'"'),"-Central",$Central)
  if($Source){ $a += @("-Source",('"'+$Source+'"')) }
  if($Reset){ $a += "-Reset" }
  Start-Process powershell -Verb RunAs -ArgumentList $a   # 비번은 보안상 명령줄로 안 넘김 — 재실행 후 물어봄
  exit
}

Write-Host "============================================"
Write-Host "   MySQL 8.4 자동 세팅"
Write-Host "============================================"

# --- 1. 바이너리 위치 확보 ---
$scriptDir = Split-Path -Parent $PSCommandPath
function Test-MysqlDir($d){ return ($d -and (Test-Path (Join-Path $d "bin\mysqld.exe"))) }

if(-not (Test-MysqlDir $BaseDir)){
  $srcDir = ""; $srcZip = ""
  if($Source){
    if((Test-Path $Source) -and (Get-Item $Source).PSIsContainer){ $srcDir = $Source }
    elseif(Test-Path $Source){ $srcZip = $Source }
    else { Die "지정한 -Source 를 찾을 수 없습니다: $Source" }
  } else {
    foreach($base in @($scriptDir, (Get-Location).Path)){
      $cand = Join-Path $base "mysql-8.4.9-winx64"
      if(Test-MysqlDir $cand){ $srcDir = $cand; break }
      $z = Join-Path $base "mysql-8.4.9-winx64.zip"
      if(Test-Path $z){ $srcZip = $z; break }
    }
  }
  if($srcDir){
    if(Test-Path $BaseDir){ Die "$BaseDir 가 이미 있습니다. 지우거나 -BaseDir 로 다른 경로를 지정하세요." }
    Info "추출 폴더를 $BaseDir 로 이동..."
    Move-Item $srcDir $BaseDir
  } elseif($srcZip){
    if(Test-Path $BaseDir){ Die "$BaseDir 가 이미 있습니다. 지우거나 -BaseDir 로 다른 경로를 지정하세요." }
    Info "zip 압축 해제 중..."
    $tmp = Join-Path $env:TEMP ("mysqlsetup_"+[IO.Path]::GetRandomFileName())
    Expand-Archive -LiteralPath $srcZip -DestinationPath $tmp -Force
    $inner = Join-Path $tmp "mysql-8.4.9-winx64"
    if(-not (Test-MysqlDir $inner)){ Die "zip 내부 구조가 예상과 다릅니다." }
    Move-Item $inner $BaseDir
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  } else {
    Die "MySQL 바이너리를 못 찾았습니다. reassemble.cmd로 zip을 복원해 압축을 풀거나, -Source 로 경로를 지정하세요."
  }
}
$mysqld = Join-Path $BaseDir "bin\mysqld.exe"
$mysql  = Join-Path $BaseDir "bin\mysql.exe"
Ok "MySQL 바이너리: $BaseDir\bin"

# --- 1.5 기존 세팅 탐지 → (동의 시) 전부 정리 ---
# 대상은 '이 BaseDir을 가리키는 mysqld 서비스'로 한정 — 같은 이름의 무관한 서비스는 건드리지 않는다.
$dataDir = Join-Path $BaseDir "data"
$existingSvcs = @()
try {
  Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
    Where-Object { $_.PathName -match 'mysqld' -and $_.PathName -match [regex]::Escape($BaseDir) } |
    ForEach-Object { $existingSvcs += $_.Name }
} catch {}
$existingSvcs = @($existingSvcs | Select-Object -Unique)
$hasExisting = ($existingSvcs.Count -gt 0) -or (Test-Path $dataDir)

if($hasExisting){
  Write-Host ""
  Write-Host "[!] 기존 MySQL 세팅이 발견됐습니다:" -ForegroundColor Yellow
  if($existingSvcs.Count){ Write-Host "    - 서비스: $($existingSvcs -join ', ')" }
  if(Test-Path $dataDir){ Write-Host "    - 데이터 폴더: $dataDir" }
  $doReset = [bool]$Reset
  if(-not $doReset){
    $ans = Read-Host "전부 삭제하고 새로 설치할까요? (이 폴더의 데이터가 지워집니다) [y/N]"
    $doReset = ($ans -match '^[Yy]')
  }
  if(-not $doReset){ Die "취소했습니다(기존 세팅 유지). 새로 설치하려면 다시 실행해 삭제에 동의하세요." }

  foreach($s in $existingSvcs){
    Info "기존 서비스 중지/제거: $s"
    try{ Stop-Service -Name $s -Force -ErrorAction SilentlyContinue }catch{}
    Start-Sleep -Milliseconds 500
    & $mysqld "--remove" $s 2>$null | Out-Null
    cmd /c "sc.exe delete `"$s`" >nul 2>&1"
    for($w=0; $w -lt 12; $w++){ if(-not (Get-Service -Name $s -ErrorAction SilentlyContinue)){ break }; Start-Sleep -Milliseconds 500 }
  }
  try {
    Get-CimInstance Win32_Process -Filter "Name='mysqld.exe'" -ErrorAction SilentlyContinue |
      Where-Object { $_.ExecutablePath -like "$BaseDir*" } |
      ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  } catch {}
  Start-Sleep -Seconds 1
  if(Test-Path $dataDir){ Info "기존 데이터 폴더 삭제..."; Remove-Item $dataDir -Recurse -Force }
  cmd /c "netsh advfirewall firewall delete rule name=`"MySQL $Port`" >nul 2>&1"
  Ok "기존 세팅 정리 완료 — 새로 설치합니다"
}

# --- 2. 충돌 점검(정리 후 최종 확인) ---
if(Get-Service -Name $ServiceName -ErrorAction SilentlyContinue){
  Die "서비스 '$ServiceName' 가 (다른 경로로) 이미 존재합니다. -ServiceName 으로 다른 이름을 쓰세요."
}
try {
  if(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue){
    Die "포트 $Port 를 이미 사용 중입니다. -Port 로 다른 포트를 지정하세요."
  }
} catch {}

# --- 3. 중앙 서버(원격 허용) 여부 ---
if($Central -eq "ask"){
  $ans = Read-Host "다른 PC에서 접속하는 '중앙 서버'로 쓰나요? (원격 허용 + 방화벽 3306) [y/N]"
  $Central = if($ans -match '^[Yy]'){ "yes" } else { "no" }
}
$bindLine = if($Central -eq "yes"){ "bind-address=0.0.0.0" } else { "# bind-address=127.0.0.1  (로컬 전용)" }

# --- 4. my.ini ---
$baseFwd = $BaseDir -replace '\\','/'
$myini = @"
[mysqld]
basedir=$baseFwd
datadir=$baseFwd/data
port=$Port
$bindLine
character-set-server=utf8mb4
collation-server=utf8mb4_0900_ai_ci
"@
$iniPath = Join-Path $BaseDir "my.ini"
[IO.File]::WriteAllText($iniPath, ($myini -replace "`r?`n","`r`n"), (New-Object Text.UTF8Encoding($false)))
Ok "설정 파일: $iniPath"

# --- 5. 데이터 초기화(폴더 없을 때만) ---
$dataDir = Join-Path $BaseDir "data"
$fresh = $false
if(-not (Test-Path $dataDir)){
  Info "데이터 디렉터리 초기화..."
  & $mysqld "--defaults-file=$iniPath" "--initialize-insecure"
  if($LASTEXITCODE -ne 0){ Die "초기화 실패(exit $LASTEXITCODE). $BaseDir\data 의 *.err 로그를 확인하세요." }
  $fresh = $true; Ok "초기화 완료"
} else {
  Info "데이터 디렉터리가 이미 있어 초기화를 건너뜁니다(기존 데이터 유지)."
}

# --- 6. 서비스 등록 + 시작 ---
Info "서비스 등록: $ServiceName"
& $mysqld "--install" $ServiceName "--defaults-file=$iniPath"
if($LASTEXITCODE -ne 0){ Die "서비스 등록 실패(exit $LASTEXITCODE)." }
Info "서비스 시작..."
Start-Service $ServiceName
for($i=0; $i -lt 30; $i++){ if((Get-Service $ServiceName).Status -eq 'Running'){ break }; Start-Sleep -Milliseconds 500 }
if((Get-Service $ServiceName).Status -ne 'Running'){ Die "서비스가 시작되지 않았습니다. $BaseDir\data 의 *.err 로그를 확인하세요." }
Ok "서비스 실행 중"

# --- 7. root 비밀번호(신규 초기화한 경우만) ---
if($fresh){
  $sec = Read-Host "root 계정에 설정할 비밀번호를 입력" -AsSecureString
  $pw  = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
  if(-not $pw){ Die "비밀번호가 비어 있습니다." }
  $escaped = $pw -replace "'","''"
  $sqlFile = Join-Path $env:TEMP ("mysqlpw_"+[IO.Path]::GetRandomFileName()+".sql")
  "ALTER USER 'root'@'localhost' IDENTIFIED BY '$escaped'; FLUSH PRIVILEGES;" | Out-File -FilePath $sqlFile -Encoding ascii
  Info "root 비밀번호 설정..."
  cmd /c "`"$mysql`" -u root --skip-password -P $Port -h 127.0.0.1 < `"$sqlFile`""
  $rc = $LASTEXITCODE
  Remove-Item $sqlFile -Force -ErrorAction SilentlyContinue
  if($rc -ne 0){ Die "root 비밀번호 설정 실패(exit $rc)." }
  Ok "root 비밀번호 설정 완료"
  $ver = & $mysql "-u" "root" "-p$pw" "-P" $Port "-h" "127.0.0.1" "-N" "-e" "SELECT VERSION();" 2>$null
} else {
  $ver = "(기존 데이터 — 기존 root 비번으로 접속해 확인하세요)"
}

# --- 8. 방화벽(중앙 서버일 때) ---
if($Central -eq "yes"){
  Info "방화벽 $Port(TCP) 인바운드 허용..."
  netsh advfirewall firewall add rule name="MySQL $Port" dir=in action=allow protocol=TCP localport=$Port | Out-Null
  Ok "방화벽 규칙 추가"
}

# --- 9. 완료 ---
Write-Host ""
Ok "완료! MySQL이 서비스 '$ServiceName'(포트 $Port)로 실행 중입니다.  $ver"
Write-Host ""
Write-Host "다음 단계 — 앱 DB 만들기 (schema.sql / create-app-user.sql 를 이 폴더에 두고):"
Write-Host "  `"$mysql`" -u root -p < schema.sql"
Write-Host "  `"$mysql`" -u root -p < create-app-user.sql"
Write-Host ""
try{ Read-Host "엔터를 누르면 종료" }catch{}
