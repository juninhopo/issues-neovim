-- Main initialization file for issues-neovim

local M = {}

-- Default configuration
M.config = {
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

-- Setup function called by Lazy.nvim
function M.setup(opts)
  -- Merge user config with defaults
  opts = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Store the configuration
  M.config = opts
  
  -- Setup GitHub token from environment if not set
  if not M.config.github.token then
    M.config.github.token = vim.env.GITHUB_TOKEN
  end
  
  -- Register the GitHub token for the CLI to use
  if M.config.github.token then
    vim.g.github_token = M.config.github.token
  end
  
  -- Setup keymappings if which-key is available
  if pcall(require, "which-key") then
    local wk = require("which-key")
    wk.register({
      [M.config.keymaps.open] = { 
        function()
          local current_dir = vim.fn.getcwd()
          vim.cmd(string.format(
            "FloatermNew --height=%s --width=%s --title=%s cd %s && issues-neovim tui",
            M.config.ui.float.height,
            M.config.ui.float.width,
            vim.fn.shellescape(M.config.ui.float.title),
            vim.fn.shellescape(current_dir)
          ))
        end, 
        "GitHub Issues" 
      },
    })
  end
end

return M 