# taskcalendar-widget — 오프라인/폐쇄망용 분할 배포

폐쇄망 PC에서 **`git clone` 만으로** `TaskCalendarWidget.exe` 을 받기 위해, 90MiB 단위로 분할해 올린 저장소입니다. (GitHub 단일 파일 100MB 제한 회피)

- **대상 파일**: `TaskCalendarWidget.exe` (원본 약 166 MB, 2 조각)
- **버전**: 0.12.0-dbtest

- 분할↔재결합 무손실(SHA256) 검증됨.

## 사용법 (폐쇄망 PC)
1. 이 저장소를 `git clone` (또는 `git pull`)
2. **`reassemble.cmd` 더블클릭** → `TaskCalendarWidget.exe` 생성 + SHA256 자동 검증
3. "무결성 OK" 가 보이면 생성된 파일을 사용 (오프라인 완결, 추가 다운로드 없음)

> 수동 재결합(명령 프롬프트):
> ```bat
> copy /b parts\TaskCalendarWidget.exe.001+parts\TaskCalendarWidget.exe.002 TaskCalendarWidget.exe
> ```
> (의존성 없음 — Windows 내장 `copy /b` + `certutil` 만 사용)

## 무결성 (SHA256)
```
1C3C1B1527AED3040ABB6C6A96C24836666FCCFB0FCBDF2871ACB3D8361F2D0B *TaskCalendarWidget.exe
```

## 구성
| 항목 | 설명 |
|---|---|
| `parts/*.001 ~ .002` | 분할 파일 (각 ≤ 90 MiB) |
| `reassemble.cmd` | 재결합 + SHA256 자동 검증 (의존성 0) |
| `SHA256SUMS.txt` | 재결합본 검증용 해시 |

---
*이 저장소는 `offline-pack` 도구로 자동 생성되었습니다.*