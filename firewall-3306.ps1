<#
  firewall-3306.ps1 — 이 PC를 '중앙 DB 서버'로 쓸 때 다른 PC가 MySQL에 붙도록 방화벽을 연다.

  왜 필요한가: MySQL 쪽 준비(bind_address, 계정 host='%')가 끝나 있어도 Windows 방화벽이
  인바운드 3306을 막으면 다른 PC에서 접속이 안 된다. 증상이 "연결 안 됨"뿐이라 원인 찾기가 어렵다.

  사용(더블클릭이면 firewall-3306.cmd):
      firewall-3306.cmd                 # 사내망(로컬 서브넷)만 허용 — 권장
      firewall-3306.cmd -Scope Any      # 모든 주소 허용(범위가 넓다, 필요할 때만)
      firewall-3306.cmd -Remove         # 규칙 삭제(원복)
      firewall-3306.cmd -Port 3307      # 포트를 바꿔 쓸 때

  - 관리자 권한이 필요하다. 없으면 자동으로 UAC로 다시 띄운다.
  - 재실행해도 안전(같은 이름 규칙을 지우고 다시 만든다 — 중복 규칙이 쌓이지 않는다).
  - 위젯 DeployConfig.DbHost 에 넣을 이 PC의 IP도 함께 보여준다.
#>
[CmdletBinding()]
param(
  [int]$Port = 3306,
  [ValidateSet('LocalSubnet','Any')]
  [string]$Scope = 'LocalSubnet',    # 기본은 사내망만 — 범위를 좁게 잡는다
  [switch]$Remove,                   # 규칙 삭제(원복)
  [string]$RuleName = ''             # 기본: "MySQL <Port>" (setup.ps1이 만드는 이름과 동일)
)
$ErrorActionPreference = "Continue"
function Info($m){ Write-Host "[*] $m" }
function Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[!] $m" -ForegroundColor Yellow }
function Die($m){ Write-Host "[오류] $m" -ForegroundColor Red; try{ Read-Host "엔터를 누르면 종료" }catch{}; exit 1 }

if(-not $RuleName){ $RuleName = "MySQL $Port" }

# --- 0. 관리자 권한 확인 → 없으면 재실행(UAC) ---
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $admin){
  Info "관리자 권한으로 다시 실행합니다 (UAC 창을 승인하세요)..."
  $a = @("-NoProfile","-ExecutionPolicy","Bypass","-File",('"'+$PSCommandPath+'"'),
         "-Port",$Port,"-Scope",$Scope,"-RuleName",('"'+$RuleName+'"'))
  if($Remove){ $a += "-Remove" }
  Start-Process powershell -Verb RunAs -ArgumentList $a
  exit
}

Write-Host "============================================"
Write-Host "   MySQL 방화벽 $Port(TCP) 인바운드"
Write-Host "============================================"

# --- 1. 삭제 모드 ---
if($Remove){
  Info "규칙 삭제: `"$RuleName`""
  cmd /c "netsh advfirewall firewall delete rule name=`"$RuleName`" >nul 2>&1"
  $left = cmd /c "netsh advfirewall firewall show rule name=`"$RuleName`" 2>nul"
  if("$left" -match '규칙 이름|Rule Name'){ Die "규칙이 아직 남아 있습니다." }
  Ok "삭제 완료 — 다른 PC에서 이 PC의 MySQL로 접속할 수 없습니다."
  try{ Read-Host "엔터를 누르면 종료" }catch{}
  exit 0
}

# --- 2. 규칙 추가(중복 방지: 같은 이름을 지우고 다시) ---
Info "기존 동일 이름 규칙 정리..."
cmd /c "netsh advfirewall firewall delete rule name=`"$RuleName`" >nul 2>&1"

Info "규칙 추가: `"$RuleName`" · TCP $Port · 범위 $Scope"
$add = cmd /c "netsh advfirewall firewall add rule name=`"$RuleName`" dir=in action=allow protocol=TCP localport=$Port remoteip=$Scope profile=any 2>&1"
if($LASTEXITCODE -ne 0){ Die "규칙 추가 실패: $add" }

# --- 3. 검증: 규칙이 실제로 조회되는가 ---
$show = cmd /c "netsh advfirewall firewall show rule name=`"$RuleName`" 2>nul"
if(-not ("$show" -match '규칙 이름|Rule Name')){ Die "규칙을 추가했는데 조회되지 않습니다." }
Ok "방화벽 규칙 적용됨"
if($Scope -eq 'LocalSubnet'){
  Write-Host "   범위 = 같은 서브넷(사내망)만. 다른 대역에서 붙어야 하면:  firewall-3306.cmd -Scope Any"
} else {
  Warn "범위 = 모든 주소(Any). 필요한 범위가 아니면 -Scope LocalSubnet 으로 다시 실행하세요."
}

# --- 4. MySQL이 실제로 그 포트를 듣고 있는가(원인 분리용) ---
Write-Host ""
$listen = cmd /c "netstat -ano -p tcp 2>nul | findstr :$Port"
if("$listen" -match "LISTENING"){ Ok "MySQL이 $Port 포트를 수신 중입니다." }
else {
  Warn "$Port 포트를 수신하는 프로세스가 없습니다 — MySQL 서비스가 꺼져 있을 수 있습니다."
  Write-Host "     서비스 확인:  sc query MySQL84     시작:  net start MySQL84"
}

# --- 5. 위젯 DeployConfig.DbHost 에 넣을 이 PC의 IP ---
Write-Host ""
Write-Host "── 위젯에 넣을 이 PC의 주소(DeployConfig.DbHost) ──"
try {
  $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
         Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' }
  if($ips){ foreach($i in $ips){ Write-Host ("   {0}   ({1})" -f $i.IPAddress, $i.InterfaceAlias) } }
  else { Warn "표시할 IPv4 주소가 없습니다." }
} catch {
  cmd /c "ipconfig | findstr /C:IPv4"
}
Write-Host ""
Write-Host "   위 주소 중 사내망 주소를 widget/DeployConfig.cs 의 DbHost 에 넣고 위젯을 다시 빌드하면"
Write-Host "   다른 PC의 위젯이 이 PC의 MySQL에 붙습니다."
Write-Host "   ※ 이 PC가 DHCP로 주소를 받으면 재부팅 때 바뀔 수 있습니다 — 고정 IP(또는 DHCP 예약)를 권장합니다."
Write-Host "   ※ 테스트 기간에는 이 PC를 켜 두고, 절전으로 들어가지 않게 설정하세요."

Write-Host ""
Ok "완료"
try{ Read-Host "엔터를 누르면 종료" }catch{}
