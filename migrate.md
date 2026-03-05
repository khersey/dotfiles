# Migration Guide

How to adopt this dotfiles structure on a machine with an existing shell setup. Written for an AI agent assisting a user.

**Assumptions:** This repo is already cloned at `~/dotfiles`. The user has an existing shell config that works. The goal is to restructure into the two-layer model (see [setup.md](setup.md)) without breaking anything.

**Guiding principles:**
- Never delete config without backing it up first
- Never write credentials to a file in a git repo or to stdout/logs
- Build `~/.files/` *before* replacing the shell entry point — the new config depends on it
- Verify the new shell works before cleaning up backups

## 1. Create directory structure

```sh
mkdir -p ~/code ~/dev ~/.files
```

## 2. Detect the user's shell

```sh
basename "$SHELL"
# "zsh" → entry point is ~/.zshrc
# "bash" → entry point is ~/.bash_profile
```

Read the entry point file. Also read `~/.bashrc`, `~/.profile`, and `~/.bash_profile` if they exist — users often have config scattered across several of these.

## 3. Audit existing config

Read every shell config file and classify each block into one of four categories:

| Category | Destination | How to identify |
|----------|-------------|-----------------|
| **Credentials** | `~/.files/creds.sh` | `export` lines containing API keys, tokens, passwords, secrets. Look for variable names containing `KEY`, `TOKEN`, `SECRET`, `PASSWORD`, `CREDENTIAL`, or values starting with `sk-`, `ghp_`, `xoxb-`, bearer tokens, etc. |
| **Machine-local env** | `~/.files/env.sh` | PATH modifications, tool init (`eval "$(brew shellenv)"`, NVM loading, pyenv, rbenv), `JAVA_HOME`, `ANDROID_HOME`, and similar. Anything that references paths specific to this machine's installed software. |
| **Machine-local shell init** | `~/.files/init.{bash,zsh}` | Completions, integrations (OrbStack, etc.), shell options that are specific to this machine or this shell. |
| **Already provided** | Nowhere — skip it | Aliases and functions that overlap with `~/dotfiles/shell/aliases.sh` or `~/dotfiles/shell/functions.sh`. Compare before migrating. Common overlaps: `ll`, `..`, `extract`, prompt config, `CLICOLOR`. |

If a block doesn't fit any category, it's likely a custom alias or function. Ask the user whether it belongs in `~/dotfiles/` (portable) or `~/.files/` (machine-specific).

### Security: handling credentials

**Do not** echo, log, or write credential values to stdout or any file inside a git repo. When building `~/.files/creds.sh`:

1. Identify credential lines in the existing config
2. Write them directly to `~/.files/creds.sh` (which is outside any git repo)
3. Confirm `~/.files/` is not inside a git worktree: `git -C ~/.files rev-parse 2>/dev/null` should fail
4. If the user's existing config is in a git repo (e.g. their own dotfiles repo), flag any credentials found there — they may need to rotate those secrets since they were previously committed

## 4. Build `~/.files/`

Create the files in this order. Each file should be created and populated *before* the shell entry point is replaced, because `~/dotfiles/shell/env.sh` will source `~/.files/env.sh` and `~/.files/creds.sh` automatically, and the shell-specific init files will source `~/.files/init.{bash,zsh}`.

### `~/.files/creds.sh`

Extract all credential exports from the user's existing shell config:

```sh
# Example structure — actual values come from the user's config
export ANTHROPIC_API_KEY="..."
export OPENAI_API_KEY="..."
export AWS_ACCESS_KEY_ID="..."
```

Set permissions immediately after creation:

```sh
chmod 600 ~/.files/creds.sh
```

### `~/.files/env.sh`

Extract all machine-local PATH modifications and tool initialization:

```sh
# Example structure
eval "$(/opt/homebrew/bin/brew shellenv)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export PATH="$HOME/Library/Python/3.12/bin:$PATH"
```

**Do not include** anything already set in `~/dotfiles/shell/env.sh` (`CLICOLOR`, `~/.local/bin`, `~/.bin`).

### `~/.files/init.bash` and/or `~/.files/init.zsh`

Extract machine-specific shell init (completions, tool integrations) based on which shell(s) the user runs:

```sh
# Example — bash
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
source ~/.orbstack/shell/init.bash 2>/dev/null || :
```

```sh
# Example — zsh
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
```

## 5. Wire up the shell entry point

Back up first, then replace.

### If zsh:

```sh
cp ~/.zshrc ~/.zshrc.bak 2>/dev/null
cat > ~/.zshrc << 'EOF'
source "$HOME/dotfiles/shell/env.sh"
source "$HOME/dotfiles/shell/aliases.sh"
source "$HOME/dotfiles/shell/functions.sh"
source "$HOME/dotfiles/shell/zsh/init.zsh"
EOF
```

### If bash:

```sh
cp ~/.bash_profile ~/.bash_profile.bak 2>/dev/null
cat > ~/.bash_profile << 'EOF'
source "$HOME/dotfiles/shell/env.sh"
source "$HOME/dotfiles/shell/aliases.sh"
source "$HOME/dotfiles/shell/functions.sh"
source "$HOME/dotfiles/shell/bash/init.bash"
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
EOF
```

The entry point is `~/.bash_profile` because macOS Terminal opens login shells, which skip `~/.bashrc`. The last line chains to `~/.bashrc` so non-login shells (tmux panes, etc.) also work.

If the user wants to switch to zsh: `chsh -s /bin/zsh`, then use the zsh entry point.

## 6. Verify

Open a **new** shell (don't just `source` — a fresh shell tests the full init chain).

```sh
# Confirm dotfiles loaded
type gwt          # should show function definition
type prelint      # should show function definition

# Confirm machine-specific env loaded
echo $PATH        # should include Homebrew, NVM, etc.

# Confirm credentials loaded (check existence, not value)
[ -n "$ANTHROPIC_API_KEY" ] && echo "creds ok" || echo "creds MISSING"

# Test a command that depends on PATH (e.g. node, python, brew)
which node        # or whatever the user had before
```

If anything is missing, compare `~/.zshrc.bak` (or `~/.bash_profile.bak`) against the new `~/.files/` files to find what was dropped.

## 7. Migrate repos (optional)

If the user wants to adopt the `~/code/` + `~/dev/` workspace convention:

```sh
# Move existing clones into ~/code/
mv ~/projects/my-app ~/code/my-app
mv ~/projects/my-lib ~/code/my-lib
```

For repos currently on a feature branch, switch back to main/master and create a worktree:

```sh
cd ~/code/my-app
git checkout main
git pull
gwt my-feature-branch
```

Result:

```
~/code/my-app/                        # on main
~/dev/my-app--my-feature-branch/      # worktree
```

## 8. Cleanup

Only after verification succeeds and the user has worked in the new setup for at least one session:

```sh
rm ~/.zshrc.bak ~/.bash_profile.bak ~/.bashrc.bak 2>/dev/null
```

Do **not** delete backup files automatically. Ask the user first.
