<#
  check.ps1 — MySQL 설치 점검(읽기 전용). setup 후 "제대로 됐는지" 한 번에 확인한다.
  서비스 실행 / 접속+버전 / 문자셋 / (앱 DB 있으면) 테이블·건수·앱계정 / 포트 리스닝.
  보통은 check.cmd 더블클릭. 비번만 넣으면 됨. 아무것도 바꾸지 않는다.
#>
[CmdletBinding()]
param(
  [string]$BaseDir = "C:\mysql",
  [int]$Port = 3306,
  [string]$ServiceName = "MySQL84",
  [string]$RootPassword = ""
)
$ErrorActionPreference = "Continue"   # 읽기 전용 점검 — 네이티브 stderr가 창을 닫지 않게 Continue
$script:pass = 0; $script:fail = 0
function Chk($name,$ok,$detail){
  if($ok){ Write-Host ("[OK]   {0}  {1}" -f $name,$detail) -ForegroundColor Green; $script:pass++ }
  else   { Write-Host ("[실패] {0}  {1}" -f $name,$detail) -ForegroundColor Red;   $script:fail++ }
}
function Warn($name,$detail){ Write-Host ("[!]    {0}  {1}" -f $name,$detail) -ForegroundColor Yellow }

Write-Host "============================================"
Write-Host "   MySQL 설치 점검 (읽기 전용)"
Write-Host "============================================"

# --- mysql.exe 위치(지정 경로 → 서비스 binPath 추론) ---
$mysql = Join-Path $BaseDir "bin\mysql.exe"
if(-not (Test-Path $mysql)){
  try {
    $svc = Get-CimInstance Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
    if($svc -and $svc.PathName -match '"?([A-Za-z]:[^"]*)\\bin\\mysqld\.exe'){
      $cand = Join-Path $Matches[1] "bin\mysql.exe"
      if(Test-Path $cand){ $mysql = $cand; $BaseDir = $Matches[1] }
    }
  } catch {}
}
if(-not (Test-Path $mysql)){
  Write-Host "[실패] mysql.exe 를 못 찾았습니다. -BaseDir 로 설치 경로를 지정하세요 (예: -BaseDir C:\mysql)" -ForegroundColor Red
  try{ Read-Host "엔터를 누르면 종료" }catch{}; exit 1
}

# --- 1. 서비스 ---
$svcObj = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
Chk "서비스($ServiceName)" ($svcObj -and $svcObj.Status -eq 'Running') ("상태=" + $(if($svcObj){$svcObj.Status}else{'없음'}))

# --- root 비번 ---
if(-not $RootPassword){
  $sec = Read-Host "root 비밀번호 입력" -AsSecureString
  $RootPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}
# 임시 옵션파일 — 비번을 명령줄에 안 둬서 경고/크래시 없음
$cnf = Join-Path $env:TEMP ("mychk_"+[IO.Path]::GetRandomFileName()+".cnf")
$pwEsc = ($RootPassword -replace '\\','\\') -replace '"','\"'
"[client]`r`nuser=root`r`npassword=""$pwEsc""`r`nhost=127.0.0.1`r`nport=$Port" | Out-File -FilePath $cnf -Encoding ascii
function Q($sql){ return ("" + (& $mysql "--defaults-extra-file=$cnf" "-N" "-B" "-e" $sql)) }

# --- 2. 접속 + 버전 ---
$ver = (Q "SELECT VERSION();").Trim()
Chk "접속+버전" ($ver -match '^8\.4') ("VERSION()=" + $(if($ver){$ver}else{'접속 실패 — 비번을 확인하세요'}))

if($ver -match '^8\.4'){
  # --- 3. 문자셋/콜레이션 ---
  $cs = (Q "SELECT @@character_set_server, @@collation_server;").Trim()
  Chk "문자셋" (($cs -match 'utf8mb4') -and ($cs -match 'utf8mb4_0900_ai_ci')) $cs

  # --- 5. 앱 DB(있을 때만) ---
  $hasDb = (Q "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='taskmgr';").Trim()
  if($hasDb -eq 'taskmgr'){
    $tbls = (Q "SELECT GROUP_CONCAT(TABLE_NAME ORDER BY TABLE_NAME) FROM information_schema.TABLES WHERE TABLE_SCHEMA='taskmgr';").Trim()
    Chk "앱 DB 테이블" (($tbls -match 'customer') -and ($tbls -match 'project')) ("테이블: " + $tbls)
    $pc = (Q "SELECT COUNT(*) FROM taskmgr.project;").Trim()
    $cc = (Q "SELECT COUNT(*) FROM taskmgr.customer;").Trim()
    Write-Host ("       과제 $pc 건 / 발주처 $cc 건")
    $appUser = (Q "SELECT COUNT(*) FROM mysql.user WHERE user='taskmgr_app';").Trim()
    Chk "앱 계정(taskmgr_app)" ($appUser -eq '1') ("존재 개수=" + $appUser)
  } else {
    Warn "앱 DB" "taskmgr 미생성 — schema.sql / create-app-user.sql 를 아직 안 돌렸습니다(서버만 준비된 상태)."
  }
}

# --- 4. 포트 리스닝 ---
$listen = $null
try { $listen = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue } catch {}
if($listen){
  $addrs = (($listen | ForEach-Object { $_.LocalAddress } | Select-Object -Unique) -join ', ')
  $remote = if($addrs -match '0\.0\.0\.0|::'){ ' (원격 접속 가능)' } else { ' (로컬 전용)' }
  Chk "포트 $Port" $true ("리스닝: " + $addrs + $remote)
} else {
  Chk "포트 $Port" $false "리스닝 안 함(서비스 미기동?)"
}

Remove-Item $cnf -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host ("결과: {0} 통과 / {1} 실패" -f $script:pass, $script:fail)
if($script:fail -eq 0){ Write-Host "★ 설치 정상입니다." -ForegroundColor Green }
else { Write-Host "위 [실패] 항목을 확인하세요." -ForegroundColor Red }
try{ Read-Host "엔터를 누르면 종료" }catch{}
