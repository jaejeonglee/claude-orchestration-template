# Codex 어댑터

이 디렉토리는 **Codex 어댑터**다. 규칙 원본은 `AGENTS.md`, 훅 로직은 `.claude/hooks/*.sh`에 있고,
여기 있는 `hooks.json`은 Codex 이벤트를 그 공용 스크립트로 연결하기만 한다.

Claude와 Codex가 같은 스크립트를 호출하므로 위험 명령 차단·포맷팅·세션 시작 컨텍스트가
양쪽에서 동일하게 동작한다.

## 동작 조건

```
- 현재 릴리스에서 훅은 기본 활성이다.
- 저장소가 trusted 상태여야 프로젝트 훅이 로드된다.
- 비관리 훅은 정의별로 검토·신뢰해야 실행된다. 새로 설치하거나 훅이 바뀌면
  Codex CLI의 `/hooks`에서 현재 hash를 확인하고 승인한다.
- 사용자/조직 설정에서 비활성화되어 있으면 동작하지 않는다:
    [features]
    hooks = false
- 현재 command 핸들러만 실행된다 (prompt·agent 핸들러는 파싱만 되고 건너뛴다).
- 구버전 Codex는 legacy opt-in이 필요할 수 있다: codex_hooks = true
```

`~/.codex/config.toml`은 이 템플릿이 수정하지 않는다. 사용자 설정이나 조직 managed policy와
충돌할 수 있기 때문이다. 훅이 동작하지 않으면 위 조건을 직접 확인한다.

## 설계 노트

Codex가 보장하는 canonical matcher를 사용한다.

- `PreToolUse: ^Bash$` — 셸 명령만 위험 명령 검사 대상으로 제한한다.
- `PostToolUse: Edit|Write` — `apply_patch` 계열 파일 수정만 포맷 대상으로 제한한다.
- `SessionStart` / `Stop` — 이벤트 전체에 적용한다.

`apply_patch`도 `tool_input.command`를 사용하므로 matcher 없이 PreToolUse를 실행하면 패치 본문을
셸 명령으로 오인할 수 있다. PostToolUse도 matcher가 없으면 읽기 도구의 `path`를 포맷해 버릴 수
있으므로 matcher를 제거하지 않는다.

훅 command는 세션 `cwd`가 아니라 Git root에서 스크립트를 찾는다. 프로젝트 하위 디렉토리에서
Codex를 시작해도 동일하게 동작한다.

이 어댑터의 검증 범위는 POSIX Bash 환경(macOS/Linux)이다. WSL에서는 WSL 내부의 Codex를 사용한다.
Native Windows용 `commandWindows`는 셸별 중첩 quoting을 동일하게 보장할 수 없어 제공하지 않는다.
Windows 지원이 필요하면 해당 환경에서 별도 어댑터와 계약 테스트를 추가해야 한다.

## Claude와의 알려진 비대칭

| 항목 | Claude Code | Codex |
|---|---|---|
| 위험 명령 차단 | 훅 + `permissions.deny` (이중) | 훅만 |
| 종료 시 검증 | prompt 훅 — 의미론적 판단 | command 훅 — 결정적 항목만 권고 |
| 워크플로우 호출 | `/이름` 슬래시 커맨드 | `.claude/skills/<이름>/SKILL.md` 절차 수행 |

"에러 핸들링이 충분한가" 같은 의미론적 판단은 command 훅으로 강제할 수 없다.
그 층은 `AGENTS.md`의 규칙이 담당하며, 양쪽 에이전트에 동일하게 적용된다.

## 스키마 호환성

`hooks.json`의 필드명은 설치된 Codex 버전과 다를 수 있다. 훅이 로드되지 않으면
해당 버전의 설정 레퍼런스와 대조해 조정한다 — 스크립트 자체는 그대로 재사용하면 된다.
