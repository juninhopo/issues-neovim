-- Plugin registration for issues-neovim

if vim.g.loaded_issues_neovim == 1 then
  return
end
vim.g.loaded_issues_neovim = 1

-- Define user command to open issues-neovim
vim.api.nvim_create_user_command("LazyVimIssues", function()
  local issues = require("issues-neovim")
  local current_dir = vim.fn.getcwd()
  
  vim.cmd(string.format(
    "FloatermNew --height=%s --width=%s --title=%s cd %s && issues-neovim tui",
    issues.config.ui.float.height,
    issues.config.ui.float.width,
    vim.fn.shellescape(issues.config.ui.float.title),
    vim.fn.shellescape(current_dir)
  ))
end, {
  desc = "Open LazyVim Issues CLI",
  nargs = 0,
})

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