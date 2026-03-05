new machine: dump setup.md into claude or codex

migrating an existing machine: dump migrate.md into claude or codex

## Directory conventions

This is the philosophy implemented:

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
