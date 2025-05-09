-- TUI Module for issues-neovim
local api = require("issues-neovim.api")
local utils = require("issues-neovim.utils")

local M = {}

-- Default state
local state = {
  issues = {},
  issue_details = nil,
  comments = {},
  selected_issue_idx = 1,
  owner = nil,
  repo = nil,
  token = nil,
  ui = nil,
  buf_issues = nil,
  buf_details = nil,
  win_issues = nil,
  win_details = nil,
  loading = false,
  page = 1,
  per_page = 30,
  issue_state = "open", -- or "closed"
  search_term = nil,
}

-- Reset state when TUI is closed
local function reset_state()
  state = {
    issues = {},
    issue_details = nil,
    comments = {},
    selected_issue_idx = 1,
    owner = nil,
    repo = nil,
    token = nil,
    ui = nil,
    buf_issues = nil,
    buf_details = nil,
    win_issues = nil,
    win_details = nil,
    loading = false,
    page = 1,
    per_page = 30,
    issue_state = "open",
    search_term = nil,
  }
end

-- Format title with status and number
local function format_title(issue)
  local status_icon = issue.state == "open" and "● " or "✓ "
  local status_color = issue.state == "open" and "%#GitSignsAdd#" or "%#GitSignsChange#"
  return string.format(
    "%s%s%s #%d: %s",
    status_color,
    status_icon,
    "%#Normal#",
    issue.number,
    issue.title
  )
end

-- Format date
local function format_date(date_str)
  return os.date("%Y-%m-%d %H:%M", utils.parse_iso_date(date_str))
end

-- Open the TUI interface
function M.open(opts)
  -- First detect repository if not provided
  if not opts.owner or not opts.repo then
    local repo_info = api.detect_repository()
    if repo_info.detected then
      opts.owner = repo_info.owner
      opts.repo = repo_info.repo
    end
  end
  
  -- Update state with options
  state.owner = opts.owner
  state.repo = opts.repo
  state.token = opts.token
  state.ui = opts.ui
  
  -- Create the UI
  create_ui()
  
  -- Load issues
  load_issues()
end

