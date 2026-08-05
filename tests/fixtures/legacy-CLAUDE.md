# legacy-project

# Part 1. 코딩 자세 (4원칙)

# Part 2. 프로젝트 워크플로우

## 기능 개발 워크플로우

```
/new-spec  → 기획 초안 작성 (.claude/docs/specs/*.draft.md)
사람       → 확정
구현       → 문서 동기화 → draft 삭제
```

깊은 검증이나 대량 병렬 작업이 필요하면 Claude Code의 서브에이전트(Task)로 격리된 컨텍스트에서 처리한다 — 메인 대화를 오염시키지 않는다.

## Skills

| 커맨드 | 역할 |
|---|---|
| `/new-spec <기능명>` | 기획 초안 작성 |
| `/update-task` | 현재 상태 갱신 |
| `/add-hook <설명>` | 자연어 자동화 요청을 훅으로 변환 (`settings.json`) |

## 아키텍처 변경 감지 시

다음 중 하나라도 발생하면 `/update-architecture`를 실행해 `architecture.md`를 갱신한다.
| `migrate-from-ai` | 구버전 `.ai/` 디렉토리를 새 구조로 분류·이동 |
| `add-hook <설명>` | 자연어 자동화 요청을 훅으로 변환 (`settings.local.json`) |

## 새 규칙 발견 시

새 규칙이면 `/add-rule`을 실행한다.

## 모를 때 — 탐색 사다리
