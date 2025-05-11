# Issues Neovim

A Neovim plugin to view and manage GitHub issues directly from your editor. This plugin integrates with GitHub's API to allow you to browse, view, and (eventually) create/comment on issues without leaving Neovim.

![Screenshot 2025-05-10 at 03 57 48](https://github.com/user-attachments/assets/6e8a84bf-808c-4e38-b760-e1416960faa7)
![Screenshot 2025-05-10 at 03 58 41](https://github.com/user-attachments/assets/60644310-56ad-4e2a-a5b6-e283d5b95bdd)


## Features

| Features                          | Done               |
| --------------------------------- | ------------------ |
| List issues on Public Repository  | ✅                 |
| List Issues on Private Repository | ❌                 |
| Details Issue                     | ✅                 |
| Create Issue                      | ❌                 |
| Close Issue                       | ❌                 |
| Re-open Issue                     | ❌                 |
| Comment Issue                     | ❌                 |

## Requirements

- Neovim 0.8.0+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for HTTP requests and utilities)
- Git repository connected to GitHub

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "juninhopo/issues-neovim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "voldikss/vim-floaterm"
  },
  dev = false, -- Garantir que não está em modo de desenvolvimento
  pin = false, -- Não fixar versão
  enable = true, -- Garantir que está habilitado
  priority = 50, -- Prioridade normal de carregamento
  lazy = false, -- Carregar durante a inicialização
  branch = "main", -- Usar a branch main
},
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "juninhopo/issues-neovim",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    require("issues_neovim").setup()
  end
}
```

## Configuration

You can configure the plugin by passing a table to the setup function:

```lua
return {
  "juninhopo/issues-neovim",
  dependencies = {
    "nvim-lua/plenary.nvim"
  },
  config = function()
    require("issues_neovim").setup({
      enabled = true,
      keys = {
        open = "<leader>gi",
        close = "q",
        refresh = "r",
        navigate = { prev = "k", next = "j" },
        view_details = "<CR>",
        create_issue = "c",
        add_comment = "a",
      },
      ui = {
        width = 0.8,
        height = 0.8,
        border = "rounded",
        title = "GitHub Issues",
      },
      github = {
        api_url = "https://api.github.com",
        -- Optional: Set your GitHub username if different from juninhopo
        -- username = "your-github-username",
        -- Optional: Set your GitHub token here or use one of the other methods mentioned in the docs
        -- token = nil, -- Will check environment variables and ~/.config/github_token
      },
    })
  end,
}
```

### GitHub Authentication

For private repositories or better rate limits, a GitHub token is recommended. The plugin will look for a token in the following order:

1. Token set directly in configuration:
   ```lua
   require("issues_neovim").setup({
     github = {
       token = "your-github-token"
     }
   })
   ```

2. Environment variable `GITHUB_TOKEN` in your shell (e.g., in `.zshrc`):
   ```bash
   export GITHUB_TOKEN="your-github-token"
   ```

3. Token stored in file `~/.config/github_token`

To create a GitHub token, visit: https://github.com/settings/tokens
For basic repository access, the `repo` scope should be sufficient.

## Usage

- Open the issues list: `<leader>gi` or `:IssuesNeovim`
- Navigate between issues: `j/k` (or your configured keys)
- View issue details: `<CR>` (Enter)
- Refresh issues: `r`
- Close the window: `q`

## Commands

- `:IssuesNeovim` - Open the issues list
- `:IssuesNeovimRefresh` - Refresh the list of issues

## Troubleshooting

- **API errors**: Make sure your GitHub token has the correct permissions
- **No issues found**: Verify that you're in a valid git repository with a GitHub remote
- **Plugin doesn't load**: Check that plenary.nvim is installed and accessible

## License

MIT

## Author

juninhopo
