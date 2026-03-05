# Portable shell functions — git workflow + utilities
# Works in both bash and zsh

# ============================================================
# Repo/branch detection helpers
# ============================================================

_repo_name() {
  local cwd="$PWD"
  case "$cwd" in
    "$HOME/dev/"*)
      local remainder="${cwd#$HOME/dev/}"
      local top="${remainder%%/*}"
      printf '%s\n' "${top%%--*}"
      ;;
    "$HOME/code/"*|"$HOME/Code/"*)
      local remainder="${cwd#$HOME/}"
      remainder="${remainder#[Cc]ode/}"
      printf '%s\n' "${remainder%%/*}"
      ;;
    *)
      local toplevel
      toplevel="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
      basename "$toplevel"
      ;;
  esac
}

_primary_branch() {
  local primary
  primary="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^.*/@@')"
  if [ -z "$primary" ]; then
    if git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
      primary="main"
    else
      primary="master"
    fi
  fi
  printf '%s\n' "$primary"
}

# ============================================================
# Git workflow
# ============================================================

gwt() {
  local branch="${1:?Usage: gwt <branch> [source_branch]}"
  local source_branch="$2"
  local repo
  repo="$(_repo_name)" || { echo "Not in a recognized repo directory" >&2; return 1; }

  local source_dir="$HOME/code/$repo"
  if [ -L "$source_dir" ]; then
    echo "$repo is devlinked; run devunlink first" >&2
    return 1
  fi
  if [ ! -d "$source_dir/.git" ]; then
    echo "Source repo not found: $source_dir" >&2
    return 1
  fi

  local folder_name="${branch//\//-}"
  local worktree_dir="$HOME/dev/${repo}--${folder_name}"

  # If worktree directory exists, just cd into it
  if [ -d "$worktree_dir" ]; then
    cd "$worktree_dir" || return 1
    return
  fi

  # Resolve source branch
  if [ -z "$source_branch" ]; then
    source_branch="$(builtin cd "$source_dir" && _primary_branch)"
  fi

  git -C "$source_dir" fetch --all --prune

  [ -d "$HOME/dev" ] || command mkdir -p "$HOME/dev"

  # If the branch is currently checked out in ~/code/<repo>, free it up
  local current_branch
  current_branch="$(git -C "$source_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  if [ "$current_branch" = "$branch" ]; then
    # Push if there are unpushed commits
    local unpushed
    unpushed="$(git -C "$source_dir" log --oneline "origin/$branch..$branch" 2>/dev/null)"
    if [ -n "$unpushed" ]; then
      echo "Pushing unpushed commits on $branch..."
      git -C "$source_dir" push || { echo "Push failed; resolve before creating worktree" >&2; return 1; }
    fi
    local primary
    primary="$(builtin cd "$source_dir" && _primary_branch)"
    echo "Switching ~/code/$repo from $branch to $primary"
    git -C "$source_dir" checkout "$primary"
  fi

  if git -C "$source_dir" show-ref --verify --quiet "refs/heads/$branch" ||
     git -C "$source_dir" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git -C "$source_dir" worktree add "$worktree_dir" "$branch"
  else
    git -C "$source_dir" worktree add "$worktree_dir" -b "$branch" "$source_branch"
  fi

  # Copy peon-ping config from source repo if it exists
  local peon_src="$source_dir/.claude/hooks/peon-ping"
  if [ -d "$peon_src" ]; then
    command mkdir -p "$worktree_dir/.claude/hooks/peon-ping"
    command cp "$peon_src/config.json" "$worktree_dir/.claude/hooks/peon-ping/" 2>/dev/null
  fi

  cd "$worktree_dir" || return 1
}

devlink() {
  local cwd="$PWD"
  case "$cwd" in
    "$HOME/dev/"*) ;;
    *)
      local resolved
      resolved="$(builtin cd -P . 2>/dev/null && pwd)"
      case "$resolved" in
        "$HOME/dev/"*) ;;
        *) echo "Must be called from a worktree in ~/dev/" >&2; return 1 ;;
      esac
      ;;
  esac

  local repo
  repo="$(_repo_name)" || { echo "Cannot determine repo" >&2; return 1; }
  local code_path="$HOME/code/$repo"

  # Idempotent: already linked
  if [ -L "$code_path" ]; then
    echo "Already linked: $code_path -> $(readlink "$code_path")"
    return
  fi

  local wt_root
  wt_root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not in a git worktree" >&2; return 1; }
  local stashed="$HOME/code/.$repo.stashed"
  local git_file="$wt_root/.git"

  # Stash the clone
  command mv "$code_path" "$stashed"

  # Fix worktree .git reference to point to stashed location
  if [ -f "$git_file" ]; then
    sed "s|$code_path/|$stashed/|g" "$git_file" > "$git_file.tmp" && command mv "$git_file.tmp" "$git_file"
  fi

  ln -s "$wt_root" "$code_path"
  echo "Linked: $code_path -> $wt_root"
}

