#!/usr/bin/env bash
# 세션 시작 컨텍스트 주입 — Claude / Codex 공용 SessionStart 훅
#
# 출력: 현재 작업 / 최근 저널 / 문서 구조 / 최근 커밋 / 미커밋 변경 / 정기 점검 신호
# 종료 코드: 항상 0 (정보 출력 전용, 세션을 막지 않는다)
#
# 프로젝트 루트 앵커링: 하위 디렉토리에서 에이전트를 실행해도 경로가 빗나가지 않도록
# 환경변수 → git 루트 → cwd 순으로 결정한다.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${CODEX_PROJECT_DIR:-}}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
cd "$PROJECT_DIR" 2>/dev/null || exit 0

echo '=== 현재 작업 ==='
cat .claude/CURRENT_TASK.md 2>/dev/null

echo ''
echo '=== 최근 작업 기록 (JOURNAL 끝 15줄) ==='
tail -n 15 .claude/JOURNAL.md 2>/dev/null

echo ''
echo '=== 문서 구조 (.claude/docs/) ==='
(cd .claude/docs 2>/dev/null && find . -maxdepth 2 -not -path '.' | sort)

echo ''
echo '=== 최근 커밋 ==='
git log --oneline -5 2>/dev/null

DIRTY=$(git status --short 2>/dev/null | head -15)
if [ -n "$DIRTY" ]; then
  echo ''
  echo '=== 커밋 안 된 변경 (이전 세션의 잔재일 수 있음) ==='
  echo "$DIRTY"
fi

# 주간 아키텍처 감사: 마커가 7일 초과 + 그 사이 커밋이 있을 때만 (조용한 주는 알리지 않음)
if [ -f .claude/.last-arch-audit ] \
  && [ -n "$(find .claude/.last-arch-audit -mtime +7 2>/dev/null)" ] \
  && [ "$(git log --oneline --since='7 days ago' 2>/dev/null | wc -l)" -gt 0 ]; then
  echo ''
  echo '=== 주간 아키텍처 감사 기한 경과 — 이 세션에서 update-architecture 워크플로우를 실행하세요 ==='
fi

# 상태 파일 부패: 14일간 CURRENT_TASK는 그대로인데 커밋만 쌓인 경우
if [ -f .claude/CURRENT_TASK.md ] \
  && [ -n "$(find .claude/CURRENT_TASK.md -mtime +14 2>/dev/null)" ] \
  && [ "$(git log --oneline --since='14 days ago' 2>/dev/null | wc -l)" -gt 0 ]; then
  echo ''
  echo '=== CURRENT_TASK.md가 14일째 갱신되지 않았는데 커밋은 계속되었습니다 — 상태 파일이 죽었을 수 있으니 update-task 워크플로우 실행 권장 ==='
fi

exit 0
