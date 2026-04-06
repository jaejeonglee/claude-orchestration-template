#!/bin/bash
# claude-orchestration-template init script
# 사용법: bash <(curl -s https://raw.githubusercontent.com/ljjunh/claude-orchestration-template/main/scripts/init.sh)
# 또는 클론 후: bash scripts/init.sh

set -e

TEMPLATE_REPO="https://raw.githubusercontent.com/ljjunh/claude-orchestration-template/main"
TARGET_DIR="${1:-$(pwd)}"
TODAY=$(date +%Y-%m-%d)

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "🤖 Claude Orchestration Template 설치"
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
echo -e "${GREEN}[1/5] 디렉토리 구조 생성...${NC}"
mkdir -p "$TARGET_DIR/.claude/agents"
mkdir -p "$TARGET_DIR/.claude/scripts"
mkdir -p "$TARGET_DIR/.claude/skills/new-spec"
mkdir -p "$TARGET_DIR/.claude/skills/update-task"
mkdir -p "$TARGET_DIR/.ai/docs/specs"
mkdir -p "$TARGET_DIR/.ai/docs/migrations"

# 파일 다운로드 또는 복사
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_LOCAL="$(dirname "$SCRIPT_DIR")"

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

echo -e "${GREEN}[2/5] 에이전트 설정 복사...${NC}"
copy_or_download ".claude/agents/codex-reasoner.md" "$TARGET_DIR/.claude/agents/codex-reasoner.md"
copy_or_download ".claude/agents/gemini-researcher.md" "$TARGET_DIR/.claude/agents/gemini-researcher.md"
copy_or_download ".claude/scripts/call-gemini.sh" "$TARGET_DIR/.claude/scripts/call-gemini.sh"
chmod +x "$TARGET_DIR/.claude/scripts/call-gemini.sh"
copy_or_download ".claude/settings.json" "$TARGET_DIR/.claude/settings.json"
copy_or_download ".claude/skills/new-spec/SKILL.md" "$TARGET_DIR/.claude/skills/new-spec/SKILL.md"
copy_or_download ".claude/skills/update-task/SKILL.md" "$TARGET_DIR/.claude/skills/update-task/SKILL.md"

echo -e "${GREEN}[3/5] AI 문서 복사...${NC}"
copy_or_download ".ai/README.md" "$TARGET_DIR/.ai/README.md"
copy_or_download ".ai/agents.md" "$TARGET_DIR/.ai/agents.md"
copy_or_download ".ai/context-reset.md" "$TARGET_DIR/.ai/context-reset.md"

# 템플릿 변수 치환해서 생성
echo -e "${GREEN}[4/5] 프로젝트 설정 파일 생성...${NC}"

# architecture.md
cat "$TEMPLATE_LOCAL/.ai/architecture.md" > "$TARGET_DIR/.ai/architecture.md"

# conventions.md
cat "$TEMPLATE_LOCAL/.ai/conventions.md" > "$TARGET_DIR/.ai/conventions.md"

# CLAUDE.md (변수 치환)
sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
  "$TEMPLATE_LOCAL/CLAUDE.md.template" > "$TARGET_DIR/CLAUDE.md"

# CURRENT_TASK.md (변수 치환)
sed "s/{{DATE}}/$TODAY/g" \
  "$TEMPLATE_LOCAL/CURRENT_TASK.md.template" > "$TARGET_DIR/CURRENT_TASK.md"

# .ai/docs 빈 파일들
touch "$TARGET_DIR/.ai/docs/PROJECT.md"
touch "$TARGET_DIR/.ai/docs/TODO.md"
touch "$TARGET_DIR/.ai/docs/API_DOCS.md"

# .gitignore 업데이트
echo -e "${GREEN}[5/5] .gitignore 업데이트...${NC}"
GITIGNORE="$TARGET_DIR/.gitignore"
ENTRIES=(".claude" ".ai" "CLAUDE.md" "CURRENT_TASK.md")

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
echo -e "${GREEN}✅ 설치 완료!${NC}"
echo ""
echo "생성된 파일:"
echo "  .claude/agents/codex-reasoner.md"
echo "  .claude/agents/gemini-researcher.md"
echo "  .claude/scripts/call-gemini.sh"
echo "  .claude/settings.json"
echo "  .claude/skills/new-spec/SKILL.md"
echo "  .claude/skills/update-task/SKILL.md"
echo "  .ai/ (README, agents, architecture, conventions, context-reset, docs/)"
echo "  CLAUDE.md"
echo "  CURRENT_TASK.md"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo "  1. export GEMINI_API_KEY=your_key  (gemini-researcher 사용 시)"
echo "  2. .ai/architecture.md 를 프로젝트 구조에 맞게 작성"
echo "  3. .ai/conventions.md 를 프로젝트 규칙에 맞게 작성"
echo "  4. .ai/docs/PROJECT.md 에 현재 상태 기록"
echo "  5. claude 실행!"
echo ""
