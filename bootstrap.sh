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

# Initialize Starship
eval "$(starship init bash)"
