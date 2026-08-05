#!/bin/bash
# claude-template init script
# 사용법: bash <(curl -s https://raw.githubusercontent.com/jaejeonglee/claude-template/main/scripts/init.sh)
# 또는 클론 후: bash scripts/init.sh

set -e

TEMPLATE_REPO="https://raw.githubusercontent.com/jaejeonglee/claude-template/main"
TARGET_DIR="${1:-$(pwd)}"
TODAY=$(date +%Y-%m-%d)
PROJECT_NAME=$(basename "$TARGET_DIR")

# 로컬 템플릿 경로 (클론 후 실행 시에만 유효)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_LOCAL="$(dirname "$SCRIPT_DIR")"

# 로컬 템플릿이 유효한지 확인 (AGENTS.md.template 존재 여부로 판단)
if [ ! -f "$TEMPLATE_LOCAL/AGENTS.md.template" ]; then
  TEMPLATE_LOCAL=""
fi

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "Claude Template 설치"
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
mkdir -p "$TARGET_DIR/.claude/skills/new-spec"
mkdir -p "$TARGET_DIR/.claude/skills/update-task"
mkdir -p "$TARGET_DIR/.claude/skills/add-rule"
mkdir -p "$TARGET_DIR/.claude/skills/update-architecture"
mkdir -p "$TARGET_DIR/.claude/skills/migrate-from-ai"
mkdir -p "$TARGET_DIR/.claude/skills/add-hook"

# 공용 훅 스크립트 + Codex 어댑터
mkdir -p "$TARGET_DIR/.claude/hooks"
mkdir -p "$TARGET_DIR/.codex"

# 표준 문서 카테고리 디렉토리 (이미 있으면 그대로 유지)
mkdir -p "$TARGET_DIR/.claude/docs/api"
mkdir -p "$TARGET_DIR/.claude/docs/contracts"
mkdir -p "$TARGET_DIR/.claude/docs/runbooks"
mkdir -p "$TARGET_DIR/.claude/docs/decisions"
mkdir -p "$TARGET_DIR/.claude/docs/reference"
mkdir -p "$TARGET_DIR/.claude/docs/specs"

# [2/4] 스킬 + 설정 (항상 최신으로 덮어씀)
echo -e "${GREEN}[2/4] 스킬·설정 복사...${NC}"
copy_file ".claude/skills/new-spec/SKILL.md" "$TARGET_DIR/.claude/skills/new-spec/SKILL.md"
copy_file ".claude/skills/update-task/SKILL.md" "$TARGET_DIR/.claude/skills/update-task/SKILL.md"
copy_file ".claude/skills/add-rule/SKILL.md" "$TARGET_DIR/.claude/skills/add-rule/SKILL.md"
copy_file ".claude/skills/update-architecture/SKILL.md" "$TARGET_DIR/.claude/skills/update-architecture/SKILL.md"
copy_file ".claude/skills/migrate-from-ai/SKILL.md" "$TARGET_DIR/.claude/skills/migrate-from-ai/SKILL.md"
copy_file ".claude/skills/add-hook/SKILL.md" "$TARGET_DIR/.claude/skills/add-hook/SKILL.md"
copy_file ".claude/settings.json" "$TARGET_DIR/.claude/settings.json"

# 공용 훅 스크립트 (Claude/Codex가 같은 파일을 호출)
for hook in pre-tool-use post-tool-use session-start stop-check; do
  copy_file ".claude/hooks/${hook}.sh" "$TARGET_DIR/.claude/hooks/${hook}.sh"
  chmod +x "$TARGET_DIR/.claude/hooks/${hook}.sh"
done

# Codex 어댑터
copy_file ".codex/hooks.json" "$TARGET_DIR/.codex/hooks.json"
copy_file ".codex/README.md" "$TARGET_DIR/.codex/README.md"

# 구버전 정리: 제거된 에이전트/스크립트 고아 파일 삭제
for orphan in \
  ".claude/agents/codex-reasoner.md" \
  ".claude/agents/gemini-researcher.md" \
  ".claude/scripts/call-codex.sh" \
  ".claude/scripts/call-gemini.sh"; do
  if [ -f "$TARGET_DIR/$orphan" ]; then
    rm -f "$TARGET_DIR/$orphan"
    echo "  제거: $orphan (구버전)"
  fi
