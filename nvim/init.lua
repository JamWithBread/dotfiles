require('global_options')
require('autocmds')
require('key_mappings')
require('variables')
require('plugins_config')
require('plugins')

require('alpha_config')
require('iron_config')
require('lsp_config')
require('lualine_config')
require('noice_config')
require('bufferline_config')
require('nvim-cmp_config')

vim.opt.relativenumber = true
vim.opt.scrolloff = 999
vim.opt.virtualedit = "block"
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.termguicolors = true

require('colorscheme')



