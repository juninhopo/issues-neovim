-- Plugin registration for issues-neovim

if vim.g.loaded_issues_neovim == 1 then
  return
end
vim.g.loaded_issues_neovim = 1

-- Utility function to check CLI availability
local function check_cli_availability()
  local handle = io.popen("which issues-neovim 2>/dev/null")
  if not handle then return false end
  
  local result = handle:read("*a")
  handle:close()
  
  return result and #result > 0
end

-- Optionally offer to install CLI for Lazy.nvim users
local function offer_cli_install()
  if not check_cli_availability() then
    vim.api.nvim_echo({
      { "issues-neovim: ", "WarningMsg" },
      { "CLI not found. Would you like to install it globally? (y/n) " }
    }, false, {})
    
    local answer = string.lower(vim.fn.nr2char(vim.fn.getchar()))
    vim.api.nvim_echo({ { "\n" } }, false, {})
    
    if answer == "y" then
      vim.api.nvim_echo({
        { "Installing issues-neovim CLI globally...\n", "None" }
      }, false, {})
      
      -- Get the plugin dir
      local plugin_dir
      local lazy_dir = vim.fn.expand("~/.local/share/nvim/lazy/issues-neovim")
      if vim.fn.isdirectory(lazy_dir) == 1 then
        plugin_dir = lazy_dir
      else
        -- Try to detect plugin directory using the current file
        plugin_dir = vim.fn.fnamemodify(vim.fn.resolve(debug.getinfo(1, "S").source:sub(2)), ":h:h")
      end
      
      -- First try direct global installation (more reliable)
      local install_cmd = string.format("cd %s && npm install -g .", vim.fn.shellescape(plugin_dir))
      
      local install_job = vim.fn.jobstart(install_cmd, {
        on_exit = function(_, code)
          if code == 0 then
            vim.api.nvim_echo({
              { "issues-neovim: ", "None" },
              { "CLI installed successfully! Please restart Neovim.\n", "None" }
            }, false, {})
          else
            -- Fallback to npm link if global install failed
            vim.api.nvim_echo({
              { "issues-neovim: ", "WarningMsg" },
              { "Global install failed, trying local install and link...\n", "None" }
            }, false, {})
            
            local link_cmd = string.format("cd %s && npm install && npm link", vim.fn.shellescape(plugin_dir))
            local link_job = vim.fn.jobstart(link_cmd, {
              on_exit = function(_, link_code)
                if link_code == 0 then
                  vim.api.nvim_echo({
                    { "issues-neovim: ", "None" },
                    { "CLI installed successfully via npm link! Please restart Neovim.\n", "None" }
                  }, false, {})
                else
                  vim.api.nvim_echo({
                    { "issues-neovim: ", "ErrorMsg" },
                    { "Failed to install CLI. Please run 'npm install -g issues-neovim' manually.\n", "None" }
                  }, false, {})
                end
              end
            })
          end
        end
      })
    end
  end
end

-- Define user command to open issues-neovim
vim.api.nvim_create_user_command("LazyVimIssues", function()
  if not check_cli_availability() then
    offer_cli_install()
    return
  end

  local issues = require("issues-neovim")
  local current_dir = vim.fn.getcwd()
  
  vim.cmd(string.format(
    "FloatermNew --height=%s --width=%s --title=%s cd %s && issues-neovim tui",
    issues.config.ui.float.height,
    issues.config.ui.float.width,
    vim.fn.shellescape(issues.config.ui.float.title),
    vim.fn.shellescape(current_dir)
  ))
end, {
  desc = "Open LazyVim Issues CLI",
  nargs = 0,
})

-- Define debug command to output diagnostic information
vim.api.nvim_create_user_command("LazyVimIssuesDebug", function()
  if not check_cli_availability() then
    offer_cli_install()
    return
  end

  local current_dir = vim.fn.getcwd()
  vim.cmd(string.format("FloatermNew --height=0.7 --width=0.7 --title='Issues Debug' cd %s && issues-neovim debug", 
    vim.fn.shellescape(current_dir)))
end, {
  desc = "Show diagnostic information for issues-neovim",
  nargs = 0,
})

-- Define full diagnostic report command
vim.api.nvim_create_user_command("LazyVimIssuesDiagnose", function()
  if not check_cli_availability() then
    offer_cli_install()
    return
  end

  local current_dir = vim.fn.getcwd()
  vim.cmd(string.format("FloatermNew --height=0.9 --width=0.9 --title='Issues Diagnostic Report' cd %s && issues-neovim diagnose", 
    vim.fn.shellescape(current_dir)))
end, {
  desc = "Generate complete diagnostic report for issues-neovim",
  nargs = 0,
})

-- Define CLI installation command specifically for Lazy.nvim users
vim.api.nvim_create_user_command("LazyVimIssuesInstallCLI", function()
  offer_cli_install()
end, {
  desc = "Install the issues-neovim CLI globally",
  nargs = 0,
})

-- Define health check module
do
  local ok, health = pcall(require, "health")
  
  if ok then
    -- For Neovim 0.8+, register the health module
    if vim.fn.has("nvim-0.8") == 1 then
      health.register {
        name = "issues-neovim",
        check = function()
          require("issues-neovim.health").check()
        end,
      }
    else
      -- For older Neovim versions
      -- Register the health module using the old style
      _G.health_issues_neovim = {
        check = function()
          require("issues-neovim.health").check()
        end,
      }
    end
  end
end

-- Check for dependencies
local has_floaterm = vim.fn.exists(":FloatermNew") == 2

if not has_floaterm then
  vim.api.nvim_echo({
    { "issues-neovim: ", "WarningMsg" },
    { "vim-floaterm is required for floating terminal support. Please install it or use integrated terminal mode." },
  }, true, {})
end

-- Check CLI availability on plugin load
if not check_cli_availability() then
  vim.schedule(function()
    vim.api.nvim_echo({
      { "issues-neovim: ", "WarningMsg" },
      { "CLI not detected. Run :LazyVimIssuesInstallCLI to install it, or run 'npm install -g issues-neovim' manually." },
    }, true, {})
  end)
end