done
# 빈 디렉토리 정리 (사용자 커스텀 파일이 있으면 보존됨)
rmdir "$TARGET_DIR/.claude/agents" 2>/dev/null && echo "  제거: .claude/agents/ (빈 디렉토리)"
rmdir "$TARGET_DIR/.claude/scripts" 2>/dev/null && echo "  제거: .claude/scripts/ (빈 디렉토리)"

# [3/4] 문서 (이미 있으면 건너뜀)
echo -e "${GREEN}[3/4] 문서 생성...${NC}"
copy_if_not_exists ".claude/docs/architecture.md" "$TARGET_DIR/.claude/docs/architecture.md"
copy_if_not_exists ".claude/docs/conventions.md" "$TARGET_DIR/.claude/docs/conventions.md"

# 규칙 원본은 AGENTS.md (Claude/Codex 공용). CLAUDE.md는 이를 import하는 얇은 진입점.
RULES_FILE="$TARGET_DIR/AGENTS.md"

# 구버전 마이그레이션: 규칙이 CLAUDE.md에 통째로 들어있던 설치를 AGENTS.md로 승격
if [ ! -f "$RULES_FILE" ] && [ -f "$TARGET_DIR/CLAUDE.md" ] \
  && grep -qE '# Part 1\. 코딩 자세|## 핵심 규칙|## 탐색 사다리' "$TARGET_DIR/CLAUDE.md"; then
  mv "$TARGET_DIR/CLAUDE.md" "$RULES_FILE"
  echo "  이관: CLAUDE.md → AGENTS.md (규칙 원본 승격)"
fi

