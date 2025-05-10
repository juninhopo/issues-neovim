-- Script para testar o plugin issues-neovim
package.path = package.path .. ";./lua/?.lua"

-- Certifique-se de que plenary.nvim está acessível
-- Se você receber um erro, ajuste o caminho para seu ambiente
-- package.path = package.path .. ";/caminho/para/plenary.nvim/lua/?.lua"

local ok, issues_neovim = pcall(require, "issues_neovim")
if not ok then
  print("Erro ao carregar o módulo issues_neovim:")
  print(issues_neovim)
  os.exit(1)
end

-- Configurar o plugin
issues_neovim.setup({
  github = {
    -- Defina seu token GitHub aqui, se necessário
    -- token = "seu_token_github"
  }
})

-- Expor funções para teste no escopo global
_G.open_issues = function()
  issues_neovim.ui.open()
end

print("Plugin issues-neovim carregado com sucesso!")
print("Execute ':lua open_issues()' para abrir a interface") 