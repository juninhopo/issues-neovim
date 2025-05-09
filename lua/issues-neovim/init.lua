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
  
  -- Register commands
  M.register_commands()
  
  -- Setup keymappings if which-key is available
  if pcall(require, "which-key") then
    local wk = require("which-key")
    wk.register({
      [M.config.keymaps.open] = { 
        function()
          M.open_issues_browser()
        end, 
        "GitHub Issues" 
      },
    })
  end
end

-- Register Neovim commands
function M.register_commands()
  vim.api.nvim_create_user_command("GithubIssues", function()
    M.open_issues_browser()
  end, { desc = "Open GitHub Issues browser" })
  
  vim.api.nvim_create_user_command("GithubIssue", function(opts)
    if opts.args and tonumber(opts.args) then
      M.view_issue(tonumber(opts.args))
    else
      vim.notify("Invalid issue number", vim.log.levels.ERROR)
    end
  end, { nargs = 1, desc = "View GitHub issue by number" })
  
  vim.api.nvim_create_user_command("GithubCreateIssue", function()
    M.create_issue()
  end, { desc = "Create a new GitHub issue" })
end

-- Function to open the issues browser
function M.open_issues_browser()
  -- Load the TUI module
  local tui = require("issues-neovim.tui")
  tui.open({
    owner = M.config.github.owner,
    repo = M.config.github.repo,
    token = M.config.github.token,
    ui = M.config.ui
  })
end

-- Function to view a specific issue
function M.view_issue(issue_number)
  -- Load the issue view module
  local issue_view = require("issues-neovim.issue_view")
  issue_view.open(issue_number, {
    owner = M.config.github.owner,
    repo = M.config.github.repo,
    token = M.config.github.token,
    ui = M.config.ui
  })
end

-- Function to create a new issue
function M.create_issue()
  -- Load the issue creation module
  local issue_create = require("issues-neovim.issue_create")
  issue_create.open({
    owner = M.config.github.owner,
    repo = M.config.github.repo,
    token = M.config.github.token,
    ui = M.config.ui
  })
end

return M 