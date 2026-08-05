#!/usr/bin/env bash
# 파일 저장 후 포맷터 실행 — Claude / Codex 공용 PostToolUse 훅
#
# 입력: 이벤트 JSON (stdin)
#   Claude: {"tool_input":{"file_path":"/abs/path/x.py"}}
#   Codex : {"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch..."}}
#   Codex apply_patch는 패치 헤더의 Add/Update/Move 대상 파일을 모두 처리한다.
#
# 종료 코드: 항상 0.
#   포맷터 실패가 본 작업을 가리면 안 된다. 도구가 없거나 실패해도 조용히 통과한다.
#   (차단이 필요한 검사는 pre-tool-use.sh의 몫)

set -uo pipefail

INPUT=$(cat 2>/dev/null || true)
[ -z "${INPUT//[[:space:]]/}" ] && exit 0

printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0

ANCHOR_DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
ANCHOR_DIR="${CLAUDE_PROJECT_DIR:-${CODEX_PROJECT_DIR:-$ANCHOR_DIR}}"
[ -n "$ANCHOR_DIR" ] || ANCHOR_DIR=$(pwd)
if PROJECT_DIR=$(git -C "$ANCHOR_DIR" rev-parse --show-toplevel 2>/dev/null); then
  PROJECT_DIR=$(cd "$PROJECT_DIR" 2>/dev/null && pwd -P) || exit 0
else
  PROJECT_DIR=$(cd "$ANCHOR_DIR" 2>/dev/null && pwd -P) || exit 0
fi

format_file() {
  local requested_file="$1"
  local candidate_dir
  local absolute_file

  [ -z "$requested_file" ] && return 0
  case "$requested_file" in
    /*) absolute_file="$requested_file" ;;
    *) absolute_file="$PROJECT_DIR/$requested_file" ;;
  esac

  [ -f "$absolute_file" ] || return 0
  # 프로젝트 내부의 symlink가 외부 파일을 가리키는 우회를 막는다.
  # 최종 경로 symlink는 이식성 있게 경계를 검증하기 어려우므로 모두 건너뛴다.
  [ -L "$absolute_file" ] && return 0
  candidate_dir=$(cd "$(dirname "$absolute_file")" 2>/dev/null && pwd -P) || return 0
  absolute_file="$candidate_dir/$(basename "$absolute_file")"

  case "$absolute_file" in
    "$PROJECT_DIR"/*) ;;
    *) return 0 ;;
  esac

  case "$absolute_file" in
    *.js|*.cjs|*.mjs|*.jsx|*.ts|*.tsx)
      npx --no-install eslint --fix "$absolute_file" 2>/dev/null
      ;;
    *.py)
      if command -v ruff >/dev/null 2>&1; then
        ruff format "$absolute_file" 2>/dev/null
        ruff check --fix "$absolute_file" 2>/dev/null
      elif command -v black >/dev/null 2>&1; then
        black -q "$absolute_file" 2>/dev/null
      fi
      ;;
    *.go)
      command -v gofmt >/dev/null 2>&1 && gofmt -w "$absolute_file" 2>/dev/null
      ;;
    *.rs)
      command -v rustfmt >/dev/null 2>&1 && rustfmt "$absolute_file" 2>/dev/null
      ;;
  esac
}

# Claude Edit/Write payload와 경로 기반 호환 payload.
while IFS= read -r file; do
  format_file "$file"
done < <(printf '%s' "$INPUT" | jq -r '
  . as $root
  | ($root.tool_input.file_path?, $root.tool_input.path?,
     $root.tool_input.filePath?, $root.file_path?)
  | if type == "array" then .[] else . end
  | select(type == "string" and length > 0)
' 2>/dev/null)

# Codex apply_patch payload. 삭제 대상은 이미 없으므로 format_file에서 건너뛴다.
printf '%s' "$INPUT" \
  | jq -r '.tool_input.command // empty | select(type == "string")' 2>/dev/null \
  | sed -n -E \
      -e 's/^\*\*\* (Add|Update) File: //p' \
      -e 's/^\*\*\* Move to: //p' \
  | while IFS= read -r file; do
      format_file "$file"
    done

exit 0
