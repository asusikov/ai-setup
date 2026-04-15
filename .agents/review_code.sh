#!/bin/bash

# Usage: ./review_code.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/prompts/review-code.md"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Error: Prompt file '$PROMPT_FILE' not found."
  exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

claude --permission-mode plan --model claude-opus-4-6 "$PROMPT"
