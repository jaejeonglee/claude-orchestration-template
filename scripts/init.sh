#!/bin/bash
# claude-orchestration-template init script
# 사용법: bash <(curl -s https://raw.githubusercontent.com/jaejeonglee/claude-orchestration-template/main/scripts/init.sh)
# 또는 클론 후: bash scripts/init.sh

set -e

TEMPLATE_REPO="https://raw.githubusercontent.com/jaejeonglee/claude-orchestration-template/main"
TARGET_DIR="${1:-$(pwd)}"
TODAY=$(date +%Y-%m-%d)

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "Claude Orchestration Template 설치"
echo "────────────────────────────────────────"
echo "대상 디렉토리: $TARGET_DIR"
echo ""

# 프로젝트 정보 입력
read -p "프로젝트 이름: " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}[오류] 프로젝트 이름을 입력해주세요.${NC}"
  exit 1
fi

echo ""
echo "기술 스택 (선택, 엔터로 건너뜀):"
read -p "  Runtime (예: Node.js 22): " RUNTIME
read -p "  Framework (예: Fastify 5): " FRAMEWORK
read -p "  Database (예: MySQL 8): " DATABASE

echo ""

# 디렉토리 생성
echo -e "${GREEN}[1/4] 디렉토리 구조 생성...${NC}"
mkdir -p "$TARGET_DIR/.claude/agents"
mkdir -p "$TARGET_DIR/.claude/scripts"
mkdir -p "$TARGET_DIR/.claude/skills/new-spec"
mkdir -p "$TARGET_DIR/.claude/skills/update-task"
mkdir -p "$TARGET_DIR/.claude/docs/specs"

# 파일 다운로드 또는 복사
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_LOCAL="$(dirname "$SCRIPT_DIR")"

# 파일 복사 (항상 덮어씀 — agents, scripts, skills 등 템플릿 파일)
copy_or_download() {
  local src="$1"
  local dest="$2"

  if [ -f "$TEMPLATE_LOCAL/$src" ]; then
    cp "$TEMPLATE_LOCAL/$src" "$dest"
  else
    curl -sf "$TEMPLATE_REPO/$src" -o "$dest" || {
      echo -e "${RED}[오류] $src 다운로드 실패${NC}"
      exit 1
    }
  fi
}

# 파일 복사 (이미 있으면 건너뜀 — 프로젝트별 커스텀 파일)
copy_if_not_exists() {
  local src="$1"
  local dest="$2"

  if [ -f "$dest" ]; then
    echo "  건너뜀 (이미 있음): $(basename $dest)"
    return
  fi

  if [ -f "$TEMPLATE_LOCAL/$src" ]; then
    cp "$TEMPLATE_LOCAL/$src" "$dest"
    echo "  생성: $(basename $dest)"
  else
    curl -sf "$TEMPLATE_REPO/$src" -o "$dest" || {
      echo -e "${RED}[오류] $src 다운로드 실패${NC}"
      exit 1
    }
    echo "  생성: $(basename $dest)"
  fi
}

echo -e "${GREEN}[2/4] 에이전트·스킬 설정 복사...${NC}"
# agents, scripts, skills는 항상 최신 템플릿으로 덮어씀
copy_or_download ".claude/agents/codex-reasoner.md" "$TARGET_DIR/.claude/agents/codex-reasoner.md"
copy_or_download ".claude/agents/gemini-researcher.md" "$TARGET_DIR/.claude/agents/gemini-researcher.md"
copy_or_download ".claude/scripts/call-gemini.sh" "$TARGET_DIR/.claude/scripts/call-gemini.sh"
chmod +x "$TARGET_DIR/.claude/scripts/call-gemini.sh"
copy_or_download ".claude/skills/new-spec/SKILL.md" "$TARGET_DIR/.claude/skills/new-spec/SKILL.md"
copy_or_download ".claude/skills/update-task/SKILL.md" "$TARGET_DIR/.claude/skills/update-task/SKILL.md"
# settings.json은 이미 있으면 건너뜀 (기존 hook 설정 보호)
copy_if_not_exists ".claude/settings.json" "$TARGET_DIR/.claude/settings.json"

echo -e "${GREEN}[3/4] 프로젝트 문서 생성...${NC}"
# 프로젝트별 파일은 이미 있으면 건너뜀
copy_if_not_exists ".claude/docs/architecture.md" "$TARGET_DIR/.claude/docs/architecture.md"
copy_if_not_exists ".claude/docs/conventions.md" "$TARGET_DIR/.claude/docs/conventions.md"

# CLAUDE.md — 이미 있으면 건너뜀
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  echo "  건너뜀 (이미 있음): CLAUDE.md"
else
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
    "$TEMPLATE_LOCAL/CLAUDE.md.template" > "$TARGET_DIR/CLAUDE.md"
  echo "  생성: CLAUDE.md"
fi

# CURRENT_TASK.md — 이미 있으면 건너뜀
if [ -f "$TARGET_DIR/.claude/CURRENT_TASK.md" ]; then
  echo "  건너뜀 (이미 있음): .claude/CURRENT_TASK.md"
else
  sed "s/{{DATE}}/$TODAY/g" \
    "$TEMPLATE_LOCAL/CURRENT_TASK.md.template" > "$TARGET_DIR/.claude/CURRENT_TASK.md"
  echo "  생성: .claude/CURRENT_TASK.md"
fi

# PROGRESS.md — 이미 있으면 건너뜀
if [ -f "$TARGET_DIR/.claude/PROGRESS.md" ]; then
  echo "  건너뜀 (이미 있음): .claude/PROGRESS.md"
else
  cp "$TEMPLATE_LOCAL/PROGRESS.md.template" "$TARGET_DIR/.claude/PROGRESS.md"
  echo "  생성: .claude/PROGRESS.md"
fi

# .gitignore 업데이트
echo -e "${GREEN}[4/4] .gitignore 업데이트...${NC}"
GITIGNORE="$TARGET_DIR/.gitignore"
ENTRIES=(".claude" "CLAUDE.md")

for entry in "${ENTRIES[@]}"; do
  if [ -f "$GITIGNORE" ]; then
    if ! grep -qxF "$entry" "$GITIGNORE"; then
      echo "$entry" >> "$GITIGNORE"
      echo "  추가: $entry"
    else
      echo "  이미 있음: $entry"
    fi
  else
    echo "$entry" >> "$GITIGNORE"
    echo "  추가: $entry"
  fi
done

# 완료 메시지
echo ""
echo "────────────────────────────────────────"
echo -e "${GREEN}설치 완료!${NC}"
echo ""
echo "생성된 파일:"
echo "  .claude/agents/       — 서브 에이전트 (codex-reasoner, gemini-researcher)"
echo "  .claude/scripts/      — 에이전트 유틸리티 (call-gemini.sh)"
echo "  .claude/settings.json — 훅 설정"
echo "  .claude/skills/       — 슬래시 커맨드 (/new-spec, /update-task)"
echo "  .claude/docs/         — 프로젝트 문서 (architecture, conventions, specs/)"
echo "  .claude/CURRENT_TASK.md — 현재 작업 상태"
echo "  .claude/PROGRESS.md   — 전체 진행 기록"
echo "  CLAUDE.md             — 세션 진입점"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo "  1. export GEMINI_API_KEY=your_key  (gemini-researcher 사용 시)"
echo "  2. .claude/docs/architecture.md 를 프로젝트 구조에 맞게 작성"
echo "  3. .claude/docs/conventions.md 를 프로젝트 규칙에 맞게 작성"
echo "  4. claude 실행!"
echo ""
