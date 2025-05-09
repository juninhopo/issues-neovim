-- issue-lazyvim.lua
-- Adicione este arquivo em ~/.config/nvim/lua/plugins/
-- Isto irá registrar o comando "GitHub Issues" no menu do LazyVim

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
            -- Obter o diretório atual para garantir que o comando seja executado no contexto correto
            local current_dir = vim.fn.getcwd()
            
            -- Abrir o terminal flutuante para a interface TUI do issue-lazyvim
            vim.cmd(string.format(
              "FloatermNew --height=0.9 --width=0.9 --title=GitHub\\ Issues cd %s && issue-lazyvim tui",
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