if [ -f "$RULES_FILE" ]; then
  # 기존 AGENTS.md가 있으면 누락된 섹션만 추가 (멱등적 병합)
  APPENDED=0

  # 구버전 정리: Claude 전용 워크플로우 표현을 공용 표현으로 교체
  if grep -qF '깊은 검증이나 대량 병렬 작업이 필요하면 Claude Code의 서브에이전트(Task)로 격리된 컨텍스트에서 처리한다' "$RULES_FILE"; then
    sed 's/깊은 검증이나 대량 병렬 작업이 필요하면 Claude Code의 서브에이전트(Task)로 격리된 컨텍스트에서 처리한다/깊은 검증이나 대량 병렬 작업이 필요하면, 현재 에이전트 환경이 지원하는 격리된 서브에이전트로 처리한다/' \
      "$RULES_FILE" > "$RULES_FILE.tmp" && mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: Claude 전용 서브에이전트 표현을 공용 표현으로 교체"
    APPENDED=1
  fi

  # 구버전 Skills 섹션에 비슬래시 환경용 SKILL.md 라우팅 추가
  if ! grep -qF '각 절차의 상세 단계는 `.claude/skills/<이름>/SKILL.md`에 있다.' "$RULES_FILE" && \
     grep -qE '^## (Skills|워크플로우 \(절차 문서\))$' "$RULES_FILE"; then
    awk '
      /^## Skills$/ {
        print "## 워크플로우 (절차 문서)";
        print "";
        print "각 절차의 상세 단계는 `.claude/skills/<이름>/SKILL.md`에 있다.";
        print "슬래시 커맨드를 지원하는 환경에서는 `/<이름>`으로 호출되고, 그렇지 않은 환경에서는";
        print "**같은 SKILL.md를 읽고 동일한 절차를 그대로 따른다.** 호출 방식이 달라도 결과는 같아야 한다.";
        next
      }
      /^## 워크플로우 \(절차 문서\)$/ {
        print;
        print "";
        print "각 절차의 상세 단계는 `.claude/skills/<이름>/SKILL.md`에 있다.";
        print "슬래시 커맨드를 지원하는 환경에서는 `/<이름>`으로 호출되고, 그렇지 않은 환경에서는";
        print "**같은 SKILL.md를 읽고 동일한 절차를 그대로 따른다.** 호출 방식이 달라도 결과는 같아야 한다.";
        next
      }
      { print }
    ' "$RULES_FILE" > "$RULES_FILE.tmp" && mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: 워크플로우에 SKILL.md 공용 라우팅 추가"
    APPENDED=1
  fi

  # 구버전 표 헤더와 add-hook 저장 위치를 현재 공용 표현으로 교체
  if grep -qE '^\| 커맨드[[:space:]]*\| 역할[[:space:]]*\|$' "$RULES_FILE" || \
     grep -qF '자연어 자동화 요청을 훅으로 변환 (`settings.json`)' "$RULES_FILE"; then
    sed -E \
      -e 's#^\| 커맨드[[:space:]]*\| 역할[[:space:]]*\|$#| 워크플로우 | 역할 |#' \
      -e 's#자연어 자동화 요청을 훅으로 변환 \(`settings.json`\)#자연어 자동화 요청을 훅으로 변환 (`settings.local.json`)#g' \
      "$RULES_FILE" > "$RULES_FILE.tmp" && mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: 워크플로우 표의 구버전 표현 교체"
    APPENDED=1
  fi

  # 구버전 워크플로우 표의 Claude 슬래시 표기를 공용 이름으로 정규화
  if grep -qE '^\|.*`/(new-spec|update-task|add-rule|update-architecture|migrate-from-ai|add-hook)' "$RULES_FILE"; then
    awk '
      /^\|/ {
        gsub("`/new-spec", "`new-spec");
        gsub("`/update-task", "`update-task");
        gsub("`/add-rule", "`add-rule");
        gsub("`/update-architecture", "`update-architecture");
        gsub("`/migrate-from-ai", "`migrate-from-ai");
        gsub("`/add-hook", "`add-hook");
      }
      { print }
    ' "$RULES_FILE" > "$RULES_FILE.tmp" && mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: 워크플로우 표의 슬래시 표기를 공용 이름으로 교체"
    APPENDED=1
  fi

  # 구버전 본문에 남은 Claude 슬래시 실행 표현을 공용 워크플로우 표현으로 교체
  if grep -qE '^/new-spec[[:space:]]+→|`/?update-architecture`를 실행|`/?add-rule`을 실행' "$RULES_FILE"; then
    sed -E \
      -e 's#^/new-spec[[:space:]]+→#new-spec   →#' \
      -e 's#`/?update-architecture`를 실행#update-architecture 워크플로우를 실행#g' \
      -e 's#`/?add-rule`을 실행#add-rule 워크플로우를 실행#g' \
      "$RULES_FILE" > "$RULES_FILE.tmp" && mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: 본문의 슬래시 실행 표현을 공용 워크플로우 표현으로 교체"
    APPENDED=1
  fi

  # 구버전 정리: "작업 완료 시" 규칙을 저널 방식으로 교체
  if grep -qF '**작업 완료 시**: `.claude/CURRENT_TASK.md` 항상 업데이트' "$RULES_FILE"; then
    awk '
      /\*\*작업 완료 시\*\*: `\.claude\/CURRENT_TASK\.md` 항상 업데이트/ {
        print "- **작업 완료 시**: `date +\"%Y-%m-%d %H:%M\"`로 시각 확인 후 `.claude/JOURNAL.md`에 한 줄 요약 append, `.claude/CURRENT_TASK.md`는 \"지금 + 다음\"만 남기고 갱신 (완료 항목은 저널로 보내고 제거)";
        next
      }
      { print }
    ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
      mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: '작업 완료 시' 규칙을 JOURNAL 방식으로 교체"
    APPENDED=1
  fi

  # 구버전 정리: 제거된 "## 에이전트 라우팅" 섹션 삭제
  if grep -q "^## 에이전트 라우팅" "$RULES_FILE"; then
    awk '
      /^## 에이전트 라우팅/ { skip=1; next }
      skip && /^---$/ { skip=0; next }
      skip { next }
      { print }
    ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
      mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: 구버전 '에이전트 라우팅' 섹션 제거"
    APPENDED=1
  fi

  # 구버전 정리: codex/gemini 참조가 남은 구버전 워크플로우 섹션 제거 후 신버전 추가
  if grep -q "gemini-researcher\|codex-reasoner" "$RULES_FILE"; then
    awk '
      /^## 기능 개발 워크플로우/ { skip=1; next }
      skip && /^---$/ { skip=0; next }
      skip { next }
      { print }
    ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
      mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: 구버전 '기능 개발 워크플로우' 섹션 제거 (codex/gemini 참조)"
    APPENDED=1
  fi

  # 신버전 워크플로우 섹션 추가 (없으면)
  if ! grep -q "^## 기능 개발 워크플로우" "$RULES_FILE"; then
    cat >> "$RULES_FILE" << 'WORKFLOW_SECTION'

