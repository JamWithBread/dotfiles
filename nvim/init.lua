-- Bootstrap Packer
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
local packer_bootstrap = false

if fn.empty(fn.glob(install_path)) > 0 then
  print("Installing Packer...")
  packer_bootstrap = fn.system({
    'git', 
    'clone', 
    '--depth', 
    '1', 
    'https://github.com/wbthomason/packer.nvim', 
    install_path
  })
  vim.cmd [[packadd packer.nvim]]
end

-- Load core settings (these don't depend on plugins)
require('global_options')
require('autocmds')
require('key_mappings')
require('variables')

-- Inline options that don't depend on plugins
vim.opt.relativenumber = true
vim.opt.scrolloff = 999
vim.opt.virtualedit = "block"
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.termguicolors = true

-- Load plugins definition FIRST
require('plugins')

-- Check if plugins are actually installed before loading configs
local packer_compiled = fn.stdpath('config')..'/plugin/packer_compiled.lua'
local plugins_installed = fn.filereadable(packer_compiled) == 1

if plugins_installed then
  -- Only load plugin configurations if plugins are installed
  require('plugins_config')
  require('alpha_config')
  require('iron_config')
  require('lsp_config')
  require('lualine_config')
  require('noice_config')
  require('bufferline_config')
  require('nvim-cmp_config')
  require('colorscheme')
else
  -- First time setup
  print("Plugins not installed yet. Please run :PackerSync")
  
  -- Set a basic colorscheme that doesn't require plugins
  vim.cmd('colorscheme default')
  
  -- Auto-run PackerSync on first install
  if packer_bootstrap then
    require('packer').sync()
  end
end
