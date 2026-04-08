---
trigger: manual
description: 새 기능 기획 초안(spec draft) 템플릿 생성
---

# /new-spec

사용법: `/new-spec <기능명>`

표준 기획 초안 템플릿을 `.claude/docs/specs/<기능명>.draft.md`로 생성한다.

## 파일 수명 주기

draft 파일은 **작업용 임시 파일**이다. 작업이 끝나면 반드시 삭제한다.

| 단계 | 파일 상태 |
|---|---|
| 초안 작성 중 | `.claude/docs/specs/<기능명>.draft.md` 존재 |
| codex-reasoner 리뷰 후 | `.claude/docs/specs/<기능명>.review.md` (선택) |
| 사람 확정 + 구현 완료 | **두 파일 모두 삭제** |

> 구현이 완료되고 코드·문서에 반영되었다면 draft/review 파일은 즉시 삭제한다.
> 완료된 기획서를 보관하려면 노션·지라 등 외부 도구를 사용한다.

## 생성할 템플릿

```markdown
# <기능명> — 기획 초안

> 작성: gemini-researcher / 날짜: <TODAY>
> 상태: DRAFT (사람이 확정하기 전까지 구현 기준 아님)

---

## 1. 목적

[이 기능이 왜 필요한가]

## 2. 사용자 시나리오

[누가, 언제, 어떤 흐름으로 사용하는가]

## 3. 정책

[비즈니스 규칙, 제한 조건, 예외 처리 정책]

## 4. API 계약 초안

### Request
METHOD /api/...

### Response
{ "field": "type" }

### Error Cases
| 코드 | 조건 |
|---|---|
| 400 | ... |

## 5. 데이터 변경 영향

[추가·변경·제거할 스키마 또는 상태]

## 6. 실패 케이스

| 케이스 | 처리 |
|---|---|
| ... | ... |

## 7. 미정 항목

- [ ] ...
```

## 실행 절차 (Claude가 수행)

1. 인자에서 기능명 추출 → kebab-case 변환
2. `Write` 도구로 `.claude/docs/specs/<기능명>.draft.md` 생성
3. 사용자에게 안내:
   - 생성된 파일 경로
   - "gemini-researcher에게 초안 작성을 요청하거나 직접 채워주세요"
   - "초안 완성 후 codex-reasoner 리뷰 → 사람 확정 → Claude 구현 순서로 진행합니다"
   - "**구현 완료 후 draft 파일 삭제 필수**"
