# Claude Orchestration Template

Claude Code 기반 AI 오케스트레이션 구조 템플릿.

Claude(오케스트레이터) + codex-reasoner(깊은 추론) + gemini-researcher(리서치·기획) 3개 에이전트가 역할을 분담해서 작동한다.

---

## 빠른 시작

### 신규 프로젝트

```bash
bash <(curl -s https://raw.githubusercontent.com/jaejeonglee/claude-orchestration-template/main/scripts/init.sh)
claude
```

### 기존 프로젝트

```bash
bash <(curl -s https://raw.githubusercontent.com/jaejeonglee/claude-orchestration-template/main/scripts/init.sh)
bash <(curl -s https://raw.githubusercontent.com/jaejeonglee/claude-orchestration-template/main/scripts/analyze.sh)
claude
```

`analyze.sh`는 프로젝트 코드를 분석해서 `.claude/docs/raw-analysis.md`에 덤프하고, `claude` 실행하면 이를 기반으로 문서를 자동 채움.

---

## 설치되는 것

```
.claude/
├── agents/
│   ├── codex-reasoner.md     # 깊은 추론 전문가 (Claude 기반)
│   └── gemini-researcher.md  # 리서치·기획 전문가 (Gemini API)
├── docs/
│   ├── architecture.md       # 시스템 구조 (프로젝트별 작성)
│   ├── conventions.md        # 구현 규칙 (프로젝트별 작성)
│   └── specs/                # 기획 초안 (임시, 완료 후 삭제)
├── scripts/
│   └── call-gemini.sh        # Gemini API 호출 스크립트
├── settings.json             # Hooks (ESLint, Stop 체크, compact 복구)
├── skills/
│   ├── new-spec/             # /new-spec 커맨드
│   └── update-task/          # /update-task 커맨드
├── CURRENT_TASK.md           # AI 핸드오프 노트
└── PROGRESS.md               # 전체 진행 기록

CLAUDE.md                     # 세션 시작 시 자동 로드
```

> `.claude`와 `CLAUDE.md`는 `.gitignore`에 자동 추가됨 (로컬 전용)

---

## 에이전트 역할

| 에이전트 | 역할 | 언제 |
|---|---|---|
| **Claude** | 오케스트레이터 | 코드 생성·수정, 흐름 설계, 결과 통합 |
| **codex-reasoner** | 깊은 추론 | 로직 검증, 보안 분석, 버그 추론 |
| **gemini-researcher** | 리서치·기획 | 공식 문서 확인, 기능 초안 작성 |

### 기능 개발 흐름

```
gemini-researcher → 기획 초안
codex-reasoner   → 스펙 리뷰
사람             → 확정
Claude           → 구현
codex-reasoner   → 코드 리뷰 (Critical/Warning/Info)
Critical/Warning → 사람 보고 후 반영
Info             → Claude 바로 반영
Claude           → 문서 동기화 + draft 삭제
```

---

## 환경 변수

| 변수 | 필수 | 설명 |
|---|---|---|
| `GEMINI_API_KEY` | gemini-researcher 사용 시 | Google AI Studio에서 발급 |
| `GEMINI_MODEL` | 선택 | 기본값: `gemini-2.5-pro` |

---

## Hooks

| Hook | 동작 |
|---|---|
| `PostToolUse (Edit\|Write)` | JS/TS 파일 수정 시 ESLint auto-fix |
| `Stop` | 작업 완료 시 문서 동기화·에러 핸들링 체크 |
| `SessionStart (compact)` | 컨텍스트 압축 이후 자동으로 복구 안내 + CURRENT_TASK 출력 |

---

## 슬래시 커맨드

| 커맨드 | 역할 |
|---|---|
| `/new-spec <기능명>` | 기획 초안 템플릿 생성 |
| `/update-task` | CURRENT_TASK.md 갱신 |

---

## 프로젝트별 커스터마이즈

설치 후 아래 파일을 프로젝트에 맞게 수정:

1. `.claude/docs/architecture.md` — 시스템 구조, 기술 스택, 데이터 흐름
2. `.claude/docs/conventions.md` — 코딩 규칙, 도메인 규칙, 구현 게이트

도메인 특화 skill이 필요하면 `.claude/skills/<이름>/SKILL.md` 추가.
