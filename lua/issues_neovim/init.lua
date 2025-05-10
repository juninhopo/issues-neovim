---@class IssuesNeovim: issues_neovim.plugins
local M = {}

setmetatable(M, {
  __index = function(t, k)
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require("issues_neovim." .. k)
    return rawget(t, k)
  end,
})

_G.IssuesNeovim = M

---@class issues_neovim.Config
---@field enabled boolean
---@field keys table
---@field ui issues_neovim.ui.Config
---@field github issues_neovim.github.Config
local config = {
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
    username = "juninhopo",
    token = nil, -- GitHub Personal Access Token
  },
}

---@class issues_neovim.config: issues_neovim.Config
M.config = setmetatable({}, {
  __index = function(_, k)
    config[k] = config[k] or {}
    return config[k]
  end,
  __newindex = function(_, k, v)
    config[k] = v
  end,
})

M.did_setup = false

---@param opts issues_neovim.Config?
function M.setup(opts)
  if M.did_setup then
    return vim.notify("issues-neovim is already setup", vim.log.levels.ERROR, { title = "issues-neovim" })
  end
  M.did_setup = true

  opts = opts or {}
  config = vim.tbl_deep_extend("force", config, opts)
  
  -- Set up keymappings
  vim.keymap.set("n", config.keys.open, function()
    M.ui.open()
  end, { desc = "Open GitHub Issues" })
  
  -- Load components
  if config.enabled then
    M.github.setup()
    M.ui.setup()
  end
end

return M 