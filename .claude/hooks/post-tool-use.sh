#!/usr/bin/env bash
# 파일 저장 후 포맷터 실행 — Claude / Codex 공용 PostToolUse 훅
#
# 입력: 이벤트 JSON (stdin)
#   Claude: {"tool_input":{"file_path":"/abs/path/x.py"}}
#   Codex : {"tool_input":{"path":"/abs/path/x.py"}}  (apply_patch 계열은 키가 다를 수 있음)
#
# 종료 코드: 항상 0.
#   포맷터 실패가 본 작업을 가리면 안 된다. 도구가 없거나 실패해도 조용히 통과한다.
#   (차단이 필요한 검사는 pre-tool-use.sh의 몫)

set -uo pipefail

INPUT=$(cat 2>/dev/null || true)
[ -z "${INPUT//[[:space:]]/}" ] && exit 0

FILE=$(printf '%s' "$INPUT" | jq -r '
  (.tool_input.file_path // .tool_input.path // .tool_input.filePath // .file_path // empty)
  | if type == "array" then (.[0] // "") else tostring end
' 2>/dev/null) || exit 0

[ -z "$FILE" ] || [ "$FILE" = "null" ] && exit 0
[ -f "$FILE" ] || exit 0

case "$FILE" in
  *.js|*.cjs|*.mjs|*.jsx|*.ts|*.tsx)
    npx --no-install eslint --fix "$FILE" 2>/dev/null
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$FILE" 2>/dev/null
      ruff check --fix "$FILE" 2>/dev/null
    elif command -v black >/dev/null 2>&1; then
      black -q "$FILE" 2>/dev/null
    fi
    ;;
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$FILE" 2>/dev/null
    ;;
  *.rs)
    command -v rustfmt >/dev/null 2>&1 && rustfmt "$FILE" 2>/dev/null
    ;;
esac

exit 0
