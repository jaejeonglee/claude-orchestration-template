# Claude Orchestration Template

Claude Code를 더 체계적으로 쓰기 위한 설정 템플릿.

설치하면 Claude 혼자 일하지 않고, 역할을 나눠서 일합니다.

- **Claude** — 코드 작성하는 사람
- **gemini-researcher** — 공식 문서 찾아오는 사람
- **codex-reasoner** — 로직·보안 검증하는 사람

> 복잡한 작업을 한 명한테 다 시키면 품질이 들쭉날쭉합니다. 역할을 나누면 훨씬 안정적입니다.

---

## 설치

프로젝트 폴더에서 아래 한 줄 실행:

```bash
bash <(curl -s https://raw.githubusercontent.com/jaejeonglee/claude-orchestration-template/main/scripts/init.sh)
```

설정 파일은 `.claude/` 폴더에 들어가고, `.gitignore`에 자동으로 추가됩니다 (= Git에 안 올라감, 내 컴퓨터에만 있음).

---

## 쓰는 법

### 처음 한 번

```bash
claude
> 이 프로젝트 파악해줘
```

Claude가 코드를 읽고 프로젝트 문서를 자동으로 정리해줍니다.

### 평소

그냥 평소처럼 말하면 됩니다. Claude가 알아서 적절한 역할로 넘깁니다.

```
"결제 API 추가해줘"                  → Claude가 직접 구현
"이 인증 로직 보안 문제 있어?"        → codex-reasoner가 분석
"Fastify v5 마이그레이션 방법 찾아줘"  → gemini-researcher가 조사
```

### 편리한 커맨드

| 입력 | 동작 |
|---|---|
| `/new-spec 결제` | "결제" 기능 기획 초안 만들기 |
| `/update-task` | 지금 뭐 하고 있는지 기록 |
| `/add-rule 에러 메시지는 한글로` | 프로젝트 규칙 추가 |
| `/update-architecture` | 프로젝트 구조 스캔 → architecture.md 생성/갱신 |

### 세션이 끊겨도 괜찮음

새로 `claude` 실행하면 이전에 뭐 하고 있었는지 자동으로 보여줍니다.

---

## 일하는 순서 (기능 개발할 때)

```
1. gemini-researcher가 기획 초안을 씀
2. codex-reasoner가 "이게 지금 코드랑 맞나?" 검토
3. 사람이 확인하고 OK
4. Claude가 구현
```

중요: **사람이 OK 안 한 기획은 절대 코드로 안 들어갑니다.**

---

## 자동으로 해주는 것

| 상황 | 동작 |
|---|---|
| `claude` 실행할 때 | 이전 작업 내용 자동 출력 |
| JS/TS 파일 저장할 때 | ESLint 자동 수정 |
| 작업 끝낼 때 | "문서 업데이트 안 했지?" 검증 |

---

## 보안

이런 파일은 Claude가 읽을 수 없도록 막혀있습니다:

- `.env`, `.env.*`
- `*.pem`, `*.key`
- `credentials*`, `*secret*`

말로만 "읽지 마"가 아니라 **실제로 차단**됩니다.

---

## 환경 변수 (선택)

외부 AI를 같이 쓸 수 있습니다. **없어도 Claude 혼자 다 할 수 있어요.**

| 변수 | 효과 |
|---|---|
| `GEMINI_API_KEY` | 공식 문서 조사할 때 Gemini 사용 |
| `OPENAI_API_KEY` | 로직/보안 분석할 때 OpenAI 사용 |

없으면? Claude가 WebSearch나 자체 추론으로 대신 처리합니다.
