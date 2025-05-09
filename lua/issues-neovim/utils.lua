-- Utilities module for issues-neovim
local M = {}

-- Split a string into lines
function M.split_lines(str)
  if not str or str == "" then
    return {}
  end
  
  local lines = {}
  for line in string.gmatch(str, "[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

-- Parse ISO 8601 date string to timestamp
function M.parse_iso_date(date_str)
  if not date_str then return 0 end
  
  -- Parse ISO 8601 format: 2023-01-30T15:30:45Z
  local year, month, day, hour, min, sec = 
    date_str:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
  
  if not year then
    -- Fallback if format doesn't match
    return os.time()
  end
  
  return os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec)
  })
end

-- Truncate string if longer than max_length
function M.truncate(str, max_length)
  if not str then return "" end
  if #str <= max_length then return str end
  
  return string.sub(str, 1, max_length - 3) .. "..."
end

-- Format relative time (e.g., "2 hours ago")
function M.relative_time(timestamp)
  local diff = os.time() - timestamp
  
  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins .. " minute" .. (mins == 1 and "" or "s") .. " ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. " hour" .. (hours == 1 and "" or "s") .. " ago"
  elseif diff < 2592000 then -- ~30 days
    local days = math.floor(diff / 86400)
    return days .. " day" .. (days == 1 and "" or "s") .. " ago"
  elseif diff < 31536000 then -- ~365 days
    local months = math.floor(diff / 2592000)
    return months .. " month" .. (months == 1 and "" or "s") .. " ago"
  else
    local years = math.floor(diff / 31536000)
    return years .. " year" .. (years == 1 and "" or "s") .. " ago"
  end
end

-- Format file size
function M.format_size(size)
  local suffix = {"B", "KB", "MB", "GB", "TB"}
  local i = 1
  
  while size > 1024 and i < #suffix do
    size = size / 1024
    i = i + 1
  end
  
  return string.format("%.1f %s", size, suffix[i])
end

-- Escape special characters in a string for use in patterns
function M.escape_pattern(str)
  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

-- Create a debounced function
function M.debounce(func, delay)
  local timer = nil
  return function(...)
    local args = {...}
    
    if timer then
      timer:stop()
      timer = nil
    end
    
    timer = vim.defer_fn(function()
      func(unpack(args))
      timer = nil
    end, delay)
  end
end

-- Wrap text to fit within a specific width
function M.wrap_text(text, width)
  if not text or text == "" then
    return {}
  end
  
  local lines = {}
  for paragraph in text:gmatch("([^\n\r]*)[\n\r]*") do
    if paragraph == "" then
      table.insert(lines, "")
    else
      local line = ""
      for word in paragraph:gmatch("%S+") do
        if #line + #word + 1 <= width then
          if line ~= "" then
            line = line .. " " .. word
          else
            line = word
          end
        else
          table.insert(lines, line)
          line = word
        end
      end
      if line ~= "" then
        table.insert(lines, line)
      end
    end
  end
  
  return lines
end

-- Safe JSON encode/decode with error handling
function M.safe_json_encode(data)
  local ok, result = pcall(vim.json.encode, data)
  if not ok then
    return nil, "Failed to encode JSON: " .. tostring(result)
  end
  return result
end

function M.safe_json_decode(json_str)
  local ok, result = pcall(vim.json.decode, json_str)
  if not ok then
    return nil, "Failed to decode JSON: " .. tostring(result)
  end
  return result
end

-- Check if the current directory is a git repository
function M.is_git_repo()
  local result = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")
  return result:match("true") ~= nil
end

-- Get the remote URL for the git repository
function M.get_repo_remote_url()
  -- Try first with origin
  local result = vim.fn.system("git remote get-url origin 2>/dev/null")
  if result and result ~= "" and not result:match("fatal") then
    return vim.trim(result)
  end
  
  -- If origin doesn't exist, try to get any remote
  result = vim.fn.system("git remote 2>/dev/null")
  if result and result ~= "" then
    local remote = vim.split(result, "\n")[1]
    if remote then
      result = vim.fn.system("git remote get-url " .. remote .. " 2>/dev/null")
      if result and result ~= "" and not result:match("fatal") then
        return vim.trim(result)
      end
    end
  end
  
  return nil
end

-- Parse owner and repo from a GitHub remote URL
function M.parse_remote_url(url)
  -- Example patterns:
  -- https://github.com/owner/repo.git
  -- git@github.com:owner/repo.git
  -- git://github.com/owner/repo.git
  
  local owner, repo
  
  -- HTTPS format
  owner, repo = url:match("github%.com[/:]([^/]+)/([^/%.]+)%.?g?i?t?$")
  
  -- Remove any trailing .git
  if repo then
    repo = repo:gsub("%.git$", "")
  end
  
  return owner, repo
end

-- Detect if running on Windows
function M.is_windows()
  return vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1
end

return M 