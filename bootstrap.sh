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
    echo "source ~/dotfiles/init.sh &> /dev/null" >> ~/.bashrc
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
fi

# Install Claude Code if not present
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

# Install rtk (Rust Token Killer) if not present
if ! command -v rtk &> /dev/null; then
    echo "Installing rtk..."
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
fi

# Directory of this bootstrap script (so we can find vendored files regardless of CWD)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install the custom Claude Code status line.
# The ~/.claude dir may not exist yet (fresh Claude install), so create it.
mkdir -p ~/.claude
cp "$DOTFILES_DIR/statusline.sh" ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# Register the status line in ~/.claude/settings.json — unless it's already there.
if ! grep -q "statusline.sh" ~/.claude/settings.json 2>/dev/null; then
    if command -v node &> /dev/null; then
        node -e '
            const fs=require("fs");
            const [,path,cmd]=process.argv; // node -e: argv=[node, arg1, arg2] (no script path)
            let d={};
            try{const p=JSON.parse(fs.readFileSync(path,"utf8"));if(p&&typeof p==="object"&&!Array.isArray(p))d=p;}catch(e){}
            d.statusLine={type:"command",command:cmd,padding:0};
            fs.writeFileSync(path,JSON.stringify(d,null,2)+"\n");
        ' ~/.claude/settings.json ~/.claude/statusline.sh
    elif command -v python3 &> /dev/null; then
        python3 - ~/.claude/settings.json ~/.claude/statusline.sh <<'PY'
import json, sys, os
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    try:
        with open(path) as fh:
            loaded = json.load(fh)
        if isinstance(loaded, dict):
            data = loaded
    except ValueError:
        pass
data["statusLine"] = {"type": "command", "command": cmd, "padding": 0}
with open(path, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
    else
        echo "⚠ node/python3 not found — add the statusLine block to ~/.claude/settings.json manually."
    fi
fi
