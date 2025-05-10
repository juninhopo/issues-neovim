---@class issues_neovim.utils
local M = {}

-- Format date string from GitHub API format to a more readable format
---@param date_string string
---@return string
function M.format_date(date_string)
  if not date_string then
    return "N/A"
  end
  
  local year, month, day, hour, min = date_string:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+)")
  if not year then
    return date_string
  end
  
  -- Garantir que o formato seja consistente (DD/MM/YYYY)
  return string.format("%02d/%02d/%s", 
    tonumber(day), 
    tonumber(month), 
    year:sub(3, 4)  -- Usar apenas os dois últimos dígitos do ano
  )
end

-- Extract owner and repo from git remote URL
---@return table|nil
function M.get_git_repo_info()
  local handle = io.popen("git config --get remote.origin.url 2>/dev/null")
  if not handle then
    return nil
  end
  
  local result = handle:read("*a")
  handle:close()
  
  if not result or result == "" then
    return nil
  end
  
  -- Clean up the result
  result = result:gsub("%s+$", "")
  
  -- Extract owner and repo from different git URL formats
  local owner, repo
  
  -- Format: https://github.com/owner/repo.git
  owner, repo = result:match("github%.com[/:]([^/]+)/([^/%.]+)%.?g?i?t?$")
  
  if not owner or not repo then
    -- Format: git@github.com:owner/repo.git
    owner, repo = result:match("github%.com[/:]([^/]+)/([^/%.]+)%.?g?i?t?$")
  end
  
  if not owner or not repo then
    return nil
  end
  
  return {
    owner = owner,
    repo = repo
  }
end

-- Truncate a string if it's longer than max_length
---@param str string
---@param max_length number
---@return string
function M.truncate(str, max_length)
  if not str then
    return ""
  end
  
  if #str <= max_length then
    return str
  end
  
  return str:sub(1, max_length - 3) .. "..."
end

-- Create a border with a title
---@param title string
---@param width number
---@param style string
---@return table
function M.create_border(title, width, style)
  style = style or "rounded"
  local border = {}
  
  if style == "rounded" then
    border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
  elseif style == "single" then
    border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" }
  elseif style == "double" then
    border = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" }
  elseif style == "none" then
    border = { " ", " ", " ", " ", " ", " ", " ", " " }
  end
  
  -- Add title to the top border
  if title and #title > 0 then
    local title_str = " " .. title .. " "
    local padding = math.floor((width - #title_str) / 2)
    border[2] = string.rep("─", padding) .. title_str .. string.rep("─", width - padding - #title_str)
  end
  
  return border
end

-- Convert a state string to a colored string
---@param state string
---@return string
function M.colorize_state(state)
  if state == "open" then
    return "%#DiagnosticInfo#OPEN%*"
  elseif state == "closed" then
    return "%#DiagnosticError#CLOSED%*"
  else
    return state
  end
end

-- Escape special characters in strings for pattern matching
---@param str string
---@return string
function M.escape_pattern(str)
  return str:gsub("([^%w])", "%%%1")
end

return M 