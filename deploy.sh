#!/bin/bash
set -euo pipefail
USAGE=$(cat <<-END
    Usage: ./deploy.sh [OPTIONS] [--aliases <alias1,alias2,...>], eg. ./deploy.sh --vim --aliases=speechmatics,custom
    Creates ~/.zshrc and ~/.tmux.conf (linux) or ~/.config/tmux/tmux.conf.local (mac) with location
    specific config

    OPTIONS:
        --vim                   deploy very simple vimrc config 
        --aliases               specify additional alias scripts to source in .zshrc, separated by commas
END
)

export DOT_DIR=$(dirname $(realpath $0))

VIM="false"
ALIASES=()
while (( "$#" )); do
    case "$1" in
        -h|--help)
            echo "$USAGE" && exit 1 ;;
        --vim)
            VIM="true" && shift ;;
        --aliases=*)
            IFS=',' read -r -a ALIASES <<< "${1#*=}" && shift ;;
        --) # end argument parsing
            shift && break ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2 && exit 1 ;;
    esac
done

echo "deploying on machine..."
echo "using extra aliases: ${ALIASES[*]:-}"

# Tmux setup
# On Mac, oh-my-tmux framework lives at ~/.config/tmux/tmux.conf (loaded via XDG).
# Customizations go in ~/.config/tmux/tmux.conf.local
# On Linux, oh-my-tmux framework should be manually copied to ~/.tmux.conf.
# Customizations go in ~/.tmux.conf.local
operating_system="$(uname -s)"
if [ "$operating_system" = "Darwin" ]; then
    mkdir -p $HOME/.config/tmux
    echo "source $DOT_DIR/config/tmux.conf" > $HOME/.config/tmux/tmux.conf.local
else
    echo "source $DOT_DIR/config/tmux.conf" > $HOME/.tmux.conf.local
fi

# Neovim / LazyVim config
mkdir -p "$HOME/.config"
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    echo "Backing up existing nvim config to ~/.config/nvim.bak"
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
fi
ln -sf "$DOT_DIR/config/nvim" "$HOME/.config/nvim"

# Vimrc
if [[ $VIM == "true" ]]; then
    echo "deploying .vimrc"
    echo "source $DOT_DIR/config/vimrc" > $HOME/.vimrc
fi

# zshrc setup
echo "source $DOT_DIR/config/zshrc.sh" > $HOME/.zshrc
# Append additional alias scripts if specified
if [ -n "${ALIASES+x}" ]; then
    for alias in "${ALIASES[@]:-}"; do
        echo "source $DOT_DIR/config/aliases_${alias}.sh" >> $HOME/.zshrc
    done
fi

# Install uv if not already present
if ! command -v uv &> /dev/null; then
    echo "installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo "changing default shell to zsh"
chsh -s $(which zsh) || echo "Could not change default shell (may require manual step)"

echo "Run 'exec zsh' to reload your shell."
