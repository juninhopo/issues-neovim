return {
  {
    "juninhopo/issues-neovim",
    dependencies = {
      "folke/which-key.nvim",
      "voldikss/vim-floaterm",
      "nvim-lua/plenary.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("issues-neovim").setup({
        -- Your configuration options here
        github = {
          token = vim.env.GITHUB_TOKEN, -- Set from environment variable
          -- owner = "YourDefaultOwner", -- Optional: Set default repo owner
          -- repo = "YourDefaultRepo",   -- Optional: Set default repo name
        },
      })
    end,
    -- No need for build step since we're using pure Lua
  }
} 