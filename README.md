# Claude Orchestration Template

Claude Code 기반 AI 오케스트레이션 구조 템플릿.

Claude(오케스트레이터) + codex-reasoner(깊은 추론) + gemini-researcher(리서치·기획) 3개 에이전트가 역할을 분담해서 작동한다.

---

## 빠른 시작

```bash
# 프로젝트 루트에서 실행
bash <(curl -s https://raw.githubusercontent.com/ljjunh/claude-orchestration-template/main/scripts/init.sh)
```

또는 클론 후:

```bash
git clone https://github.com/ljjunh/claude-orchestration-template
bash claude-orchestration-template/scripts/init.sh
```

---

## 설치되는 것

```
.claude/
├── agents/
│   ├── codex-reasoner.md     # 깊은 추론 전문가 (Claude 기반)
│   └── gemini-researcher.md  # 리서치·기획 전문가 (Gemini API)
├── scripts/
│   └── call-gemini.sh        # Gemini API 호출 스크립트
├── settings.json             # Hooks (ESLint, Stop 체크, compact 복구)
└── skills/
    ├── new-spec/             # /new-spec 커맨드
    └── update-task/          # /update-task 커맨드

.ai/
├── README.md                 # AI 진입점, 문서 맵
├── agents.md                 # 역할 분담, 라우팅, 워크플로우
├── architecture.md           # 시스템 구조 (프로젝트별 작성)
├── conventions.md            # 구현 규칙 (프로젝트별 작성)
├── context-reset.md          # compact 이후 복구 체크리스트
└── docs/
    ├── PROJECT.md            # 현재 상태 문서
    ├── TODO.md               # 미완료 항목
    ├── API_DOCS.md           # API 계약
    ├── specs/                # 기획 초안 (임시, 완료 후 삭제)
    └── migrations/           # 미적용 마이그레이션 (임시, 완료 후 삭제)

CLAUDE.md                     # 세션 시작 시 자동 로드
CURRENT_TASK.md               # AI 핸드오프 노트
```

> `.claude`, `.ai`, `CLAUDE.md`, `CURRENT_TASK.md`는 `.gitignore`에 자동 추가됨 (로컬 전용)

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
codex-reasoner   → 코드 기준 리뷰
사람             → 확정
Claude           → 구현 → 문서 동기화 → draft 삭제
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
| `SessionStart (compact)` | 컨텍스트 압축 이후 자동으로 context-reset + CURRENT_TASK 출력 |

---

## 슬래시 커맨드

| 커맨드 | 역할 |
|---|---|
| `/new-spec <기능명>` | 기획 초안 템플릿 생성 |
| `/update-task` | CURRENT_TASK.md 갱신 |

---

## 프로젝트별 커스터마이즈

설치 후 아래 파일을 프로젝트에 맞게 수정:

1. `.ai/architecture.md` — 시스템 구조, 기술 스택, 데이터 흐름
2. `.ai/conventions.md` — 코딩 규칙, 도메인 규칙, 구현 게이트
3. `.ai/docs/PROJECT.md` — 현재 상태 기록

도메인 특화 skill이 필요하면 `.claude/skills/<이름>/SKILL.md` 추가.
