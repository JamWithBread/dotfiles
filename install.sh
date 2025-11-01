#!/bin/bash

set -e

echo "🚀 Installing dotfiles..."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
        # Detect package manager
        if command -v apt-get &> /dev/null; then
            PKG_MANAGER="apt"
        elif command -v dnf &> /dev/null; then
            PKG_MANAGER="dnf"
        elif command -v yum &> /dev/null; then
            PKG_MANAGER="yum"
        else
            echo "❌ No supported package manager found (apt, dnf, or yum)"
            exit 1
        fi

        echo "Detected package manager: $PKG_MANAGER"

        if [ "$PKG_MANAGER" = "apt" ]; then
            echo "Updating package lists..."
            sudo apt-get update

            echo "Installing core tools..."
            sudo apt-get install -y tmux git ripgrep fd-find fzf zsh curl wget unzip build-essential cmake locales

            # Generate locale
            echo "Configuring locale..."
            sudo locale-gen en_US.UTF-8
            sudo update-locale LANG=en_US.UTF-8
        else
            # dnf/yum (Amazon Linux, RHEL, Fedora, CentOS)
            echo "Installing core tools..."
            sudo $PKG_MANAGER install -y tmux git zsh wget unzip make gcc gcc-c++ cmake

            # Install ripgrep
            if ! command -v rg &> /dev/null; then
                echo "Installing ripgrep..."
                sudo $PKG_MANAGER install -y ripgrep 2>/dev/null || echo "⚠️  ripgrep not available in default repos"
            fi

            # Install fd-find (may not be in default repos)
            if ! command -v fd &> /dev/null; then
                echo "Installing fd-find..."
                sudo $PKG_MANAGER install -y fd-find 2>/dev/null || echo "⚠️  fd-find not available in default repos"
            fi

            # Install fzf (may not be in default repos)
            if ! command -v fzf &> /dev/null; then
                echo "Installing fzf..."
                sudo $PKG_MANAGER install -y fzf 2>/dev/null || {
                    if [ -d ~/.fzf ]; then
                        echo "fzf directory already exists, updating..."
                        cd ~/.fzf && git pull
                    else
                        echo "Installing fzf from git..."
                        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
                    fi
                    ~/.fzf/install --bin
                }
            fi
        fi
        
        # Install Neovim 0.11.4 from GitHub releases (pinned version)
        echo "Installing Neovim 0.11.4..."
        NVIM_VERSION="v0.11.4"
        
        # Detect architecture
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64)
                NVIM_ARCH="linux64"
                APPIMAGE_NAME="nvim-linux-x86_64.appimage"
                ;;
            aarch64|arm64)
                NVIM_ARCH="linux-arm64"
                APPIMAGE_NAME="nvim-linux-arm64.appimage"
                ;;
            *)
                echo "❌ Unsupported architecture: $ARCH"
                exit 1
                ;;
        esac
        
        echo "Detected architecture: $ARCH (using $NVIM_ARCH)"
        
        # Check if nvim is already installed with correct version
        if command -v nvim &> /dev/null && nvim --version &> /dev/null; then
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
        
        # Install FUSE for AppImage support (apt only)
        if [ "$PKG_MANAGER" = "apt" ]; then
            sudo apt-get install -y fuse libfuse2 2>/dev/null || echo "FUSE installation failed, will try alternative method"
        fi
        
        # Download AppImage (only available for x86_64 and aarch64)
        APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${APPIMAGE_NAME}"
        echo "Downloading Neovim AppImage from: $APPIMAGE_URL"
        
        if wget --show-progress "$APPIMAGE_URL" -O nvim.appimage 2>&1; then
            echo "✅ Download complete"
        else
            echo "❌ Download failed, trying tarball method..."
            rm -f nvim.appimage
            
            # Jump directly to tarball method
            TARBALL_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-${NVIM_ARCH}.tar.gz"
            echo "Downloading Neovim tarball from: $TARBALL_URL"
            wget --show-progress "$TARBALL_URL"
            tar xzf "nvim-${NVIM_ARCH}.tar.gz"
            sudo cp -r "nvim-${NVIM_ARCH}"/* /usr/local/
            rm -rf "nvim-${NVIM_ARCH}" "nvim-${NVIM_ARCH}.tar.gz"
            
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
            wget --show-progress "$APPIMAGE_URL" -O nvim.appimage
            chmod u+x nvim.appimage
            
            # Extract AppImage
            echo "Extracting AppImage..."
            if timeout 10 ./nvim.appimage --appimage-extract &> /dev/null; then
                echo "✅ Extraction successful"
            else
                echo "❌ AppImage extraction failed, trying tarball method..."
                rm -rf squashfs-root nvim.appimage
                
                # Download pre-built tarball instead
                TARBALL_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-${NVIM_ARCH}.tar.gz"
                echo "Downloading Neovim tarball from: $TARBALL_URL"
                wget --show-progress "$TARBALL_URL"
                echo "Extracting tarball..."
                tar xzf "nvim-${NVIM_ARCH}.tar.gz"
                sudo cp -r "nvim-${NVIM_ARCH}"/* /usr/local/
                rm -rf "nvim-${NVIM_ARCH}" "nvim-${NVIM_ARCH}.tar.gz"
                
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
            cat > /tmp/nvim-wrapper << 'EOF'
#!/bin/sh
exec /usr/local/nvim-extracted/AppRun "$@"
EOF
            sudo mv /tmp/nvim-wrapper /usr/local/bin/nvim
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
    
    if command -v nvim &> /dev/null; then
        echo "Running PackerSync (this may take 1-2 minutes)..."
        echo "This will install all Neovim plugins..."
        
        # Run nvim headless with PackerSync
        # The init.lua will now handle bootstrapping properly
        nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 2>&1 | tee /tmp/packer_install.log | grep -E '(Cloning|Updating|Error|Warning|Installing|Compiling)' || true
        
        # Check if packer_compiled exists to verify success
        if [ -f ~/.config/nvim/plugin/packer_compiled.lua ]; then
            echo "✅ Neovim plugins installed successfully"
        else
            echo "⚠️  Plugin installation may have had issues"
            echo "Check /tmp/packer_install.log for details"
            echo "You can run ':PackerSync' manually inside nvim"
        fi
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