---

## 기능 개발 워크플로우

```
new-spec   → 기획 초안 작성 (.claude/docs/specs/*.draft.md)
사람       → 확정
구현       → 문서 동기화 → draft 삭제
```

**확정되지 않은 초안은 바로 코드로 옮기지 않는다.**

깊은 검증이나 대량 병렬 작업이 필요하면, 현재 에이전트 환경이 지원하는 격리된 서브에이전트로 처리한다 — 메인 대화를 오염시키지 않는다.
WORKFLOW_SECTION
    APPENDED=1
  fi

  # 0-a. 대화 자세(Part 0) 추가 (없으면 맨 앞 헤더 뒤에 삽입)
  if ! grep -q "# Part 0. 대화 자세" "$RULES_FILE"; then
    PART0_TMP=$(mktemp)
    if [ -n "$TEMPLATE_LOCAL" ]; then
      awk '/^# Part 0\./,/^# Part 1\./' "$TEMPLATE_LOCAL/AGENTS.md.template" \
        | sed '$d' > "$PART0_TMP"
    else
      curl -sf "$TEMPLATE_REPO/AGENTS.md.template" \
        | awk '/^# Part 0\./,/^# Part 1\./' \
        | sed '$d' > "$PART0_TMP"
    fi

    if [ -s "$PART0_TMP" ]; then
      {
        head -n 1 "$RULES_FILE"
        echo ""
        echo "---"
        echo ""
        cat "$PART0_TMP"
        tail -n +2 "$RULES_FILE"
      } > "$RULES_FILE.tmp" && \
        mv "$RULES_FILE.tmp" "$RULES_FILE"
      APPENDED=1
    fi
    rm -f "$PART0_TMP"
  fi

  # 0-b. Karpathy 4원칙 추가 (없으면 맨 앞 헤더 뒤에 삽입)
  if ! grep -q "# Part 1. 코딩 자세" "$RULES_FILE"; then
    KARPATHY_TMP=$(mktemp)
    if [ -n "$TEMPLATE_LOCAL" ]; then
      awk '/^# Part 1\./,/^# Part 2\./' "$TEMPLATE_LOCAL/AGENTS.md.template" \
        | sed '$d' > "$KARPATHY_TMP"
    else
      curl -sf "$TEMPLATE_REPO/AGENTS.md.template" \
        | awk '/^# Part 1\./,/^# Part 2\./' \
        | sed '$d' > "$KARPATHY_TMP"
    fi

    if [ -s "$KARPATHY_TMP" ]; then
      # 첫 줄(헤더) + 구분선 + Karpathy 섹션 + 나머지
      {
        head -n 1 "$RULES_FILE"
        echo ""
        echo "---"
        echo ""
        cat "$KARPATHY_TMP"
        tail -n +2 "$RULES_FILE"
      } > "$RULES_FILE.tmp" && \
        mv "$RULES_FILE.tmp" "$RULES_FILE"
      APPENDED=1
    fi
    rm -f "$KARPATHY_TMP"
  fi

  # 1. 워크플로우 표에 add-rule 추가 (앵커는 표 행만 — 줄 시작이 '|')
  if ! grep -qE '^\|.*add-rule' "$RULES_FILE"; then
    if grep -qE '^\|.*update-task' "$RULES_FILE"; then
      awk '
        /^\|.*update-task/ {
          print;
          print "| `add-rule <규칙>` | 프로젝트 규칙을 `conventions.md`에 추가 |";
          next
        }
        { print }
      ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
        mv "$RULES_FILE.tmp" "$RULES_FILE"
      APPENDED=1
    fi
  fi

  # 1-b. Skills 테이블에 /update-architecture 추가
  if ! grep -qE '^\|.*update-architecture' "$RULES_FILE"; then
    if grep -qE '^\|.*add-rule' "$RULES_FILE"; then
      awk '
        /^\|.*add-rule/ {
          print;
          print "| `update-architecture` | `architecture.md`를 현재 코드 기준으로 생성/갱신 |";
          next
        }
        { print }
      ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
        mv "$RULES_FILE.tmp" "$RULES_FILE"
      APPENDED=1
    fi
  fi

  # 1-c. Skills 테이블에 /migrate-from-ai 추가
  if ! grep -qE '^\|.*migrate-from-ai' "$RULES_FILE"; then
    if grep -qE '^\|.*update-architecture' "$RULES_FILE"; then
      awk '
        /^\|.*update-architecture/ {
          print;
          print "| `migrate-from-ai` | 구버전 `.ai/` 디렉토리를 새 구조로 분류·이동 |";
          next
        }
        { print }
      ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
        mv "$RULES_FILE.tmp" "$RULES_FILE"
      APPENDED=1
    fi
  fi

  # 1-c2. Skills 테이블에 /add-hook 추가
  if ! grep -qE '^\|.*add-hook' "$RULES_FILE"; then
    if grep -qE '^\|.*migrate-from-ai' "$RULES_FILE"; then
      awk '
        /^\|.*migrate-from-ai/ {
          print;
          print "| `add-hook <설명>` | 자연어 자동화 요청을 훅으로 변환 (`settings.local.json`) |";
          next
        }
        { print }
      ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
        mv "$RULES_FILE.tmp" "$RULES_FILE"
      APPENDED=1
    fi
  fi

  # 1-d. "문서 찾기" 섹션 추가 (없으면 "## 세션 시작 시" 섹션 뒤에 삽입)
  if ! grep -q "## 문서 찾기" "$RULES_FILE"; then
    DOCFINDER_TMP=$(mktemp)
    cat > "$DOCFINDER_TMP" << 'DOC_FINDER'

