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
---@field page number
---@field per_page number

-- UI state
M.state = {
  bufnr = nil,
  winid = nil,
  details_bufnr = nil,
  details_winid = nil,
  issues = nil,
  selected_index = 1,
  mode = "list", -- "list" or "details"
  page = 1,
  per_page = 10
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
  
  -- Add pagination keymaps
  api.nvim_buf_set_keymap(buf, "n", "n", "", {
    noremap = true,
    silent = true,
    callback = function()
      if M.state.issues and #M.state.issues > 0 then
        local total_pages = math.ceil(#M.state.issues / M.state.per_page)
        if M.state.page < total_pages then
          M.state.page = M.state.page + 1
          M.render_issues()
        end
      end
    end
  })
  
  api.nvim_buf_set_keymap(buf, "n", "p", "", {
    noremap = true,
    silent = true,
    callback = function()
      if M.state.page > 1 then
        M.state.page = M.state.page - 1
        M.render_issues()
      end
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
  
  local current_page_start = (M.state.page - 1) * M.state.per_page + 1
  local current_page_end = math.min(current_page_start + M.state.per_page - 1, #M.state.issues)
  
  -- Calculate new index based on direction
  local new_index = M.state.selected_index + direction
  
  -- Handle pagination when navigating beyond current page bounds
  if new_index < current_page_start then
    -- Go to previous page if possible
    if M.state.page > 1 then
      M.state.page = M.state.page - 1
      M.render_issues()
      -- Set cursor to bottom of previous page
      local prev_page_end = math.min(current_page_start - 1, #M.state.issues)
      M.state.selected_index = prev_page_end
      api.nvim_win_set_cursor(M.state.winid, { M.state.selected_index - current_page_start + current_page_end + 4, 0 })
    else
      -- Wrap to last page
      local total_pages = math.ceil(#M.state.issues / M.state.per_page)
      M.state.page = total_pages
      M.render_issues()
      M.state.selected_index = #M.state.issues
      local last_page_size = #M.state.issues - (total_pages - 1) * M.state.per_page
      api.nvim_win_set_cursor(M.state.winid, { last_page_size + 4, 0 })
    end
    return
  elseif new_index > current_page_end then
    -- Go to next page if possible
    local total_pages = math.ceil(#M.state.issues / M.state.per_page)
    if M.state.page < total_pages then
      M.state.page = M.state.page + 1
      M.render_issues()
      -- Set cursor to top of next page
      local next_page_start = current_page_end + 1
      M.state.selected_index = next_page_start
      api.nvim_win_set_cursor(M.state.winid, { 5, 0 }) -- First row after header (4 lines) + 1
    else
      -- Wrap to first page
      M.state.page = 1
      M.render_issues()
      M.state.selected_index = 1
      api.nvim_win_set_cursor(M.state.winid, { 5, 0 })
    end
    return
  end
  
  -- If within current page, just update cursor position
  M.state.selected_index = new_index
  
  -- Calculate cursor row (adjust for header and relative position on page)
  local cursor_row = (new_index - current_page_start) + 5 -- 4 header lines + 1
  
  -- Move cursor to the selected issue
  if M.state.winid and api.nvim_win_is_valid(M.state.winid) then
    api.nvim_win_set_cursor(M.state.winid, { cursor_row, 0 })
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
  
  -- Reset to first page when refreshing
  M.state.page = 1
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
  
  local lines = {}
  local namespace = api.nvim_create_namespace("issues_neovim")
  api.nvim_buf_clear_namespace(M.state.bufnr, namespace, 0, -1)
  
  -- Calculate window width dynamically
  local window_width = api.nvim_win_get_width(M.state.winid)
  
  -- Add pagination state variables
  if not M.state.page then
    M.state.page = 1
    M.state.per_page = 10
  end
  
  -- Calculate column widths based on percentage of window width
  local col_widths = {
    number = math.min(10, math.max(4, math.floor(window_width * 0.05))),  -- 5% for issue number (max 10)
    state = math.min(15, math.max(10, math.floor(window_width * 0.12))),  -- 12% for state (max 15)
    title = math.min(80, math.max(20, math.floor(window_width * 0.55))),  -- 55% for title (max 80)
    created = math.min(15, math.max(10, math.floor(window_width * 0.15))), -- 15% for created date (max 15)
    comments = math.min(10, math.max(8, math.floor(window_width * 0.08))) -- 8% for comments count (max 10)
  }
  
  -- Calculate extra space needed for highlight syntax in state column
  -- %#DiagnosticInfo# and %#Normal# adds extra characters that don't display
  local highlight_syntax_len = #"%#DiagnosticError#" + #"%#Normal#"
  
  -- Adjust state width to account for highlight syntax (ensure it's at least 10)
  col_widths.effective_state = math.max(10, col_widths.state - highlight_syntax_len)
  
  -- Calculate total width for separators
  local separators_width = 10 -- 5 separators (4 visible + 1 at end)
  local total_width = math.min(window_width, 130) - separators_width  -- Limit total width to 130
  
  -- Adjust title width to fill available space if needed
  local used_width = col_widths.number + col_widths.state + col_widths.created + col_widths.comments
  if used_width < total_width then
    col_widths.title = total_width - used_width
  end
  
  -- Create format strings
  local format_string = "%-" .. col_widths.number .. "s | %s | %-" .. col_widths.title .. "s | %-" .. col_widths.created .. "s | %-" .. col_widths.comments .. "s"
  
  -- Insert title
  table.insert(lines, "GitHub Issues: " .. github.cache.owner .. "/" .. github.cache.repository)
  table.insert(lines, string.rep("─", window_width))
  
  -- Table header with correct spacing
  local header_padding_size = math.max(0, col_widths.effective_state - 5) -- "State" is 5 characters
  local state_header = "State" .. string.rep(" ", header_padding_size)
  local header = string.format(
    format_string,
    "#",
    state_header,
    "Title",
    "Created",
    "Comments"
  )
  table.insert(lines, header)
  table.insert(lines, string.rep("─", window_width))
  
  if not M.state.issues or #M.state.issues == 0 then
    table.insert(lines, "No issues found.")
  else
    -- Calculate pagination
    local total_issues = #M.state.issues
    local total_pages = math.ceil(total_issues / M.state.per_page)
    local start_idx = (M.state.page - 1) * M.state.per_page + 1
    local end_idx = math.min(start_idx + M.state.per_page - 1, total_issues)
    
    for i = start_idx, end_idx do
      local issue = M.state.issues[i]
      local issue_number = string.format("%-" .. col_widths.number .. "d", issue.number)
      
      -- Colored state with consistent width
      local state
      local state_text
      if issue.state == "open" then
        state_text = "OPEN"
        state = "OPEN"
      else
        state_text = "CLOSED"
        state = "CLOSED"
      end
      
      -- Padding to maintain consistent alignment
      -- Calculate based on effective width (already considering highlight tags)
      local display_width = col_widths.effective_state
      local padding_size = math.max(0, display_width - #state_text)
      local padding = string.rep(" ", padding_size)
      state = state .. padding
      
      -- Title with variable width based on window size
      local title = utils.truncate(issue.title, col_widths.title - 2) -- -2 for safety
      title = string.format("%-" .. col_widths.title .. "s", title)
      
      -- Formatted date with dynamic width
      local created = utils.format_date(issue.created_at)
      created = string.format("%-" .. col_widths.created .. "s", created)
      
      -- Comments
      local comments = string.format("%-" .. col_widths.comments .. "s", tostring(issue.comments or 0))
      
      -- Format entire line
      local line = string.format(
        format_string, 
        issue_number,
        state, 
        title, 
        created, 
        comments
      )
      
      table.insert(lines, line)
    end
  end
  
  -- Add pagination info at the bottom
  table.insert(lines, string.rep("─", window_width))
  
  -- Make sure pagination variables are defined in all cases
  local total_issues = M.state.issues and #M.state.issues or 0
  local total_pages = math.ceil(total_issues / M.state.per_page)
  local start_idx = (M.state.page - 1) * M.state.per_page + 1
  local end_idx = math.min(start_idx + M.state.per_page - 1, total_issues)
  
  -- Create a commands help line with better formatting
  local keys = config.keys
  local commands = {
    { key = keys.close, action = "Close" },
    { key = keys.refresh, action = "Refresh" },
    { key = keys.navigate.next .. "/" .. keys.navigate.prev, action = "Navigate" },
    { key = keys.view_details, action = "Details" },
    { key = "n/p", action = "Pages" },
    { key = keys.create_issue, action = "Create" },
    { key = keys.add_comment, action = "Comment" }
  }
  
  -- Calculate the length of the pagination info
  local pagination_info = string.format("Page %d of %d (%d-%d of %d issues)", 
    M.state.page, total_pages, start_idx, end_idx, total_issues)
  
  -- Format commands with colors using %#Group# syntax (for NVIM extmarks)
  local formatted_commands = {}
  for _, cmd in ipairs(commands) do
    table.insert(formatted_commands, string.format("%s %s", 
      utils.format_key(cmd.key), cmd.action))
  end
  
  -- Decide layout based on window size
  -- Always split into multiple lines for better readability
  table.insert(lines, pagination_info)
  
  -- Store command line numbers for later highlighting
  local command_line_numbers = {}
  
  -- Calculate how many commands can fit per line (approx. 4 commands per line for 80-char width)
  local cmds_per_line = math.max(2, math.floor(window_width / 20))
  
  -- Distribute commands across lines
  for i = 1, #formatted_commands, cmds_per_line do
    local line_cmds = {}
    for j = i, math.min(i + cmds_per_line - 1, #formatted_commands) do
      table.insert(line_cmds, formatted_commands[j])
    end
    table.insert(command_line_numbers, #lines + 1)
    table.insert(lines, table.concat(line_cmds, " | "))
  end
  
  -- Set lines
  api.nvim_buf_set_lines(M.state.bufnr, 0, -1, false, lines)
  
  -- Highlight header
  api.nvim_buf_add_highlight(M.state.bufnr, namespace, "Title", 0, 0, -1)
  api.nvim_buf_add_highlight(M.state.bufnr, namespace, "Comment", 2, 0, -1)
  
  -- Calculate footer starting line
  local pagination_line = #lines - #command_line_numbers - 1
  
  -- Highlight the separator line
  api.nvim_buf_add_highlight(M.state.bufnr, namespace, "Comment", pagination_line, 0, -1)
  
  -- Highlight pagination info
  api.nvim_buf_add_highlight(M.state.bufnr, namespace, "Special", pagination_line + 1, 0, -1)
  
  -- Highlight command lines
  for i, line_num in ipairs(command_line_numbers) do
    -- Highlight the entire line with a muted color
    api.nvim_buf_add_highlight(M.state.bufnr, namespace, "Comment", line_num - 1, 0, -1)
    
    -- We need to highlight the keys (text inside []) with the green color
    -- This is easier with naive string matching than with regex
    local line = lines[line_num]
    if line then
      local pos = 1
      while true do
        local bracket_start = line:find("%[", pos)
        if not bracket_start then break end
        
        local bracket_end = line:find("%]", bracket_start)
        if not bracket_end then break end
        
        -- Highlight the key in green (DiagnosticHint)
        api.nvim_buf_add_highlight(M.state.bufnr, namespace, "DiagnosticHint", 
          line_num - 1, bracket_start - 1, bracket_end)
        
        pos = bracket_end + 1
      end
    end
  end
  
  -- Set cursor to selected issue with bounds checking
  if M.state.winid and api.nvim_win_is_valid(M.state.winid) and M.state.issues and #M.state.issues > 0 then
    -- Ensure selected_index is within bounds
    if M.state.selected_index < 1 then
      M.state.selected_index = 1
    elseif M.state.selected_index > #M.state.issues then
      M.state.selected_index = #M.state.issues
    end
    
    -- Check if selected issue is on current page
    local current_page_start = (M.state.page - 1) * M.state.per_page + 1
    local current_page_end = math.min(current_page_start + M.state.per_page - 1, #M.state.issues)
    
    if M.state.selected_index < current_page_start or M.state.selected_index > current_page_end then
      -- Selected issue is not on current page, adjust to first item on current page
      M.state.selected_index = current_page_start
    end
    
    -- Calculate cursor position based on position in current page
    local position_in_page = M.state.selected_index - current_page_start + 1
    
    -- Position cursor (4 header lines + position in page)
    api.nvim_win_set_cursor(M.state.winid, { position_in_page + 4, 0 })
  else
    -- If no issues, position cursor at header
    if M.state.winid and api.nvim_win_is_valid(M.state.winid) then
      api.nvim_win_set_cursor(M.state.winid, { 3, 0 }) -- Position at header line
    end
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
  
  -- Adjust for header (4 lines) and pagination
  local line_idx = current_line - 4
  if line_idx < 1 then
    return
  end
  
  -- Calculate the actual issue index based on pagination
  local current_page_start = (M.state.page - 1) * M.state.per_page + 1
  local issue_index = current_page_start + line_idx - 1
  
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