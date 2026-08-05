#!/usr/bin/env bash
# 위험 명령 차단 — Claude / Codex 공용 PreToolUse 훅
#
# 입력: 이벤트 JSON (stdin)
#   Claude: {"tool_name":"Bash","tool_input":{"command":"git push --force"}}
#   Codex : {"tool_name":"Bash","tool_input":{"command":"git push --force"}}
#   → command가 문자열이든 배열이든 동일하게 처리한다.
#
# 종료 코드: 0 = 통과, 2 = 차단 (사유는 stderr)
#
# fail 정책 (의도적 설계):
#   stdin 비어있음        → 통과. 수동 실행/테스트로 간주.
#   JSON 파싱 실패        → 차단(fail-close). 훅 입력 계약이 바뀌면 조용히 무력화되는
#                           대신 시끄럽게 실패한다 — 과거 env var 방식이 조용히 죽었던
#                           전례가 있어 이 방향을 택했다.
#   유효 JSON, command 없음 → 통과. 셸 호출이 아니므로 검사 대상이 아니다.
#
# 한계: 문자열 검사는 실행과 데이터를 구분하지 못한다. 커밋 메시지나 echo 안에
#       위험 문자열이 들어 있어도 차단된다. 표현을 바꿔 우회 가능하며, 실사용
#       빈도가 낮아 감수한다.

set -uo pipefail

INPUT=$(cat)
[ -z "${INPUT//[[:space:]]/}" ] && exit 0

if ! printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1; then
  echo "차단: 훅 입력을 JSON으로 파싱하지 못했습니다 (fail-close). .claude/hooks/pre-tool-use.sh 확인 필요" >&2
  exit 2
fi

CMD=$(printf '%s' "$INPUT" | jq -r '
  (.tool_input.command // .tool_input.cmd // .command // empty)
  | if type == "array" then join(" ") else tostring end
' 2>/dev/null)

[ -z "$CMD" ] || [ "$CMD" = "null" ] && exit 0

block() {
  echo "차단: $1" >&2
  exit 2
}

# force push — --force-with-lease는 허용 (뒤에 -with-lease가 붙어 경계 매칭에 안 걸림)
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+push' \
  && printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])--force([[:space:]]|$)|(^|[[:space:]])-f([[:space:]]|$)'; then
  block "force push는 되돌릴 수 없습니다. 사람이 직접 실행하세요 (--force-with-lease는 허용됨)"
fi

# git reset --hard — 인자 순서 무관
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+reset([[:space:]]+[^-][^[:space:]]*)*[[:space:]]+--hard'; then
  block "git reset --hard는 커밋 안 된 작업을 날립니다. 사람이 직접 실행하세요"
fi

# git clean -f 계열
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+clean[[:space:]]' \
  && printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])-[a-zA-Z]*f'; then
  block "git clean -f는 미추적 파일을 삭제합니다. 사람이 직접 실행하세요"
fi

# 루트/홈/현재 디렉토리 재귀 삭제
if printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])rm[[:space:]]' \
  && printf '%s' "$CMD" | grep -Eq 'rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-[a-zA-Z]*r|--recursive' \
  && printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])(/|~|\.|\.\.)([[:space:]]|$)|(^|[[:space:]])(/\*|~/\*)([[:space:]]|$)'; then
  block "재귀 삭제가 루트/홈/현재 디렉토리를 대상으로 합니다. 사람이 직접 실행하세요"
fi

exit 0
