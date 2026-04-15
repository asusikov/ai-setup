#!/bin/bash

# Usage: ./fix_spec_after_review.sh <task_number>

TASK_NUMBER=${1:?"Usage: $0 <task_number>"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/prompts/fix-spec-after-review.md"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Error: Prompt file '$PROMPT_FILE' not found."
  exit 1
fi

PROMPT=$(sed "s/{{TASK_NUMBER}}/$TASK_NUMBER/g" "$PROMPT_FILE")

claude -p "$PROMPT" --allowedTools "Write,Edit" --model claude-opus-4-6
