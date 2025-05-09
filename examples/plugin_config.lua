-- Example configuration for issues-neovim plugin
-- Copy this to ~/.config/nvim/lua/plugins/issues-neovim.lua

return {
  {
    "juninhopo/issues-neovim",
    dependencies = {
      "voldikss/vim-floaterm",
      "folke/which-key.nvim",
    },
    event = "VeryLazy",
    -- Basic configuration: use default settings
    config = true,

    -- OR use custom configuration:
    -- opts = {
    --   keymaps = {
    --     open = "<leader>gi", -- Change to your preferred keybinding
    --   },
    --   ui = {
    --     float = {
    --       height = 0.9,
    --       width = 0.9,
    --       title = "GitHub Issues",
    --     },
    --   },
    --   github = {
    --     token = nil, -- Will use GITHUB_TOKEN env var if nil
    --     owner = "LazyVim", -- Change to target repository owner
    --     repo = "LazyVim",  -- Change to target repository name
    --   },
    -- },
  },
} 