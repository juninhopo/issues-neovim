local health = vim.health or require('health')
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

local function execute_command(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then return nil, "Failed to execute command" end
  
  local result = handle:read("*a")
  local success = handle:close()
  
  return success, result
end

local M = {}

function M.check()
  start("Issues Neovim")

  -- Check if node is installed
  local node_exists, node_version = execute_command("node --version")
  if not node_exists then
    error("Node.js is not installed. Please install Node.js (version 14+)")
    info("Install Node.js via https://nodejs.org/ or with your package manager.")
  else
    local version_num = node_version:match("v(%d+)%.") 
    if version_num and tonumber(version_num) < 14 then
      warn("Node.js is installed, but version is old: " .. node_version:gsub("%s+$", ""))
      info("We recommend Node.js v14 or higher")
    else
      ok("Node.js is installed: " .. node_version:gsub("%s+$", ""))
    end
  end

  -- Check CLI availability (for Lazy.nvim users, this matters more than package.json)
  local cli_success, cli_output = execute_command("which issues-neovim || echo 'Not found'")
  if cli_success and not cli_output:match("Not found") then
    ok("issues-neovim CLI is accessible: " .. cli_output:gsub("%s+$", ""))
    
    -- Check CLI version
    local version_success, version_output = execute_command("issues-neovim --version")
    if version_success then
      ok("CLI version: " .. version_output:gsub("%s+$", ""))
    else
      warn("CLI installed but version check failed")
    end
  else
    error("issues-neovim CLI is not accessible")
    info("For Lazy.nvim users: Please install the CLI globally with 'npm install -g issues-neovim'")
    info("Or link it manually: 'cd ~/.local/share/nvim/lazy/issues-neovim && npm install && npm link'")
  end

  -- If plugin was installed via Lazy.nvim, check the correct location
  local plugin_dir = vim.fn.fnamemodify(vim.fn.resolve(debug.getinfo(1, "S").source:sub(2)), ":h:h:h")
  local lazy_install = plugin_dir:match("lazy") ~= nil
  
  if lazy_install then
    ok("Plugin appears to be installed via Lazy.nvim at: " .. plugin_dir)
    
    -- For Lazy users, no need to check for package.json in detail
    -- Just verify CLI accessibility which we already did above
  else
    -- Standard checks for direct installs
    local package_exists = vim.fn.filereadable(plugin_dir .. "/package.json") == 1
    
    if package_exists then
      ok("package.json file found")
      
      -- Check dependency installation
      local modules_dir = plugin_dir .. "/node_modules"
      if vim.fn.isdirectory(modules_dir) == 1 then
        ok("node_modules found")
      else
        error("node_modules not found. Run 'npm install' in the plugin directory")
        info("Plugin directory: " .. plugin_dir)
      end
    else
      warn("package.json file not found. This is normal if using Lazy.nvim.")
      info("For direct installs: Check if the plugin installation is complete.")
    end
  end

  -- Check environment variables and configuration
  local github_token = vim.env.GITHUB_TOKEN or vim.g.github_token
  if github_token then
    ok("GitHub token found")
  else
    warn("GitHub token not found. Some features may be limited.")
    info("Configure token in your .bashrc/.zshrc: export GITHUB_TOKEN=your_token")
    info("Or in your Neovim config: vim.g.github_token = 'your_token'")
  end

  -- Check vim-floaterm plugin dependency
  if vim.fn.exists(":FloatermNew") == 2 then
    ok("vim-floaterm plugin found")
  else
    warn("vim-floaterm plugin not found. The floating interface will not work.")
    info("Install vim-floaterm with your plugin manager")
  end

  -- Check if GitHub API is accessible (basic connectivity test)
  local curl_exists, _ = execute_command("which curl")
  if curl_exists then
    local api_success, api_output = execute_command("curl --silent -I https://api.github.com")
    if api_success and api_output:match("HTTP/[%d%.]+%s+200") then
      ok("GitHub API is accessible")
    else
      warn("Could not access GitHub API. Check your internet connection.")
      info("Command output: " .. (api_output or "no output"))
    end
  end

  info("Debugging tips:")
  info("1. Run ':checkhealth issues-neovim' to see this diagnostic information")
  info("2. For advanced debugging, run: 'DEBUG=issues-neovim:* issues-neovim tui'")
  info("3. Logs are saved in: ~/.issues-neovim/debug.log")
  info("4. For Lazy.nvim users: Install CLI globally with 'npm install -g issues-neovim'")
end

return M 