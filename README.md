# issues-neovim

A Neovim plugin to view and manage GitHub issues directly from your editor. This plugin integrates with GitHub's API to allow you to browse, view, and (eventually) create/comment on issues without leaving Neovim.

![Screenshot 2025-05-10 at 03 52 27](https://github.com/user-attachments/assets/00f89f2e-cbd4-4f5a-ab5a-26c188f021c6)


## Features

- Lists all open and closed issues in the current repository
- Detailed view of issues with description and comments
- Easily navigate between issues
- Support for refreshing issue data
- Designed to work seamlessly with LazyVim

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
    "nvim-lua/plenary.nvim"
  },
  config = function()
    require("issues_neovim").setup({
      -- Your configuration here (optional)
    })
  end,
}
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
    username = "your-github-username", -- Optional, defaults to juninhopo
    token = nil, -- GitHub Personal Access Token (optional, but recommended)
  },
})
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
