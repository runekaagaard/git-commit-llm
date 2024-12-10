# git-commit-llm

Generate git commit messages using Large Language Models to analyze your changes. Creates concise, consistent commit messages following git best practices.

## Features

- 🤖 AI-powered commit message generation based on your changes
- 📝 Two message styles:
  - Default: Concise single-line commits
  - Major mode (--major): Detailed multi-line messages for substantial changes
- 🛠️ Flexible workflow options:
  - Preview changes with --diff before generating message
  - Auto-stage all changes with --add-all
  - Automatic push after commit with --push
  - Custom LLM model selection with --model
- ✨ Smart features:
  - Branch context-aware messages
  - Interactive editor review before committing
  - Proper git conventions and formatting

## How It Works

1. Analyzes staged changes using `git diff`
2. Sends the diff to Claude AI with formatting instructions
3. Shows you the changes first if --diff is enabled
4. Opens your editor with the suggested message
5. Creates the commit when you save
6. Optionally pushes changes if --push is enabled

## Requirements

- git
- A text editor set in `$EDITOR`
- Python 3.7+
- An API key for your chosen LLM provider

## Installation

First install pipx:

```bash
# On Ubuntu/Debian
sudo apt update && sudo apt install pipx
pipx ensurepath

# On macOS
brew install pipx
pipx ensurepath

# On other systems with pip
python3 -m pip install --user pipx
python3 -m pipx ensurepath
```

Then install the llm CLI tool and Claude plugin:

```bash
pipx install llm
pipx inject llm llm-claude-3
```

Then install git-commit-llm:

```bash
# Download and install
curl -o /usr/local/bin/git-commit-llm https://raw.githubusercontent.com/runekaagaard/git-commit-llm/refs/heads/main/git-commit-llm
chmod +x /usr/local/bin/git-commit-llm
```

## Usage

### Basic Usage
```bash
# Generate commit message for staged changes
git-commit-llm

# Stage all changes and generate commit message
git-commit-llm --add-all

# Generate detailed message for major changes
git-commit-llm --major
```

### Options
```
-h, --help       Show help message
-a, --add-all    Stage all changes before generating commit message
-m, --major      Generate a detailed multi-line commit message
--model MODEL    Select LLM model (default: claude-3-sonnet-20240229)
--push          Push changes after committing
--diff          Display staged changes before generating commit message
```

### Workflow

1. Make your changes
2. (Optional) Stage changes with `git add` or use `--add-all`
3. Run `git-commit-llm`
4. Review the generated message in your editor
5. Save to commit, exit without saving to abort

## Examples

### Simple Change
```bash
$ git-commit-llm
# Opens editor with a message like:
Fix navigation styling in header component
```

### Major Change
```bash
$ git-commit-llm --major
# Opens editor with a message like:
Add user authentication system

Implement JWT-based authentication with the following features:
- Email/password login endpoint with rate limiting
- Secure token refresh mechanism
- Password reset flow with email verification
- Session management and logout endpoints
```

## Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

## License

Mozilla Public License Version 2.0
