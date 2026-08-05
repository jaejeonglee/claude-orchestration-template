#!/usr/bin/env bash
# 작업 종료 시 결정적 점검 — 주로 Codex용 Stop 훅
#
# Claude는 의미론적 판단이 가능한 prompt 훅(settings.json)이 이 역할을 하고,
# Codex는 command 훅만 실행되므로 "기계적으로 확인 가능한 것"만 여기서 검사한다.
# 이 비대칭은 의도된 것이며 .codex/README.md에 명시돼 있다.
#
# 종료 코드: 항상 0 (권고만 한다).
#   "작업 단위가 완료되었는가"는 본질적으로 판단 문제라서, 결정적 검사로 차단하면
#   단순 질의응답 턴까지 전부 막힌다 (실제로 겪은 과발동 버그). 따라서 차단 대신
#   신호만 출력하고 판단은 규칙(AGENTS.md)에 맡긴다.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${CODEX_PROJECT_DIR:-}}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
cd "$PROJECT_DIR" 2>/dev/null || exit 0

DIRTY=$(git status --short 2>/dev/null)
[ -z "$DIRTY" ] && exit 0

# 커밋 안 된 변경이 있는데 저널이 그 변경보다 오래됐다면 기록 누락 가능성
NEEDS_JOURNAL=0
if [ -f .claude/JOURNAL.md ]; then
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    if [ "$f" -nt .claude/JOURNAL.md ]; then
      NEEDS_JOURNAL=1
      break
    fi
  done < <(git status --porcelain 2>/dev/null | awk '{print $NF}')
else
  NEEDS_JOURNAL=1
fi

MESSAGE=$(printf '%s\n' \
  '=== 종료 전 점검 ===' \
  '- 커밋되지 않은 변경이 있습니다:' \
  "$(printf '%s\n' "$DIRTY" | head -10)")
if [ "$NEEDS_JOURNAL" -eq 1 ]; then
  MESSAGE=$(printf '%s\n%s' "$MESSAGE" '- 변경 이후 .claude/JOURNAL.md가 갱신되지 않았습니다. 작업 단위가 끝났다면 시각과 함께 기록하세요.')
fi
MESSAGE=$(printf '%s\n%s' "$MESSAGE" '- 코드 로직을 바꿨다면 관련 테스트 실행 결과를 보고했는지 확인하세요.')

# Codex Stop 훅은 exit 0에서 stdout이 있으면 JSON이어야 한다.
command -v jq >/dev/null 2>&1 || exit 0
jq -n --arg systemMessage "$MESSAGE" '{continue: true, systemMessage: $systemMessage}'

exit 0
