# Dotfiles

Reference for this shell setup. If you're an agent helping a user adopt this structure, see [migrate.md](migrate.md).

## Philosophy

Config is split into two layers:

- **`~/dotfiles/`** — Portable universals. Works on every machine, tracked in git. Aliases, functions, environment defaults, and the git worktree workflow live here. This repo.
- **`~/.files/`** — Machine-specific config. Credentials, local PATHs, tool-specific init. Not tracked in git — each machine gets its own.

Workspaces follow the same principle:

- **`~/code/<repo>`** — Stable clones. Always on main/master. Used for builds, devenv, containers, and as the anchor for worktrees.
- **`~/dev/<repo>--<branch>`** — Ephemeral git worktrees. One per feature branch, created via `gwt`, cleaned via `gwt_clean`. Disposable once the branch merges.

Nothing machine-specific goes in `~/dotfiles/`. Nothing secret goes in git.

## How it wires together

The shell entry point (`~/.zshrc` or `~/.bash_profile`) sources four files from this repo:

```
~/.zshrc (or ~/.bash_profile)
  └── source ~/dotfiles/shell/env.sh          ← portable env + auto-sources ~/.files/env.sh and ~/.files/creds.sh
  └── source ~/dotfiles/shell/aliases.sh      ← portable aliases
  └── source ~/dotfiles/shell/functions.sh    ← git workflow, utilities
  └── source ~/dotfiles/shell/zsh/init.zsh   ← shell-specific prompt, completions, sources ~/.files/init.zsh
```

`env.sh` automatically sources `~/.files/env.sh` and `~/.files/creds.sh` if they exist. The shell-specific init files (`init.zsh`/`init.bash`) source `~/.files/init.{zsh,bash}` if they exist. You never need to reference `~/.files/` directly in your shell entry point.

## `~/.files/` structure

| File | Purpose |
|------|---------|
| `creds.sh` | API keys, tokens, passwords. Never commit this. |
| `env.sh` | Machine-local PATHs, tool init (Homebrew, NVM, Python, etc.) |
| `init.bash` | Machine-specific bash init (completions, integrations) |
| `init.zsh` | Machine-specific zsh init (completions, integrations) |

## Directory conventions

| Path | Purpose |
|------|---------|
| `~/dotfiles/` | This repo. Portable across machines. |
| `~/.files/` | Machine-specific config. Not in git. |
| `~/code/<repo>` | Stable git clones, always on main/master. |
| `~/dev/<repo>--<branch>` | Ephemeral git worktrees. |

## Key commands

| Command | Description |
|---------|-------------|
| `gwt <branch> [base]` | Create worktree in `~/dev/` or cd if exists |
| `gwt_clean [-n] [-f]` | Remove worktrees whose remote branch is gone |
| `gitmp` | Go to `~/code/<repo>`, checkout main/master, pull |
| `gitc <branch>` | Go to `~/code/<repo>`, checkout branch |
| `gitf` | `git fetch --all --prune` |
| `gitmm` | Fetch + merge primary branch |
| `devlink` | Symlink `~/code/<repo>` to current worktree |
| `devunlink` | Restore original clone from symlink |
| `prelint` | Run pre-commit on all files |
| `reload` | Re-source shell config |
