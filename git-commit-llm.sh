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
                    Similar to 'git add -A'

DESCRIPTION:
    This script uses Claude AI to analyze your git changes and generate an appropriate
    commit message following standard Git commit message conventions.

WORKFLOW:
    1. Changes are analyzed and sent to Claude AI
    2. Generated commit message is saved to a temporary file
    3. Your \$EDITOR opens with the suggested message
    4. If you save and exit, the commit is created
    5. If you exit without saving (Ctrl+C), the commit is aborted

PROMPT:
    "Analyze this git diff and write a commit message following these rules:
    1. First line: concise summary in imperative mood (max 50 chars)
    2. If changes are minor, stop after the first line
    3. If changes are substantial:
       - Add a blank line
       - Add detailed explanation with line breaks at 72 chars
    4. Context: This change is on branch: [BRANCH_NAME]

    Focus on the 'what' and 'why' rather than the 'how'. Break convention only if it 
    significantly improves clarity."

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

ERROR HANDLING:
    - The script checks for a valid git repository before proceeding
    - Verifies changes exist before attempting to generate a commit
    - Validates \$EDITOR is set and executable
    - Ensures the LLM tool is available and properly configured
    - Handles API failures gracefully with informative error messages
    - Cleans up temporary files even if the script fails
    - Preserves git state if any step fails (no partial commits)

EXAMPLES:
    # Generate commit message for staged changes:
    git-commit-llm

    # Stage all changes and generate commit message:
    git-commit-llm --add-all

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
PROMPT="Analyze this git diff and generate a git commit message. Use one of these two formats:

FOR TRIVIAL CHANGES (e.g. typo fixes, small refactors, simple updates):
- Single line summary only
- Use imperative mood
- Maximum 50 characters
- Example: 'Fix typo in login error message'

FOR SUBSTANTIAL CHANGES (e.g. new features, breaking changes, complex refactors):
- First line: summary in imperative mood (max 50 chars)
- Blank line
- Detailed explanation with line breaks at 72 chars
- Example:
  Add user authentication system
  
  Implement JWT-based authentication with the following features:
  - Email/password login endpoint
  - Token refresh mechanism
  - Password reset flow
  - Rate limiting on auth endpoints

Context: This change is on branch: $BRANCH_NAME

IMPORTANT: Choose format based on change complexity - prefer single line for simple changes."

if ! git diff --cached | llm --model=claude-3-5-sonnet-20241022 "$PROMPT" > "$TEMP_FILE" 2>/dev/null; then
    error "Failed to generate commit message using LLM" 3
fi

# Check if file is empty
if [ ! -s "$TEMP_FILE" ]; then
    error "LLM generated an empty commit message" 3
fi

# Open editor for user to review/modify
$EDITOR "$TEMP_FILE" || error "Editor closed with an error" 4

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
