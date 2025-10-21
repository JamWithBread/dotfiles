#!/bin/bash

set -e

echo "🚀 Installing dotfiles..."

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "❌ Unsupported OS: $OSTYPE"
    exit 1
fi

echo "📍 Detected OS: $OS"

# Install dependencies
install_dependencies() {
    echo ""
    echo "📦 Installing dependencies..."
    
    if [ "$OS" = "mac" ]; then
        # Check for Homebrew
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # Core tools
        echo "Installing core tools..."
        brew install neovim tmux git ripgrep fd fzf zsh zoxide
        
        # Check Neovim version
        echo "Checking Neovim version..."
        NVIM_VERSION=$(nvim --version | head -n 1 | awk '{print $2}')
        echo "Installed Neovim version: $NVIM_VERSION"
        
        if [[ "$NVIM_VERSION" < "v0.10" ]]; then
            echo "⚠️  Warning: Neovim version is older than 0.10. Please update with: brew upgrade neovim"
        fi
        
        # GNU utilities for better compatibility
        echo "Installing GNU utilities..."
        brew install coreutils findutils gnu-sed gawk grep gnu-tar
        
        # Set zsh as default shell
        if [ "$SHELL" != "$(which zsh)" ]; then
            echo "Setting zsh as default shell..."
            chsh -s $(which zsh)
        fi
        
    elif [ "$OS" = "linux" ]; then
        echo "Updating package lists..."
        sudo apt-get update
        
        echo "Installing core tools..."
        sudo apt-get install -y tmux git ripgrep fd-find fzf zsh curl wget
        
        # Install Neovim 0.11.4 from GitHub releases (pinned version)
        echo "Installing Neovim 0.11.4..."
        NVIM_VERSION="v0.11.4"
        
        # Download and install Neovim AppImage
        wget -q https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim.appimage
        chmod u+x nvim.appimage
        sudo mv nvim.appimage /usr/local/bin/nvim
        
        # Verify installation
        /usr/local/bin/nvim --version | head -n 1
        
        # Install zoxide
        echo "Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        
        # Set zsh as default shell
        if [ "$SHELL" != "$(which zsh)" ]; then
            echo "Setting zsh as default shell..."
            chsh -s $(which zsh)
        fi
    fi
    
    echo "✅ Dependencies installed"
}

# Install Zinit
install_zinit() {
    echo ""
    echo "📦 Installing Zinit plugin manager..."
    
    ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
    
    if [ -d "$ZINIT_HOME" ]; then
        echo "Zinit already installed, updating..."
        cd "$ZINIT_HOME" && git pull
    else
        echo "Installing Zinit..."
        mkdir -p "$(dirname $ZINIT_HOME)"
        
        if git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"; then
            echo "✅ Zinit installed successfully"
        else
            echo "❌ Failed to install Zinit"
            exit 1
        fi
    fi
}

# Install Packer (nvim plugin manager)
install_packer() {
    echo ""
    echo "📦 Installing Packer for Neovim..."
    
    PACKER_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/packer/start/packer.nvim"
    
    if [ -d "$PACKER_PATH" ]; then
        echo "Packer already installed, updating..."
        cd "$PACKER_PATH" && git pull
    else
        echo "Installing Packer..."
        git clone --depth 1 https://github.com/wbthomason/packer.nvim "$PACKER_PATH"
    fi
    
    echo "✅ Packer installed"
}

# Setup symlinks
setup_symlinks() {
    echo ""
    echo "🔗 Creating symlinks..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    echo "Dotfiles directory: $DOTFILES_DIR"
    
    # Backup and symlink nvim
    if [ -d ~/.config/nvim ] || [ -L ~/.config/nvim ]; then
        if [ -L ~/.config/nvim ]; then
            echo "Removing existing nvim symlink..."
            rm ~/.config/nvim
        else
            echo "Backing up existing nvim config..."
            mv ~/.config/nvim ~/.config/nvim.backup.$TIMESTAMP
        fi
    fi
    mkdir -p ~/.config
    ln -sf "$DOTFILES_DIR/nvim" ~/.config/nvim
    echo "✅ Linked nvim config"
    
    # Backup and symlink tmux
    if [ -f ~/.tmux.conf ] || [ -L ~/.tmux.conf ]; then
        if [ -L ~/.tmux.conf ]; then
            rm ~/.tmux.conf
        else
            mv ~/.tmux.conf ~/.tmux.conf.backup.$TIMESTAMP
        fi
    fi
    ln -sf "$DOTFILES_DIR/tmux.conf" ~/.tmux.conf
    echo "✅ Linked tmux config"
    
    # Backup and symlink zshrc
    if [ -f ~/.zshrc ] || [ -L ~/.zshrc ]; then
        if [ -L ~/.zshrc ]; then
            rm ~/.zshrc
        else
            mv ~/.zshrc ~/.zshrc.backup.$TIMESTAMP
        fi
    fi
    ln -sf "$DOTFILES_DIR/zsh/zshrc" ~/.zshrc
    echo "✅ Linked zshrc"
    
    # Backup and symlink p10k
    if [ -f ~/.p10k.zsh ] || [ -L ~/.p10k.zsh ]; then
        if [ -L ~/.p10k.zsh ]; then
            rm ~/.p10k.zsh
        else
            mv ~/.p10k.zsh ~/.p10k.zsh.backup.$TIMESTAMP
        fi
    fi
    ln -sf "$DOTFILES_DIR/zsh/p10k.zsh" ~/.p10k.zsh
    echo "✅ Linked p10k config"
    
    if [ ! -z "$(ls ~/.*.backup.$TIMESTAMP 2>/dev/null)" ] || [ ! -z "$(ls ~/.config/*.backup.$TIMESTAMP 2>/dev/null)" ]; then
        echo ""
        echo "📦 Backups created with timestamp: $TIMESTAMP"
    fi
}

# Install nvim plugins
install_nvim_plugins() {
    echo ""
    echo "✅ Neovim setup complete"
    echo "Note: Run ':PackerSync' inside nvim on first launch to install plugins"
}

# Main installation
main() {
    echo "╔════════════════════════════════════════╗"
    echo "║     Dotfiles Installation Script       ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    install_dependencies
    install_zinit
    install_packer
    setup_symlinks
    install_nvim_plugins
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║     ✅ Installation Complete!          ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Start zsh: zsh"
    echo "  2. On first zsh launch, Zinit will install all plugins (~30 seconds)"
    echo "  3. If p10k wizard appears, configure or press 'q' to use existing config"
    echo "  4. Run 'nvim' and execute ':PackerSync' to install plugins"
    echo ""
    echo "Tips:"
    echo "  • Create ~/.zshrc.local for machine-specific configs"
    echo "  • Customize p10k theme by running: p10k configure"
    echo "  • Install a Nerd Font for best experience (see README.md)"
    echo ""
}

main
