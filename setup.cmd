@echo off
rem MySQL 8.4 자동 세팅 — 더블클릭하면 관리자 권한으로 setup.ps1 실행
rem (초기화 -> 서비스 등록/시작 -> root 비번 -> 방화벽 -> 확인)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
