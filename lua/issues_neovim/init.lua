---@class IssuesNeovim: issues_neovim.plugins
local M = {}

-- Metafunction to load submodules on demand
setmetatable(M, {
  __index = function(t, k)
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require("issues_neovim." .. k)
    return rawget(t, k)
  end,
})

-- Export to global scope for debugging
_G.IssuesNeovim = M

---@class issues_neovim.Config
---@field enabled boolean If the plugin is enabled
---@field keys table Key configuration
---@field ui issues_neovim.ui.Config UI configuration
---@field github issues_neovim.github.Config GitHub API configuration
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

-- Flag to control if the plugin has already been configured
M.did_setup = false

---Configure the issues-neovim plugin
---@param opts issues_neovim.Config? Configuration options
function M.setup(opts)
  if M.did_setup then
    return vim.notify(
      "issues-neovim is already setup",
      vim.log.levels.ERROR,
      { title = "issues-neovim" }
    )
  end
  M.did_setup = true

  -- Merge configurations
  opts = opts or {}
  config = vim.tbl_deep_extend("force", config, opts)
  
  -- Define key mappings
  vim.keymap.set("n", config.keys.open, function()
    M.ui.open()
  end, { desc = "Open GitHub Issues" })
  
  -- Load components
  if config.enabled then
    M.github.setup()
    M.ui.setup()
  end
end

---Diagnostic function to test the GitHub API
---@return boolean success If the connection to the API was successful
function M.diagnose_github_api()
  local github = require("issues_neovim.github")
  
  -- Check configuration
  vim.notify(
    "Checking GitHub configuration...",
    vim.log.levels.INFO,
    { title = "issues-neovim" }
  )
  
  -- Check token
  if not config.github.token or config.github.token == "" then
    vim.notify(
      "GitHub token not configured. Checking alternatives...",
      vim.log.levels.WARN,
      { title = "issues-neovim" }
    )
    
    -- Check environment variable
    local env_token = os.getenv("GITHUB_TOKEN")
    if env_token and env_token ~= "" then
      vim.notify(
        "Token found in GITHUB_TOKEN environment variable",
        vim.log.levels.INFO,
        { title = "issues-neovim" }
      )
    else
      -- Check token file
      local token_path = vim.fn.expand("~/.config/github_token")
      local token_file = io.open(token_path)
      if token_file then
        vim.notify(
          "Token found in file " .. token_path,
          vim.log.levels.INFO,
          { title = "issues-neovim" }
        )
        token_file:close()
      else
        vim.notify(
          "ERROR: GitHub token not found. Configure a token to use the API.",
          vim.log.levels.ERROR,
          { title = "issues-neovim" }
        )
      end
    end
  else
    vim.notify(
      "GitHub token configured.",
      vim.log.levels.INFO,
      { title = "issues-neovim" }
    )
  end
  
  -- Check repository information
  local owner, repo = github.get_current_repo()
  if not owner or not repo then
    vim.notify(
      "ERROR: Could not determine the current repository. Are you in a Git repository?",
      vim.log.levels.ERROR,
      { title = "issues-neovim" }
    )
    return false
  else
    vim.notify(
      "Current repository: " .. owner .. "/" .. repo,
      vim.log.levels.INFO,
      { title = "issues-neovim" }
    )
  end
  
  -- Build API URL
  local api_url = github.build_api_url("/issues?state=all")
  if not api_url then
    vim.notify(
      "ERROR: Could not build the API URL",
      vim.log.levels.ERROR,
      { title = "issues-neovim" }
    )
    return false
  else
    vim.notify(
      "API URL: " .. api_url,
      vim.log.levels.INFO,
      { title = "issues-neovim" }
    )
  end
  
  -- Test the API
  vim.notify(
    "Making request to GitHub API...",
    vim.log.levels.INFO,
    { title = "issues-neovim" }
  )
  local issues = github.get_issues(true)
  
  if issues then
    vim.notify(
      "Success! Found " .. #issues .. " issues.",
      vim.log.levels.INFO,
      { title = "issues-neovim" }
    )
    return true
  else
    vim.notify(
      "Failed to get issues. Check the log file for more details.",
      vim.log.levels.ERROR,
      { title = "issues-neovim" }
    )
    return false
  end
end

return M 