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

## 함께 담긴 것 — `taskcalendar-widget/`

이 저장소는 폐쇄망 반입 창구로도 쓰고 있습니다. **수행과제 캘린더의 과제 DB 테스트 세트**가 [`taskcalendar-widget/`](taskcalendar-widget/) 에 있습니다(위젯 exe 분할본 + DB 구축 스크립트). 시작은 그 폴더의 **`읽어보세요.txt`** 부터.

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