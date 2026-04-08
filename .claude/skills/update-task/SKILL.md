---
trigger: manual
description: CURRENT_TASK.md 업데이트 가이드
---

# /update-task

사용법: `/update-task`

현재 작업 상태를 파악하고 `.claude/CURRENT_TASK.md`를 최신 상태로 갱신한다.

## 실행 절차 (Claude가 수행)

### Step 1. 현황 파악

```bash
git branch --show-current
git log --oneline -5
git status
```

### Step 2. 변경 내용 반영

`.claude/CURRENT_TASK.md`에서 아래 항목을 갱신:

- **현재 작업** — 지금 진행 중인 작업 목표 (변경된 경우)
- **완료된 것** — 방금 완료된 항목에 `[x]` 체크
- **남은 것** — 새로 식별된 항목 추가
- **막힌 부분** — 현재 블로커 기술, 없으면 `(현재 없음)`
- **다음 작업 시작 시 읽어야 할 것** — 변경된 파일 경로 반영

### Step 3. 날짜 갱신

`_마지막 업데이트: YYYY-MM-DD_` → 오늘 날짜로 업데이트

## 주의사항

- 완료 여부가 불확실한 항목은 `[x]`로 체크하지 않는다
- 구현 완료 ≠ 검증 완료. 검증되지 않은 항목은 `[x]` 보류
- `.claude/CURRENT_TASK.md`는 AI 간 핸드오프 문서이므로 다음 세션 AI가 읽었을 때 맥락이 명확해야 한다
