# mysql-8.4.9-winx64-offline — 오프라인/폐쇄망용 분할 배포

폐쇄망 PC에서 **`git clone` 만으로** `mysql-8.4.9-winx64.zip` 을 받기 위해, 90MiB 단위로 분할해 올린 저장소입니다. (GitHub 단일 파일 100MB 제한 회피)

- **대상 파일**: `mysql-8.4.9-winx64.zip` (원본 약 267 MB, 3 조각)
- **버전**: 8.4.9
- **공식 출처**: <https://cdn.mysql.com/archives/mysql-8.4/mysql-8.4.9-winx64.zip>
- 분할↔재결합 무손실(SHA256) 검증됨.

## 사용법 (폐쇄망 PC)
1. 이 저장소를 `git clone` (또는 `git pull`)
2. **`reassemble.cmd` 더블클릭** → `mysql-8.4.9-winx64.zip` 생성 + SHA256 자동 검증
3. "무결성 OK" 가 보이면 생성된 파일을 사용 (오프라인 완결, 추가 다운로드 없음)

> 수동 재결합(명령 프롬프트):
> ```bat
> copy /b parts\mysql-8.4.9-winx64.zip.001+parts\mysql-8.4.9-winx64.zip.002+parts\mysql-8.4.9-winx64.zip.003 mysql-8.4.9-winx64.zip
> ```
> (의존성 없음 — Windows 내장 `copy /b` + `certutil` 만 사용)

## 무결성
- **SHA256** (재결합본 검증용): `5795BA250E89290F7507ED3BCC6A655BE373616ABB58B877ACDEA71E1B8F4E8C`
- **MD5** (MySQL 공식 배포값과 대조 완료 ✓): `fe14853279d1704e0f0eb253ea8c8d33`

원본은 MySQL 공식 CDN(`cdn.mysql.com`)에서 받아 **공식 MD5와 일치 확인** 후 분할했습니다.

## 설치
재결합 → 압축 해제 후, **`setup.cmd` 더블클릭** 한 번으로 서버가 뜹니다(관리자 권한 자동 상승, 초기화·서비스 등록·root 비번·방화벽·확인까지). 이미 하다가 꼬였으면 기존 세팅을 지우고 새로 깔지 물어봅니다. 수동 절차·옵션은 **[SETUP.md](SETUP.md)** 참고.

## 함께 담긴 것

이 저장소는 폐쇄망 반입 창구로도 쓰고 있습니다.

| 폴더 | 내용 |
|---|---|
| [`workbench/`](workbench/) | **MySQL Workbench 8.0.42** (오라클 공식 GUI, 43MB) — 테이블·데이터를 표로 보고 편집. ZIP 서버 패키지엔 GUI가 없어 따로 담음 |
| [`taskcalendar-widget/`](taskcalendar-widget/) | **수행과제 캘린더 과제 DB 테스트 세트** — 위젯 exe 분할본 + DB 구축 스크립트 |

각 폴더의 **`읽어보세요.txt`** 부터 보세요.

---

## 라이선스 / 재배포 고지

이 저장소는 **Oracle의 MySQL 소프트웨어를 수정 없이 재배포**합니다.

| 구성 | 라이선스 | 소스 |
|---|---|---|
| MySQL Community Server 8.4.9 | **GPLv2** | <https://dev.mysql.com/downloads/mysql/> |
| MySQL Workbench Community 8.0.42 | **GPLv2** | <https://dev.mysql.com/downloads/workbench/> |

- 두 소프트웨어 모두 **GPLv2로 자유롭게 사용·재배포** 가능하며, 위 공식 경로에서 **대응 소스코드를 받을 수 있습니다**(GPLv2 소스 제공 고지).
- 바이너리는 **오라클 공식 CDN에서 받아 공개 MD5와 대조**한 뒤 올렸습니다(각 폴더의 `읽어보세요.txt`에 해시 기재).
- 이 저장소에 담긴 **수행과제 캘린더 위젯은 GPL이 아닙니다.** MySQL 서버와는 별도 프로세스로 네트워크 프로토콜(MySQL wire protocol)로만 통신하며, 사용하는 커넥터는 [MySqlConnector](https://mysqlconnector.net/)(**MIT 라이선스**)로 Oracle의 GPL Connector/NET을 쓰지 않습니다.

## 설치 확인
**`check.cmd` 더블클릭** → root 비번만 넣으면 서비스·버전·문자셋·(앱 DB)·포트를 한 번에 점검합니다(읽기 전용, 아무것도 안 바꿈). 각 항목 `[OK]/[실패]` + 결과 요약.

## 구성
| 항목 | 설명 |
|---|---|
| `parts/*.001 ~ .003` | 분할 파일 (각 ≤ 90 MiB) |
| `reassemble.cmd` | 재결합 + SHA256 자동 검증 (의존성 0) |
| `SHA256SUMS.txt` | 재결합본 검증용 해시 |

---
*이 저장소는 `offline-pack` 도구로 자동 생성되었습니다.*