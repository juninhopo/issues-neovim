-- Plugin registration for issues-neovim

if vim.g.loaded_issues_neovim == 1 then
  return
end
vim.g.loaded_issues_neovim = 1

-- Load the core plugin
local issues = require("issues-neovim")

-- Define health check module (optional but recommended)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "issues-neovim",
  callback = function()
    -- Set up buffer-local options for issues-neovim windows
    vim.bo.buflisted = false
    vim.bo.bufhidden = "wipe"
  end,
})

-- Check for dependencies
local has_floaterm = vim.fn.exists(":FloatermNew") == 2

if not has_floaterm then
  vim.api.nvim_echo({
    { "issues-neovim: ", "WarningMsg" },
    { "vim-floaterm is required for floating terminal support. Please install it or use integrated terminal mode." },
  }, true, {})
end 