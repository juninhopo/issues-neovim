if vim.g.loaded_issues_neovim then
  return
end
vim.g.loaded_issues_neovim = true

-- Auto commands to call the plugin's setup function
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Defer loading to avoid blocking Neovim startup
    vim.defer_fn(function()
      require("issues_neovim").setup()
    end, 100)
  end,
  group = vim.api.nvim_create_augroup("IssuesNeovimSetup", { clear = true }),
}) 