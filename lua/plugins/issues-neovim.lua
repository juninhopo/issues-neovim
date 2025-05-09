return {
  {
    "juninhopo/issues-neovim",
    dependencies = {
      "folke/which-key.nvim",
      "voldikss/vim-floaterm",
      "nvim-lua/plenary.nvim", -- Required for Job API in install script
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
    -- Run installation script once on plugin install
    build = function()
      local plugin_dir = vim.fn.stdpath("data") .. "/lazy/issues-neovim"
      vim.fn.system("cd " .. plugin_dir .. " && npm install && npm link")
    end,
  }
} 