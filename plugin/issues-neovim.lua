-- Plugin registration for issues-neovim

if vim.g.loaded_issues_neovim == 1 then
  return
end
vim.g.loaded_issues_neovim = 1

-- Load the core plugin
local issues = require("issues-neovim")

-- Define health check module
if vim.fn.has('nvim-0.8') == 1 then
  vim.api.nvim_create_autocmd("User", {
    pattern = "NeovimLspHealthEnd",
    once = true,
    callback = function()
      vim.health.report_start("Issues Neovim")
      vim.health.report_info("Use :checkhealth issues-neovim for detailed diagnostics")
    end,
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "issues-neovim",
  callback = function()
    -- Set up buffer-local options for issues-neovim windows
    vim.bo.buflisted = false
    vim.bo.bufhidden = "wipe"
  end,
})

-- Register health check module
if vim.health then
  _G.JuninhoPo_issues_neovim_health = function()
    require('issues-neovim.health').check()
  end
  
  vim.api.nvim_exec([[
    function! health#issues_neovim#check()
      lua _G.JuninhoPo_issues_neovim_health()
    endfunction
  ]], false)
end

-- Check for dependencies
local has_floaterm = vim.fn.exists(":FloatermNew") == 2

if not has_floaterm then
  vim.api.nvim_echo({
    { "issues-neovim: ", "WarningMsg" },
    { "vim-floaterm is required for floating terminal support. Please install it or use :checkhealth issues-neovim for diagnostics." },
  }, true, {})
end 