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
    token = nil, -- Will be loaded from token_loader
    owner = nil, -- Will be auto-detected
    repo = nil,  -- Will be auto-detected
  },
}

-- Setup function called by Lazy.nvim
function M.setup(opts)
  -- Merge user config with defaults
  opts = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Store the configuration
  M.config = opts
  
  -- Load token from various sources if not explicitly set
  if not M.config.github.token then
    local token_loader = require("issues-neovim.token_loader")
    M.config.github.token = token_loader.load_token()
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

-- Auto-detect repository info if not set
function M.detect_repo()
  -- Only detect if owner or repo is not set
  if M.config.github.owner and M.config.github.repo then
    return M.config.github.owner, M.config.github.repo
  end
  
  local utils = require("issues-neovim.utils")
  
  -- Check if in a git repository
  if utils.is_git_repo() then
    -- Get remote URL
    local remote_url = utils.get_repo_remote_url()
    if remote_url then
      -- Parse owner and repo from URL
      local owner, repo = utils.parse_remote_url(remote_url)
      
      -- Update config if parsed successfully
      if owner and repo then
        if not M.config.github.owner then
          M.config.github.owner = owner
        end
        if not M.config.github.repo then
          M.config.github.repo = repo
        end
        return owner, repo
      end
    end
  end
  
  -- Return the current values (might be nil)
  return M.config.github.owner, M.config.github.repo
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
  
  vim.api.nvim_create_user_command("GithubSetToken", function(opts)
    M.set_token(opts.args)
  end, { nargs = 1, desc = "Set GitHub token and save it" })
end

-- Function to set and save GitHub token
function M.set_token(token)
  if not token or token == "" then
    vim.notify("Token cannot be empty", vim.log.levels.ERROR)
    return
  end
  
  local token_loader = require("issues-neovim.token_loader")
  local success, err = token_loader.save_token(token)
  
  if success then
    M.config.github.token = token
    vim.notify("GitHub token saved successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to save token: " .. (err or "unknown error"), vim.log.levels.ERROR)
  end
end

-- Function to open the issues browser
function M.open_issues_browser()
  -- Check if token is available
  if not M.config.github.token or M.config.github.token == "" then
    vim.notify("GitHub token not found. Use :GithubSetToken to set one.", vim.log.levels.ERROR)
    return
  end

  -- Auto-detect repository if not set
  local owner, repo = M.detect_repo()
  
  -- Verify owner and repo are set
  if not owner or not repo then
    vim.notify("Repository owner or name not detected. Please set them manually in your config.", vim.log.levels.ERROR)
    return
  end

  -- Load the TUI module
  local tui = require("issues-neovim.tui")
  tui.open({
    owner = owner,
    repo = repo,
    token = M.config.github.token,
    ui = M.config.ui
  })
end

-- Function to view a specific issue
function M.view_issue(issue_number)
  -- Check if token is available
  if not M.config.github.token or M.config.github.token == "" then
    vim.notify("GitHub token not found. Use :GithubSetToken to set one.", vim.log.levels.ERROR)
    return
  end

  -- Auto-detect repository if not set
  local owner, repo = M.detect_repo()
  
  -- Verify owner and repo are set
  if not owner or not repo then
    vim.notify("Repository owner or name not detected. Please set them manually in your config.", vim.log.levels.ERROR)
    return
  end

  -- Load the issue view module
  local issue_view = require("issues-neovim.issue_view")
  issue_view.open(issue_number, {
    owner = owner,
    repo = repo,
    token = M.config.github.token,
    ui = M.config.ui
  })
end

-- Function to create a new issue
function M.create_issue()
  -- Check if token is available
  if not M.config.github.token or M.config.github.token == "" then
    vim.notify("GitHub token not found. Use :GithubSetToken to set one.", vim.log.levels.ERROR)
    return
  end

  -- Auto-detect repository if not set
  local owner, repo = M.detect_repo()
  
  -- Verify owner and repo are set
  if not owner or not repo then
    vim.notify("Repository owner or name not detected. Please set them manually in your config.", vim.log.levels.ERROR)
    return
  end

  -- Load the issue creation module
  local issue_create = require("issues-neovim.issue_create")
  issue_create.open({
    owner = owner,
    repo = repo,
    token = M.config.github.token,
    ui = M.config.ui
  })
end

return M 