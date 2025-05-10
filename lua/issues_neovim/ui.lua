---@class issues_neovim.ui
local M = {}

local api = vim.api
local utils = require("issues_neovim.utils")
local github = require("issues_neovim").github
local config = require("issues_neovim").config

---@class issues_neovim.ui.State
---@field bufnr number|nil
---@field winid number|nil
---@field details_bufnr number|nil
---@field details_winid number|nil
---@field issues issues_neovim.github.Issue[]|nil
---@field selected_index number
---@field mode string

-- UI state
M.state = {
  bufnr = nil,
  winid = nil,
  details_bufnr = nil,
  details_winid = nil,
  issues = nil,
  selected_index = 1,
  mode = "list", -- "list" or "details"
}

function M.setup()
  -- Create commands
  api.nvim_create_user_command("IssuesNeovim", function()
    M.open()
  end, {})
  
  api.nvim_create_user_command("IssuesNeovimRefresh", function()
    M.refresh()
  end, {})
end

-- Open the issues window
function M.open()
  if M.state.winid and api.nvim_win_is_valid(M.state.winid) then
    api.nvim_set_current_win(M.state.winid)
    return
  end
  
  -- Create buffer if it doesn't exist
  if not M.state.bufnr or not api.nvim_buf_is_valid(M.state.bufnr) then
    M.state.bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(M.state.bufnr, "buftype", "nofile")
    api.nvim_buf_set_option(M.state.bufnr, "bufhidden", "wipe")
    api.nvim_buf_set_option(M.state.bufnr, "swapfile", false)
    api.nvim_buf_set_option(M.state.bufnr, "filetype", "issues-neovim")
    api.nvim_buf_set_name(M.state.bufnr, "GitHub Issues")
  end
  
  -- Get dimensions
  local ui_width = math.floor(api.nvim_get_option("columns") * config.ui.width)
  local ui_height = math.floor(api.nvim_get_option("lines") * config.ui.height)
  local row = math.floor((api.nvim_get_option("lines") - ui_height) / 2)
  local col = math.floor((api.nvim_get_option("columns") - ui_width) / 2)
  
  -- Create window
  M.state.winid = api.nvim_open_win(M.state.bufnr, true, {
    relative = "editor",
    width = ui_width,
    height = ui_height,
    row = row,
    col = col,
    style = "minimal",
    border = config.ui.border,
    title = config.ui.title,
  })
  
  -- Set window options
  api.nvim_win_set_option(M.state.winid, "cursorline", true)
  api.nvim_win_set_option(M.state.winid, "winhighlight", "Normal:Normal,FloatBorder:FloatBorder")
  
  -- Set keymaps
  M.set_keymaps()
  
  -- Load issues
  M.load_issues()
end

-- Close the issues window
function M.close()
  if M.state.details_winid and api.nvim_win_is_valid(M.state.details_winid) then
    api.nvim_win_close(M.state.details_winid, true)
    M.state.details_winid = nil
    M.state.details_bufnr = nil
  end
  
  if M.state.winid and api.nvim_win_is_valid(M.state.winid) then
    api.nvim_win_close(M.state.winid, true)
    M.state.winid = nil
  end
  
  M.state.mode = "list"
end

-- Set keymaps for the issues window
function M.set_keymaps()
  local keys = config.keys
  local buf = M.state.bufnr
  
  -- Close window
  api.nvim_buf_set_keymap(buf, "n", keys.close, "", {
    noremap = true,
    silent = true,
    callback = function()
      M.close()
    end
  })
  
  -- Refresh issues
  api.nvim_buf_set_keymap(buf, "n", keys.refresh, "", {
    noremap = true,
    silent = true,
    callback = function()
      M.refresh()
    end
  })
  
  -- Navigate issues
  api.nvim_buf_set_keymap(buf, "n", keys.navigate.next, "", {
    noremap = true,
    silent = true,
    callback = function()
      M.navigate(1)
    end
  })
  
  api.nvim_buf_set_keymap(buf, "n", keys.navigate.prev, "", {
    noremap = true,
    silent = true,
    callback = function()
      M.navigate(-1)
    end
  })
  
  -- View issue details
  api.nvim_buf_set_keymap(buf, "n", keys.view_details, "", {
    noremap = true,
    silent = true,
    callback = function()
      if M.state.mode == "list" then
        M.show_issue_details()
      else
        -- Close details and go back to list
        if M.state.details_winid and api.nvim_win_is_valid(M.state.details_winid) then
          api.nvim_win_close(M.state.details_winid, true)
          M.state.details_winid = nil
          M.state.details_bufnr = nil
          M.state.mode = "list"
          api.nvim_set_current_win(M.state.winid)
        end
      end
    end
  })
  
  -- Create new issue
  api.nvim_buf_set_keymap(buf, "n", keys.create_issue, "", {
    noremap = true,
    silent = true,
    callback = function()
      vim.notify("Creating a new issue is not implemented yet", vim.log.levels.INFO, { title = "issues-neovim" })
    end
  })
  
  -- Add comment
  api.nvim_buf_set_keymap(buf, "n", keys.add_comment, "", {
    noremap = true,
    silent = true,
    callback = function()
      vim.notify("Adding a comment is not implemented yet", vim.log.levels.INFO, { title = "issues-neovim" })
    end
  })
