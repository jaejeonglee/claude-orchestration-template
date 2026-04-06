#!/bin/bash
# claude-orchestration-template analyze script
# 기존 프로젝트 분석 후 .ai/docs/ 자동 채우기 준비
# 사용법: bash scripts/analyze.sh (프로젝트 루트에서 실행)

set -e

TARGET_DIR="${1:-$(pwd)}"
TODAY=$(date +%Y-%m-%d)
OUTPUT="$TARGET_DIR/.ai/docs/raw-analysis.md"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "🔍 프로젝트 분석 시작"
echo "────────────────────────────────────────"
echo "대상 디렉토리: $TARGET_DIR"
echo ""

# .ai 디렉토리 없으면 init 먼저 하라고 안내
if [ ! -d "$TARGET_DIR/.ai" ]; then
  echo "❌ .ai 디렉토리가 없습니다. 먼저 init.sh를 실행하세요."
  exit 1
fi

echo -e "${GREEN}수집 중...${NC}"

cat > "$OUTPUT" << 'HEADER'
# Project Raw Analysis

> 이 파일은 analyze.sh가 자동 생성한 프로젝트 분석 덤프입니다.
> Claude가 이 파일을 읽고 .ai/ 문서들을 채운 후 이 파일을 삭제합니다.

HEADER

echo "_분석 날짜: ${TODAY}_" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# ── 1. package.json ──────────────────────────────
echo "## 1. package.json" >> "$OUTPUT"
echo '```json' >> "$OUTPUT"
if [ -f "$TARGET_DIR/package.json" ]; then
  cat "$TARGET_DIR/package.json" >> "$OUTPUT"
else
  echo "(없음)" >> "$OUTPUT"
