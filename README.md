# git-commit-llm

A command-line tool that generates git commit messages by analyzing staged changes using Large Language Models.

## Features

- Generates single-line commit messages by default
- Optional detailed multi-line messages for major changes
- Branch context awareness for better message relevance
- Interactive message review in your editor before committing

## Options

- --major: Generate detailed multi-line commit messages
- --diff: Show staged changes before generating message
- --add-all: Stage all changes before commit
- --push: Push changes after committing
- --model: Select specific LLM model (default: claude-3-sonnet-20240229)

## Requirements

- git
- Text editor (set in $EDITOR)
- Python 3.7+
- llm CLI tool with configured API key

## Operation

1. Analyzes staged changes with git diff
2. Sends changes to LLM for analysis
3. Displays changes if --diff is enabled
4. Opens editor with generated message
5. Creates commit on save, aborts on exit
6. Pushes changes if --push is enabled

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
