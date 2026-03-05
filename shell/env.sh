# Portable environment — same on every machine
# Machine-specific PATHs and env vars go in ~/.files/env.sh

export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bin:$PATH"

# Source machine-specific env and creds
[ -f "$HOME/.files/env.sh" ] && source "$HOME/.files/env.sh"
[ -f "$HOME/.files/creds.sh" ] && source "$HOME/.files/creds.sh"
