# Claude Template

Claude Code를 더 체계적으로 쓰기 위한 설정 템플릿.

세 가지를 잡습니다:

1. **코딩 자세** — [Karpathy 4원칙](https://x.com/karpathy/status/2015883857489522876) (가정 금지, 단순함, 수술적 변경, 목표 기반 실행)
2. **프로젝트 메모리** — 세션이 바뀌어도 유지되는 문서 체계 (architecture / conventions / 작업 상태)
3. **워크플로우 규율** — 기획 → 사람 확정 → 구현 게이트, 문서 자동 동기화

> 모델이 강해질수록 그럴듯하게 폭주하기 쉽습니다. "확정 게이트"와 "영속 메모리"는 모델이 강할수록 더 중요해집니다.

---

## 설치

프로젝트 폴더에서 아래 한 줄 실행:

```bash
bash <(curl -s https://raw.githubusercontent.com/jaejeonglee/claude-template/main/scripts/init.sh)
```

설정 파일은 `.claude/`·`.codex/` 폴더와 `AGENTS.md`·`CLAUDE.md`로 들어가고, `.gitignore`에 자동으로 추가됩니다 (= Git에 안 올라감, 내 컴퓨터에만 있음).

### 템플릿 개발 검증

훅 계약과 기존 설치 마이그레이션은 독립 fixture로 검증합니다.

```bash
bash tests/hooks-test.sh
```

### Claude Code와 Codex 함께 쓰기

규칙 원본은 `AGENTS.md` 하나입니다. Claude는 `CLAUDE.md`가 이걸 import하고, Codex는 `AGENTS.md`를 직접 읽습니다. 훅 로직(`.claude/hooks/*.sh`)도 양쪽이 같은 스크립트를 호출하므로 **위험 명령 차단·저장 시 포맷팅·세션 시작 컨텍스트가 동일하게 동작**합니다.

같아지지 않는 부분도 있습니다. Claude는 종료 시 의미론적 판단(에러 핸들링 충분성 등)이 가능한 prompt 훅을 쓰지만 Codex는 command 훅만 실행하므로, Codex 쪽은 결정적으로 확인 가능한 항목만 권고합니다. 자세한 조건과 비대칭은 `.codex/README.md`에 있습니다.

---

## 쓰는 법

### 처음 한 번

```bash
claude
> 이 프로젝트 파악해줘
```

Claude가 코드를 읽고 프로젝트 문서를 자동으로 정리해줍니다.

### 평소

그냥 평소처럼 말하면 됩니다. 깊은 검증이나 대량 작업이 필요하면 Claude가 알아서 서브에이전트(Task)를 띄워 격리된 컨텍스트에서 처리합니다.

모르는 게 나오면 추측하지 않습니다 — 코드 맵 → 문서 → 과거 기록 → 웹 순으로 스스로 찾아보고, 그래도 남는 "결정"만 물어봅니다. 코드 맵("결제 로직 어디 있나" → `src/services/payment/`)은 `/update-architecture`가 만들고 주간 감사가 갱신합니다.

### 편리한 커맨드

| 입력 | 동작 |
|---|---|
| `/new-spec 결제` | "결제" 기능 기획 초안 만들기 |
| `/update-task` | 지금 뭐 하고 있는지 기록 |
| `/add-rule 에러 메시지는 한글로` | 프로젝트 규칙 추가 |
| `/update-architecture` | 프로젝트 구조 스캔 → architecture.md 생성/갱신 |
| `/migrate-from-ai` | 구버전 `.ai/` 디렉토리 → 새 구조로 자동 분류·이동 |
| `/add-hook 파이썬 저장하면 black 실행` | 자연어 → 자동화 훅 등록 |

### 세션이 끊겨도 괜찮음

새로 `claude` 실행하면 이전에 뭐 하고 있었는지, 문서 구조가 어떤지 자동으로 보여줍니다.

---

## 문서 구조

```
.claude/docs/
├── architecture.md   # 시스템 구조 (작게 유지, 항상 로드)
├── conventions.md    # 코딩·도메인 규칙 (작게 유지, 항상 로드)
├── api/              # API 스펙
├── contracts/        # 스키마, 컨트랙트, proto
├── runbooks/         # 운영 가이드, 보안 플레이북
├── decisions/        # 의사결정 기록 (ADR)
├── specs/            # 기획 초안 (작업 중)
└── reference/        # 큰 참조 자료
```

핵심 두 파일(architecture/conventions)은 작게 유지하고, 큰 레퍼런스는 카테고리 디렉토리에 둡니다. Claude는 필요할 때 해당 위치를 찾아봅니다.

---

## 일하는 순서 (기능 개발할 때)

```
1. /new-spec 으로 기획 초안 작성
2. 사람이 확인하고 OK
3. 구현 → 문서 동기화 → 초안 삭제
```

중요: **사람이 OK 안 한 기획은 절대 코드로 안 들어갑니다.**

---

## 자동으로 해주는 것

| 상황 | 동작 |
|---|---|
| `claude` 실행할 때 | 이전 작업 상태 + 작업 일지 + 문서 구조 + 커밋 안 된 변경 자동 출력 |
| 파일 저장할 때 | 언어별 포맷터 자동 실행 (eslint / ruff·black / gofmt / rustfmt — 있는 것만) |
| 작업 끝낼 때 | 테스트 실행 여부 + 작업 일지 기록 + 문서 동기화 + 미커밋 변경 알림 검증 |
| 마지막 감사 후 7일 경과 | "이 세션에서 `/update-architecture` 실행하라" 신호 — 문서-코드 드리프트 + conventions 정합성 점검 |
| CURRENT_TASK 14일 방치 + 커밋 지속 | "상태 파일이 죽었을 수 있음" 신호 — `/update-task` 권장 |

### 작업 기록이 남는 방식

| 파일 | 담당 |
|---|---|
| `.claude/CURRENT_TASK.md` | 지금 하는 것 + 다음 할 것 (얇게 유지) |
| `.claude/JOURNAL.md` | 끝난 일 + 시각 (append-only 일지) |
| git log | 코드 변경 이력 |

작업이 끝날 때마다 Claude가 시각과 함께 일지에 한 줄 남깁니다. "그때 뭐 했더라"는 일지에서, "코드가 왜 이렇게 바뀌었지"는 git에서 찾으면 됩니다.

### 나만의 자동화 추가

`/add-hook`으로 말하면 Claude가 훅 설정으로 변환해줍니다:

```
/add-hook 파이썬 파일 저장하면 black 실행
/add-hook 세션 시작할 때 npm outdated 보여줘
```

커스텀 훅은 `settings.local.json`에 저장되므로 템플릿을 업데이트해도 사라지지 않습니다.

---

## 보안

이런 파일은 Claude가 읽을 수 없도록 막혀있습니다 (하위 디렉토리 포함):

- `.env`, `.env.*`
- `*.pem`, `*.key`
- `credentials*`, `*secret*`

되돌릴 수 없는 명령은 **이중으로** 차단됩니다 (필요하면 사람이 직접 실행):

- 1차: `permissions.deny` 문자열 매칭
- 2차: PreToolUse 훅이 실행 직전 명령을 정규식 검사 — `git push origin main --force`처럼 인자 순서를 바꾼 우회도 잡음
- 대상: 루트/홈/현재 디렉토리 재귀 삭제, force push (`--force-with-lease`는 허용), `git reset --hard`, `git clean -f*`

**정직한 범위**: 이 차단은 Claude의 파일 도구와 셸 명령 수준에서 동작합니다. Claude가 작성해 실행하는 임의 스크립트(Python의 `open()` 등)까지 막는 것은 아닙니다 — 그 층은 CLAUDE.md 규칙과 코드 리뷰가 담당하고, 완전 격리가 필요하면 샌드박스를 쓰세요.
