# AI 문서 구조

이 디렉토리는 AI 에이전트가 프로젝트를 이해하기 위한 문서들을 포함합니다.
`.gitignore`에 포함되어 있으며 로컬에서만 유지됩니다.

---

## 읽는 순서

새 세션 시작 시 아래 순서로 읽습니다:

1. `.ai/README.md` — 이 파일 (문서 구조 파악)
2. `.ai/agents.md` — 역할 분담 및 워크플로우
3. `.ai/architecture.md` — 시스템 구조
4. `.ai/conventions.md` — 프로젝트 규칙
5. `CURRENT_TASK.md` — 현재 작업 상태

---

## 문서 맵

| 파일 | 역할 | 업데이트 주체 |
|---|---|---|
| `README.md` | 이 파일, AI 진입점 | 프로젝트 설정 시 1회 |
| `agents.md` | 에이전트 역할·워크플로우·라우팅 | 규칙 변경 시 |
| `architecture.md` | 시스템 구조·기술 스택·데이터 흐름 | 구조 변경 시 |
| `conventions.md` | 코딩 규칙·도메인 규칙·구현 게이트 | 규칙 변경 시 |
| `context-reset.md` | compact 이후 복구 체크리스트 | 거의 안 바꿈 |
| `docs/PROJECT.md` | 현재 상태 (정책·런타임 계약) | 코드 변경 시 동기화 |
| `docs/TODO.md` | 미완료·우선순위 | 작업 완료 시 |
| `docs/API_DOCS.md` | API 계약 | API 변경 시 |
| `docs/specs/*.draft.md` | 기획 초안 (임시) | 구현 완료 시 **삭제** |
| `docs/migrations/*.sql` | 미적용 마이그레이션 (임시) | 적용 완료 시 **삭제** |

---

## 임시 파일 규칙

`specs/*.draft.md`, `specs/*.review.md`, `migrations/*.sql`은 **작업용 임시 파일**입니다.
해당 작업이 완료되면 반드시 삭제합니다. 파일이 존재 = 아직 작업 중을 의미합니다.
