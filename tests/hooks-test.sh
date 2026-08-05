#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
HOOK_TEST_TMP=$(mktemp -d)
trap 'rm -rf "$HOOK_TEST_TMP"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -qF "$expected" "$file" || fail "$file 에 예상 문자열이 없음: $expected"
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if grep -qF "$unexpected" "$file"; then
    fail "$file 에 제거되어야 할 문자열이 남음: $unexpected"
  fi
}

for script in "$REPO_ROOT"/.claude/hooks/*.sh "$REPO_ROOT/scripts/init.sh"; do
  bash -n "$script" || fail "shell syntax: $script"
done
jq empty "$REPO_ROOT/.codex/hooks.json" || fail "invalid .codex/hooks.json"
jq -e '.hooks.PreToolUse[0].matcher == "^Bash$"' "$REPO_ROOT/.codex/hooks.json" >/dev/null \
  || fail "PreToolUse matcher"
jq -e '.hooks.PostToolUse[0].matcher == "Edit|Write"' "$REPO_ROOT/.codex/hooks.json" >/dev/null \
  || fail "PostToolUse matcher"
jq -e '[.. | objects | .command? // empty]
  | all(contains("git rev-parse --show-toplevel"))' "$REPO_ROOT/.codex/hooks.json" >/dev/null \
  || fail "hook commands must resolve from git root"
jq -e '[.. | objects | has("commandWindows")] | all(. == false)' \
  "$REPO_ROOT/.codex/hooks.json" >/dev/null \
  || fail "native Windows adapter must not be advertised without contract tests"

printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
  | bash "$REPO_ROOT/.claude/hooks/pre-tool-use.sh" \
  || fail "safe Bash command"

printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git push --force"}}' \
  | bash "$REPO_ROOT/.claude/hooks/pre-tool-use.sh" >/dev/null 2>&1
PRE_TOOL_STATUS=$?
[ "$PRE_TOOL_STATUS" -eq 2 ] || fail "force push must exit 2"

FORMAT_REPO="$HOOK_TEST_TMP/format repo"
mkdir -p "$FORMAT_REPO/src" "$FORMAT_REPO/lib" "$HOOK_TEST_TMP/bin"
git -C "$FORMAT_REPO" init -q
printf 'const a=1\n' > "$FORMAT_REPO/src/a.js"
printf 'const b=2\n' > "$FORMAT_REPO/lib/b.js"
printf 'const c=3\n' > "$FORMAT_REPO/src/c.js"
printf 'const outside=3\n' > "$HOOK_TEST_TMP/outside.js"
ln -s "$HOOK_TEST_TMP/outside.js" "$FORMAT_REPO/src/outside-link.js"

cat > "$HOOK_TEST_TMP/bin/npx" <<'FAKE_NPX'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOOK_FORMAT_LOG"
FAKE_NPX
chmod +x "$HOOK_TEST_TMP/bin/npx"

PATCH_TEXT=$(printf '%s\n' \
  '*** Begin Patch' \
  '*** Update File: src/a.js' \
  '*** Add File: lib/b.js' \
  '*** Update File: ../outside.js' \
  '*** End Patch')
POST_PAYLOAD=$(jq -n \
  --arg cwd "$FORMAT_REPO/src" \
  --arg command "$PATCH_TEXT" \
  '{cwd: $cwd, tool_name: "apply_patch", tool_input: {command: $command}}')
printf '%s' "$POST_PAYLOAD" \
  | env PATH="$HOOK_TEST_TMP/bin:$PATH" HOOK_FORMAT_LOG="$HOOK_TEST_TMP/format.log" \
      bash "$REPO_ROOT/.claude/hooks/post-tool-use.sh"

assert_contains "$HOOK_TEST_TMP/format.log" "$FORMAT_REPO/src/a.js"
assert_contains "$HOOK_TEST_TMP/format.log" "$FORMAT_REPO/lib/b.js"
assert_not_contains "$HOOK_TEST_TMP/format.log" "$HOOK_TEST_TMP/outside.js"

CLAUDE_PAYLOAD=$(jq -n \
  --arg cwd "$FORMAT_REPO/src" \
  --arg file "$FORMAT_REPO/src/c.js" \
  '{cwd: $cwd, tool_name: "Write", tool_input: {file_path: $file}}')
printf '%s' "$CLAUDE_PAYLOAD" \
  | env PATH="$HOOK_TEST_TMP/bin:$PATH" HOOK_FORMAT_LOG="$HOOK_TEST_TMP/format.log" \
      bash "$REPO_ROOT/.claude/hooks/post-tool-use.sh"
assert_contains "$HOOK_TEST_TMP/format.log" "$FORMAT_REPO/src/c.js"

SYMLINK_PATCH=$(printf '%s\n' \
  '*** Begin Patch' \
  '*** Update File: src/outside-link.js' \
  '*** End Patch')
SYMLINK_PAYLOAD=$(jq -n \
  --arg cwd "$FORMAT_REPO/src" \
  --arg command "$SYMLINK_PATCH" \
  '{cwd: $cwd, tool_name: "apply_patch", tool_input: {command: $command}}')
printf '%s' "$SYMLINK_PAYLOAD" \
  | env PATH="$HOOK_TEST_TMP/bin:$PATH" HOOK_FORMAT_LOG="$HOOK_TEST_TMP/format.log" \
      bash "$REPO_ROOT/.claude/hooks/post-tool-use.sh"
assert_not_contains "$HOOK_TEST_TMP/format.log" "$FORMAT_REPO/src/outside-link.js"

STOP_OUTPUT=$(cd "$FORMAT_REPO" && bash "$REPO_ROOT/.claude/hooks/stop-check.sh")
printf '%s' "$STOP_OUTPUT" | jq -e '
  .continue == true
  and (.systemMessage | contains("커밋되지 않은 변경"))
' >/dev/null || fail "Stop output must be valid advisory JSON"

MIGRATION_REPO="$HOOK_TEST_TMP/migration repo"
mkdir -p "$MIGRATION_REPO"
git -C "$MIGRATION_REPO" init -q
cp "$REPO_ROOT/tests/fixtures/legacy-CLAUDE.md" "$MIGRATION_REPO/CLAUDE.md"

bash "$REPO_ROOT/scripts/init.sh" "$MIGRATION_REPO" >/dev/null \
  || fail "first init migration"
MIGRATED_AGENTS="$MIGRATION_REPO/AGENTS.md"
assert_contains "$MIGRATED_AGENTS" '## 워크플로우 (절차 문서)'
assert_contains "$MIGRATED_AGENTS" '같은 SKILL.md를 읽고 동일한 절차를 그대로 따른다.'
assert_contains "$MIGRATED_AGENTS" '현재 에이전트 환경이 지원하는 격리된 서브에이전트'
assert_contains "$MIGRATED_AGENTS" '| 워크플로우 | 역할 |'
assert_contains "$MIGRATED_AGENTS" 'settings.local.json'
assert_contains "$MIGRATED_AGENTS" 'update-architecture 워크플로우를 실행'
assert_contains "$MIGRATED_AGENTS" 'add-rule 워크플로우를 실행'
assert_not_contains "$MIGRATED_AGENTS" 'Claude Code의 서브에이전트(Task)'
assert_not_contains "$MIGRATED_AGENTS" '`/new-spec'

INSTALLED_PRE_COMMAND=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$MIGRATION_REPO/.codex/hooks.json")
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
  | (cd "$MIGRATION_REPO/.claude/docs" && sh -c "$INSTALLED_PRE_COMMAND") \
  || fail "installed hook command from subdirectory"

BEFORE_SECOND_INIT=$(shasum -a 256 "$MIGRATED_AGENTS" | awk '{print $1}')
bash "$REPO_ROOT/scripts/init.sh" "$MIGRATION_REPO" >/dev/null \
  || fail "second init migration"
AFTER_SECOND_INIT=$(shasum -a 256 "$MIGRATED_AGENTS" | awk '{print $1}')
[ "$BEFORE_SECOND_INIT" = "$AFTER_SECOND_INIT" ] || fail "AGENTS.md migration is not idempotent"

echo "OK: hook contracts and init migration"
