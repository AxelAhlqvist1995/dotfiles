#!/bin/bash
set -euo pipefail

DOTFILES_REPO="https://github.com/axelahlqvist1995/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

echo "=== Installing packages ==="
sudo apt-get update -q
sudo apt-get install -y tmux git zsh curl

echo "=== Installing oh-my-zsh ==="
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Already installed, skipping"
fi

echo "=== Installing Powerlevel10k ==="
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
else
    echo "Already installed, skipping"
fi

echo "=== Installing zsh plugins ==="
install_plugin() {
    local name=$1 repo=$2
    local dir="$HOME/.oh-my-zsh/custom/plugins/$name"
    if [ ! -d "$dir" ]; then
        echo "Installing $name..."
        git clone "$repo" "$dir"
    else
        echo "$name already installed, skipping"
    fi
}
install_plugin zsh-autosuggestions         https://github.com/zsh-users/zsh-autosuggestions
install_plugin zsh-syntax-highlighting     https://github.com/zsh-users/zsh-syntax-highlighting
install_plugin zsh-completions             https://github.com/zsh-users/zsh-completions
install_plugin zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search

echo "=== Installing oh-my-tmux ==="
if [ ! -d "$HOME/.local/share/tmux/oh-my-tmux" ]; then
    mkdir -p "$HOME/.local/share/tmux"
    git clone https://github.com/gpakosz/.tmux.git "$HOME/.local/share/tmux/oh-my-tmux"
else
    echo "Already installed, skipping"
fi
cp "$HOME/.local/share/tmux/oh-my-tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "=== Cloning dotfiles ==="
if [ ! -d "$DOTFILES_DIR" ]; then
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    echo "Already cloned, pulling latest..."
    git -C "$DOTFILES_DIR" pull
fi

echo "=== Running deploy ==="
cd "$DOTFILES_DIR" && ./deploy.sh

echo ""
echo "=== Setup complete! ==="
echo "Run 'exec zsh' to start using your new shell config."
echo "Run 'tmux' to start tmux with oh-my-tmux."
