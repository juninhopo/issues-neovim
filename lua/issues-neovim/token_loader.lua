local M = {}
local utils = require("issues-neovim.utils")
local uv = vim.loop

-- Locations to check for tokens
local token_locations = {
  env = "GITHUB_TOKEN",
  home_file = "~/.githubtoken",
  config_file = "~/.config/issues-neovim/token"
}

-- Read token from file
local function read_token_from_file(file_path)
  local expanded_path = vim.fn.expand(file_path)
  local f = io.open(expanded_path, "r")
  if not f then
    return nil
  end
  
  local token = f:read("*line")
  f:close()
  
  if token then
    return token:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
  end
  return nil
end

-- Write token to file
local function write_token_to_file(file_path, token)
  local expanded_path = vim.fn.expand(file_path)
  local dir_path = vim.fn.fnamemodify(expanded_path, ":h")
  
  -- Create directory if it doesn't exist
  if vim.fn.isdirectory(dir_path) == 0 then
    local ok = uv.fs_mkdir(dir_path, 448) -- 0700 in octal
    if not ok then
      return false, "Failed to create directory: " .. dir_path
    end
  end
  
  local f = io.open(expanded_path, "w")
  if not f then
    return false, "Failed to open file for writing: " .. expanded_path
  end
  
  f:write(token)
  f:close()
  
  -- Set secure permissions
  if not utils.is_windows() then
    uv.fs_chmod(expanded_path, 384) -- 0600 in octal
  end
  
  return true
end

-- Load token from various sources
function M.load_token()
  -- Check environment variable first
  local token = os.getenv(token_locations.env)
  if token and token ~= "" then
    return token
  end
  
  -- Check ~/.githubtoken
  token = read_token_from_file(token_locations.home_file)
  if token then
    return token
  end
  
  -- Check ~/.config/issues-neovim/token
  token = read_token_from_file(token_locations.config_file)
  if token then
    return token
  end
  
  return nil
end

-- Save token to the config file
function M.save_token(token)
  if not token or token == "" then
    return false, "Token cannot be empty"
  end
  
  return write_token_to_file(token_locations.config_file, token)
end

return M 