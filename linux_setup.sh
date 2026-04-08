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

echo "=== Installing Neovim ==="
if ! command -v nvim &> /dev/null; then
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ]; then
        NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
        NVIM_DIR="nvim-linux-arm64"
    else
        NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
        NVIM_DIR="nvim-linux-x86_64"
    fi
    curl -LO "$NVIM_URL"
    sudo tar -C /opt -xzf "$NVIM_DIR.tar.gz"
    sudo ln -sf "/opt/$NVIM_DIR/bin/nvim" /usr/local/bin/nvim
    rm "$NVIM_DIR.tar.gz"
else
    echo "Already installed, skipping"
fi

echo "=== Bootstrapping LazyVim plugins ==="
# deploy.sh will symlink ~/.config/nvim from dotfiles, then we bootstrap plugins
echo "Plugins will be bootstrapped after deploy runs..."

echo "=== Installing fnm and Node.js ==="
if [ ! -d "$HOME/.local/share/fnm" ]; then
    curl -fsSL https://fnm.vercel.app/install | bash --no-use
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env)"
    fnm install --lts
    fnm use lts-latest
else
    echo "fnm already installed, skipping"
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env)"
    fnm use lts-latest 2>/dev/null || fnm install --lts && fnm use lts-latest
fi

echo "=== Installing Claude Code ==="
if ! command -v claude &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
else
    echo "Already installed, skipping"
fi

echo "=== Cloning dotfiles ==="
if [ ! -d "$DOTFILES_DIR" ]; then
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    echo "Already cloned, pulling latest..."
    git -C "$DOTFILES_DIR" pull
fi

echo "=== Running deploy ==="
cd "$DOTFILES_DIR" && ./deploy.sh

echo "=== Bootstrapping LazyVim plugins ==="
echo "This may take a minute..."
nvim --headless "+Lazy! sync" +qa 2>&1

echo ""
echo "=== Setup complete! ==="
echo "Run 'exec zsh' to start using your new shell config."
echo "Run 'tmux' to start tmux with oh-my-tmux."
echo "Run 'nvim' to start Neovim with LazyVim."
