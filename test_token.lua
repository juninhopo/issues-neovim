-- Simple script to check if GitHub token is available

-- Check environment variable
local env_token = os.getenv("GITHUB_TOKEN")
print("GitHub token from environment: " .. (env_token and "FOUND" or "NOT FOUND"))

-- Try to open token files
local function check_file(path)
  local expanded_path = vim.fn.expand(path)
  local f = io.open(expanded_path, "r")
  if f then
    local token = f:read("*line")
    f:close()
    return token and #token > 0
  end
  return false
end

print("GitHub token in ~/.githubtoken: " .. (check_file("~/.githubtoken") and "FOUND" or "NOT FOUND"))
print("GitHub token in ~/.config/issues-neovim/token: " .. (check_file("~/.config/issues-neovim/token") and "FOUND" or "NOT FOUND")) 