#!/bin/bash
# OpenAI (Codex) API 호출 스크립트
# 사용법: echo "질문" | ./call-codex.sh
# 환경변수: OPENAI_API_KEY (필수), OPENAI_MODEL (선택, 기본 gpt-5-codex)

set -e

if [ -z "$OPENAI_API_KEY" ]; then
  echo "[ERROR] OPENAI_API_KEY 환경변수가 설정되지 않았습니다." >&2
  echo "export OPENAI_API_KEY=your_key_here" >&2
  exit 1
fi

INPUT=$(cat)

if [ -z "$INPUT" ]; then
  echo "[ERROR] 질문 내용이 없습니다. stdin으로 입력해주세요." >&2
  exit 1
fi

MODEL="${OPENAI_MODEL:-gpt-5-codex}"

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -d "{
    \"model\": \"${MODEL}\",
    \"messages\": [{
      \"role\": \"user\",
      \"content\": $(echo "$INPUT" | jq -Rs .)
    }],
    \"temperature\": 0.2
  }")

# 에러 응답 확인
ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty' 2>/dev/null)
if [ -n "$ERROR" ]; then
  echo "[OpenAI API Error] $ERROR" >&2
  exit 1
fi

# 결과 추출
echo "$RESPONSE" | jq -r '.choices[0].message.content // "[응답 없음]"'
