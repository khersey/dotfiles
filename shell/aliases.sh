# Portable aliases and small utility functions
# Works in both bash and zsh

# ls
export LS_OPTS='-Gh'
alias ls='ls ${LS_OPTS}'
alias ll='ls -FGlAhp'

# navigation
cd() { builtin cd "$@"; ls -FGlAhp; }
alias cd..='cd ../'
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ......='cd ../../../../../'
alias .......='cd ../../../../../../'

# file operations
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# macOS
alias f='open -a Finder ./'
alias ~='cd ~'
alias c='clear'
alias path='echo -e ${PATH//:/\\n}'
alias which='type -a'
alias fix_stty='stty sane'
alias nocolor='sed -e "s/\x1B\[[0-9;]*[a-zA-Z]//g"'

# search
alias qfind='find . -name'
ff()  { /usr/bin/find . -name "$@"; }
ffs() { /usr/bin/find . -name "$@"'*'; }
ffe() { /usr/bin/find . -name '*'"$@"; }

# process management
findPid() { lsof -t -c "$@"; }
alias memHogsTop='top -l 1 -o rsize | head -20'
alias memHogsPs='ps wwaxm -o pid,stat,vsize,rss,time,command | head -10'
alias cpu_hogs='ps wwaxr -o pid,stat,%cpu,time,command | head -10'
alias topForever='top -l 9999999 -s 10 -o cpu'
alias ttop='top -R -F -s 10 -o rsize'
my_ps() { ps "$@" -u "$USER" -o pid,%cpu,%mem,start,time,bsdtime,command; }

# networking
alias myip='curl ip.appspot.com'
alias netCons='lsof -i'
alias flushDNS='dscacheutil -flushcache'
alias lsock='sudo /usr/sbin/lsof -i -P'
alias lsockU='sudo /usr/sbin/lsof -nP | grep UDP'
alias lsockT='sudo /usr/sbin/lsof -nP | grep TCP'
alias ipInfo0='ipconfig getpacket en0'
alias ipInfo1='ipconfig getpacket en1'
alias openPorts='sudo lsof -i | grep LISTEN'
alias showBlocked='sudo ipfw list'

# file utilities
mcd() { mkdir -p "$1" && cd "$1"; }

extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar e "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# tool aliases
alias yoloclaude='claude --dangerously-skip-permissions'
alias yolocodex='codex --yolo'
alias surf='windsurf'
