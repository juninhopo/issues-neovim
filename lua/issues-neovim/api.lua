-- GitHub API Module
local curl = require("plenary.curl")
local json = require("plenary.json")

local M = {}

-- Cache for API responses
local cache = {}

-- Default config
local config = {
  api_url = "https://api.github.com",
  user_agent = "Neovim-IssuesNeovim",
  cache_enabled = true,
  cache_duration = 5 * 60 * 1000, -- 5 minutes
  request_retries = 3,
  request_retry_delay = 1000, -- ms
}

-- Initialize the API with authentication
function M.setup(opts)
  -- Merge user config with defaults
  config = vim.tbl_deep_extend("force", config, opts or {})
end

-- Helper function to handle API request
local function api_request(method, endpoint, params, data, token)
  -- Build request URL
  local url = config.api_url .. endpoint
  
  -- Prepare headers
  local headers = {
    Accept = "application/vnd.github.v3+json",
    ["User-Agent"] = config.user_agent,
  }
  
  -- Add authentication if token is provided
  if token then
    headers.Authorization = "token " .. token
  end
  
  -- Add URL parameters if provided
  if params then
    local query_params = {}
    for k, v in pairs(params) do
      table.insert(query_params, k .. "=" .. vim.fn.shellescape(tostring(v)))
    end
    
    if #query_params > 0 then
      url = url .. "?" .. table.concat(query_params, "&")
    end
  end
  
  -- Prepare request options
  local opts = {
    method = method,
    url = url,
    headers = headers,
    callback = nil,
    timeout = 10000, -- 10 second timeout
  }
  
  -- Add body data for POST, PATCH, PUT methods
  if data and (method == "POST" or method == "PATCH" or method == "PUT") then
    opts.body = json.encode(data)
    headers["Content-Type"] = "application/json"
  end
  
  -- Execute request with retry logic
  local response, err
  for attempt = 1, config.request_retries do
    local success, result = pcall(function()
      return curl.request(opts)
    end)
    
    if success and result then
      response = result
      break
    else
      err = result or "Request failed"
      -- Wait before retry (except on last attempt)
      if attempt < config.request_retries then
        vim.defer_fn(function() end, config.request_retry_delay)
      end
    end
  end
  
  -- Handle connection errors
  if not response then
    return nil, "Connection error: " .. (err or "Failed to connect to GitHub API")
  end
  
  -- Handle HTTP errors with detailed messages
  if response.status < 200 or response.status >= 300 then
    local error_body = response.body or ""
    local error_message = ""
    
    -- Try to parse the error response from GitHub
    local success, parsed_error = pcall(json.decode, error_body)
    if success and parsed_error and parsed_error.message then
      error_message = parsed_error.message
    else
      error_message = error_body
    end
    
    -- Format error message with HTTP status
    local detailed_error = string.format(
      "HTTP %d: %s", 
      response.status, 
      error_message
    )
    
    -- Add specific guidance for common errors
    if response.status == 401 then
      detailed_error = detailed_error .. " (Authentication failed - check your GitHub token)"
    elseif response.status == 403 then
      detailed_error = detailed_error .. " (Permission denied - check token permissions or rate limits)"
    elseif response.status == 404 then
      detailed_error = detailed_error .. " (Not Found - check repository owner/name)"
    elseif response.status == 422 then
      detailed_error = detailed_error .. " (Validation failed - check your input data)"
    end
    
    return nil, detailed_error
  end
  
  -- Parse response
  local success, parsed = pcall(json.decode, response.body)
  if not success then
    return nil, "Failed to parse response: " .. (parsed or "invalid JSON")
  end
  
  return parsed
end

-- Get cached response or fetch from API
local function get_cached_or_fetch(cache_key, fetch_fn)
  -- Return from cache if enabled and valid
  if config.cache_enabled and cache[cache_key] then
    local cached = cache[cache_key]
    local is_valid = os.time() * 1000 - cached.timestamp < config.cache_duration
    
    if is_valid then
      return cached.data
    end
  end
  
  -- Fetch fresh data
  local data, err = fetch_fn()
  
  -- Handle error
  if not data then
    return nil, err
  end
  
  -- Cache the result if caching is enabled
  if config.cache_enabled then
    cache[cache_key] = {
      data = data,
      timestamp = os.time() * 1000
    }
  end
  
  return data
end

-- Clear all cached API responses
function M.clear_cache()
  cache = {}
end

