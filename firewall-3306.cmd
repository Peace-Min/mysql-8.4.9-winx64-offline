@echo off
rem MySQL 3306 방화벽 열기 — 이 PC를 중앙 DB 서버로 쓸 때 더블클릭(UAC 승인 필요).
rem 기본은 사내망(로컬 서브넷)만 허용. 원복은  firewall-3306.cmd -Remove
rem 모든 주소 허용:  firewall-3306.cmd -Scope Any     포트 변경:  firewall-3306.cmd -Port 3307
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0firewall-3306.ps1" %*
