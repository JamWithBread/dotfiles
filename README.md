# My Dotfiles

Portable configuration for Neovim, Tmux, and Zsh with Powerlevel10k theme.

## Features

### Neovim
- LSP configuration with autocompletion
- Syntax highlighting
- File navigation
- Custom keybindings
- Alpha dashboard
- Bufferline and Lualine statusline
- **Compatible with Neovim 0.10+**

### Tmux
- Enhanced keybindings
- Mouse support
- Better pane navigation

### Zsh
- **Zinit** plugin manager (fast and modern)
- **Powerlevel10k** theme
- Syntax highlighting
- Auto-suggestions with async support
- Enhanced history search
- Smart directory navigation (zoxide, enhancd)
- Git integration
- Colored man pages
- macOS: GNU utilities instead of BSD

## Prerequisites

### Required: Neovim 0.10+
```bash
# macOS
brew install neovim

# Linux
# Add Neovim PPA for latest version
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt-get install neovim
```

### Required: Nerd Font

Powerlevel10k requires a Nerd Font for icons and symbols.

**macOS:**
```bash
brew tap homebrew/cask-fonts
brew install --cask font-meslo-lg-nerd-font
```

**Linux:**
```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
fc-cache -f -v
```

**Then:** Set your terminal font to **"MesloLGS NF"**

## Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles

# Run the install script
cd ~/dotfiles
./install.sh
```

The script will:
1. Install required dependencies (neovim, tmux, zsh, etc.)
2. Install Zinit plugin manager
3. Install Packer for Neovim
4. Create symlinks to your home directory
5. Install Neovim plugins

## Post-Installation

1. **Restart your terminal:**
```bash
   exec zsh
```

2. **First zsh launch:**
   - Zinit will automatically install all plugins (~30 seconds)
   - You may see plugin installations scrolling by

3. **Powerlevel10k configuration:**
   - If the p10k wizard appears, follow the prompts to customize your theme
   - Or press `q` to skip and use the included configuration
   - You can always run `p10k configure` later to change it

4. **Neovim plugins:**
   - Open nvim: `nvim`
   - Run `:PackerSync` if any plugins need updating

## Directory Structure
```
dotfiles/
├── nvim/               # Neovim configuration
│   ├── init.lua
│   └── lua/
│       ├── plugins.lua
│       ├── lsp_config.lua
│       ├── global_options.lua
│       └── ...
├── zsh/                # Zsh configuration
│   ├── zshrc
│   └── p10k.zsh
├── tmux.conf           # Tmux configuration
├── install.sh          # Installation script
├── .gitignore
└── README.md
```

## Machine-Specific Configuration

For settings that should only apply to specific machines (like work vs personal), create a `~/.zshrc.local` file:
```bash
# Example ~/.zshrc.local

# Machine-specific aliases
alias work='cd ~/work/projects'
alias myserver='ssh user@example.com'

# Machine-specific PATH
export PATH="/custom/path:$PATH"

# Environment variables
export MY_CUSTOM_VAR="value"
```

This file is gitignored and won't be synced to your repository.

## Key Bindings

### Zsh
- `Ctrl+F` - Move forward one word
- `Ctrl+B` - Move backward one word
- `Ctrl+E` - Move to end of line
- `Ctrl+P` - History substring search (previous)
- `Ctrl+N` - History substring search (next)

### Tmux
- See `tmux.conf` for full keybinding list
- Default prefix: `Ctrl+B`

### Neovim
- See `nvim/lua/key_mappings.lua` for custom keybindings

## Included Command-Line Tools

After installation, you'll have access to:

- **zoxide** (`z`): Smarter cd - jumps to frecent directories
```bash
  z documents    # Jump to ~/Documents or most frecent match
```

- **enhancd**: Enhanced cd with interactive selection
```bash
  cd **<TAB>     # Interactive directory picker
```

- **fzf**: Fuzzy finder for files, history, etc.
```bash
  Ctrl+R         # Fuzzy search command history
  Ctrl+T         # Fuzzy search files
```

- **ripgrep** (`rg`): Fast grep alternative
```bash
  rg "search term" .
```

- **fd**: Fast find alternative
```bash
  fd filename
```

## Customization

### Zsh Theme (Powerlevel10k)
```bash
p10k configure
```

### Neovim
Edit configuration files in `nvim/lua/`:
- `plugins.lua` - Add/remove plugins
- `lsp_config.lua` - Configure language servers
- `key_mappings.lua` - Custom keybindings
- `colorscheme.lua` - Change theme

### Tmux
Edit `tmux.conf` directly

### Zsh
- Edit `zsh/zshrc` for changes you want synced across machines
- Edit `~/.zshrc.local` for machine-specific changes

## Updating
```bash
cd ~/dotfiles
git pull
./install.sh
```

The install script safely backs up existing configs before updating.

## Compatibility Notes

- **Neovim**: Requires version 0.10 or higher
- **bufferline.nvim**: Pinned to specific commit for compatibility
- **Removed options**: `termencoding` (deprecated in Neovim 0.10+)
- **vim-markdown-composer**: Disabled (requires Rust compilation)

## Troubleshooting

### Zsh plugins not loading
```bash
# Reinstall Zinit plugins
rm -rf ~/.local/share/zinit
exec zsh
```

### Neovim plugins not working
```bash
nvim
:PackerClean
:PackerSync
```

### Icons not showing (boxes/question marks)
Make sure you've installed a Nerd Font and set it in your terminal.

### Permission denied on install.sh
```bash
chmod +x install.sh
```

### Neovim version too old
```bash
# macOS
brew upgrade neovim

# Linux
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt-get install neovim
```

## One-Line Install

Once pushed to GitHub, use this for quick setup on new machines:
```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh && exec zsh
```

## Uninstalling
```bash
# Remove symlinks
rm ~/.config/nvim
rm ~/.tmux.conf
rm ~/.zshrc
rm ~/.p10k.zsh

# Restore from backup (replace TIMESTAMP with your backup date)
mv ~/.config/nvim.backup.TIMESTAMP ~/.config/nvim
mv ~/.tmux.conf.backup.TIMESTAMP ~/.tmux.conf
mv ~/.zshrc.backup.TIMESTAMP ~/.zshrc
```

## License

MIT
