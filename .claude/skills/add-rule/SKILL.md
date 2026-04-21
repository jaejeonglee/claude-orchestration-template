---
trigger: manual
description: 프로젝트 규칙을 conventions.md에 추가
---

# /add-rule

사용법: `/add-rule <규칙 내용>`

프로젝트 개발 중 발견한 규칙을 `.claude/docs/conventions.md`에 기록한다.

## 실행 절차 (Claude가 수행)

### Step 1. 규칙 분류

추가할 규칙이 어느 카테고리에 속하는지 판단:

| 카테고리 | 예시 |
|---|---|
| **코딩 규칙** | "에러 메시지는 항상 한글", "변수명은 camelCase" |
| **도메인 규칙** | "결제는 idempotency key 필수", "사용자 ID는 UUID v7" |
| **보안 규칙** | "인증 토큰은 항상 httpOnly 쿠키", "PII 로깅 금지" |
| **운영 규칙** | "배포 전 Playwright 테스트 필수", "커밋 메시지는 Conventional Commits" |

### Step 2. conventions.md 업데이트

해당 카테고리 섹션을 찾아서 규칙 추가. 섹션이 없으면 생성.

```markdown
## 코딩 규칙

- [기존 규칙들...]
- <YYYY-MM-DD> [새 규칙 내용]
```

날짜 주석을 붙여서 언제 추가된 규칙인지 추적 가능하게 한다.

### Step 3. PROGRESS.md에 로그

```markdown
## 완료
- [YYYY-MM-DD] 규칙 추가: [규칙 요약]
```

### Step 4. 보고

```
규칙을 conventions.md에 기록했습니다.
- 카테고리: [카테고리]
- 내용: [규칙 내용]
```

## 주의사항

- **중복 확인 필수** — 이미 같은 취지의 규칙이 있으면 수정 제안, 추가하지 않음
- **구체적으로 작성** — "좋게 하자" X, "에러 메시지는 한글, 마침표 없이" O
- **예외 케이스 명시** — "단, 레거시 `src/legacy/`는 제외" 같은 조건 명확히
