#!/bin/bash
# claude-orchestration-template init script
# 사용법: bash <(curl -s https://raw.githubusercontent.com/jaejeonglee/claude-orchestration-template/main/scripts/init.sh)
# 또는 클론 후: bash scripts/init.sh

set -e

TEMPLATE_REPO="https://raw.githubusercontent.com/jaejeonglee/claude-orchestration-template/main"
TARGET_DIR="${1:-$(pwd)}"
TODAY=$(date +%Y-%m-%d)
PROJECT_NAME=$(basename "$TARGET_DIR")

# 로컬 템플릿 경로 (클론 후 실행 시에만 유효)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_LOCAL="$(dirname "$SCRIPT_DIR")"

# 로컬 템플릿이 유효한지 확인 (CLAUDE.md.template 존재 여부로 판단)
if [ ! -f "$TEMPLATE_LOCAL/CLAUDE.md.template" ]; then
  TEMPLATE_LOCAL=""
fi

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "Claude Orchestration Template 설치"
echo "────────────────────────────────────────"
echo "대상: $TARGET_DIR"
echo ""

# 파일 복사 또는 다운로드
copy_file() {
  local src="$1"
  local dest="$2"

  if [ -n "$TEMPLATE_LOCAL" ] && [ -f "$TEMPLATE_LOCAL/$src" ]; then
    cp "$TEMPLATE_LOCAL/$src" "$dest"
  else
    curl -sf "$TEMPLATE_REPO/$src" -o "$dest" || {
      echo -e "${RED}[오류] $src 다운로드 실패${NC}"
      exit 1
    }
  fi
}

# 이미 있으면 건너뜀
copy_if_not_exists() {
  local src="$1"
  local dest="$2"

  if [ -f "$dest" ]; then
    echo "  건너뜀: $(echo $dest | sed "s|$TARGET_DIR/||")"
    return
  fi

  copy_file "$src" "$dest"
  echo "  생성: $(echo $dest | sed "s|$TARGET_DIR/||")"
}

# [1/4] 디렉토리
echo -e "${GREEN}[1/4] 디렉토리 생성...${NC}"
mkdir -p "$TARGET_DIR/.claude/agents"
mkdir -p "$TARGET_DIR/.claude/scripts"
mkdir -p "$TARGET_DIR/.claude/skills/new-spec"
mkdir -p "$TARGET_DIR/.claude/skills/update-task"
mkdir -p "$TARGET_DIR/.claude/skills/add-rule"
mkdir -p "$TARGET_DIR/.claude/docs/specs"

# [2/4] 에이전트·스킬 (항상 최신으로 덮어씀)
echo -e "${GREEN}[2/4] 에이전트·스킬 복사...${NC}"
copy_file ".claude/agents/codex-reasoner.md" "$TARGET_DIR/.claude/agents/codex-reasoner.md"
copy_file ".claude/agents/gemini-researcher.md" "$TARGET_DIR/.claude/agents/gemini-researcher.md"
copy_file ".claude/scripts/call-gemini.sh" "$TARGET_DIR/.claude/scripts/call-gemini.sh"
copy_file ".claude/scripts/call-codex.sh" "$TARGET_DIR/.claude/scripts/call-codex.sh"
chmod +x "$TARGET_DIR/.claude/scripts/call-gemini.sh"
chmod +x "$TARGET_DIR/.claude/scripts/call-codex.sh"
copy_file ".claude/skills/new-spec/SKILL.md" "$TARGET_DIR/.claude/skills/new-spec/SKILL.md"
copy_file ".claude/skills/update-task/SKILL.md" "$TARGET_DIR/.claude/skills/update-task/SKILL.md"
copy_file ".claude/skills/add-rule/SKILL.md" "$TARGET_DIR/.claude/skills/add-rule/SKILL.md"
copy_file ".claude/settings.json" "$TARGET_DIR/.claude/settings.json"

# [3/4] 문서 (이미 있으면 건너뜀)
echo -e "${GREEN}[3/4] 문서 생성...${NC}"
copy_if_not_exists ".claude/docs/architecture.md" "$TARGET_DIR/.claude/docs/architecture.md"
copy_if_not_exists ".claude/docs/conventions.md" "$TARGET_DIR/.claude/docs/conventions.md"