-- Create the UI layout
local function create_ui()
  -- Calculate dimensions
  local width = math.floor(vim.o.columns * (state.ui.float.width or 0.9))
  local height = math.floor(vim.o.lines * (state.ui.float.height or 0.9))
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  -- Split the width: 1/3 for issues list, 2/3 for issue details
  local issues_width = math.floor(width * 0.33)
  local details_width = width - issues_width - 2 -- account for separator
  
  -- Create issues list buffer
  state.buf_issues = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(state.buf_issues, 'bufhidden', 'wipe')
  
  -- Create issue details buffer
  state.buf_details = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(state.buf_details, 'bufhidden', 'wipe')
  
  -- Create the layout
  local opts = {
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
  }
  
  -- Issues list window (left)
  state.win_issues = vim.api.nvim_open_win(state.buf_issues, true, {
    relative = 'editor',
    width = issues_width,
    height = height - 2, -- account for header and footer
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Issues ' .. (state.issue_state == "open" and "(Open)" or "(Closed)"),
  })
  
  -- Issue details window (right)
  state.win_details = vim.api.nvim_open_win(state.buf_details, false, {
    relative = 'editor',
    width = details_width,
    height = height - 2,
    row = row,
    col = col + issues_width + 2,
    style = 'minimal',
    border = 'rounded',
    title = ' Issue Details ',
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(state.buf_issues, 'modifiable', false)
  vim.api.nvim_buf_set_option(state.buf_details, 'modifiable', false)
  
  -- Register key mappings for issues list
  local function map(mode, key, handler, desc)
    vim.keymap.set(mode, key, handler, { buffer = state.buf_issues, desc = desc, noremap = true, silent = true })
  end
  
  map('n', 'j', function() move_selection(1) end, "Next issue")
  map('n', 'k', function() move_selection(-1) end, "Previous issue")
  map('n', '<cr>', function() view_selected_issue() end, "View issue details")
  map('n', 'c', function() prompt_comment() end, "Add comment")
  map('n', 'n', function() prompt_create_issue() end, "New issue")
  map('n', 'r', function() load_issues() end, "Refresh issues")
  map('n', 'o', function() toggle_issue_state() end, "Toggle open/closed")
  map('n', 's', function() prompt_search() end, "Search issues")
  map('n', 'l', function() view_api_limits() end, "View API limits")
  map('n', 'q', function() close_ui() end, "Close")
  
  -- Set filetype for syntax highlighting
  vim.api.nvim_buf_set_option(state.buf_issues, 'filetype', 'issues-list')
  vim.api.nvim_buf_set_option(state.buf_details, 'filetype', 'issues-detail')
  
  -- Define syntax highlighting
  vim.cmd([[
    syntax match IssueOpen /●/
    syntax match IssueClosed /✓/
    highlight default link IssueOpen GitSignsAdd
    highlight default link IssueClosed GitSignsChange
  ]])
  
  -- Show footer with key bindings
  local footer_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(footer_buf, 'bufhidden', 'wipe')
  
  local footer_text = " j/k: Navigate | Enter: View | c: Comment | n: New | r: Refresh | o: Toggle Open/Closed | s: Search | q: Close"
  vim.api.nvim_buf_set_lines(footer_buf, 0, -1, false, {footer_text})
  vim.api.nvim_buf_set_option(footer_buf, 'modifiable', false)
  
  vim.api.nvim_open_win(footer_buf, false, {
    relative = 'editor',
    width = width,
    height = 1,
    row = row + height - 1,
    col = col,
    style = 'minimal',
    focusable = false,
  })
end

-- Move selection in the issues list
local function move_selection(dir)
  local new_idx = state.selected_issue_idx + dir
  if new_idx >= 1 and new_idx <= #state.issues then
    state.selected_issue_idx = new_idx
    update_issues_list()
    
    -- Ensure selection is visible
    vim.api.nvim_win_set_cursor(state.win_issues, {state.selected_issue_idx, 0})
  end
end

-- View the selected issue
local function view_selected_issue()
  if #state.issues == 0 then
    return
  end
  
  local issue = state.issues[state.selected_issue_idx]
  if issue then
    load_issue_details(issue.number)
  end
end

-- Toggle between open and closed issues
local function toggle_issue_state()
  state.issue_state = state.issue_state == "open" and "closed" or "open"
  
  -- Update window title
  vim.api.nvim_win_set_config(state.win_issues, {
    title = ' Issues ' .. (state.issue_state == "open" and "(Open)" or "(Closed)")
  })
  
  -- Reset to page 1 and refresh
  state.page = 1
  load_issues()
end

-- Load issues from GitHub API
local function load_issues()
  state.loading = true
  update_status("Loading issues...")
  
  -- Reset issues list
  state.issues = {}
  update_issues_list()
  
  local function handle_issues(data, err)
    state.loading = false
    
    if err or not data then
      local error_msg = err or "Unknown error"
      
      -- Add more helpful diagnostic information
      local diagnostic_info = ""
      if err and err:match("authentication") then
        diagnostic_info = "\n\nPossible causes:\n" ..
                         "- GitHub token is invalid or expired\n" ..
                         "- Token lacks 'repo' permissions\n\n" ..
                         "Try setting a new token with :GithubSetToken"
      elseif err and err:match("Not Found") then
        diagnostic_info = "\n\nPossible causes:\n" ..
                         "- Repository '" .. state.owner .. "/" .. state.repo .. "' doesn't exist\n" ..
                         "- Your token doesn't have access to this repository\n" ..
                         "- Repository name may be incorrect"
      elseif err and err:match("timeout") then
        diagnostic_info = "\n\nPossible causes:\n" ..
                         "- Network connectivity issues\n" ..
                         "- GitHub API may be experiencing problems\n\n" ..
                         "Try again later or check your internet connection"
      elseif not data then
        diagnostic_info = "\n\nTry checking:\n" ..
                         "- Your GitHub token is set correctly\n" ..
                         "- You have git installed and configured\n" ..
                         "- You're in a valid git repository\n" ..
                         "- The remote URL is a GitHub repository"
      end
      
      update_status("Error loading issues: " .. error_msg .. diagnostic_info, "error")
      
      -- Show diagnostic info in the details pane
      vim.api.nvim_buf_set_option(state.buf_details, 'modifiable', true)
      local lines = {
        "Error loading issues",
        "===================",
        "",
        "Error: " .. error_msg,
        "",
        "Diagnostic Information:",
        "- Repository: " .. (state.owner or "unknown") .. "/" .. (state.repo or "unknown"),
        "- GitHub token: " .. (state.token and "Set" or "Not set or invalid"),
        "- Issue state: " .. state.issue_state,
        "",
        "Troubleshooting Steps:",
        "1. Verify your GitHub token is valid and has proper permissions",
        "2. Check that the repository exists and you have access to it",
        "3. Verify you have a working internet connection",
        "4. Try again later if GitHub API might be experiencing issues",
        "",
        "You can set a new token with :GithubSetToken or update your configuration."
      }
      vim.api.nvim_buf_set_lines(state.buf_details, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(state.buf_details, 'modifiable', false)
      
      return
    end
    
    state.issues = data
    update_issues_list()
    
    if #data == 0 then
      update_status("No issues found")
    else
      update_status("Loaded " .. #data .. " issues")
      
      -- Auto-select first issue if none selected
      if state.selected_issue_idx > #data then
        state.selected_issue_idx = 1
      end
      
      -- Auto-load first issue details
      view_selected_issue()
    end
  end
  
  -- Use search or regular list
  if state.search_term then
    local query = state.search_term .. " repo:" .. state.owner .. "/" .. state.repo
    if state.issue_state ~= "all" then
      query = query .. " state:" .. state.issue_state
    end
    
    api.search_issues({
      token = state.token,
      query = query,
      per_page = state.per_page
    }, handle_issues)
  else
    api.list_issues({
      token = state.token,
      owner = state.owner,
      repo = state.repo,
      state = state.issue_state,
      per_page = state.per_page,
      page = state.page
    }, handle_issues)
  end
end

-- Load details for a specific issue
local function load_issue_details(issue_number)
  state.loading = true
  update_status("Loading issue #" .. issue_number .. "...")
  
  -- Clear details
  state.issue_details = nil
  state.comments = {}
  update_issue_details()
  
  -- Load issue details
  api.get_issue({
    token = state.token,
    owner = state.owner,
    repo = state.repo,
    issue_number = issue_number
  }, function(issue, err)
    if err or not issue then
      update_status("Error loading issue: " .. (err or "Unknown error"), "error")
      state.loading = false
      return
    end
    
    state.issue_details = issue
    
    -- Load comments
    api.get_comments({
      token = state.token,
      owner = state.owner,
      repo = state.repo,
      issue_number = issue_number
    }, function(comments, err)
      state.loading = false
      
      if err then
        update_status("Error loading comments: " .. err, "error")
        comments = {}
      else
        state.comments = comments or {}
      end
      
      update_issue_details()
      update_status("Loaded issue #" .. issue_number)
    end)
  end)
end

-- Update the issues list display
local function update_issues_list()
  vim.api.nvim_buf_set_option(state.buf_issues, 'modifiable', true)
  
  local lines = {}
  for i, issue in ipairs(state.issues) do
    local line = format_title(issue)
    table.insert(lines, line)
  end
  
  if #lines == 0 then
    table.insert(lines, "No issues found")
  end
  
  vim.api.nvim_buf_set_lines(state.buf_issues, 0, -1, false, lines)
  
  -- Highlight selected line
  vim.api.nvim_buf_add_highlight(state.buf_issues, -1, 'Visual', state.selected_issue_idx - 1, 0, -1)
  
  vim.api.nvim_buf_set_option(state.buf_issues, 'modifiable', false)
end

-- Update issue details display
local function update_issue_details()
  vim.api.nvim_buf_set_option(state.buf_details, 'modifiable', true)
  
  local lines = {}
  
  if not state.issue_details then
    table.insert(lines, "Select an issue to view details")
  else
    local issue = state.issue_details
    
    -- Issue header
    local status = issue.state == "open" and "Open" or "Closed"
    local status_color = issue.state == "open" and "%#GitSignsAdd#" or "%#GitSignsChange#"
    
    table.insert(lines, string.format("%s[%s]%s #%d: %s", status_color, status, "%#Normal#", issue.number, issue.title))
    table.insert(lines, string.format("Created by %s on %s", issue.user.login, format_date(issue.created_at)))
    
    if issue.state == "closed" and issue.closed_at then
      table.insert(lines, string.format("Closed on %s", format_date(issue.closed_at)))
    end
    
    -- Labels
    if #issue.labels > 0 then
      local labels = {}
      for _, label in ipairs(issue.labels) do
        table.insert(labels, label.name)
      end
      table.insert(lines, "Labels: " .. table.concat(labels, ", "))
    end
    
    -- Body
    table.insert(lines, "")
    table.insert(lines, "Description:")
    table.insert(lines, "----------------------------------------")
    
    -- Split body into lines
    local body_lines = utils.split_lines(issue.body or "No description provided")
    for _, line in ipairs(body_lines) do
      table.insert(lines, line)
    end
    
    -- Comments
    if #state.comments > 0 then
      table.insert(lines, "")
      table.insert(lines, string.format("Comments (%d):", #state.comments))
      table.insert(lines, "----------------------------------------")
      
      for _, comment in ipairs(state.comments) do
        table.insert(lines, "")
        table.insert(lines, string.format("%s commented on %s:", comment.user.login, format_date(comment.created_at)))
        table.insert(lines, "")
        
        -- Split comment body into lines
        local comment_lines = utils.split_lines(comment.body or "")
        for _, line in ipairs(comment_lines) do
          table.insert(lines, line)
        end
      end
    else
      table.insert(lines, "")
      table.insert(lines, "No comments")
    end
  end
  
  vim.api.nvim_buf_set_lines(state.buf_details, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf_details, 'modifiable', false)
end

-- Update status message
local function update_status(message, type)
  if type == "error" then
    vim.notify(message, vim.log.levels.ERROR)
  else
    vim.notify(message, vim.log.levels.INFO)
  end
end

-- Prompt for search query
local function prompt_search()
  vim.ui.input({
    prompt = "Search issues: ",
    default = state.search_term or "",
  }, function(input)
    if input and input ~= "" then
      state.search_term = input
      state.page = 1
      load_issues()
    elseif input == "" then
      state.search_term = nil
      state.page = 1
      load_issues()
    end
  end)
end

-- Prompt for creating a new issue
local function prompt_create_issue()
  vim.ui.input({
    prompt = "Issue title: ",
  }, function(title)
    if not title or title == "" then
      return
    end
    
    -- Create a temporary buffer for the description
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "# Issue Description",
      "#",
      "# Write a detailed description of the issue here.",
      "# Lines starting with # will be ignored.",
      "",
    })
    
    -- Open buffer in a split
    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_name(buf, "ISSUE_DESCRIPTION.md")
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
    
    -- Register command to submit the issue
    vim.api.nvim_create_user_command("IssueSubmit", function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local body_lines = {}
      
      for _, line in ipairs(lines) do
        if not line:match("^%s*#") then
          table.insert(body_lines, line)
        end
      end
      
      local body = table.concat(body_lines, "\n")
      
      -- Close the buffer
      vim.cmd("bdelete!")
      
      -- Create the issue
      state.loading = true
      update_status("Creating issue...")
      
      api.create_issue({
        token = state.token,
        owner = state.owner,
        repo = state.repo,
        title = title,
        body = body
      }, function(issue, err)
        state.loading = false
        
        if err or not issue then
          update_status("Error creating issue: " .. (err or "Unknown error"), "error")
          return
        end
        
        update_status("Issue #" .. issue.number .. " created successfully")
        load_issues()
      end)
    end, {})
    
    -- Register command to cancel
    vim.api.nvim_create_user_command("IssueCancel", function()
      vim.cmd("bdelete!")
      update_status("Issue creation cancelled")
    end, {})
    
    -- Show instructions
    vim.notify("Write your issue description and use :IssueSubmit to create or :IssueCancel to abort", vim.log.levels.INFO)
  end)
end

-- Prompt for adding a comment
local function prompt_comment()
  if not state.issue_details then
    update_status("Select an issue first", "error")
    return
  end
  
  -- Create a temporary buffer for the comment
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "# Write your comment below",
    "#",
    "# Lines starting with # will be ignored.",
    "",
  })
  
  -- Open buffer in a split
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, "ISSUE_COMMENT.md")
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  
  -- Register command to submit the comment
  vim.api.nvim_create_user_command("CommentSubmit", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local comment_lines = {}
    
    for _, line in ipairs(lines) do
      if not line:match("^%s*#") then
        table.insert(comment_lines, line)
      end
    end
    
    local body = table.concat(comment_lines, "\n")
    
    -- Close the buffer
    vim.cmd("bdelete!")
    
    if body:gsub("%s", "") == "" then
      update_status("Comment is empty, not submitted")
      return
    end
    
    -- Create the comment
    state.loading = true
    update_status("Adding comment...")
    
    api.create_comment({
      token = state.token,
      owner = state.owner,
      repo = state.repo,
      issue_number = state.issue_details.number,
      body = body
    }, function(comment, err)
      state.loading = false
      
      if err or not comment then
        update_status("Error creating comment: " .. (err or "Unknown error"), "error")
        return
      end
      
      update_status("Comment added successfully")
      load_issue_details(state.issue_details.number)
    end)
  end, {})
  
  -- Register command to cancel
  vim.api.nvim_create_user_command("CommentCancel", function()
    vim.cmd("bdelete!")
    update_status("Comment cancelled")
  end, {})
  
  -- Show instructions
  vim.notify("Write your comment and use :CommentSubmit to post or :CommentCancel to abort", vim.log.levels.INFO)
end

-- View API rate limits
local function view_api_limits()
  state.loading = true
  update_status("Checking API rate limits...")
  
  api.get_rate_limits(state.token, function(data, err)
    state.loading = false
    
    if err or not data then
      update_status("Error checking rate limits: " .. (err or "Unknown error"), "error")
      return
    end
    
    local resources = data.resources
    local core = resources.core
    local remaining = core.remaining
    local limit = core.limit
    local reset_time = os.date("%H:%M:%S", core.reset)
    
    local message = string.format(
      "GitHub API Rate Limits: %d/%d remaining, resets at %s",
      remaining,
      limit,
      reset_time
    )
    
    update_status(message)
    
    -- Show detailed info in a scratch buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "GitHub API Rate Limits",
      "=====================",
      "",
      string.format("Core: %d/%d remaining (resets at %s)", core.remaining, core.limit, reset_time),
      string.format("Search: %d/%d remaining", resources.search.remaining, resources.search.limit),
      string.format("GraphQL: %d/%d remaining", resources.graphql.remaining, resources.graphql.limit),
    })
    
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_height(0, 8)
  end)
end

-- Close the UI
local function close_ui()
  if state.win_issues and vim.api.nvim_win_is_valid(state.win_issues) then
    vim.api.nvim_win_close(state.win_issues, true)
  end
  
  if state.win_details and vim.api.nvim_win_is_valid(state.win_details) then
    vim.api.nvim_win_close(state.win_details, true)
  end
  
  reset_state()
end

return M 