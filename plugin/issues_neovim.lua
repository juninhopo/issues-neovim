-- Check if the plugin has already been loaded
if vim.g.loaded_issues_neovim then
	return
end
vim.g.loaded_issues_neovim = true

-- Shortcut to create commands
local cmd = vim.api.nvim_create_user_command

-- Command to open the main GitHub Issues interface
cmd("IssuesNeovim", function()
	require("issues_neovim").ui.open()
end, {
	desc = "Open GitHub Issues interface",
})

-- Command to run GitHub API diagnostics
cmd("IssuesNeovimDiagnose", function()
	require("issues_neovim").diagnose_github_api()
end, {
	desc = "Diagnose GitHub API connection issues",
})

-- Command to configure the GitHub token
cmd("IssuesNeovimSetupToken", function()
	local token_path = vim.fn.expand("~/.config/github_token")
	vim.cmd("edit " .. token_path)
end, {
	desc = "Configure GitHub token",
})

-- Autocmd to initialize the plugin on Neovim startup
--vim.api.nvim_create_autocmd("VimEnter", {
--  callback = function()
--    -- Load with delay to avoid blocking Neovim initialization
--    vim.defer_fn(function()
--     require("issues_neovim").setup()
--   end, 100)
--  end,
--  group = vim.api.nvim_create_augroup("IssuesNeovimSetup", { clear = true }),
-- })