devunlink() {
  local repo
  repo="$(_repo_name)" || { echo "Cannot determine repo" >&2; return 1; }

  local code_path="$HOME/code/$repo"
  local stashed="$HOME/code/.$repo.stashed"

  if [ ! -L "$code_path" ]; then
    echo "Not linked: $code_path is not a symlink"
    return
  fi

  if [ ! -d "$stashed" ]; then
    echo "No stashed repo found at $stashed" >&2
    return 1
  fi

  local wt_root
  wt_root="$(readlink "$code_path")"
  local git_file="$wt_root/.git"

  rm "$code_path"
  command mv "$stashed" "$code_path"

  # Fix worktree .git reference back to restored location
  if [ -f "$git_file" ]; then
    sed "s|$stashed/|$code_path/|g" "$git_file" > "$git_file.tmp" && command mv "$git_file.tmp" "$git_file"
  fi

  echo "Unlinked: $code_path restored"
}

gitmp() {
  local repo
  repo="$(_repo_name)" || { echo "Not in a recognized repo directory" >&2; return 1; }

  local repo_dir="$HOME/code/$repo"
  if [ -L "$repo_dir" ]; then
    echo "$repo is devlinked; run devunlink first" >&2
    return 1
  fi
  if [ ! -d "$repo_dir/.git" ]; then
    echo "Repo not found: $repo_dir" >&2
    return 1
  fi

  cd "$repo_dir" || return 1
  local primary
  primary="$(_primary_branch)"
  git checkout "$primary"
  git pull
}

gitc() {
  local branch="${1:?Usage: gitc <branch>}"
  local repo
  repo="$(_repo_name)" || { echo "Not in a recognized repo directory" >&2; return 1; }

  local repo_dir="$HOME/code/$repo"
  if [ -L "$repo_dir" ]; then
    echo "$repo is devlinked; run devunlink first" >&2
    return 1
  fi
  if [ ! -d "$repo_dir/.git" ]; then
    echo "Repo not found: $repo_dir" >&2
    return 1
  fi

  cd "$repo_dir" || return 1
  git checkout "$branch"
}

gitf() {
  git fetch --all --prune
}

gitmm() {
  git fetch --all --prune
  local primary
  primary="$(_primary_branch)"
  git merge "origin/$primary"
}

tagfp() {
  git tag -f "$1"
  git push -f origin "$1"
}

gwt_clean() {
  local dry_run=false force=false
  while [ $# -gt 0 ]; do
    case "$1" in
      -n|--dry-run) dry_run=true ;;
      -f|--force) force=true ;;
      *) echo "Usage: gwt_clean [-n|--dry-run] [-f|--force]" >&2; return 1 ;;
    esac
    shift
  done

  local original_dir="$PWD"

  for wt_dir in "$HOME/dev/"*--*; do
    [ -d "$wt_dir" ] || continue

    local dir_name
    dir_name="$(basename "$wt_dir")"
    local repo="${dir_name%%--*}"
    local source_dir="$HOME/code/$repo"

    [ -d "$source_dir/.git" ] || continue

    local branch
    branch="$(git -C "$wt_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    [ -z "$branch" ] || [ "$branch" = "HEAD" ] && continue

    # Skip if branch still exists on remote
    git -C "$source_dir" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 && continue

    if $dry_run; then
      echo "[DRY-RUN] Would remove: $wt_dir ($branch)"
      continue
    fi

    if ! $force && [ -n "$(git -C "$wt_dir" status --porcelain 2>/dev/null)" ]; then
      echo "Skipping $wt_dir (dirty, use -f to force)" >&2
      continue
    fi

    echo "Removing: $wt_dir ($branch)"
    git -C "$source_dir" worktree remove ${force:+--force} "$wt_dir"
  done

  if [ ! -d "$original_dir" ]; then
    cd "$HOME/code" || cd "$HOME"
    echo "Original directory removed; now in $PWD"
  fi
}

# ============================================================
# Utility functions
# ============================================================

prelint() {
  uv run pre-commit run --all-files
}

aws_sso() {
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    aws sso login
  fi
}

tf() {
  # replace with gcp or azure oauth or whatever you use here:
  aws_sso
  # add any env variables here required to run tf here:
  # MY_ENV_VAR = THIS \
  terraform "$@"
}

cafe() {
  caffeinate -d
}

lilpeon() {
  local pack="${1:-}"
  local target_root="${2:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  local peon_dir="${CLAUDE_PEON_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/peon-ping}"
  local global_cfg="$peon_dir/config.json"
  local local_dir="$target_root/.claude/hooks/peon-ping"
  local local_cfg="$local_dir/config.json"

  local packs_dir="$HOME/.openpeon/packs"
  [ -d "$packs_dir" ] || packs_dir="$peon_dir/packs"

  if [ -z "$pack" ]; then
    echo "Usage: lilpeon <pack> [repo_or_worktree_path]" >&2
    return 1
  fi

  if [ ! -f "$global_cfg" ]; then
    echo "Global peon config not found: $global_cfg" >&2
    return 1
  fi

  if [ ! -d "$packs_dir/$pack" ]; then
    echo "Pack '$pack' not found in: $packs_dir" >&2
    echo "Installed packs:" >&2
    find "$packs_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort >&2
    return 1
  fi

  mkdir -p "$local_dir"
  cp "$global_cfg" "$local_cfg"

  python3 - "$local_cfg" "$pack" <<'PY'
import json, sys
cfg_path, pack = sys.argv[1], sys.argv[2]
with open(cfg_path) as f:
  cfg = json.load(f)
  cfg["active_pack"] = pack
  with open(cfg_path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PY

  echo "Wrote local config: $local_cfg"
  echo "Set active_pack: $pack"
}
