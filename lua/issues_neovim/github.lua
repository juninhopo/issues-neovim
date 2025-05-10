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

---Setup the GitHub module
function M.setup()
  -- Validate config
  M.set_token()
  
  -- Try to get the repository from git config
  M.get_current_repo()
end

---Set GitHub token from various sources
function M.set_token()
  if config.token and config.token ~= "" then
    return true
  end
  
  -- Try to get token from environment variable
  local env_token = os.getenv("GITHUB_TOKEN")
  if env_token and env_token ~= "" then
    config.token = env_token
    return true
  end
  
  -- Try to get token from file
  local token_path = Path:new(vim.fn.expand("~/.config/github_token"))
  if token_path:exists() then
    config.token = token_path:read()
    config.token = vim.trim(config.token)
    return true
  end
  
  -- Create a GitHub token file with instructions
  if not token_path:exists() then
    local instructions = [[
# GitHub Personal Access Token
# 
# To use the issues-neovim plugin, you need to create a GitHub personal access token.
# Follow these steps:
#
# 1. Go to https://github.com/settings/tokens
# 2. Click on "Generate new token" > "Generate new token (classic)"
# 3. Name the token something like "issues-neovim"
# 4. Select the "repo" scope for repository access
# 5. Click on "Generate token"
# 6. Copy the generated token and paste it below, removing this comment
#
# Example:
# ghp_1234567890abcdefghijklmnopqrstuvwxyz
]]
    token_path:write(instructions, "w")
    vim.notify(
      "GitHub token file created at " .. token_path:absolute() .. ". Please follow the instructions in the file.",
      vim.log.levels.WARN,
      { title = "issues-neovim" }
    )
  end
  
  vim.notify(
    "GitHub token not configured. Some features may not work properly.",
    vim.log.levels.WARN,
    { title = "issues-neovim" }
  )
  return false
end

---Get the current repository from git config
---@return string|nil owner Repository owner
---@return string|nil repo Repository name
function M.get_current_repo()
  local result = utils.get_git_repo_info()
  if result then
    M.cache.owner = result.owner
    M.cache.repository = result.repo
    return result.owner, result.repo
  end
  
  return nil, nil
end

---Build the API URL for the current repository
---@param endpoint string The API endpoint to append
---@return string|nil url The full API URL
function M.build_api_url(endpoint)
  if not M.cache.owner or not M.cache.repository then
    if not M.get_current_repo() then
      return nil
    end
  end
  
  return string.format(
    "%s/repos/%s/%s%s", 
    config.api_url, 
    M.cache.owner, 
    M.cache.repository,
    endpoint or ""
  )
end

---Make a request to the GitHub API
---@param url string The API URL to request
---@param method string The HTTP method to use
---@return table|nil response The parsed API response
function M.api_request(url, method)
  method = method or "GET"
  
  local headers = {
    Accept = "application/vnd.github.v3+json",
  }
  
  if config.token then
    headers.Authorization = "token " .. config.token
  end
  
  -- Use a simpler approach, without callbacks
  local response = curl.get(url, {
    headers = headers,
    timeout = 10000,
  })
  
  -- Debug log
  local log_path = vim.fn.stdpath("data") .. "/github_api_debug.log"
  local log_file = io.open(log_path, "w")
  if log_file then
    log_file:write("URL: " .. url .. "\n")
    log_file:write("Status: " .. (response.status or "unknown") .. "\n")
    log_file:write("Headers: " .. vim.inspect(response.headers or {}) .. "\n")
    log_file:write("Body snippet: " .. string.sub(response.body or "", 1, 200) .. "...\n")
    log_file:close()
  end
  
  if not response or response.status ~= 200 then
    local error_msg = response and response.body or "Failed to connect to GitHub API"
    vim.notify(
      "GitHub API error: " .. error_msg,
      vim.log.levels.ERROR,
      { title = "issues-neovim" }
    )
    return nil
  end
  
  -- Decode JSON with error handling
  local success, result = pcall(vim.json.decode, response.body)
  if not success then
    vim.notify(
      "Error processing JSON response from GitHub API",
      vim.log.levels.ERROR,
      { title = "issues-neovim" }
    )
    return nil
  end
  
  return result
end

---Get issues for the current repository
---@param force_refresh boolean Whether to force a refresh of cached issues
---@return issues_neovim.github.Issue[]|nil issues The list of issues
function M.get_issues(force_refresh)
  if M.cache.issues and #M.cache.issues > 0 and not force_refresh then
    return M.cache.issues
  end
  
  -- Add 'pulls=false' parameter to exclude pull requests
  local api_url = M.build_api_url("/issues?state=all&pulls=false")
  if not api_url then
    vim.notify(
      "Could not determine repository information",
      vim.log.levels.ERROR,
      { title = "issues-neovim" }
    )
    return nil
  end
  
  local issues = M.api_request(api_url)
  if issues then
    -- Filter out pull requests that might still come through
    local filtered_issues = {}
    for _, issue in ipairs(issues) do
      if not issue.pull_request then
        table.insert(filtered_issues, issue)
      end
    end
    M.cache.issues = filtered_issues
    return filtered_issues
  end
  
  return nil
end

---Get a specific issue by number
---@param issue_number number The issue number to get
---@param force_refresh boolean Whether to force a refresh of cached issues
---@return issues_neovim.github.Issue|nil issue The issue
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

---Get comments for a specific issue
---@param issue_number number The issue number to get comments for
---@param force_refresh boolean Whether to force a refresh of cached comments
---@return issues_neovim.github.Comment[]|nil comments The comments
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

---Debug function for API response
---@param url string The API URL to debug
---@return table debug_info Debug information about the API response
function M.debug_api_response(url)
  local headers = {
    Accept = "application/vnd.github.v3+json",
  }
  
  if config.token then
    headers.Authorization = "token " .. config.token
  end
  
  local response = curl.request({
    url = url,
    method = "GET",
    headers = headers,
  })
  
  local debug_info = {
    status = response.status,
    headers = vim.inspect(response.headers),
    body_snippet = string.sub(response.body or "", 1, 100) .. "...",
    success = response.status >= 200 and response.status < 300
  }
  
  -- Log to file for inspection
  local log_path = vim.fn.stdpath("data") .. "/github_api_debug.log"
  local file = io.open(log_path, "w")
  if file then
    file:write("URL: " .. url .. "\n")
    file:write("Status: " .. debug_info.status .. "\n")
    file:write("Headers: " .. debug_info.headers .. "\n")
    file:write("Body: " .. (response.body or "") .. "\n")
    file:close()
    vim.notify(
      "Debug info written to " .. log_path,
      vim.log.levels.INFO,
      { title = "issues-neovim" }
    )
  end
  
  return debug_info
end

return M 