# Zsh-specific init — prompt, completions, settings

# Prompt: cyan user, green host, yellow path, red $
PROMPT='%F{cyan}%n%f@%F{green}%m%f:%F{yellow}%~%f%F{red}$%f '

# Completion system
autoload -Uz compinit && compinit

# Zsh-only aliases
alias reload='source ~/.zshrc'
alias show_options='setopt'

# Case-insensitive tab completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Don't error on unmatched globs (matches bash behavior)
setopt NO_NOMATCH

# gwt completion — branch names from ~/code/<repo>
_gwt() {
  local repo
  repo="$(_repo_name 2>/dev/null)" || return
  local source_dir="$HOME/code/$repo"
  [ -d "$source_dir/.git" ] || return
  local -a branches
  branches=( ${(f)"$(git -C "$source_dir" branch -a 2>/dev/null | sed 's/^[* ]*//' | sed 's|remotes/origin/||' | sort -u)"} )
  _describe 'branch' branches
}
compdef _gwt gwt

# gitc completion — same branch list
_gitc() {
  local repo
  repo="$(_repo_name 2>/dev/null)" || return
  local source_dir="$HOME/code/$repo"
  [ -d "$source_dir/.git" ] || return
  local -a branches
  branches=( ${(f)"$(git -C "$source_dir" branch -a 2>/dev/null | sed 's/^[* ]*//' | sed 's|remotes/origin/||' | sort -u)"} )
  _describe 'branch' branches
}
compdef _gitc gitc

# Source machine-specific zsh init (OrbStack, etc.)
[ -f "$HOME/.files/init.zsh" ] && source "$HOME/.files/init.zsh"
