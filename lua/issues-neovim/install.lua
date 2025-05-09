local M = {}

-- Function to install the CLI
function M.setup()
  local Job = require("plenary.job")
  local plugin_dir = vim.fn.stdpath("data") .. "/lazy/issues-neovim"
  
  vim.notify("Installing issues-neovim CLI dependencies...", vim.log.levels.INFO)
  
  -- Run npm install
  Job:new({
    command = "npm",
    args = { "install" },
    cwd = plugin_dir,
    on_exit = function(j, return_val)
      if return_val == 0 then
        vim.notify("Dependencies installed successfully", vim.log.levels.INFO)
        
        -- Run npm link
        Job:new({
          command = "npm",
          args = { "link" },
          cwd = plugin_dir,
          on_exit = function(_, link_return_val)
            if link_return_val == 0 then
              vim.notify("issues-neovim CLI linked successfully!", vim.log.levels.INFO)
            else
              vim.notify("Failed to link CLI. You may need to run 'sudo npm link' in " .. plugin_dir, vim.log.levels.ERROR)
            end
          end,
        }):start()
      else
        vim.notify("Failed to install dependencies. Check if Node.js is installed.", vim.log.levels.ERROR)
      end
    end,
  }):start()
end

return M 