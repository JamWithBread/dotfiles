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
        
    elif [ "$OS" = "linux" ]; then
        echo "Updating package lists..."
        sudo apt-get update
        
        echo "Installing core tools..."
        sudo apt-get install -y tmux git ripgrep fd-find fzf zsh curl wget unzip
        
        # Install Neovim 0.11.4 from GitHub releases (pinned version)
        echo "Installing Neovim 0.11.4..."
        NVIM_VERSION="v0.11.4"
        
        # Check if nvim is already installed with correct version
        if command -v nvim &> /dev/null; then
            CURRENT_VERSION=$(nvim --version 2>/dev/null | head -n 1 | awk '{print $2}')
            if [ "$CURRENT_VERSION" = "$NVIM_VERSION" ]; then
                echo "✅ Neovim $NVIM_VERSION already installed"
                return
            else
                echo "Current Neovim version: $CURRENT_VERSION, upgrading to $NVIM_VERSION..."
            fi
        fi
        
        # Try AppImage first (requires FUSE)
        echo "Attempting AppImage installation..."
        
        # Install FUSE for AppImage support
        sudo apt-get install -y fuse libfuse2 2>/dev/null || echo "FUSE installation failed, will try alternative method"
        
        # Download AppImage
        echo "Downloading Neovim AppImage..."
        if wget --show-progress https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim.appimage -O nvim.appimage 2>&1; then
            echo "✅ Download complete"
        else
            echo "❌ Download failed, trying tarball method..."
            rm -f nvim.appimage
            
            # Jump directly to tarball method
            wget --show-progress https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz
            tar xzf nvim-linux64.tar.gz
            sudo cp -r nvim-linux64/* /usr/local/
            rm -rf nvim-linux64 nvim-linux64.tar.gz
            
            # Verify tarball installation
            if /usr/local/bin/nvim --version &> /dev/null; then
                echo "✅ Neovim installed from tarball"
            else
                echo "❌ All installation methods failed"
                exit 1
            fi
            
            return
        fi
        
        chmod u+x nvim.appimage
        
        # Test if AppImage works
        echo "Testing AppImage..."
        if timeout 5 ./nvim.appimage --version &> /dev/null; then
            echo "✅ AppImage works, installing to /usr/local/bin/nvim"
            sudo mv nvim.appimage /usr/local/bin/nvim
        else
            echo "⚠️  AppImage failed (likely no FUSE in container), trying extraction method..."
            rm -f nvim.appimage
            
            # Download and extract AppImage manually
            echo "Downloading Neovim AppImage for extraction..."
            wget --show-progress https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim.appimage -O nvim.appimage
            chmod u+x nvim.appimage
            
            # Extract AppImage
            echo "Extracting AppImage..."
            if timeout 10 ./nvim.appimage --appimage-extract &> /dev/null; then
                echo "✅ Extraction successful"
            else
                echo "❌ AppImage extraction failed, trying tarball method..."
                rm -rf squashfs-root nvim.appimage
                
                # Download pre-built tarball instead
                echo "Downloading Neovim tarball..."
                wget --show-progress https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz
                echo "Extracting tarball..."
                tar xzf nvim-linux64.tar.gz
                sudo cp -r nvim-linux64/* /usr/local/
                rm -rf nvim-linux64 nvim-linux64.tar.gz
                
                # Verify tarball installation
                if /usr/local/bin/nvim --version &> /dev/null; then
                    echo "✅ Neovim installed from tarball"
                else
                    echo "❌ All installation methods failed"
                    exit 1
                fi
                
                return
            fi
            
            # Move extracted files
            sudo rm -rf /usr/local/nvim-extracted
            sudo mv squashfs-root /usr/local/nvim-extracted
            rm -f nvim.appimage
            
            # Create wrapper script
            echo "Creating nvim wrapper..."
            sudo tee /usr/local/bin/nvim > /dev/null << 'EOF'
#!/bin/sh
exec /usr/local/nvim-extracted/AppRun "$@"
EOF
            sudo chmod +x /usr/local/bin/nvim
            
            echo "✅ Neovim installed from extracted AppImage"
        fi
        
        # Verify installation
        echo "Verifying Neovim installation..."
        if command -v nvim &> /dev/null && nvim --version &> /dev/null; then
            nvim --version | head -n 1
            echo "✅ Neovim installed successfully"
        else
            echo "❌ Neovim installation failed"
            echo "Checking PATH: $PATH"
            echo "Checking /usr/local/bin:"
            ls -la /usr/local/bin/nvim* 2>/dev/null || echo "No nvim found in /usr/local/bin"
            exit 1
        fi
        
        # Install zoxide
        echo "Installing zoxide..."
        if ! command -v zoxide &> /dev/null; then
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        else
            echo "✅ zoxide already installed"
        fi
    fi
    
    echo "✅ Dependencies installed"
}

# Set zsh as default shell
setup_zsh() {
    echo ""
    echo "🐚 Configuring zsh..."
    
    ZSH_PATH=$(which zsh)
    
    # Add zsh to valid shells if not already there
    if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
        echo "Adding zsh to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
    
    # Change default shell
    if [ "$SHELL" != "$ZSH_PATH" ]; then
        echo "Setting zsh as default shell..."
        echo "Note: You'll need to log out and back in for this to take effect"
        chsh -s "$ZSH_PATH" || {
            echo "⚠️  Could not change shell automatically. Run this manually:"
            echo "    chsh -s $ZSH_PATH"
        }
    else
        echo "✅ zsh is already the default shell"
    fi
}

# Install Zinit
install_zinit() {
    echo ""
    echo "📦 Installing Zinit plugin manager..."
    
    ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
    
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
    echo "📦 Installing Neovim plugins..."
    
    # Try to install plugins non-interactively
    if command -v nvim &> /dev/null; then
        echo "Running PackerSync..."
        nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 2>&1 | grep -v "^$" || true
        echo "✅ Neovim plugins installed"
        echo "Note: Run ':PackerSync' inside nvim if you encounter any issues"
    else
        echo "⚠️  Neovim not found in PATH"
        echo "Note: Run ':PackerSync' inside nvim on first launch to install plugins"
    fi
}

# Verify installation
verify_installation() {
    echo ""
    echo "🔍 Verifying installation..."
    
    local all_good=true
    
    # Check nvim
    if command -v nvim &> /dev/null; then
        echo "✅ nvim: $(nvim --version | head -n 1)"
    else
        echo "❌ nvim: not found"
        all_good=false
    fi
    
    # Check tmux
    if command -v tmux &> /dev/null; then
        echo "✅ tmux: $(tmux -V)"
    else
        echo "❌ tmux: not found"
        all_good=false
    fi
    
    # Check zsh
    if command -v zsh &> /dev/null; then
        echo "✅ zsh: $(zsh --version)"
    else
        echo "❌ zsh: not found"
        all_good=false
    fi
    
    # Check symlinks
    if [ -L ~/.config/nvim ]; then
        echo "✅ nvim config symlinked"
    else
        echo "❌ nvim config not symlinked"
        all_good=false
    fi
    
    if [ -L ~/.tmux.conf ]; then
        echo "✅ tmux config symlinked"
    else
        echo "❌ tmux config not symlinked"
        all_good=false
    fi
    
    if [ -L ~/.zshrc ]; then
        echo "✅ zshrc symlinked"
    else
        echo "❌ zshrc not symlinked"
        all_good=false
    fi
    
    if [ "$all_good" = true ]; then
        echo ""
        echo "✅ All checks passed!"
    else
        echo ""
        echo "⚠️  Some checks failed. Review the output above."
    fi
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
    setup_zsh
    install_nvim_plugins
    verify_installation
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║     ✅ Installation Complete!          ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Start a new shell session: exec zsh"
    echo "  2. Zinit will install plugins on first zsh launch (~30 seconds)"
    echo "  3. If p10k wizard appears, configure or press 'q' to use existing config"
    echo "  4. Verify nvim plugins: nvim +PackerStatus"
    echo ""
    echo "Tips:"
    echo "  • Create ~/.zshrc.local for machine-specific configs"
    echo "  • Customize p10k theme: p10k configure"
    echo "  • Install a Nerd Font for best experience (see README.md)"
    echo "  • If shell didn't change, log out and back in"
    echo ""
}

main
