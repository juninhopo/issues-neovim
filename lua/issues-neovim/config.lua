-- Configuration options for issues-neovim

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
    -- Floaterm settings
    float = {
      height = 0.9,
      width = 0.9,
      title = "GitHub Issues",
    },
  },
  
  -- GitHub related settings
  github = {
    token = nil, -- Will use GITHUB_TOKEN env var if nil
    owner = "LazyVim",
    repo = "LazyVim",
  },
}

-- Apply configuration
function M.apply(opts)
  local config = vim.tbl_deep_extend("force", M.defaults, opts or {})
  
  -- Apply GitHub token from environment if not set explicitly
  if not config.github.token then
    config.github.token = vim.env.GITHUB_TOKEN
  end
  
  -- Set GitHub token for CLI to access
  if config.github.token then
    vim.g.github_token = config.github.token
  end
  
  return config
end

return M 