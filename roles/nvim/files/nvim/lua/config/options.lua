-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Python-specific options
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4 -- Python uses 4 spaces
    vim.opt_local.shiftwidth = 4 -- Indent with 4 spaces
    vim.opt_local.expandtab = true -- Use spaces instead of tabs
    vim.opt_local.textwidth = 88 -- PEP 8 recommends 88 (Black default)
    vim.opt_local.colorcolumn = "88" -- Visual guide at 88 characters
    vim.opt_local.foldmethod = "indent" -- Fold based on indentation
    vim.opt_local.foldlevel = 99 -- Don't fold by default
  end,
  desc = "Set Python-specific options",
})
