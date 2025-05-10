-- Script to test the issues-neovim plugin
package.path = package.path .. ";./lua/?.lua"

-- Make sure plenary.nvim is accessible
-- If you get an error, adjust the path to your environment
-- package.path = package.path .. ";/path/to/plenary.nvim/lua/?.lua"

local ok, issues_neovim = pcall(require, "issues_neovim")
if not ok then
  print("Error loading the issues_neovim module:")
  print(issues_neovim)
  os.exit(1)
end

-- Configure the plugin
issues_neovim.setup({
  github = {
    -- Define your GitHub token here, if needed
    -- token = "your_github_token"
  }
})

-- Expose functions for testing in the global scope
_G.open_issues = function()
  issues_neovim.ui.open()
end

print("Plugin issues-neovim loaded successfully!")
print("Run ':lua open_issues()' to open the interface") 