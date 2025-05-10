-- Verificar se o plugin já foi carregado
if vim.g.loaded_issues_neovim then
  return
end
vim.g.loaded_issues_neovim = true

-- Atalho para criar comandos
local cmd = vim.api.nvim_create_user_command

-- Comando para abrir a interface principal do GitHub Issues
cmd("IssuesNeovim", function()
  require("issues_neovim").ui.open()
end, {
  desc = "Abrir interface do GitHub Issues",
})

-- Comando para executar diagnóstico da API do GitHub
cmd("IssuesNeovimDiagnose", function()
  require("issues_neovim").diagnose_github_api()
end, {
  desc = "Diagnosticar problemas de conexão com a API do GitHub",
})

-- Comando para configurar o token do GitHub
cmd("IssuesNeovimSetupToken", function()
  local token_path = vim.fn.expand("~/.config/github_token")
  vim.cmd("edit " .. token_path)
end, {
  desc = "Configurar token do GitHub",
})

-- Autocmd para inicializar o plugin na inicialização do Neovim
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Carregar com atraso para não bloquear a inicialização do Neovim
    vim.defer_fn(function()
      require("issues_neovim").setup()
    end, 100)
  end,
  group = vim.api.nvim_create_augroup("IssuesNeovimSetup", { clear = true }),
}) 