@echo off
rem MySQL 설치 점검 — 더블클릭하면 서비스/버전/문자셋/앱DB/포트를 한 번에 확인(읽기 전용)
rem root 비밀번호만 입력하면 됨. 아무것도 바꾸지 않음.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check.ps1" %*
