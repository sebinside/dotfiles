#!/usr/bin/env bash

# Install Starship if not present
if ! command -v starship &> /dev/null; then
    echo "Installing Starship..."
    # Pass -y to auto-confirm starship installer prompts
    curl -sS https://raw.githubusercontent.com/starship/starship/refs/tags/v1.24.0/install/install.sh | sh -s -- -y
fi

# Ensure config directory exists
mkdir -p ~/.config

# Apply preset if config missing
if [ ! -f ~/.config/starship.toml ]; then
    echo "Applying Starship preset..."
    starship preset no-nerd-font > ~/.config/starship.toml
fi

# Initialize Starship
eval "$(starship init bash)"

# Add personal aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Key bindings for history search
bind '"\e[5~": history-search-backward'
bind '"\e[6~": history-search-forward'

# Additional useful key bindings
bind '"\e[A": history-search-backward'  # Up arrow
bind '"\e[B": history-search-forward'   # Down arrow

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

# Alt left / right
bind '"\e[1;3D":"cd ..\n"'
bind '"\e[1;3C":"l\n"'
