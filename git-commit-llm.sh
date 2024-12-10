#!/bin/bash

set -o pipefail

help_text() {
    cat << EOF
[Previous help text remains the same...]
EOF
}

error() {
    echo "Error: $1" >&2
    exit "$2"
}

cleanup() {
    if [ -f "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
    fi
}

# Set up trap for cleanup
trap cleanup EXIT

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "Not in a git repository" 2
fi

# Parse arguments
ADD_ALL=0
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            help_text
            exit 0
            ;;
        -a|--add-all)
            ADD_ALL=1
            shift
            ;;
        *)
            error "Invalid argument: $1" 8
            ;;
    esac
done

# Check for EDITOR
if [ -z "$EDITOR" ]; then
    error "\$EDITOR environment variable is not set" 6
fi

# Check if llm command is available
if ! command -v llm >/dev/null 2>&1; then
    error "llm command not found. Please install it first" 3
fi

# Add all changes if requested
if [ $ADD_ALL -eq 1 ]; then
    git add -A
fi

# Check if there are any changes to commit
if git diff --cached --quiet; then
    error "No changes staged for commit" 1
fi

# Get current branch name
BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached HEAD")

# Create temporary file
TEMP_FILE=$(mktemp /tmp/git-commit-llm.XXXXXX) || error "Failed to create temporary file" 7

# Generate commit message using Claude
PROMPT="Analyze this git diff and write a commit message following these rules:
1. First line: concise summary in imperative mood (max 50 chars)
2. If changes are minor, stop after the first line
3. If changes are substantial:
   - Add a blank line
   - Add detailed explanation with line breaks at 72 chars
4. Context: This change is on branch: $BRANCH_NAME

Focus on the 'what' and 'why' rather than the 'how'. Break convention only if it 
significantly improves clarity."

if ! git diff --cached | llm --model=claude-3-5-sonnet-20241022 "$PROMPT" > "$TEMP_FILE" 2>/dev/null; then
    error "Failed to generate commit message using LLM" 3
fi

# Check if file is empty
if [ ! -s "$TEMP_FILE" ]; then
    error "LLM generated an empty commit message" 3
fi

# Open editor for user to review/modify
if ! $EDITOR "$TEMP_FILE"; then
    error "Editor closed without saving" 4
fi

# Check if file was modified and saved
if [ ! -s "$TEMP_FILE" ]; then
    error "Empty commit message, aborting" 4
fi

# Create the commit
if ! git commit -F "$TEMP_FILE"; then
    error "Failed to create commit" 5
fi

# Success!
echo "Successfully created commit"
exit 0
