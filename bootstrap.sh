#!/usr/bin/env bash

# Install Starship if not present
if ! command -v starship &> /dev/null; then
    echo "Installing Starship..."
    # Pass -y to auto-confirm starship installer prompts
    curl -sS https://raw.githubusercontent.com/starship/starship/refs/tags/v1.24.0/install/install.sh | sh -s -- -y
fi

# Ensure config directory exists
mkdir -p ~/.config
mkdir  -p ~/.cache/starship/

# Apply preset if config missing
if [ ! -f ~/.config/starship.toml ]; then
    echo "Applying Starship preset..."
    starship preset no-nerd-font > ~/.config/starship.toml
fi

# Add init.sh to .bashrc if not already present
if ! grep -Fq "source ~/dotfiles/init.sh" ~/.bashrc 2>/dev/null; then
    echo "source ~/dotfiles/init.sh" >> ~/.bashrc
fi