---

## 문서 찾기

특정 정보가 필요하면 아래 위치를 우선 탐색한다. 카테고리는 디렉토리 단위로 안정적이고, 디렉토리 안의 실제 파일은 `ls`로 동적 확인.

| 무엇을 찾을 때 | 위치 | 로드 방식 |
|---|---|---|
| 시스템 구조, 모듈 | `.claude/docs/architecture.md` | 항상 로드 (작게 유지) |
| 코딩 규칙, 정책 | `.claude/docs/conventions.md` | 항상 로드 (작게 유지) |
| API 스펙 / OpenAPI | `.claude/docs/api/` | 필요 시 grep |
| 스마트 컨트랙트, DB 스키마, proto, ddl | `.claude/docs/contracts/` | 필요 시 |
| 운영 가이드, 보안 플레이북, 인시던트 | `.claude/docs/runbooks/` | 필요 시 |
| 의사결정 기록 (ADR) | `.claude/docs/decisions/` | 필요 시 |
| 기획 초안 (작업 중) | `.claude/docs/specs/` | 작업 시 |
| 기타 큰 참조 자료 | `.claude/docs/reference/` | 필요 시 |

**원칙:**
- `architecture.md`, `conventions.md`는 **작고 핵심만** — 항상 컨텍스트에 로드되니까.
- 큰 레퍼런스(API 100K+, 보안 플레이북, ADR 등)는 카테고리 디렉토리에 배치 — 필요할 때만 읽기.
- 새 카테고리가 생기면 SessionStart 훅의 디렉토리 트리에 자동 반영됨.
DOC_FINDER

    # "## 세션 시작 시" 섹션 끝나는 지점 또는 파일 끝에 삽입
    if grep -q "## 세션 시작 시" "$RULES_FILE"; then
      # 첫 번째 "---" 구분선 뒤에 삽입
      awk -v doc_finder_file="$DOCFINDER_TMP" '
        BEGIN { inserted = 0 }
        /^## 세션 시작 시/ { in_session = 1 }
        in_session && /^---$/ && !inserted {
          while ((getline line < doc_finder_file) > 0) print line
          close(doc_finder_file)
          inserted = 1
          next
        }
        { print }
        END {
          if (!inserted) {
            while ((getline line < doc_finder_file) > 0) print line
            close(doc_finder_file)
          }
        }
      ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
        mv "$RULES_FILE.tmp" "$RULES_FILE"
    else
      cat "$DOCFINDER_TMP" >> "$RULES_FILE"
    fi
    rm -f "$DOCFINDER_TMP"
    APPENDED=1
  fi

  # 2-a. "아키텍처 변경 감지 시" 섹션 추가
  if ! grep -q "## 아키텍처 변경 감지 시" "$RULES_FILE"; then
    cat >> "$RULES_FILE" << 'ARCH_SECTION'

---

## 아키텍처 변경 감지 시