fi
echo '```' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# ── 2. 디렉토리 구조 ──────────────────────────────
echo "## 2. 디렉토리 구조 (depth 3)" >> "$OUTPUT"
echo '```' >> "$OUTPUT"
find "$TARGET_DIR" -maxdepth 3 \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/.ai/*" \
  -not -path "*/.claude/*" \
  -not -name "*.log" \
  | sed "s|$TARGET_DIR/||" | sort >> "$OUTPUT"
echo '```' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# ── 3. 라우트 / 엔드포인트 ────────────────────────
echo "## 3. 라우트 파일" >> "$OUTPUT"
ROUTE_FILES=$(find "$TARGET_DIR/src" -name "*.js" -o -name "*.ts" 2>/dev/null | xargs grep -l "router\|route\|\.get\|\.post\|\.put\|\.delete\|\.patch" 2>/dev/null | grep -i "route\|controller\|handler" | head -20 || true)

if [ -n "$ROUTE_FILES" ]; then
  for f in $ROUTE_FILES; do
    echo "### $(echo $f | sed "s|$TARGET_DIR/||")" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
    head -80 "$f" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
    echo "" >> "$OUTPUT"
  done
else
  # route 파일명이 아니더라도 라우트 패턴이 있는 파일 찾기
  echo "(route 파일 자동 감지 실패 — src/ 구조 수동 확인 필요)" >> "$OUTPUT"
fi
echo "" >> "$OUTPUT"

# ── 4. DB 스키마 ──────────────────────────────────
echo "## 4. DB 스키마" >> "$OUTPUT"
# SQL 파일
SQL_FILES=$(find "$TARGET_DIR" -name "*.sql" -not -path "*/node_modules/*" -not -path "*/.ai/*" 2>/dev/null | head -10 || true)
if [ -n "$SQL_FILES" ]; then
  for f in $SQL_FILES; do
    echo "### $(echo $f | sed "s|$TARGET_DIR/||")" >> "$OUTPUT"
    echo '```sql' >> "$OUTPUT"
    cat "$f" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
    echo "" >> "$OUTPUT"
  done
fi
# Prisma schema
if [ -f "$TARGET_DIR/prisma/schema.prisma" ]; then
  echo "### prisma/schema.prisma" >> "$OUTPUT"
  echo '```prisma' >> "$OUTPUT"
  cat "$TARGET_DIR/prisma/schema.prisma" >> "$OUTPUT"
  echo '```' >> "$OUTPUT"
fi
# Drizzle / TypeORM entity 파일
SCHEMA_FILES=$(find "$TARGET_DIR/src" -name "*.entity.ts" -o -name "*.schema.ts" -o -name "schema.ts" 2>/dev/null | head -10 || true)
for f in $SCHEMA_FILES; do
  echo "### $(echo $f | sed "s|$TARGET_DIR/||")" >> "$OUTPUT"
  echo '```' >> "$OUTPUT"
  cat "$f" >> "$OUTPUT"
  echo '```' >> "$OUTPUT"
done
echo "" >> "$OUTPUT"

# ── 5. 환경 변수 ──────────────────────────────────
echo "## 5. 환경 변수 (.env.example / .env.sample)" >> "$OUTPUT"
for env_file in ".env.example" ".env.sample" ".env.template" ".env.schema"; do
  if [ -f "$TARGET_DIR/$env_file" ]; then
    echo "### $env_file" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
    cat "$TARGET_DIR/$env_file" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
  fi
done
# .env는 읽지 않음 (보안)
echo "" >> "$OUTPUT"

# ── 6. git 로그 ───────────────────────────────────
echo "## 6. git log (최근 20개)" >> "$OUTPUT"
echo '```' >> "$OUTPUT"
git -C "$TARGET_DIR" log --oneline -20 2>/dev/null || echo "(git 없음)" >> "$OUTPUT"
echo '```' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# ── 7. 기존 README ───────────────────────────────
echo "## 7. README.md" >> "$OUTPUT"
if [ -f "$TARGET_DIR/README.md" ]; then
  echo '```markdown' >> "$OUTPUT"
  head -100 "$TARGET_DIR/README.md" >> "$OUTPUT"
  echo '```' >> "$OUTPUT"
else
  echo "(없음)" >> "$OUTPUT"
fi
echo "" >> "$OUTPUT"

# ── CURRENT_TASK.md 에 지시 작성 ─────────────────
TASK_FILE="$TARGET_DIR/CURRENT_TASK.md"

cat > "$TASK_FILE" << EOF
# Current Task

_마지막 업데이트: ${TODAY}_

---

## 현재 작업

**[AI 초기 설정] 프로젝트 분석 후 .ai/ 문서 채우기**

analyze.sh가 수집한 raw-analysis.md를 기반으로 아래 문서를 채워주세요.

## 해야 할 것

- [ ] \`.ai/docs/raw-analysis.md\` 읽기
- [ ] \`.ai/architecture.md\` 채우기 (기술 스택, 디렉토리 구조, 데이터 흐름, 외부 의존성)
- [ ] \`.ai/conventions.md\` 채우기 (코딩 패턴, 도메인 규칙, 구현 게이트)
- [ ] \`.ai/docs/PROJECT.md\` 채우기 (현재 상태, 정책, 런타임 계약)
- [ ] \`.ai/docs/API_DOCS.md\` 채우기 (엔드포인트 목록 + 요청/응답 계약)
- [ ] \`.ai/docs/TODO.md\` 채우기 (git log 기반 추정 미완료 항목)
- [ ] \`.ai/docs/raw-analysis.md\` **삭제** (문서 채우기 완료 후)
- [ ] 이 CURRENT_TASK.md를 현재 상태로 업데이트

## 작성 기준

- **추측하지 말 것** — raw-analysis.md에 없는 내용은 \`[확인 필요]\`로 표시
- **현재 상태만** — 미래 계획은 TODO.md에, PROJECT.md엔 현재 동작하는 것만
- 완료 후 "분석 완료, 확인해주세요" 로 보고

## 다음 작업 시작 시 읽어야 할 것

- \`.ai/docs/raw-analysis.md\` (분석 덤프)
- 위 체크리스트
EOF

echo ""
echo "────────────────────────────────────────"
echo -e "${GREEN}✅ 분석 완료!${NC}"
echo ""
echo "생성된 파일:"
echo "  .ai/docs/raw-analysis.md  (프로젝트 정보 덤프)"
echo "  CURRENT_TASK.md           (Claude 작업 지시)"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo "  claude 를 실행하면 자동으로 문서를 채웁니다."
echo ""
