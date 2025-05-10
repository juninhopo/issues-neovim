return {
  "juninhopo/issues-neovim",
  dependencies = {
    "nvim-lua/plenary.nvim"
  },
  keys = {
    { "<leader>gi", "<cmd>IssuesNeovim<cr>", desc = "GitHub Issues" },
  },
  config = function()
    require("issues_neovim").setup({
      -- Default configuration is used unless overridden here
    })
  end,
} 