-- Set up lspconfig.
local lspconfig = require('lspconfig')

-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
-- Only setup LSP servers if they're available
if vim.fn.executable('r') == 1 then
    lspconfig.r_language_server.setup{}
end

if vim.fn.executable('bash-language-server') == 1 then
    lspconfig.bashls.setup{}
end

--require'navigator'.setup({
--    lsp = {
--        format_on_save = false,
--        diagnostic_scrollbar_sign = false
--    },
--})

--local null_ls = require("null-ls")
--
--null_ls.setup({
--    sources = {
--        null_ls.builtins.code_actions.shellcheck,
--        null_ls.builtins.formatting.styler,
--        null_ls.builtins.formatting.format_r
--    },
--})
