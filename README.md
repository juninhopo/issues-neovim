# Issues Neovim

A Neovim plugin for managing GitHub issues directly from your editor. No JavaScript or external dependencies required - fully implemented in Lua!

## Features

- Browse open and closed issues
- View issue details and comments
- Create new issues
- Comment on existing issues
- Search issues
- Automatic repository detection based on git remote URL
- Beautiful floating UI using native Neovim windows

## Requirements

- Neovim 0.7+ 
- Dependencies defined in plugin spec:
  - [folke/which-key.nvim](https://github.com/folke/which-key.nvim)
  - [voldikss/vim-floaterm](https://github.com/voldikss/vim-floaterm)
  - [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
  - [rcarriga/nvim-notify](https://github.com/rcarriga/nvim-notify)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
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
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'juninhopo/issues-neovim',
  requires = {
    'folke/which-key.nvim',
    'voldikss/vim-floaterm',
    'nvim-lua/plenary.nvim',
    'rcarriga/nvim-notify',
  },
  config = function()
    require('issues-neovim').setup({
      -- Your configuration options here
      github = {
        token = vim.env.GITHUB_TOKEN,
      },
    })
  end
}
```

## Configuration

### GitHub Authentication

To use this plugin, you need a GitHub personal access token with the appropriate permissions to access repositories and manage issues.

1. Create a personal access token on GitHub: [https://github.com/settings/tokens](https://github.com/settings/tokens)
2. Grant it the `repo` scope for full repository access
3. Set the token in your environment or directly in your Neovim config:

```lua
-- Option 1: Set in your shell environment (recommended)
-- export GITHUB_TOKEN=your_token_here

-- Option 2: Set directly in your Neovim config (less secure)
require('issues-neovim').setup({
  github = {
    token = "your_token_here", -- Not recommended to hardcode
  }
})
```

### Default Configuration

```lua
require('issues-neovim').setup({
  -- Default keybinding settings
  keymaps = {
    -- Open issues-neovim
    open = "<leader>gi",
  },
  
  -- Default UI settings
  ui = {
    -- Float window settings
    float = {
      height = 0.9,
      width = 0.9,
      title = "GitHub Issues",
    },
  },
  
  -- GitHub related settings
  github = {
    token = nil, -- Will use GITHUB_TOKEN env var if nil
    owner = nil, -- Will detect from current repository if nil
    repo = nil,  -- Will detect from current repository if nil
  },
  
  -- API settings
  api = {
    url = "https://api.github.com",
    cache_enabled = true,
    cache_duration = 5 * 60 * 1000, -- 5 minutes in milliseconds
    request_retries = 3,
    request_retry_delay = 1000, -- 1 second
  },
})
```

## Usage

Once installed, you can use the following commands:

### Commands

- `:GithubIssues` - Open the issues browser
- `:GithubIssue <number>` - View a specific issue by number
- `:GithubCreateIssue` - Create a new issue

### Default Keybindings

- `<leader>gi` - Open the issues browser

### Issue Browser Keybindings

When in the issues browser:

- `j/k` - Navigate through issues
- `Enter` - View issue details
- `c` - Add a comment to the selected issue
- `n` - Create a new issue
- `r` - Refresh issues list
- `o` - Toggle between open and closed issues
- `s` - Search issues
- `l` - View API rate limits
- `q` - Close the browser

## License

Licensed under the ISC License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

Created by [juninhopo](https://github.com/juninhopo)
