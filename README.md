# git-commit-llm

Generate git commit messages using LLMs by analyzing your staged changes.

## Requirements

- git
- Text editor (set in `$EDITOR`)
- llm CLI tool with API key

## Installation

Install dependencies:
```bash
# Install llm CLI tool
pipx install llm
pipx inject llm llm-claude-3
```

Install git-commit-llm:
```bash
curl -o /usr/local/bin/git-commit-llm https://raw.githubusercontent.com/runekaagaard/git-commit-llm/refs/heads/main/git-commit-llm
chmod +x /usr/local/bin/git-commit-llm
```

## Usage

Basic usage:
```bash
# Generate commit message for staged changes
git-commit-llm

# Stage all changes and generate message
git-commit-llm --stage-all

# Generate detailed message for major changes
git-commit-llm --major
```

Available options:
```
-h, --help          Show help message
-s, --stage-all     Stage all changes first
-m, --major         Generate detailed multi-line message
-o, --model MODEL   Select LLM model (default: claude-3-sonnet-20240229)
-p, --push          Push changes after committing
-d, --diff          Show staged changes first
```

## How it works

1. Analyzes your staged changes
2. Generates a commit message using an LLM
3. Opens your editor to review/modify
4. Creates commit on save, aborts on exit
5. Optionally pushes changes

## DWIM (Do What I Mean)

For the most common workflow of staging all changes, generating a commit message, and pushing, add this alias to your `.bashrc` or `.zshrc`:

```bash
alias gcl="git-commit-llm -sdp"
```

Now you can simply run `gcl` to:
1. Stage all changes (-s)
2. Generate a commit message
3. Push after committing (-p)

## License

Mozilla Public License Version 2.0