다음 중 하나라도 발생하면 update-architecture 워크플로우를 실행해 `architecture.md`를 갱신한다:

- 의존성 매니페스트 변경 (`package.json`, `go.mod`, `requirements.txt`, `Cargo.toml`, `pubspec.yaml` 등)
- 새 top-level 디렉토리 생성 (src/, app/, pkg/ 등의 바로 아래)
- 주요 설정 파일 추가/변경 (`tsconfig`, `*.config.*`, `Dockerfile` 등)
- 데이터 스키마 변경 (migration, `schema.prisma`, `*.proto`, `*.sql` 등)
- 외부 API / 서비스 통합 추가·제거

버그 수정, 리팩터링, 로직 변경만으로는 갱신하지 않는다.

**주 1회 정기 감사**: 세션 시작 출력에 "주간 아키텍처 감사 기한 경과" 신호가 보이면, 사용자의 첫 요청을 처리한 뒤 이 세션 안에서 update-architecture를 실행한다. 문서와 코드의 드리프트는 조용히 쌓이므로 신호를 무시하지 않는다.
ARCH_SECTION
    APPENDED=1
  fi

  # 2-b. 아키텍처 섹션은 있는데 주간 감사 규칙이 없는 구버전 → 규칙 줄 삽입
  if grep -q "## 아키텍처 변경 감지 시" "$RULES_FILE" && \
     ! grep -q "주 1회 정기 감사" "$RULES_FILE"; then
    awk '
      /버그 수정, 리팩터링, 로직 변경만으로는 갱신하지 않는다\./ && !done {
        print;
        print "";
        print "**주 1회 정기 감사**: 세션 시작 출력에 \"주간 아키텍처 감사 기한 경과\" 신호가 보이면, 사용자의 첫 요청을 처리한 뒤 이 세션 안에서 update-architecture를 실행한다. 문서와 코드의 드리프트는 조용히 쌓이므로 신호를 무시하지 않는다.";
        done=1;
        next
      }
      { print }
    ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
      mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: '주 1회 정기 감사' 규칙 추가"
    APPENDED=1
  fi

  # 2-b2. 핵심 규칙에 테스트·커밋 규칙 추가 (없으면 "## 핵심 규칙" 헤더 직후 삽입)
  if grep -q "^## 핵심 규칙" "$RULES_FILE" && \
     ! grep -q "구현 완료 선언 전 테스트" "$RULES_FILE"; then
    awk '
      /^## 핵심 규칙/ && !done {
        print; getline nl; print nl;
        print "- **구현 완료 선언 전 테스트**: 코드 로직을 바꿨으면 관련 테스트를 실행하고 결과를 보고한다. 테스트가 없는 프로젝트면 \"테스트 없음\"을 명시한다";
        print "- **완료 시 커밋 제안**: 작업 단위가 끝나면 커밋되지 않은 변경을 알리고 커밋을 제안한다 (커밋 여부는 사용자 결정)";
        done=1; next
      }
      { print }
    ' "$RULES_FILE" > "$RULES_FILE.tmp" && \
      mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "  정리: 핵심 규칙에 테스트·커밋 규칙 추가"
    APPENDED=1
  fi

  # 2-c. "탐색 사다리" 섹션 추가
  if ! grep -q "탐색 사다리" "$RULES_FILE"; then
    cat >> "$RULES_FILE" << 'LADDER_SECTION'

---

## 모를 때 — 탐색 사다리

추측하지 않는다. 아래 순서로 스스로 찾아본 뒤에도 남는 것만 사람에게 묻는다.

1. **코드 맵** — `architecture.md`의 코드 맵에서 위치 확인 → 해당 코드 직접 읽기
2. **프로젝트 문서** — `conventions.md`, `.claude/docs/` 카테고리 grep
3. **과거 기록** — `.claude/JOURNAL.md`, `git log --grep` (비슷한 결정이 이미 있었는지)
4. **외부 정보** — 라이브러리·API 스펙은 WebSearch로 공식 문서 확인
5. **사람** — 위를 다 거쳐도 남는 건 '사실'이 아니라 '결정'이다 → 질문 형식으로

