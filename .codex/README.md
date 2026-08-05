# Codex 어댑터

이 디렉토리는 **Codex 어댑터**다. 규칙 원본은 `AGENTS.md`, 훅 로직은 `.claude/hooks/*.sh`에 있고,
여기 있는 `hooks.json`은 Codex 이벤트를 그 공용 스크립트로 연결하기만 한다.

Claude와 Codex가 같은 스크립트를 호출하므로 위험 명령 차단·포맷팅·세션 시작 컨텍스트가
양쪽에서 동일하게 동작한다.

## 동작 조건

```
- 현재 릴리스에서 훅은 기본 활성이다.
- 저장소가 trusted 상태여야 프로젝트 훅이 로드된다.
- 사용자/조직 설정에서 비활성화되어 있으면 동작하지 않는다:
    [features]
    hooks = false
- 현재 command 핸들러만 실행된다 (prompt·agent 핸들러는 파싱만 되고 건너뛴다).
- 구버전 Codex는 legacy opt-in이 필요할 수 있다: codex_hooks = true
```

`~/.codex/config.toml`은 이 템플릿이 수정하지 않는다. 사용자 설정이나 조직 managed policy와
충돌할 수 있기 때문이다. 훅이 동작하지 않으면 위 조건을 직접 확인한다.

## 설계 노트

**matcher를 지정하지 않는다.** 도구 이름(`shell` / `local_shell` / `apply_patch` 등)이
버전에 따라 다를 수 있어서, 매칭은 훅 스크립트가 입력 JSON을 보고 스스로 판단한다.

- `pre-tool-use.sh` — `command` 필드가 없으면 통과 (셸 호출이 아님)
- `post-tool-use.sh` — `file_path`/`path` 계열이 없으면 통과

덕분에 도구명이 바뀌어도 설정을 고칠 필요가 없다.

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
