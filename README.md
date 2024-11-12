# LLM Repo Digest 🤖

A simple shell script to concatenate your source code into a single file for Large Language Models (ChatGPT, Claude, etc.).

## Usage

1. Download `llm_repo_digest.sh` 
2. Place it in any directory containing your source code cloned from github. Place it in the root folder of the directory
3. Make it executable and run:
```bash
chmod +x llm_repo_digest.sh
./llm_repo_digest.sh
```

The script will create `reponame_repo_digest.txt` containing all relevant source code files.

## What it does

- Creates a single file with all your source code (ignoring libraries, binaries, etc.)
- Automatically excludes binary files, node_modules, environemnt files, typical libraries like fontawesome, bootstrap etc
- No need for python library or dependency etc. Runs directly from shell
- Works in both git repositories and regular directories


## System Requirements

- Tested on macOS
- Should work on Linux systems
- Requires `file` command
- Works with both git and non-git directories

## License

MIT - Feel free to use and modify!

---
*Made this because pasting individual files to ChatGPT was getting tedious* 😅
