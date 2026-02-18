
require("rose-pine").setup({
    variant = "auto", -- auto, main, moon, or dawn
    dark_variant = "main", -- main, moon, or dawn
    dim_inactive_windows = false,
    extend_background_behind_borders = true,

    enable = {
        terminal = true,
        legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
        migrations = true, -- Handle deprecated options automatically
    },

    styles = {
        bold = true,
        italic = true,
        transparency = false,
    },

    groups = {
        border = "muted",
        link = "iris",
        panel = "surface",

        error = "love",
        hint = "iris",
        info = "foam",
        note = "pine",
        todo = "rose",
        warn = "gold",

        git_add = "foam",
        git_change = "rose",
        git_delete = "love",
        git_dirty = "rose",
        git_ignore = "muted",
        git_merge = "iris",
        git_rename = "pine",
        git_stage = "iris",
        git_text = "rose",
        git_untracked = "subtle",

        h1 = "iris",
        h2 = "foam",
        h3 = "rose",
        h4 = "gold",
        h5 = "pine",
        h6 = "foam",
    },

    palette = {
        --Override the builtin palette per variant
        main = {
            base = '#000000',
            overlay = '#363738',
        },
    },

    highlight_groups = {
        -- Comment = { fg = "foam" },
        -- VertSplit = { fg = "muted", bg = "muted" },
    },

    before_highlight = function(group, highlight, palette)
        -- Disable all undercurls
        -- if highlight.undercurl then
        --     highlight.undercurl = false
        -- end
        --
        -- Change palette colour
        -- if highlight.fg == palette.pine then
        --     highlight.fg = palette.foam
        -- end
    end,
})

-- Ensure highlights are applied after the colorscheme is loaded
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.cmd [[
      highlight clear LineNr
      highlight clear CursorLineNr
      syntax enable
    ]]
  end
})

-- Ensure proper color support in tmux/screen
if vim.env.TERM == 'screen-256color' or vim.env.TERM:match('tmux') then
    vim.opt.termguicolors = true
end

-- Use desert for limited color terminals (like AWS CloudShell), rose-pine otherwise
local colorscheme = "rose-pine-dawn"

-- Check if we're in a limited color environment
if vim.env.TERM == 'screen-256color' or vim.env.AWS_EXECUTION_ENV then
    colorscheme = "desert"
end

-- Fallback to desert if rose-pine isn't available
local ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not ok then
    vim.cmd("colorscheme desert")
end