if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  # 기존 CLAUDE.md가 있으면 누락된 섹션만 추가 (멱등적 병합)
  APPENDED=0

  # 1. Skills 테이블에 /add-rule 추가 (섹션 추가 전에 먼저 — 중복 매칭 방지)
  if ! grep -qE '^\|.*\/add-rule' "$TARGET_DIR/CLAUDE.md"; then
    if grep -q "/update-task" "$TARGET_DIR/CLAUDE.md"; then
      awk '
        /\/update-task.*CURRENT_TASK/ {
          print;
          print "| `/add-rule <규칙>` | 프로젝트 규칙을 `conventions.md`에 추가 |";
          next
        }
        { print }
      ' "$TARGET_DIR/CLAUDE.md" > "$TARGET_DIR/CLAUDE.md.tmp" && \
        mv "$TARGET_DIR/CLAUDE.md.tmp" "$TARGET_DIR/CLAUDE.md"
      APPENDED=1
    fi
  fi

  # 2. "새 규칙 발견 시" 섹션 추가
  if ! grep -q "## 새 규칙 발견 시" "$TARGET_DIR/CLAUDE.md"; then
    cat >> "$TARGET_DIR/CLAUDE.md" << 'RULE_SECTION'

---

## 새 규칙 발견 시

사용자 지시나 프로젝트 분석에서 아래 패턴을 감지하면 **즉시 `/add-rule`을 실행**해 `conventions.md`에 기록한다:

| 감지 패턴 | 예시 |
|---|---|
| "앞으로 ~해줘" / "항상 ~하게" | "앞으로 에러 메시지는 한글로" |
| "이 프로젝트는 ~를 지킨다" | "모든 API에 rate limit 필수" |
| "절대 ~하지 마" / "~ 금지" | "console.log 금지, 항상 logger 사용" |
| 기획 확정 과정에서 도출된 정책 | "결제는 idempotency key 필수" |

기록 후 `규칙을 conventions.md에 기록했습니다` 로 1줄 보고.
RULE_SECTION
    APPENDED=1
  fi

  if [ $APPENDED -eq 1 ]; then
    echo "  업데이트: CLAUDE.md (누락 섹션 추가)"
  else
    echo "  건너뜀: CLAUDE.md (최신 상태)"
  fi
else
  if [ -n "$TEMPLATE_LOCAL" ]; then
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
      "$TEMPLATE_LOCAL/CLAUDE.md.template" > "$TARGET_DIR/CLAUDE.md"
  else
    curl -sf "$TEMPLATE_REPO/CLAUDE.md.template" | \
      sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" > "$TARGET_DIR/CLAUDE.md"
  fi
  echo "  생성: CLAUDE.md"
fi

if [ -f "$TARGET_DIR/.claude/CURRENT_TASK.md" ]; then
  echo "  건너뜀: .claude/CURRENT_TASK.md"
else
  if [ -n "$TEMPLATE_LOCAL" ]; then
    sed "s/{{DATE}}/$TODAY/g" \
      "$TEMPLATE_LOCAL/CURRENT_TASK.md.template" > "$TARGET_DIR/.claude/CURRENT_TASK.md"
  else
    curl -sf "$TEMPLATE_REPO/CURRENT_TASK.md.template" | \
      sed "s/{{DATE}}/$TODAY/g" > "$TARGET_DIR/.claude/CURRENT_TASK.md"
  fi
  echo "  생성: .claude/CURRENT_TASK.md"
fi

if [ -f "$TARGET_DIR/.claude/PROGRESS.md" ]; then
  echo "  건너뜀: .claude/PROGRESS.md"
else
  if [ -n "$TEMPLATE_LOCAL" ]; then
    cp "$TEMPLATE_LOCAL/PROGRESS.md.template" "$TARGET_DIR/.claude/PROGRESS.md"
  else
    curl -sf "$TEMPLATE_REPO/PROGRESS.md.template" -o "$TARGET_DIR/.claude/PROGRESS.md"
  fi
  echo "  생성: .claude/PROGRESS.md"
fi

# [4/4] .gitignore
echo -e "${GREEN}[4/4] .gitignore 업데이트...${NC}"
GITIGNORE="$TARGET_DIR/.gitignore"
for entry in ".claude" "CLAUDE.md"; do
  if [ -f "$GITIGNORE" ] && grep -qxF "$entry" "$GITIGNORE"; then
    echo "  이미 있음: $entry"
  else
    echo "$entry" >> "$GITIGNORE"
    echo "  추가: $entry"
  fi
done

# 완료
echo ""
echo "────────────────────────────────────────"
echo -e "${GREEN}설치 완료!${NC}"
echo ""
echo -e "${YELLOW}다음:${NC} claude 실행"
echo ""
