#!/usr/bin/env bash

# Bash key bindings
bind '"\e[A": history-search-backward'  # Up arrow
bind '"\e[B": history-search-forward'   # Down arrow
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
alias n='npm run'
alias cpb='git branch | grep "*" | sed "s/\* //g" | xclip -selection clipboard'
alias xclip='xclip -selection clipboard'

# Remaining fish stuff
if test -n "$FISH_VERSION"
    bind \e\[1\;3D ' cd ..; commandline -f repaint'
    bind \e\[1\;3C ' commandline l; commandline -f execute'
    bind \cH backward-kill-word

    # de = docker exec -it ... bash
    function de
        set target $argv[1]

        if test -z "$target"
            # Get the first running container ID (most recently created/running)
            set target (docker ps -q | head -n1)
            if test -z "$target"
                return 1
            end
        end

        docker exec -it "$target" bash
    end
end
