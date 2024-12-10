#!/bin/bash

set -o pipefail

help_text() {
    cat << EOF
git-commit-llm - Generate commit messages using Claude AI

USAGE:
    git-commit-llm [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -a, --add-all   Stage all changes (including untracked files) before generating commit message
    -m, --major     Generate a detailed multi-line commit message for substantial changes

DESCRIPTION:
    This script uses Claude AI to analyze your git changes and generate an appropriate
    commit message. By default it creates concise single-line messages. Use --major
    for significant changes that require detailed explanation.

WORKFLOW:
    1. Changes are analyzed and sent to Claude AI
    2. Generated commit message is saved to a temporary file
    3. Your \$EDITOR opens with the suggested message
    4. Save the file to commit, exit without saving to abort

EXIT CODES:
    0   Success - commit was created
    1   No changes to commit (working directory clean)
    2   Not in a git repository
    3   LLM command failed or returned error
    4   User aborted commit (editor closed without saving)
    5   Git commit command failed
    6   \$EDITOR not set
    7   Failed to create or write temporary file
    8   Invalid command line arguments
    10  Unexpected error

EXAMPLES:
    # Generate simple commit message for staged changes:
    git-commit-llm

    # Stage all changes and generate detailed commit message:
    git-commit-llm --add-all --major

REQUIREMENTS:
    - llm command-line tool
    - git
    - Active git repository
    - \$EDITOR environment variable set
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
MAJOR=0
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
        -m|--major)
            MAJOR=1
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

# Set prompt based on commit type
if [ $MAJOR -eq 1 ]; then
    PROMPT="Write a detailed git commit message for this change on branch $BRANCH_NAME.
First line: imperative summary (max 50 chars)
Then blank line
Then detailed explanation with line breaks at 72 chars"
else
    PROMPT="Write a single-line git commit message for this change on branch $BRANCH_NAME.
Use imperative mood and maximum 50 characters."
fi

if ! git diff --cached | llm --model=claude-3-5-sonnet-20241022 "$PROMPT" > "$TEMP_FILE" 2>/dev/null; then
    error "Failed to generate commit message using LLM" 3
fi

# Get initial modification time
INITIAL_MTIME=$(stat -f %m "$TEMP_FILE" 2>/dev/null || stat -c %Y "$TEMP_FILE")

# Open editor for user to review/modify
$EDITOR "$TEMP_FILE" || error "Editor closed with an error" 4

# Get new modification time
NEW_MTIME=$(stat -f %m "$TEMP_FILE" 2>/dev/null || stat -c %Y "$TEMP_FILE")

# Check if file was saved
if [ "$INITIAL_MTIME" = "$NEW_MTIME" ]; then
    error "Commit message not saved in editor, aborting" 4
fi

# Check if file is empty or only contains comments
if [ ! -s "$TEMP_FILE" ] || ! grep -q '^[^#]' "$TEMP_FILE"; then
    error "Commit message empty or only contains comments, aborting" 4
fi

# Create the commit
if ! git commit -F "$TEMP_FILE"; then
    error "Failed to create commit" 5
fi

# Success!
echo "Successfully created commit"
exit 0