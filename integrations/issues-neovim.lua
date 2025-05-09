-- issues-neovim.lua
-- Add this file to ~/.config/nvim/lua/plugins/
-- This will register the "GitHub Issues" command in the LazyVim menu

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>g"] = { name = "+Git" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.register({
        ["<leader>gi"] = { 
          function()
            -- Get the current directory to ensure the command is executed in the correct context
            local current_dir = vim.fn.getcwd()
            
            -- Open the floating terminal for the issues-neovim TUI interface
            vim.cmd(string.format(
              "FloatermNew --height=0.9 --width=0.9 --title=GitHub\\ Issues cd %s && issues-neovim tui",
              vim.fn.shellescape(current_dir)
            ))
          end, 
          "GitHub Issues" 
        },
      })
    end,
    dependencies = {
      {
        "voldikss/vim-floaterm",
        config = function()
          vim.g.floaterm_autoclose = 1
        end
      }
    }
  },
} 