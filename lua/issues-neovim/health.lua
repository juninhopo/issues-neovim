-- Health check module for issues-neovim
local M = {}

local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

function M.check()
  start("Issues Neovim")

  -- Check Neovim version
  local nvim_version = vim.version()
  local version_ok = nvim_version.major > 0 or (nvim_version.major == 0 and nvim_version.minor >= 7)
  
  if version_ok then
    ok("Neovim version " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch)
  else
    error("Neovim version " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch .. 
          ". Neovim 0.7.0+ is required.")
  end

  -- Check for required dependencies
  check_dependency("plenary.nvim", "nvim-lua/plenary.nvim", function()
    return pcall(require, "plenary")
  end)
  
  check_dependency("which-key.nvim", "folke/which-key.nvim", function()
    return pcall(require, "which-key")
  end)
  
  check_dependency("vim-floaterm", "voldikss/vim-floaterm", function()
    return vim.fn.exists(":FloatermNew") == 2
  end)
  
  check_dependency("nvim-notify", "rcarriga/nvim-notify", function()
    return pcall(require, "notify")
  end)

  -- Check for git
  local git_ok = os.execute("git --version > /dev/null 2>&1") == 0
  if git_ok then
    ok("Git is installed")
  else
    error("Git is not installed or not in PATH. Git is required for repository detection.")
  end

  -- Check for GitHub token
  check_github_token()

  -- Check for curl support
  local curl_available = pcall(require, "plenary.curl")
  if curl_available then
    ok("Curl module is available")
  else
    error("Curl module is not available. Check plenary.nvim installation.")
  end

  -- Check if we're in a git repository
  check_git_repository()
end

-- Helper function to check for a dependency
local function check_dependency(name, repo, check_fn)
  local installed = check_fn()
  if installed then
    ok(name .. " is installed")
  else
    error(name .. " is not installed. Install it with your plugin manager: " .. repo)
  end
end

-- Check for GitHub token
local function check_github_token()
  local token_loader = require("issues-neovim.token_loader")
  local token = token_loader.load_token()
  
  if token then
    ok("GitHub token is configured")
  else
    warn("GitHub token not found. Set GITHUB_TOKEN environment variable or use :GithubSetToken")
    info("Create a token at https://github.com/settings/tokens and grant it 'repo' scope")
  end
end

-- Check if we're in a git repository
local function check_git_repository()
  local utils = require("issues-neovim.utils")
  
  if utils.is_git_repo() then
    ok("Working in a git repository")
    
    local remote_url = utils.get_repo_remote_url()
    if remote_url then
      local owner, repo = utils.parse_remote_url(remote_url)
      if owner and repo then
        ok("GitHub repository detected: " .. owner .. "/" .. repo)
      else
        warn("Remote URL does not appear to be a GitHub repository: " .. remote_url)
      end
    else
      warn("No GitHub remote URL found")
    end
  else
    warn("Not in a git repository. Repository auto-detection will not work.")
    info("You'll need to manually specify repository details in your configuration")
  end
end

return M 