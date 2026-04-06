#!/bin/bash
# Gemini API 호출 스크립트
# 사용법: echo "질문" | ./call-gemini.sh
# 환경변수: GEMINI_API_KEY

set -e

if [ -z "$GEMINI_API_KEY" ]; then
  echo "[ERROR] GEMINI_API_KEY 환경변수가 설정되지 않았습니다." >&2
  echo "export GEMINI_API_KEY=your_key_here" >&2
  exit 1
fi

INPUT=$(cat)

if [ -z "$INPUT" ]; then
  echo "[ERROR] 질문 내용이 없습니다. stdin으로 입력해주세요." >&2
  exit 1
fi

MODEL="${GEMINI_MODEL:-gemini-2.5-pro}"

RESPONSE=$(curl -s \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"contents\": [{
      \"parts\": [{
        \"text\": $(echo "$INPUT" | jq -Rs .)
      }]
    }],
    \"generationConfig\": {
      \"temperature\": 0.2,
      \"maxOutputTokens\": 8192
    }
  }")

# 에러 응답 확인
ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty' 2>/dev/null)
if [ -n "$ERROR" ]; then
  echo "[Gemini API Error] $ERROR" >&2
  exit 1
fi

# 결과 추출
echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // "[응답 없음]"'