-- API Methods
-- List issues for a repository
function M.list_issues(opts)
  local token = opts.token
  local owner = opts.owner
  local repo = opts.repo
  local state = opts.state or "open"
  local per_page = opts.per_page or 30
  local page = opts.page or 1
  
  local cache_key = string.format("issues:%s:%s:%s:%d:%d", owner, repo, state, page, per_page)
  
  return get_cached_or_fetch(cache_key, function()
    return api_request(
      "GET", 
      "/repos/" .. owner .. "/" .. repo .. "/issues", 
      { 
        state = state,
        per_page = per_page,
        page = page
      }, 
      nil, 
      token
    )
  end)
end

-- Get a single issue by number
function M.get_issue(opts)
  local token = opts.token
  local owner = opts.owner
  local repo = opts.repo
  local issue_number = opts.issue_number
  
  local cache_key = string.format("issue:%s:%s:%d", owner, repo, issue_number)
  
  return get_cached_or_fetch(cache_key, function()
    return api_request(
      "GET", 
      "/repos/" .. owner .. "/" .. repo .. "/issues/" .. issue_number,
      nil, 
      nil, 
      token
    )
  end)
end

-- Get comments for an issue
function M.get_comments(opts)
  local token = opts.token
  local owner = opts.owner
  local repo = opts.repo
  local issue_number = opts.issue_number
  
  local cache_key = string.format("comments:%s:%s:%d", owner, repo, issue_number)
  
  return get_cached_or_fetch(cache_key, function()
    return api_request(
      "GET", 
      "/repos/" .. owner .. "/" .. repo .. "/issues/" .. issue_number .. "/comments",
      nil, 
      nil, 
      token
    )
  end)
end

-- Create a new issue
function M.create_issue(opts)
  local token = opts.token
  local owner = opts.owner
  local repo = opts.repo
  local title = opts.title
  local body = opts.body
  local labels = opts.labels or {}
  
  -- Create issue
  local data, err = api_request(
    "POST", 
    "/repos/" .. owner .. "/" .. repo .. "/issues",
    nil, 
    {
      title = title,
      body = body,
      labels = labels
    }, 
    token
  )
  
  -- Invalidate issues cache
  for k in pairs(cache) do
    if k:match("^issues:" .. owner .. ":" .. repo) then
      cache[k] = nil
    end
  end
  
  return data, err
end

-- Add a comment to an issue
function M.create_comment(opts)
  local token = opts.token
  local owner = opts.owner
  local repo = opts.repo
  local issue_number = opts.issue_number
  local body = opts.body
  
  -- Create comment
  local data, err = api_request(
    "POST", 
    "/repos/" .. owner .. "/" .. repo .. "/issues/" .. issue_number .. "/comments",
    nil, 
    { body = body }, 
    token
  )
  
  -- Invalidate comments cache
  local cache_key = string.format("comments:%s:%s:%d", owner, repo, issue_number)
  cache[cache_key] = nil
  
  return data, err
end

-- Search for issues
function M.search_issues(opts)
  local token = opts.token
  local query = opts.query
  local per_page = opts.per_page or 30
  
  local cache_key = string.format("search:%s:%d", query, per_page)
  
  return get_cached_or_fetch(cache_key, function()
    local data, err = api_request(
      "GET", 
      "/search/issues", 
      { 
        q = query,
        per_page = per_page
      }, 
      nil, 
      token
    )
    
    if data and data.items then
      return data.items
    else
      return nil, err or "No search results"
    end
  end)
end

-- Check GitHub API rate limits
function M.get_rate_limits(token)
  -- Don't cache rate limits
  return api_request(
    "GET", 
    "/rate_limit", 
    nil, 
    nil, 
    token
  )
end

-- Detect repository from current directory using git
function M.detect_repository()
  local Job = require("plenary.job")
  local result = {
    detected = false,
    owner = nil,
    repo = nil
  }
  
  -- Try to get remote URL
  local remote_job = Job:new({
    command = "git",
    args = { "config", "--get", "remote.origin.url" },
    on_exit = function(j, return_val)
      if return_val ~= 0 then
        return
      end
      
      local remote_url = j:result()[1]
      if not remote_url then
        return
      end
      
      -- Parse GitHub URL to extract owner and repo
      local owner, repo = remote_url:match("github%.com[:/]([^/]+)/(.+)%.git")
      if owner and repo then
        result.detected = true
        result.owner = owner
        result.repo = repo
      end
    end
  })
  
  remote_job:sync()
  return result
end

return M 