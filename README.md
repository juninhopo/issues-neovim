# Issues Neovim

A simple Neovim plugin to manage GitHub issues for projects.

## Installation

### Lazy.nvim Installation

For Neovim users, you can easily install this plugin using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
-- Add to your Lazy.nvim configuration
{
  "juninhopo/issues-neovim",
  dependencies = {
    "voldikss/vim-floaterm",
    "folke/which-key.nvim",
  },
  event = "VeryLazy",
  config = true,
  -- Optional: use a specific commit or version
  -- commit = "main",
  -- version = "*", -- latest stable version
}
```

#### Installing the CLI for Lazy.nvim users

When using Lazy.nvim, you'll also need to install the CLI component. The plugin will automatically detect if the CLI is missing and offer to install it for you. You can:

1. **Let the plugin install it for you**: The first time you run a plugin command, it will prompt you to install the CLI
2. **Install it manually**: Run the CLI installation command
   ```vim
   :LazyVimIssuesInstallCLI
   ```
3. **Global installation**: Install it globally via npm
   ```bash
   # Navigate to the plugin directory
   cd ~/.local/share/nvim/lazy/issues-neovim
   # Install dependencies and link globally
   npm install && npm link
   ```

### CLI Installation

If you're manually cloning the repository (not using Lazy.nvim), follow these steps:

Clone this repository:

```bash
git clone https://github.com/juninhopo/issues-neovim.git
cd issues-neovim
```

Install dependencies:

```bash
npm install
```

Install the CLI globally:

```bash
npm link
```

#### CLI Not Found (Direct Installation)

If you get "command not found" when running `issues-neovim` from a direct installation:

```bash
# Reinstall the CLI globally
cd /path/to/issues-neovim
npm install
npm link
```

## Requirements

- Node.js (version 14 or higher)
- npm (version 6 or higher)
- For Neovim integration:
  - Neovim 0.5+
  - [vim-floaterm](https://github.com/voldikss/vim-floaterm)
  - [which-key.nvim](https://github.com/folke/which-key.nvim) (optional, but recommended)

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

## GitHub Token Configuration

To use the issues-neovim plugin, you need to configure a GitHub personal access token. Follow these steps:

### Creating a GitHub personal access token

1. Go to [github.com](https://github.com) and log in to your account
2. Click on your avatar in the top right corner and select "Settings"
3. In the left sidebar menu, scroll down and click on "Developer settings"
4. Select "Personal access tokens" and then "Fine-grained tokens"
5. Click on "Generate new token"
6. Give your token a name (e.g., "issues-neovim")
7. Set an expiration date for the token
8. Under "Repository access", select the repositories you want to access
9. Under "Permissions":
   - For "Repository permissions":
     - Issues: select "Read and write"
   - For "Organization permissions":
     - If you need to access issues in organizations, configure the appropriate permissions
10. Click on "Generate token"
11. **IMPORTANT**: Copy the generated token immediately, as you won't be able to see it again

### Configuring the token in issues-neovim

1. Add the token to your environment as a variable:

```bash
# Add to your .bashrc, .zshrc, or shell configuration file
export GITHUB_TOKEN="your_token_here"
```

2. Or configure the token directly in Neovim by adding to your init.lua or other configuration file:

```lua
vim.g.github_token = "your_token_here"
```

3. Restart Neovim to apply the changes

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

For read-only operations (listing issues, viewing details, searching) in public repositories, **a GitHub access token is not required**.

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

## Neovim Integration

There are multiple ways to integrate this CLI with Neovim:

### 1. Using Lazy.nvim (recommended)

Add the following to your `~/.config/nvim/lua/plugins/issues-neovim.lua` file:

```lua
return {
  {
    "juninhopo/issues-neovim",
    dependencies = {
      "voldikss/vim-floaterm",
      "folke/which-key.nvim",
    },
    event = "VeryLazy",
    config = function()
      -- Optional: Configure the keybinding
      if require("which-key", true) then
        require("which-key").register({
          ["<leader>gi"] = { 
            function()
              local current_dir = vim.fn.getcwd()
              vim.cmd(string.format(
                "FloatermNew --height=0.9 --width=0.9 --title=GitHub\\ Issues cd %s && issues-neovim tui",
                vim.fn.shellescape(current_dir)
              ))
            end, 
            "GitHub Issues" 
          },
        })
      end
      
      -- Optional: Configure the GitHub token
      -- vim.g.github_token = "your_token_here"
    end,
  },
}
```

This will:
- Add the plugin to your Neovim setup via Lazy.nvim
- Set up a `<leader>gi` shortcut to open GitHub Issues in a floating terminal
- Install the required dependencies (`vim-floaterm` and `which-key.nvim`)

### 2. Manual Floating Terminal Integration

Copy the provided integration file to your Neovim configuration directory:

```bash
cp integrations/issues-neovim.lua ~/.config/nvim/lua/plugins/
```

This will add:
- A `<leader>gi` shortcut to open GitHub Issues in a floating terminal
- Dependency on the `vim-floaterm` plugin to create a floating terminal

### 3. Integrated Terminal Integration

Alternatively, you can add the following to your configuration file:

```lua
-- ~/.config/nvim/lua/plugins/issues-neovim.lua
return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>g"] = { name = "+GitHub" },
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
        ["<leader>gi"] = { "<cmd>terminal issues-neovim<cr>", "GitHub Issues" },
      })
    end,
  },
}
```

This will add a `<leader>gi` shortcut to open the issues CLI in Neovim's integrated terminal.

## Advanced Configuration

When using the plugin via Lazy.nvim, you can customize it by providing configuration options:

```lua
return {
  {
    "juninhopo/issues-neovim",
    dependencies = {
      "voldikss/vim-floaterm",
      "folke/which-key.nvim",
    },
    opts = {
      -- Custom keybinding (optional)
      keymaps = {
        open = "<leader>gi", -- Change to your preferred keybinding
      },
      
      -- UI settings (optional)
      ui = {
        float = {
          height = 0.9,
          width = 0.9,
          title = "GitHub Issues",
        },
      },
      
      -- GitHub settings (optional)
      github = {
        token = nil, -- Will use GITHUB_TOKEN env var if nil
        owner = "owner", -- Change to target repository owner
        repo = "repository",  -- Change to target repository name
      },
    },
  },
}
```

### Available Commands

After installation, you can use:

1. **Via keyboard shortcut**: Press `<leader>gi` (or your configured keybinding)
2. **Via command**: Run `:IssuesNeovim` in Neovim

### Configuration Options

| Option                | Default        | Description                              |
|-----------------------|----------------|------------------------------------------|
| `keymaps.open`        | `<leader>gi`   | Keyboard shortcut to open the issues TUI |
| `ui.float.height`     | `0.9`          | Floating window height (0.0-1.0)         |
| `ui.float.width`      | `0.9`          | Floating window width (0.0-1.0)          |
| `ui.float.title`      | `GitHub Issues`| Floating window title                    |
| `github.token`        | `nil`          | GitHub token (uses GITHUB_TOKEN env var if nil) |
| `github.owner`        | `owner`        | GitHub repository owner                  |
| `github.repo`         | `repository`   | GitHub repository name                   |

## Development

### Available Scripts

- `npm start`: Start the TUI interface (default)
- `npm run tui`: Explicitly start the TUI interface
- `npm run check-limits`: Check GitHub API rate limits

## License

ISC

## Troubleshooting and Debugging

If you encounter issues with the plugin or CLI, you can use several tools to diagnose the problems:

### Using the Neovim Health Check

Run the following command inside Neovim to check the health of the plugin:

```vim
:checkhealth issues-neovim
```

This will run diagnostics that verify:
- Node.js installation
- Required dependencies
- GitHub token configuration
- Plugin installation status
- API connectivity

### Debug Commands

#### Basic System Information

```bash
issues-neovim debug
```

Inside Neovim, you can also run:

```vim
:LazyVimIssuesDebug
```

This will show:
- System information
- Node.js version
- Environment configuration
- Token status (without showing the token value)

#### Full Diagnostic Report

For comprehensive diagnostics, run:

```bash
issues-neovim diagnose
# Or with npm:
npm run diagnose
```

Inside Neovim:

```vim
:LazyVimIssuesDiagnose
```

This creates a complete diagnostic report including:
- System information
- Installation details
- Configuration status
- Recent logs
- Dependencies check
- GitHub API connectivity

The report is saved to `~/.issues-neovim/diagnostic-report-[timestamp].txt`

### Enabling Verbose Logging

For detailed logs to help diagnose issues:

```bash
DEBUG=issues-neovim:* issues-neovim tui
```

This enables debug logging for all components. You can also enable logging for specific components:

```bash
DEBUG=issues-neovim:cli,issues-neovim:api issues-neovim tui
```

### Log Files

Logs are saved in the `~/.issues-neovim/debug.log` file. When reporting an issue, please include:

1. The output of `:checkhealth issues-neovim`
2. The diagnostic report from `issues-neovim diagnose`
3. The relevant sections from the debug.log file

### Common Issues and Solutions

#### CLI Not Found (Lazy.nvim Users)

If you're using Lazy.nvim and get an error about the CLI not being found:

1. Run the built-in installation command:
   ```vim
   :LazyVimIssuesInstallCLI
   ```

2. Or install manually:
   ```bash
   cd ~/.local/share/nvim/lazy/issues-neovim
   npm install
   npm link
   ```

3. Or install globally:
   ```bash
   npm install -g issues-neovim
   ```

#### Authentication Errors

If you see authentication errors:

1. Check your GitHub token is correctly set:
   ```bash
   echo $GITHUB_TOKEN | wc -c
   ```
   Should return a number greater than 1

2. Verify token permissions (should have repo and issues access)

3. Try setting the token directly in your configuration:
   ```lua
   vim.g.github_token = "your_token_here"
   ```

#### TUI Display Issues

If the TUI interface appears broken:
1. Check terminal type and compatibility
2. Try updating the `blessed` and `blessed-contrib` dependencies
3. Set `TERM=xterm-256color` environment variable