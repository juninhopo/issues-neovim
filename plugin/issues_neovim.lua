-- Check if plugin is already loaded
if vim.g.loaded_issues_neovim then
  return
end
vim.g.loaded_issues_neovim = true

local cmd = vim.api.nvim_create_user_command

-- Criar comando para abrir a interface do plugin
cmd("IssuesNeovim", function()
  require("issues_neovim").ui.open()
end, {
  desc = "Abrir interface do GitHub Issues",
})

-- Criar comando para diagnosticar problemas de API
cmd("IssuesNeovimDiagnose", function()
  require("issues_neovim").diagnose_github_api()
end, {
  desc = "Diagnosticar problemas de conexão com a API do GitHub",
})

-- Criar comando para configurar o token
cmd("IssuesNeovimSetupToken", function()
  local token_path = vim.fn.expand("~/.config/github_token")
  vim.cmd("edit " .. token_path)
end, {
  desc = "Configurar token do GitHub",
})

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