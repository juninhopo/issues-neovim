-- Configuration module for issues-neovim
local M = {}

-- Default configuration
M.defaults = {
  -- Default keybinding settings
  keymaps = {
    -- Open issues-neovim in floating terminal
    open = "<leader>gi",
  },
  
  -- Default UI settings
  ui = {
    -- Float window settings
    float = {
      height = 0.9,
      width = 0.9,
      title = "GitHub Issues",
    },
  },
  
  -- GitHub related settings
  github = {
    token = nil, -- Will use GITHUB_TOKEN env var if nil
    owner = nil, -- Will detect from current repository if nil
    repo = nil,  -- Will detect from current repository if nil
  },
  
  -- API settings
  api = {
    url = "https://api.github.com",
    cache_enabled = true,
    cache_duration = 5 * 60 * 1000, -- 5 minutes in milliseconds
    request_retries = 3,
    request_retry_delay = 1000, -- 1 second
  },
}

-- Load user configuration from file
function M.load_user_config()
  local config_path = vim.fn.stdpath("config") .. "/issues-neovim-config.lua"
  
  -- Check if user config file exists
  if vim.fn.filereadable(config_path) == 1 then
    local ok, user_config = pcall(dofile, config_path)
    if ok and type(user_config) == "table" then
      return user_config
    else
      vim.notify("Failed to load user config: " .. config_path, vim.log.levels.WARN)
    end
  end
  
  return {}
end

-- Merge default and user configuration
function M.merge(user_config)
  return vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

-- Setup configuration
function M.setup(opts)
  local user_file_config = M.load_user_config()
  
  -- First merge user file config with defaults
  local config = vim.tbl_deep_extend("force", M.defaults, user_file_config)
  
  -- Then merge with explicit options passed to setup()
  config = vim.tbl_deep_extend("force", config, opts or {})
  
  -- Setup API module with config
  require("issues-neovim.api").setup({
    api_url = config.api.url,
    user_agent = "Neovim-IssuesNeovim",
    cache_enabled = config.api.cache_enabled,
    cache_duration = config.api.cache_duration,
    request_retries = config.api.request_retries,
    request_retry_delay = config.api.request_retry_delay,
  })
  
  return config
end

return M 