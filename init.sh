#!/usr/bin/env bash

# Key bindings for history search
bind '"\e[5~": history-search-backward'
bind '"\e[6~": history-search-forward'

# Additional useful key bindings
bind '"\e[A": history-search-backward'  # Up arrow
bind '"\e[B": history-search-forward'   # Down arrow

# Alt left / right
bind '"\e[1;3D":"cd ..\n"'
bind '"\e[1;3C":"l\n"'

# Add ctrl + backspace
bind '"\C-H":backward-kill-word'

# Add personal aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# CUSTOM STUFF
alias e='explorer.exe'
alias s='git s'
alias a='git add -A'
alias push='git push'
alias f='git fetch'
alias pull='git pull'
alias c='git commit -m'
alias ac='git add -A && git commit -m'
alias ca='git add -A && git commit -m'
alias gl='git l'
alias out='git checkout'
alias v='code .'
alias d='docker'
alias dl="docker ps --format '{{printf \"\x1b[94m%s\x1b[0m\" .ID}}\t{{printf \"%.20s\" .Image}}\t{{printf \"\x1b[32m%s\x1b[0m\" .Status}}\t{{.Names}}'"

# de = docker exec -it ... bash
de() {
  local target="$1"

  if [[ -z "$target" ]]; then
    # Get the first running container ID (most recently created/running)
    target=$(docker ps -q | head -n1)
    if [[ -z "$target" ]]; then
      return 1
    fi
  fi

  docker exec -it "$target" bash
}

# Initialize Starship
eval "$(starship init bash)"