end

-- Navigate between issues
function M.navigate(direction)
  if not M.state.issues or #M.state.issues == 0 then
    return
  end
  
  local new_index = M.state.selected_index + direction
  
  if new_index < 1 then
    new_index = #M.state.issues
  elseif new_index > #M.state.issues then
    new_index = 1
  end
  
  M.state.selected_index = new_index
  
  -- Move cursor to the selected issue
  if M.state.winid and api.nvim_win_is_valid(M.state.winid) then
    api.nvim_win_set_cursor(M.state.winid, { M.state.selected_index, 0 })
  end
  
  -- Update details if they're open
  if M.state.mode == "details" and M.state.details_winid and api.nvim_win_is_valid(M.state.details_winid) then
    M.show_issue_details()
  end
end

-- Load issues from GitHub
function M.load_issues()
  api.nvim_buf_set_lines(M.state.bufnr, 0, -1, false, { "Loading issues..." })
  
  -- Get issues asynchronously
  vim.defer_fn(function()
    local issues = github.get_issues(true)
    
    if not issues or #issues == 0 then
      api.nvim_buf_set_lines(M.state.bufnr, 0, -1, false, { "No issues found or error fetching issues." })
      return
    end
    
    M.state.issues = issues
    M.render_issues()
  end, 10)
end

-- Refresh issues
function M.refresh()
  if not M.state.bufnr or not api.nvim_buf_is_valid(M.state.bufnr) then
    return
  end
  
  M.load_issues()
  
  -- Also refresh details if they're visible
  if M.state.mode == "details" and M.state.details_bufnr and api.nvim_buf_is_valid(M.state.details_bufnr) then
    M.show_issue_details(true)
  end
end

-- Render issues in the buffer
function M.render_issues()
  if not M.state.bufnr or not api.nvim_buf_is_valid(M.state.bufnr) then
    return
  end
  
  if not M.state.issues or #M.state.issues == 0 then
    api.nvim_buf_set_lines(M.state.bufnr, 0, -1, false, { "No issues found." })
    return
  end
  
  local lines = {}
  local namespace = api.nvim_create_namespace("issues_neovim")
  api.nvim_buf_clear_namespace(M.state.bufnr, namespace, 0, -1)
  
  -- Add header
  table.insert(lines, "GitHub Issues: " .. github.cache.owner .. "/" .. github.cache.repository)
  table.insert(lines, string.rep("─", 80))
  table.insert(lines, " # | State  | Title                                             | Created     | Comments")
  table.insert(lines, string.rep("─", 80))
  
  -- Add issues
  for i, issue in ipairs(M.state.issues) do
    local state = utils.colorize_state(issue.state)
    local title = utils.truncate(issue.title, 50)
    local created = utils.format_date(issue.created_at)
    local line = string.format("%2d | %s | %s | %s | %d", 
      issue.number, 
      state, 
      title, 
      created, 
      issue.comments or 0
    )
    
    table.insert(lines, line)
  end
  
  -- Set lines
  api.nvim_buf_set_lines(M.state.bufnr, 0, -1, false, lines)
  
  -- Highlight header
  api.nvim_buf_add_highlight(M.state.bufnr, namespace, "Title", 0, 0, -1)
  api.nvim_buf_add_highlight(M.state.bufnr, namespace, "Comment", 2, 0, -1)
  
  -- Set cursor to selected issue
  if M.state.winid and api.nvim_win_is_valid(M.state.winid) then
    local cursor_line = M.state.selected_index
    if cursor_line < 1 then
      cursor_line = 1
    elseif cursor_line > #M.state.issues then
      cursor_line = #M.state.issues
    end
    
    api.nvim_win_set_cursor(M.state.winid, { cursor_line + 4, 0 }) -- +4 for header lines
  end
end

