# Claude Orchestration Template

Claude Code 프로젝트에 AI 오케스트레이션 구조를 설치하는 템플릿입니다.

설치 후 Claude는 세 개의 에이전트로 역할을 분리하여 작업합니다.

| 에이전트 | 역할 |
|---|---|
| **Claude** | 오케스트레이터 — 코드 작성, 흐름 조율, 결과 통합 |
| **codex-reasoner** | 심층 추론 — 로직 검증, 보안 분석, 버그 근본원인 분석 |
| **gemini-researcher** | 리서치 — 공식 문서 확인, 최신 API 스펙, 기획 초안 작성 |

---

## 설치

```bash
bash <(curl -s https://raw.githubusercontent.com/jaejeonglee/claude-orchestration-template/main/scripts/init.sh)
```

프로젝트 루트에 `.claude/` 디렉토리와 `CLAUDE.md`가 생성되며, 두 항목은 `.gitignore`에 자동 추가되어 로컬에서만 유지됩니다.

---

## 사용

### 1. 최초 실행

```bash
claude
> 이 프로젝트 파악해줘
```

Claude가 프로젝트 코드를 분석하여 `architecture.md`와 `conventions.md`를 자동으로 작성합니다.

### 2. 일상 개발

평소처럼 자연어로 요청하면 Claude가 작업 성격에 맞는 에이전트에 자동 위임합니다.

| 요청 예시 | 처리 주체 |
|---|---|
| `결제 API를 추가해줘` | Claude |
| `이 인증 로직에 보안 문제가 있는지 분석해줘` | codex-reasoner |
| `Fastify v5 마이그레이션 가이드를 확인해줘` | gemini-researcher |

### 3. 슬래시 커맨드

| 커맨드 | 역할 |
|---|---|
| `/new-spec <기능명>` | 기획 초안 템플릿 생성 |
| `/update-task` | 현재 작업 상태 갱신 |

### 4. 세션 이어가기

새 세션을 시작하면 SessionStart 훅이 `CURRENT_TASK.md`와 최근 커밋 내역을 자동으로 출력합니다. 이전 맥락을 그대로 이어 작업할 수 있습니다.

---

## 작동 방식

### 기능 개발 워크플로우

```
gemini-researcher  →  기획 초안 작성
codex-reasoner     →  현재 코드 기준 리뷰
사람               →  확정
Claude             →  구현 → 문서 동기화 → 초안 삭제
```

확정되지 않은 초안은 구현으로 이어지지 않습니다.

### 자동화 Hooks

| 시점 | 동작 |
|---|---|
| 세션 시작 | `CURRENT_TASK.md` 및 최근 커밋 출력 |
| 파일 수정 (Edit/Write) | JS/TS 파일에 ESLint auto-fix 적용 |
| 작업 완료 (Stop) | 문서 동기화 및 에러 핸들링 누락 검증 |

### 보안

민감 파일에 대한 읽기 권한을 도구 레벨에서 차단합니다.

- `.env`, `.env.*`
- `*.pem`, `*.key`
- `credentials*`, `*secret*`

---

## 환경 변수

| 변수 | 필수 여부 | 설명 |
|---|---|---|
| `GEMINI_API_KEY` | gemini-researcher 사용 시 필수 | Google AI Studio에서 발급 |
| `GEMINI_MODEL` | 선택 | 기본값 `gemini-2.5-pro` |
