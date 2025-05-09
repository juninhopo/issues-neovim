-- Issue View module
local api = require("issues-neovim.api")
local utils = require("issues-neovim.utils")

local M = {}

-- Open the issue view UI for a specific issue
function M.open(issue_number, opts)
  -- First detect repository if not provided
  if not opts.owner or not opts.repo then
    local repo_info = api.detect_repository()
    if repo_info.detected then
      opts.owner = repo_info.owner
      opts.repo = repo_info.repo
    end
  end
  
  -- Create buffers for issue view
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Calculate dimensions
  local width = math.floor(vim.o.columns * (opts.ui.float.width or 0.8))
  local height = math.floor(vim.o.lines * (opts.ui.float.height or 0.8))
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Loading Issue #' .. issue_number .. ' ',
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Loading issue...", "", "Please wait..."})
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Set key mappings
  local function map(mode, key, handler, desc)
    vim.keymap.set(mode, key, handler, { buffer = buf, desc = desc, noremap = true, silent = true })
  end
  
  map('n', 'q', function() 
    vim.api.nvim_win_close(win, true)
  end, "Close")
  
  map('n', 'c', function()
    prompt_comment(issue_number, opts, buf, win)
  end, "Add comment")
  
  -- Load issue data
  load_issue(issue_number, opts, buf, win)
end

-- Load issue data from API
local function load_issue(issue_number, opts, buf, win)
  -- Show loading message
  vim.notify("Loading issue #" .. issue_number, vim.log.levels.INFO)
  
  -- Load issue details
  api.get_issue({
    token = opts.token,
    owner = opts.owner,
    repo = opts.repo,
    issue_number = issue_number
  }, function(issue, err)
    if err or not issue then
      update_buffer(buf, {"Error loading issue: " .. (err or "Unknown error")})
      vim.api.nvim_win_set_config(win, {
        title = ' Error Loading Issue #' .. issue_number .. ' '
      })
      return
    end
    
    -- Set window title
    local state_icon = issue.state == "open" and "● " or "✓ "
    vim.api.nvim_win_set_config(win, {
      title = string.format(' %s Issue #%d - %s ', state_icon, issue.number, issue.title)
    })
    
    -- Load comments
    api.get_comments({
      token = opts.token,
      owner = opts.owner,
      repo = opts.repo,
      issue_number = issue_number
    }, function(comments, comment_err)
      -- Prepare content with or without comments
      local content = format_issue_content(issue, comments or {}, comment_err)
      update_buffer(buf, content)
    end)
  end)
end

-- Format issue content for display
local function format_issue_content(issue, comments, comment_err)
  local lines = {}
  
  -- Issue header
  local status = issue.state == "open" and "Open" or "Closed"
  table.insert(lines, string.format("#%d: %s", issue.number, issue.title))
  table.insert(lines, string.format("Status: %s", status))
  table.insert(lines, string.format("Created by %s on %s", issue.user.login, os.date("%Y-%m-%d %H:%M", utils.parse_iso_date(issue.created_at))))
  
  if issue.state == "closed" and issue.closed_at then
    table.insert(lines, string.format("Closed on %s", os.date("%Y-%m-%d %H:%M", utils.parse_iso_date(issue.closed_at))))
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
  if comment_err then
    table.insert(lines, "")
    table.insert(lines, "Error loading comments: " .. comment_err)
  elseif #comments > 0 then
    table.insert(lines, "")
    table.insert(lines, string.format("Comments (%d):", #comments))
    table.insert(lines, "----------------------------------------")
    
    for _, comment in ipairs(comments) do
      table.insert(lines, "")
      table.insert(lines, string.format("%s commented on %s:", 
        comment.user.login, 
        os.date("%Y-%m-%d %H:%M", utils.parse_iso_date(comment.created_at))
      ))
      table.insert(lines, "")
      
      -- Split comment body into lines
      local comment_lines = utils.split_lines(comment.body or "")
      for _, line in ipairs(comment_lines) do
        table.insert(lines, line)
      end
      
      table.insert(lines, "----------------------------------------")
    end
  else
    table.insert(lines, "")
    table.insert(lines, "No comments")
  end
  
  -- Add footer with instructions
  table.insert(lines, "")
  table.insert(lines, "")
  table.insert(lines, "Press 'c' to add a comment, 'q' to close")
  
  return lines
end

-- Update buffer content
local function update_buffer(buf, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
end

-- Prompt for adding a comment
local function prompt_comment(issue_number, opts, parent_buf, parent_win)
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
      vim.notify("Comment is empty, not submitted", vim.log.levels.WARN)
      return
    end
    
    -- Create the comment
    vim.notify("Adding comment...", vim.log.levels.INFO)
    
    api.create_comment({
      token = opts.token,
      owner = opts.owner,
      repo = opts.repo,
      issue_number = issue_number,
      body = body
    }, function(comment, err)
      if err or not comment then
        vim.notify("Error creating comment: " .. (err or "Unknown error"), vim.log.levels.ERROR)
        return
      end
      
      vim.notify("Comment added successfully", vim.log.levels.INFO)
      
      -- Reload issue to show the new comment
      if parent_buf and vim.api.nvim_buf_is_valid(parent_buf) and 
         parent_win and vim.api.nvim_win_is_valid(parent_win) then
        load_issue(issue_number, opts, parent_buf, parent_win)
      end
    end)
  end, {})
  
  -- Register command to cancel
  vim.api.nvim_create_user_command("CommentCancel", function()
    vim.cmd("bdelete!")
    vim.notify("Comment cancelled", vim.log.levels.INFO)
  end, {})
  
  -- Show instructions
  vim.notify("Write your comment and use :CommentSubmit to post or :CommentCancel to abort", vim.log.levels.INFO)
end

return M 