#!/usr/bin/env bash
# Stop 훅: 세션이 끝날 때마다 transcript를 요약해 Notion "AI질문" DB에 upsert한다.
# CLAUDE_NOTION_HOOK_ACTIVE가 이미 설정돼 있으면 (=이 스크립트가 띄운 하위 claude -p 세션 자신의
# Stop 이벤트) 즉시 종료해 재귀 실행을 막는다.
set -uo pipefail

if [ -n "${CLAUDE_NOTION_HOOK_ACTIVE:-}" ]; then
  exit 0
fi

payload="$(cat)"

read_field() {
  node -e "let d=JSON.parse(require('fs').readFileSync(0,'utf8'));process.stdout.write(d.$1||'')" <<< "$payload"
}

transcript_path="$(read_field transcript_path)"
session_id="$(read_field session_id)"

if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  exit 0
fi

LOG_FILE="$HOME/.claude/notion-log-hook.log"
mkdir -p "$(dirname "$LOG_FILE")"

# 원격/클라우드 실행 환경(claude.ai 웹·데스크탑 앱이 띄우는 컨테이너)은 전부 root로 돌고,
# Claude Code는 root에서 --dangerously-skip-permissions / --permission-mode bypassPermissions를
# 보안상 거부한다(둘 다 실측 확인됨). 이 하위 claude -p는 사람이 없는 무인 실행이라 그 승인을
# 대신 받아줄 방법이 없고, notion-create-pages 등 쓰기 도구 호출이 "MCP tool call requires
# approval"로 영원히 막힌다 — 즉 이 환경에서는 구조적으로 성공할 수 없다. 매 턴마다 헛되이
# 하위 세션을 띄워 리소스만 쓰지 않도록, 원격 환경이면 여기서 조용히 종료한다.
# 로컬 PC(claude.ai 데스크탑/터미널)는 root로 돌지 않고 이 env var 자체가 없으므로 영향 없음.
if [ -n "${CLAUDE_CODE_REMOTE_SESSION_ID:-}" ]; then
  exit 0
fi

PROMPT="다음은 방금 끝난(또는 계속 이어지고 있는) Claude Code 세션의 transcript(JSONL) 파일 경로다: ${transcript_path}
세션 ID: ${session_id}

1. Read 도구로 이 파일을 읽어라. 파일이 길면 offset을 늘려가며 끝까지 읽어라.
2. 사용자가 실질적으로 질문하거나 요청한 내용이 전혀 없는 세션(빈 세션, 단순 점검성 호출 등)이면 아무 것도 하지 말고 그대로 종료해라.
3. 실질적인 대화가 있으면, Notion 데이터 소스 collection://3b46959a-9e25-808e-bb60-000bbab8cf7f (\"AI질문\" 데이터베이스, 상위 페이지 https://app.notion.com/p/3b46959a9e2580fa99a1cd647cebc8a5) 에서 본문에 '세션 ID: ${session_id}'가 포함된 기존 페이지를 notion-query-data-sources로 찾아라.
4. 기존 페이지가 있으면 이번 세션 전체 내용 기준으로 본문을 다시 요약해 update하고, 없으면 새로 생성해라.
   - 이름(제목): 세션 주제를 한 줄로 요약 (한국어)
   - 날짜: 오늘 날짜
   - AI 질문 유무: __YES__ (체크)
   - 사람: 2c9d872b-594c-8172-ae98-000280d3dca0 (최정태)
   - 본문: 질문/답변 핵심 요약 (질문-답변 쌍 형식), 맨 끝 줄에 정확히 '세션 ID: ${session_id}' 를 그대로 텍스트로 남겨라 (다음 실행에서 검색용으로 필요, 지우거나 바꾸지 마라).
다른 설명이나 확인 질문 없이 위 작업만 수행하고 끝내라."

# 여기 도달했다는 건 원격 환경이 아니라는 뜻이다(원격이면 위에서 이미 종료).
# claude_ai_Notion 별칭은 로컬 PC에서 실측 확인된 이름, Notion은 혹시 모를 다른 별칭에 대한 대비.
CLAUDE_NOTION_HOOK_ACTIVE=1 claude -p "$PROMPT" \
  --allowedTools "Read mcp__claude_ai_Notion__notion-fetch mcp__claude_ai_Notion__notion-search mcp__claude_ai_Notion__notion-query-data-sources mcp__claude_ai_Notion__notion-create-pages mcp__claude_ai_Notion__notion-update-page mcp__Notion__notion-fetch mcp__Notion__notion-search mcp__Notion__notion-query-data-sources mcp__Notion__notion-create-pages mcp__Notion__notion-update-page" \
  --output-format text \
  >> "$LOG_FILE" 2>&1

exit 0