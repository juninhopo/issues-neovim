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
    -- Option 1: Use build string instead of function (more reliable in some cases)
    build = "cd ~/.local/share/nvim/lazy/issues-neovim && npm install && npm link",
    
    -- Option 2: Alternative using build function with Job API (safer for async operations)
    -- Uncomment this and comment out the string version above if needed
    -- build = function()
    --   local Job = require("plenary.job")
    --   local plugin_dir = vim.fn.stdpath("data") .. "/lazy/issues-neovim"
    --   Job:new({
    --     command = "npm",
    --     args = { "install" },
    --     cwd = plugin_dir,
    --     on_exit = function(_, exit_code)
    --       if exit_code == 0 then
    --         Job:new({
    --           command = "npm",
    --           args = { "link" },
    --           cwd = plugin_dir,
    --         }):start()
    --       end
    --     end,
    --   }):start()
    -- end,
  }
} 