**사실(코드·문서에 있는 것)은 찾아서 확인하고, 결정(정책·취향·범위)은 물어본다.**
LADDER_SECTION
    APPENDED=1
  fi

  # 2. "새 규칙 발견 시" 섹션 추가
  if ! grep -q "## 새 규칙 발견 시" "$RULES_FILE"; then
    cat >> "$RULES_FILE" << 'RULE_SECTION'

---

## 새 규칙 발견 시

사용자 지시나 프로젝트 분석에서 아래 패턴을 감지하면 **즉시 add-rule 워크플로우를 실행**해 `conventions.md`에 기록한다:

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
    echo "  업데이트: AGENTS.md (누락 섹션 추가)"
  else
    echo "  건너뜀: AGENTS.md (최신 상태)"
  fi
else
  if [ -n "$TEMPLATE_LOCAL" ]; then
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
      "$TEMPLATE_LOCAL/AGENTS.md.template" > "$RULES_FILE"
  else
    curl -sf "$TEMPLATE_REPO/AGENTS.md.template" | \
      sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" > "$RULES_FILE"
  fi
  echo "  생성: AGENTS.md"
fi

# CLAUDE.md — AGENTS.md를 import하는 얇은 진입점
if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
  if [ -n "$TEMPLATE_LOCAL" ]; then
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
      "$TEMPLATE_LOCAL/CLAUDE.md.template" > "$TARGET_DIR/CLAUDE.md"
  else
    curl -sf "$TEMPLATE_REPO/CLAUDE.md.template" | \
      sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" > "$TARGET_DIR/CLAUDE.md"
  fi
  echo "  생성: CLAUDE.md (AGENTS.md import)"
elif ! grep -q '@AGENTS\.md' "$TARGET_DIR/CLAUDE.md"; then
  # 사용자 커스텀 CLAUDE.md가 이미 있으면 import 한 줄만 앞에 붙인다
  {
    echo "@AGENTS.md"
    echo ""
    cat "$TARGET_DIR/CLAUDE.md"
  } > "$TARGET_DIR/CLAUDE.md.tmp" && mv "$TARGET_DIR/CLAUDE.md.tmp" "$TARGET_DIR/CLAUDE.md"
  echo "  업데이트: CLAUDE.md (@AGENTS.md import 추가)"
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

# JOURNAL.md — 이미 있으면 건너뜀
if [ -f "$TARGET_DIR/.claude/JOURNAL.md" ]; then
  echo "  건너뜀: .claude/JOURNAL.md"
else
  if [ -n "$TEMPLATE_LOCAL" ]; then
    cp "$TEMPLATE_LOCAL/JOURNAL.md.template" "$TARGET_DIR/.claude/JOURNAL.md"
  else
    curl -sf "$TEMPLATE_REPO/JOURNAL.md.template" -o "$TARGET_DIR/.claude/JOURNAL.md"
  fi
  echo "  생성: .claude/JOURNAL.md"
fi

# 주간 아키텍처 감사 타이머 시작점 (없으면 생성)
if [ ! -f "$TARGET_DIR/.claude/.last-arch-audit" ]; then
  touch "$TARGET_DIR/.claude/.last-arch-audit"
  echo "  생성: .claude/.last-arch-audit (주간 감사 타이머)"
fi

# 구버전 정리: PROGRESS.md 제거 (내용이 있으면 JOURNAL.md로 이관)
if [ -f "$TARGET_DIR/.claude/PROGRESS.md" ]; then
  # 헤더/빈 줄 제외한 실제 내용이 있는지 확인
  if grep -vE '^(#|\s*$)' "$TARGET_DIR/.claude/PROGRESS.md" | grep -q .; then
    {
      echo ""
      echo "## $TODAY (구 PROGRESS.md에서 이관)"
      grep -vE '^# Progress' "$TARGET_DIR/.claude/PROGRESS.md"
    } >> "$TARGET_DIR/.claude/JOURNAL.md"
    echo "  이관: .claude/PROGRESS.md → JOURNAL.md"
  fi
  rm -f "$TARGET_DIR/.claude/PROGRESS.md"
  echo "  제거: .claude/PROGRESS.md (구버전 — JOURNAL.md로 대체)"
fi

# [4/4] .gitignore
echo -e "${GREEN}[4/4] .gitignore 업데이트...${NC}"
GITIGNORE="$TARGET_DIR/.gitignore"
for entry in ".claude" ".codex" "CLAUDE.md" "AGENTS.md"; do
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
