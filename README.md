# LazyVim Issues CLI

A simple CLI to manage GitHub issues for the [LazyVim](https://github.com/LazyVim/LazyVim) project.

## Installation

Clone this repository:

```bash
git clone https://github.com/juninhopo/issues-cli.git
cd issues-cli
```

Install dependencies:

```bash
npm install
```

Install the CLI globally:

```bash
npm link
```

## GitHub API Rate Limits

The GitHub API imposes rate limits that may affect this CLI's usage:

- Unauthenticated users: 60 requests per hour (IP-based)
- Authenticated users: 5,000 requests per hour
- The search API has a separate limit of 30 requests per minute

### Checking your current limits

You can check your current rate limit status using:

```bash
npm run check-limits
```

or, if globally installed:

```bash
gh-rate-limit
```

In the TUI interface, you can press `5` to see current limits.

### Handling rate limit errors

If you receive a "Request quota exhausted" message, it means you've hit the rate limit. To resolve:

1. **Authenticate with a token**: Set the `GITHUB_TOKEN` environment variable
   ```bash
   export GITHUB_TOKEN=your_token_here
   ```

2. **Wait for the limit reset**: The CLI will show when the limit will be reset

3. **Reduce unnecessary queries**: Avoid reloading the issue list repeatedly

## Usage

### Terminal User Interface (TUI)

To start the TUI similar to Lazygit, you can run:

```bash
issues-neovim
```

or

```bash
issues-neovim tui
```

The TUI allows you to:
- Navigate open and closed issues
- View complete issue details
- Create new issues
- Add comments to issues
- Search issues by term
- Check API rate limits

#### Keyboard Shortcuts in TUI
- `↑/↓`: Navigate through the issues list
- `Enter`: View selected issue details
- `Tab`: Toggle between the issues list and details
- `c`: Comment on selected issue
- `r`: Refresh issues list
- `5`: Check GitHub API limits
- `q`: Exit application
- `1`: View open issues
- `2`: View closed issues
- `3`: Search issues
- `4`: Create a new issue

### Command Line Mode

### Authentication

For read-only operations (listing issues, viewing details, searching) in public repositories like LazyVim, **a GitHub access token is not required**.

For write operations (creating issues, commenting), you'll need a GitHub personal access token with permissions for issues. You can configure the token as an environment variable:

```bash
export GITHUB_TOKEN=your_token_here
```

If you don't configure the token and try to perform an operation that requires it, the CLI will prompt you for the token when needed.

### Available Commands

#### List issues

```bash
issues-neovim list
```

Options:
- `-o, --open`: List only open issues (default)
- `-c, --closed`: List only closed issues
- `-l, --limit <number>`: Maximum number of issues to display (default: 10)

#### View issue details

```bash
issues-neovim view <number>
```

#### Create a new issue

```bash
issues-neovim create
```

#### Add a comment to an issue

```bash
issues-neovim comment <number>
```

#### Search issues by term

```bash
issues-neovim search <term>
```

## LazyVim Integration

There are two ways to integrate this CLI with LazyVim:

### 1. Floating terminal integration (recommended)

Copy the provided integration file to your LazyVim configuration directory:

```bash
cp integrations/issues-neovim.lua ~/.config/nvim/lua/plugins/
```

This will add:
- A `<leader>gi` shortcut to open LazyVim Issues in a floating terminal
- Dependency on the `vim-floaterm` plugin to create a floating terminal

### 2. Integrated terminal integration

Alternatively, you can add the following to your configuration file:

```lua
-- ~/.config/nvim/lua/plugins/issues-neovim.lua
return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>L"] = { name = "+LazyVim" },
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
        ["<leader>Li"] = { "<cmd>terminal issues-neovim<cr>", "LazyVim Issues" },
      })
    end,
  },
}
```

This will add a `<leader>Li` shortcut to open the issues CLI in Neovim's integrated terminal.

## Development

### Requirements

- Node.js (version 14 or higher)
- npm (version 6 or higher)

### Available Scripts

- `npm start`: Start the TUI interface (default)
- `npm run tui`: Explicitly start the TUI interface
- `npm run check-limits`: Check GitHub API rate limits

## License

ISC