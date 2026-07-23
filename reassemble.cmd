@echo off
setlocal
cd /d "%~dp0"
set "NAME=mysql-8.4.9-winx64.zip"
set "EXPECT=5795BA250E89290F7507ED3BCC6A655BE373616ABB58B877ACDEA71E1B8F4E8C"

echo ============================================
echo   mysql-8.4.9-winx64-offline - 설치파일 재결합
echo ============================================
echo.

if not exist "parts\%NAME%.001" (
  echo [오류] parts\%NAME%.001 이 없습니다. git clone/pull 이 완료됐는지 확인하세요.
  pause ^& exit /b 1
)

echo 재결합 중...
copy /b "parts\mysql-8.4.9-winx64.zip.001"+"parts\mysql-8.4.9-winx64.zip.002"+"parts\mysql-8.4.9-winx64.zip.003" "%NAME%" >nul
if errorlevel 1 ( echo [실패] 재결합 오류. ^& pause ^& exit /b 1 )

echo 완료: %~dp0%NAME%
echo.
echo === SHA256 검증 ===
for /f "skip=1 tokens=* delims=" %%H in ('certutil -hashfile "%NAME%" SHA256') do (
  if not defined GOT set "GOT=%%H"
)
set "GOT=%GOT: =%"
echo  계산값: %GOT%
echo  기대값: %EXPECT%
if /I "%GOT%"=="%EXPECT%" (
  echo  [확인] 무결성 OK - %NAME% 를 사용하세요.
) else (
  echo  [경고] 해시 불일치! 파일이 손상됐을 수 있습니다. 다시 clone 후 시도하세요.
)
echo.
pause