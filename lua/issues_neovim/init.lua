---@class IssuesNeovim: issues_neovim.plugins
local M = {}

setmetatable(M, {
  __index = function(t, k)
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require("issues_neovim." .. k)
    return rawget(t, k)
  end,
})

_G.IssuesNeovim = M

---@class issues_neovim.Config
---@field enabled boolean
---@field keys table
---@field ui issues_neovim.ui.Config
---@field github issues_neovim.github.Config
local config = {
  enabled = true,
  keys = {
    open = "<leader>gi",
    close = "q",
    refresh = "r",
    navigate = { prev = "k", next = "j" },
    view_details = "<CR>",
    create_issue = "c",
    add_comment = "a",
  },
  ui = {
    width = 0.8,
    height = 0.8,
    border = "rounded",
    title = "GitHub Issues",
  },
  github = {
    api_url = "https://api.github.com",
    username = "juninhopo",
    token = nil, -- GitHub Personal Access Token
  },
}

---@class issues_neovim.config: issues_neovim.Config
M.config = setmetatable({}, {
  __index = function(_, k)
    config[k] = config[k] or {}
    return config[k]
  end,
  __newindex = function(_, k, v)
    config[k] = v
  end,
})

M.did_setup = false

---@param opts issues_neovim.Config?
function M.setup(opts)
  if M.did_setup then
    return vim.notify("issues-neovim is already setup", vim.log.levels.ERROR, { title = "issues-neovim" })
  end
  M.did_setup = true

  opts = opts or {}
  config = vim.tbl_deep_extend("force", config, opts)
  
  -- Set up keymappings
  vim.keymap.set("n", config.keys.open, function()
    M.ui.open()
  end, { desc = "Open GitHub Issues" })
  
  -- Load components
  if config.enabled then
    M.github.setup()
    M.ui.setup()
  end
end

-- Função de diagnóstico para testar a API do GitHub
function M.diagnose_github_api()
  local github = require("issues_neovim.github")
  
  -- Verificar configuração
  vim.notify("Verificando configuração do GitHub...", vim.log.levels.INFO, { title = "issues-neovim" })
  
  -- Verificar token
  if not config.github.token or config.github.token == "" then
    vim.notify("Token do GitHub não configurado. Verificando alternativas...", vim.log.levels.WARN, { title = "issues-neovim" })
    
    -- Verificar variável de ambiente
    local env_token = os.getenv("GITHUB_TOKEN")
    if env_token and env_token ~= "" then
      vim.notify("Token encontrado na variável GITHUB_TOKEN", vim.log.levels.INFO, { title = "issues-neovim" })
    else
      -- Verificar arquivo de token
      local token_path = vim.fn.expand("~/.config/github_token")
      local token_file = io.open(token_path)
      if token_file then
        vim.notify("Token encontrado no arquivo " .. token_path, vim.log.levels.INFO, { title = "issues-neovim" })
        token_file:close()
      else
        vim.notify("ERRO: Token do GitHub não encontrado. Configure um token para usar a API.", vim.log.levels.ERROR, { title = "issues-neovim" })
      end
    end
  else
    vim.notify("Token do GitHub configurado.", vim.log.levels.INFO, { title = "issues-neovim" })
  end
  
  -- Verificar informações do repositório
  local owner, repo = github.get_current_repo()
  if not owner or not repo then
    vim.notify("ERRO: Não foi possível determinar o repositório atual. Está em um repositório Git?", vim.log.levels.ERROR, { title = "issues-neovim" })
    return
  else
    vim.notify("Repositório atual: " .. owner .. "/" .. repo, vim.log.levels.INFO, { title = "issues-neovim" })
  end
  
  -- Construir URL da API
  local api_url = github.build_api_url("/issues?state=all")
  if not api_url then
    vim.notify("ERRO: Não foi possível construir a URL da API", vim.log.levels.ERROR, { title = "issues-neovim" })
    return
  else
    vim.notify("URL da API: " .. api_url, vim.log.levels.INFO, { title = "issues-neovim" })
  end
  
  -- Testar a API
  vim.notify("Fazendo requisição à API do GitHub...", vim.log.levels.INFO, { title = "issues-neovim" })
  local issues = github.get_issues(true)
  
  if issues then
    vim.notify("Sucesso! Encontrado " .. #issues .. " issues.", vim.log.levels.INFO, { title = "issues-neovim" })
    return true
  else
    vim.notify("Falha ao obter issues. Verifique o arquivo de log para mais detalhes.", vim.log.levels.ERROR, { title = "issues-neovim" })
    return false
  end
end

return M 