-- Show issue details
function M.show_issue_details(force_refresh)
  if not M.state.issues or #M.state.issues == 0 then
    return
  end
  
  -- Get current issue
  local cursor = api.nvim_win_get_cursor(M.state.winid)
  local current_line = cursor[1]
  
  -- Adjust for header (4 lines)
  local issue_index = current_line - 4
  if issue_index < 1 or issue_index > #M.state.issues then
    return
  end
  
  M.state.selected_index = issue_index
  local issue = M.state.issues[issue_index]
  
  -- Create details buffer
  if not M.state.details_bufnr or not api.nvim_buf_is_valid(M.state.details_bufnr) then
    M.state.details_bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(M.state.details_bufnr, "buftype", "nofile")
    api.nvim_buf_set_option(M.state.details_bufnr, "bufhidden", "wipe")
    api.nvim_buf_set_option(M.state.details_bufnr, "swapfile", false)
    api.nvim_buf_set_option(M.state.details_bufnr, "filetype", "markdown")
  end
  
  -- Get dimensions
  local ui_width = math.floor(api.nvim_get_option("columns") * config.ui.width)
  local ui_height = math.floor(api.nvim_get_option("lines") * config.ui.height)
  local row = math.floor((api.nvim_get_option("lines") - ui_height) / 2)
  local col = math.floor((api.nvim_get_option("columns") - ui_width) / 2)
  
  -- Create or update the details window
  if not M.state.details_winid or not api.nvim_win_is_valid(M.state.details_winid) then
    M.state.details_winid = api.nvim_open_win(M.state.details_bufnr, true, {
      relative = "editor",
      width = ui_width,
      height = ui_height,
      row = row,
      col = col,
      style = "minimal",
      border = config.ui.border,
      title = "Issue #" .. issue.number .. ": " .. utils.truncate(issue.title, 30),
    })
    
    -- Set window options
    api.nvim_win_set_option(M.state.details_winid, "wrap", true)
    api.nvim_win_set_option(M.state.details_winid, "winhighlight", "Normal:Normal,FloatBorder:FloatBorder")
  end
  
  -- Set buffer keymap
  api.nvim_buf_set_keymap(M.state.details_bufnr, "n", config.keys.close, "", {
    noremap = true,
    silent = true,
    callback = function()
      if M.state.details_winid and api.nvim_win_is_valid(M.state.details_winid) then
        api.nvim_win_close(M.state.details_winid, true)
        M.state.details_winid = nil
        M.state.details_bufnr = nil
        M.state.mode = "list"
        api.nvim_set_current_win(M.state.winid)
      end
    end
  })
  
  -- Set mode
  M.state.mode = "details"
  
  -- Get comments
  api.nvim_buf_set_lines(M.state.details_bufnr, 0, -1, false, { "Loading issue details..." })
  
  -- Format issue details and comments
  vim.defer_fn(function()
    -- Get fresh issue data
    local issue_data = issue
    if force_refresh then
      issue_data = github.get_issue(issue.number, true) or issue
    end
    
    -- Format header
    local lines = {}
    table.insert(lines, "# " .. issue_data.title)
    table.insert(lines, "")
    table.insert(lines, "**State:** " .. issue_data.state)
    table.insert(lines, "**Created by:** " .. (issue_data.user.login or "Unknown"))
    table.insert(lines, "**Created at:** " .. utils.format_date(issue_data.created_at))
    if issue_data.state == "closed" and issue_data.closed_at then
      table.insert(lines, "**Closed at:** " .. utils.format_date(issue_data.closed_at))
    end
    table.insert(lines, "")
    
    -- Add issue body
    table.insert(lines, "## Description")
    table.insert(lines, "")
    
    if issue_data.body and issue_data.body ~= "" then
      for _, line in ipairs(vim.split(issue_data.body, "\n")) do
        table.insert(lines, line)
      end
    else
      table.insert(lines, "*No description provided*")
    end
    
    -- Add comments
    table.insert(lines, "")
    table.insert(lines, "## Comments")
    table.insert(lines, "")
    
    local comments = github.get_comments(issue.number, force_refresh)
    if comments and #comments > 0 then
      for _, comment in ipairs(comments) do
        table.insert(lines, "### " .. comment.user.login .. " on " .. utils.format_date(comment.created_at))
        table.insert(lines, "")
        
        if comment.body and comment.body ~= "" then
          for _, line in ipairs(vim.split(comment.body, "\n")) do
            table.insert(lines, line)
          end
        else
          table.insert(lines, "*Empty comment*")
        end
        
        table.insert(lines, "")
        table.insert(lines, "---")
        table.insert(lines, "")
      end
    else
      table.insert(lines, "*No comments*")
    end
    
    -- Set the lines
    api.nvim_buf_set_lines(M.state.details_bufnr, 0, -1, false, lines)
  end, 10)
end

return M 