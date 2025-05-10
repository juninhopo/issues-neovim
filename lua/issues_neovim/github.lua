---@class issues_neovim.github
local M = {}

local curl = require("plenary.curl")
local Path = require("plenary.path")
local utils = require("issues_neovim.utils")
local config = require("issues_neovim").config.github

---@class issues_neovim.github.Issue
---@field number number
---@field title string
---@field state string
---@field created_at string
---@field updated_at string
---@field closed_at string|nil
---@field user table
---@field body string
---@field comments_url string
---@field comments number
---@field labels table[]

---@class issues_neovim.github.Comment
---@field id number
---@field body string
---@field user table
---@field created_at string
---@field updated_at string

-- Cache for issues and comments
M.cache = {
  issues = {},
  comments = {},
  repository = nil,
  owner = nil,
}

function M.setup()
  -- Validate config
  if not config.token then
    -- Try to get token from environment variable
    local env_token = os.getenv("GITHUB_TOKEN")
    if env_token and env_token ~= "" then
      config.token = env_token
    else
      -- Try to get token from file
      local token_path = Path:new(vim.fn.expand("~/.config/github_token"))
      if token_path:exists() then
        config.token = token_path:read()
        config.token = vim.trim(config.token)
      end
    end
  end
  
  if not config.token then
    vim.notify("GitHub token not found. Some features may not work properly.", vim.log.levels.WARN, { title = "issues-neovim" })
  end
  
  -- Try to get the repository from git config
  M.get_current_repo()
end

-- Get the current repository from git config
function M.get_current_repo()
  local result = utils.get_git_repo_info()
  if result then
    M.cache.owner = result.owner
    M.cache.repository = result.repo
    return result.owner, result.repo
  end
  
  return nil, nil
end

-- Build the API URL for the current repository
function M.build_api_url(endpoint)
  if not M.cache.owner or not M.cache.repository then
    if not M.get_current_repo() then
      return nil
    end
  end
  
  return string.format("%s/repos/%s/%s%s", 
    config.api_url, 
    M.cache.owner, 
    M.cache.repository,
    endpoint or ""
  )
end

-- Make a request to the GitHub API
function M.api_request(url, method)
  method = method or "GET"
  
  local headers = {
    Accept = "application/vnd.github.v3+json",
  }
  
  if config.token then
    headers.Authorization = "token " .. config.token
  end
  
  local response = curl.request({
    url = url,
    method = method,
    headers = headers,
    callback = function(err)
      if err then
        vim.notify("GitHub API error: " .. err, vim.log.levels.ERROR, { title = "issues-neovim" })
      end
    end,
  })
  
  if response.status ~= 200 then
    vim.notify("GitHub API error: " .. (response.body or "Unknown error"), vim.log.levels.ERROR, { title = "issues-neovim" })
    return nil
  end
  
  return vim.json.decode(response.body)
end

-- Get issues for the current repository
---@return issues_neovim.github.Issue[]|nil
function M.get_issues(force_refresh)
  if M.cache.issues and #M.cache.issues > 0 and not force_refresh then
    return M.cache.issues
  end
  
  local api_url = M.build_api_url("/issues?state=all")
  if not api_url then
    vim.notify("Could not determine repository information", vim.log.levels.ERROR, { title = "issues-neovim" })
    return nil
  end
  
  local issues = M.api_request(api_url)
  if issues then
    M.cache.issues = issues
    return issues
  end
  
  return nil
end

-- Get a specific issue by number
---@param issue_number number
---@return issues_neovim.github.Issue|nil
function M.get_issue(issue_number, force_refresh)
  if M.cache.issues and not force_refresh then
    for _, issue in ipairs(M.cache.issues) do
      if issue.number == issue_number then
        return issue
      end
    end
  end
  
  local api_url = M.build_api_url("/issues/" .. issue_number)
  if not api_url then
    return nil
  end
  
  return M.api_request(api_url)
end

-- Get comments for a specific issue
---@param issue_number number
---@return issues_neovim.github.Comment[]|nil
function M.get_comments(issue_number, force_refresh)
  if M.cache.comments[issue_number] and not force_refresh then
    return M.cache.comments[issue_number]
  end
  
  local api_url = M.build_api_url("/issues/" .. issue_number .. "/comments")
  if not api_url then
    return nil
  end
  
  local comments = M.api_request(api_url)
  if comments then
    M.cache.comments[issue_number] = comments
    return comments
  end
  
  return nil
end

return M 