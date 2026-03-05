# Bash-specific init — prompt, completions, settings

# Prompt: cyan user, green host, yellow path, red $
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\[\033[01;31m\]\$\[\033[00m\] "

# Bash-only aliases
alias reload='source ~/.bash_profile'
alias show_options='shopt'
alias cic='set completion-ignore-case On'

# gwt completion — branch names from ~/code/<repo>
_gwt_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local repo
  repo="$(_repo_name 2>/dev/null)" || return
  local source_dir="$HOME/code/$repo"
  [ -d "$source_dir/.git" ] || return
  local branches
  branches="$(git -C "$source_dir" branch -a 2>/dev/null | sed 's/^[* ]*//' | sed 's|remotes/origin/||' | sort -u)"
  COMPREPLY=($(compgen -W "$branches" -- "$cur"))
}
complete -F _gwt_completions gwt

# gitc completion — same branch list
_gitc_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local repo
  repo="$(_repo_name 2>/dev/null)" || return
  local source_dir="$HOME/code/$repo"
  [ -d "$source_dir/.git" ] || return
  local branches
  branches="$(git -C "$source_dir" branch -a 2>/dev/null | sed 's/^[* ]*//' | sed 's|remotes/origin/||' | sort -u)"
  COMPREPLY=($(compgen -W "$branches" -- "$cur"))
}
complete -F _gitc_completions gitc

# Source machine-specific bash init (git completion, OrbStack, etc.)
[ -f "$HOME/.files/init.bash" ] && source "$HOME/.files/init.bash"
