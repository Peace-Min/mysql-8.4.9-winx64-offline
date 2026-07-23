# 폐쇄망 MySQL 8.4 서버 설치 (ZIP 무인스톨)

`reassemble.cmd`로 `mysql-8.4.9-winx64.zip`을 복원한 뒤, 이 ZIP만으로 Windows에 MySQL 서버를 세웁니다. **온라인 접속 없이 완결**됩니다.

---

## ★ 자동 설치 (권장) — `setup.cmd` 더블클릭

수동 절차가 번거로우면 **`setup.cmd` 를 더블클릭**하세요. 관리자 권한을 자동으로 올리고(UAC 승인) 아래를 한 번에 처리합니다:

1. 압축 푼 폴더(또는 zip)를 찾아 `C:\mysql` 로 배치
2. `my.ini` 생성 → 데이터 초기화 → **서비스 등록/시작** → **root 비밀번호 설정**(입력 요청) → (중앙서버면) 방화벽 3306 → 버전 확인

진행 중 딱 두 가지만 물어봅니다: **중앙 서버인지(원격 허용)** / **root 비밀번호**.

> **이미 하다가 꼬였을 때**: 기존 세팅(서비스·데이터 폴더)이 발견되면 "전부 지우고 새로 설치할까요?"를 물어봅니다. `y` 를 누르면 **이 폴더의 기존 MySQL 세팅만** 깨끗이 지우고 새로 깝니다. 확인 없이 밀어버리려면 명령줄로:
> ```
> powershell -ExecutionPolicy Bypass -File setup.ps1 -Reset
> ```

세부 지정이 필요할 때(옵션):
```
powershell -ExecutionPolicy Bypass -File setup.ps1 -BaseDir C:\mysql -Port 3306 -Central yes
```
- `-BaseDir` 설치 위치 · `-Port` 포트 · `-Central yes|no` 원격 허용 · `-ServiceName` 서비스명 · `-Reset` 기존 세팅 강제 삭제

설치가 끝나면 아래 "다음: 앱 DB 구성"으로 이동하세요. **수동으로 하고 싶으면** 아래 절차를 따르면 됩니다.

---

## 수동 설치 (직접 하고 싶을 때)

관리자 권한 콘솔에서 실행. 예시 경로는 `C:\mysql` 기준(원하는 곳으로 바꿔도 됨).

## 1. 압축 해제
`mysql-8.4.9-winx64.zip`을 풀면 `mysql-8.4.9-winx64\`(bin, lib, share…)가 나옵니다. 이를 `C:\mysql`로 옮깁니다(즉 `C:\mysql\bin\mysqld.exe`가 되도록).

## 2. 설정 파일 `C:\mysql\my.ini`
```ini
[mysqld]
basedir=C:/mysql
datadir=C:/mysql/data
port=3306
# ★ 다른 PC(클라이언트)가 접속하는 중앙 서버면 아래를 켠다(로컬 전용이면 생략)
bind-address=0.0.0.0
character-set-server=utf8mb4
collation-server=utf8mb4_0900_ai_ci
```

## 3. 데이터 디렉터리 초기화
```bat
C:\mysql\bin\mysqld --defaults-file=C:\mysql\my.ini --initialize-insecure
```
- `--initialize-insecure` = root 비밀번호 없이 초기화(다음 단계에서 즉시 설정). 통제된 폐쇄망 셋업용.
- (더 엄격히: `--initialize --console` 를 쓰면 임시 root 비번이 콘솔에 출력되고 최초 로그인 시 변경해야 함)

## 4. Windows 서비스 등록 + 시작
```bat
C:\mysql\bin\mysqld --install MySQL84 --defaults-file=C:\mysql\my.ini
net start MySQL84
```

## 5. root 비밀번호 설정 (insecure 초기화한 경우)
```bat
C:\mysql\bin\mysql -u root --skip-password
```
접속 후:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '강한_비밀번호';
FLUSH PRIVILEGES;
```

## 6. 원격 접속 허용 (중앙 서버로 쓸 때)
- `my.ini`에 `bind-address=0.0.0.0` (2단계에서 설정됨)
- **Windows 방화벽 3306 인바운드 허용**:
  ```bat
  netsh advfirewall firewall add rule name="MySQL 3306" dir=in action=allow protocol=TCP localport=3306
  ```

## 7. 확인
```bat
C:\mysql\bin\mysql -u root -p -e "SELECT VERSION();"
```
`8.4.9`가 나오면 서버 준비 완료.

---

## 설치 확인 — `check.cmd` (권장)

설치가 제대로 됐는지 보려면 **`check.cmd` 더블클릭** → root 비번 입력. 읽기 전용(아무것도 안 바꿈)으로 점검:

- 서비스 실행 · 접속+버전(8.4.9) · 문자셋(utf8mb4_0900_ai_ci)
- (앱 DB가 있으면) `taskmgr` 테이블·건수·`taskmgr_app` 계정
- 포트 3306 리스닝 / 원격 접속 가능 여부

각 항목 `[OK]/[실패]` + `N 통과 / M 실패` 요약. 경로가 다르면 `check.cmd -BaseDir D:\mysql -Port 3307`.

## 다음: 앱 DB 구성
서버가 뜨면, 각 앱 저장소의 스크립트로 데이터베이스·계정을 만듭니다. 예) 수행과제 캘린더:
- `schema.sql` — DB·테이블 생성
- `db/deploy/create-app-user.sql` — 앱용 최소권한 계정(`taskmgr_app`)

> 이 저장소는 **MySQL 서버 바이너리 반입 전용**입니다. 앱별 스키마/계정 스크립트는 해당 앱 저장소에 있습니다.
