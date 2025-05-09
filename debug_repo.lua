-- Debug repository detection
local utils = require("issues-neovim.utils")

print("Testing repository detection...")

-- Check if the current directory is a git repository
local is_git_repo = utils.is_git_repo()
print("Is git repository: " .. tostring(is_git_repo))

if is_git_repo then
  -- Try to get the remote URL
  local remote_url = utils.get_repo_remote_url()
  print("Remote URL: " .. tostring(remote_url))
  
  -- Parse owner and repo from remote URL
  if remote_url then
    local owner, repo = utils.parse_remote_url(remote_url)
    print("Owner: " .. tostring(owner))
    print("Repo: " .. tostring(repo))
  else
    print("Failed to get remote URL")
  end
else
  print("Not a git repository")
end

-- Print current configuration
local issues_neovim = require("issues-neovim")
print("\nCurrent configuration:")
print("Owner: " .. tostring(issues_neovim.config.github.owner))
print("Repo: " .. tostring(issues_neovim.config.github.repo))
print("Token set: " .. tostring(issues_neovim.config.github.token ~= nil and issues_neovim.config.github.token ~= "")) 