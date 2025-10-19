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

## Installation
```bash
# (Conditional) If in fresh linux env:
apt-get update && apt-get install -y git curl sudo

# Clone the repository
git clone https://github.com/JamWithBread/dotfiles.git ~/dotfiles

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

## Key Bindings

### Zsh
- `Ctrl+F` - Move forward one word
- `Ctrl+B` - Move backward one word
- `Ctrl+E` - Move to end of line
- `Ctrl+A` - Move to front of line
- `Ctrl+P` - History substring search (previous)
- `Ctrl+N` - History substring search (next)

### Tmux
- See `tmux.conf` for full keybinding list
- Default prefix: `Ctrl+T`

### Neovim
- See `nvim/lua/key_mappings.lua` for custom keybindings

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
